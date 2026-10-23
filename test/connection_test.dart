import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medconnect/core/config/app_config.dart';
import 'package:medconnect/core/network/api_client.dart';
import 'package:medconnect/core/services/firebase_auth_service.dart';
import 'package:medconnect/data/models/consultation.dart';

void main() {
  test('Server URL → /api/tele base', () {
    expect(AppConfig.apiBase('api-12v1.gladskin.in'), 'https://api-12v1.gladskin.in/api/tele');
    expect(AppConfig.apiBase('https://api-12v1.gladskin.in/api/'), 'https://api-12v1.gladskin.in/api/tele');
    expect(AppConfig.apiBase('https://api-12v1.gladskin.in/api/tele'), 'https://api-12v1.gladskin.in/api/tele');
    expect(AppConfig.apiBase('192.168.1.5:4002'), 'http://192.168.1.5:4002/api/tele');
    expect(AppConfig.defaultServerUrl, isNotEmpty);
  });

  test('Mobile numbers → +91 format', () {
    expect(FirebaseAuthService.toE164('98450 12345'), '+919845012345');
    expect(FirebaseAuthService.toE164('09845012345'), '+919845012345');
    expect(FirebaseAuthService.toE164('919845012345'), '+919845012345');
    expect(FirebaseAuthService.toE164('+91 98450-12345'), '+919845012345');
  });

  test('Consultation uses the Agora channel sent by the server', () {
    final c = Consultation.fromJson({
      'id': '42',
      'token': 'T001',
      'storeId': '1',
      'channelName': 'mc-3f2a9c',
      'patient': {'name': 'A', 'age': 30, 'gender': 'Male', 'phone': '9845012345'},
      'status': 'waiting',
      'createdAt': '2026-10-23T08:00:00.000Z',
    });
    expect(c.channelName, 'mc-3f2a9c');
  });

  test('ApiClient unwraps {success,data}, sends Bearer token, retries once after 401', () async {
    var calls = 0;
    final seen = <String?>[];
    final client = MockClient((req) async {
      calls++;
      seen.add(req.headers['Authorization']);
      if (req.headers['Authorization'] == 'Bearer old') {
        return http.Response(jsonEncode({'success': false, 'message': 'Invalid or expired authentication token'}), 401);
      }
      return http.Response(jsonEncode({'success': true, 'data': [1, 2, 3]}), 200);
    });
    var token = 'old';
    final api = ApiClient(
      baseUrlReader: () => 'https://x.test/api/tele',
      tokenReader: ({bool forceRefresh = false}) async {
        if (forceRefresh) token = 'new';
        return token;
      },
      client: client,
    );
    expect(await api.get('/doctors'), [1, 2, 3]);
    expect(calls, 2);
    expect(seen, ['Bearer old', 'Bearer new']);
  });

  test('ApiClient shows the server message on errors', () async {
    final api = ApiClient(
      baseUrlReader: () => 'https://x.test/api/tele',
      tokenReader: ({bool forceRefresh = false}) async => 't',
      client: MockClient((_) async =>
          http.Response(jsonEncode({'success': false, 'code': 'ALREADY_TAKEN', 'message': 'Another doctor has already taken this patient'}), 409)),
    );
    await expectLater(
      api.patch('/consultations/1', {'action': 'accept'}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Another doctor has already taken this patient')),
    );
  });
}
