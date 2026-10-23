import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/services/session_service.dart';
import '../base_view_model.dart';

/// Server address screen: test the connection to the Gladskin API (GET /api/tele/health), then save.
class ServerSettingsViewModel extends BaseViewModel {
  ServerSettingsViewModel({required SessionService session})
      : _session = session,
        urlController = TextEditingController(text: session.serverUrl);

  final SessionService _session;
  final TextEditingController urlController;

  bool testing = false;
  bool saving = false;

  /// null = not tested yet.
  bool? ok;
  String? message;

  String get normalized => AppConfig.normalizeServerUrl(urlController.text);

  void onChanged() {
    ok = null;
    message = null;
    notify();
  }

  /// Calls GET /api/health on the server.
  Future<bool> test() async {
    final url = normalized;
    if (url.isEmpty) {
      ok = false;
      message = 'Enter the server address.';
      notify();
      return false;
    }
    testing = true;
    ok = null;
    message = null;
    notify();
    try {
      final res = await http.get(Uri.parse('${AppConfig.apiBase(url)}/health')).timeout(const Duration(seconds: 15));
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data is Map && data['ok'] == true) {
        final agora = data['agora'];
        final serverAppId = agora is Map ? agora['appId'] as String? : null;
        final certificate = agora is Map && agora['certificateConfigured'] == true;
        if (serverAppId != null && serverAppId != AppConfig.agoraAppId) {
          ok = false;
          message = 'Connected, but the server uses a different Agora App ID. Use the same App ID in both.';
        } else if (!certificate) {
          ok = true;
          message = 'Connected. Note: AGORA_APP_CERTIFICATE is not set on the server, so video calls will fail.';
        } else {
          ok = true;
          message = 'Connected to $url — MedConnect is ready.';
        }
      } else {
        ok = false;
        final err = data is Map ? (data['message'] ?? data['error']) : null;
        message = err is String ? 'Server problem: $err' : 'The server answered with an error (${res.statusCode}).';
      }
    } on TimeoutException {
      ok = false;
      message = 'No answer from $url. Check the address and the internet connection.';
    } on FormatException {
      ok = false;
      message = 'That address is not the Gladskin API server.';
    } catch (_) {
      ok = false;
      message = 'Cannot reach $url. Check the address and the internet connection.';
    } finally {
      testing = false;
      notify();
    }
    return ok == true;
  }

  /// Tests, then saves if the server answered.
  Future<bool> save() async {
    saving = true;
    notify();
    final good = await test();
    if (good) await _session.setServerUrl(normalized);
    saving = false;
    notify();
    return good;
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}
