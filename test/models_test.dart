import 'package:flutter_test/flutter_test.dart';
import 'package:medconnect/core/utils/formatters.dart';
import 'package:medconnect/data/models/chat_message.dart';
import 'package:medconnect/data/models/consultation.dart';
import 'package:medconnect/data/models/rtc_credentials.dart';

void main() {
  test('Consultation parses backend JSON', () {
    final c = Consultation.fromJson({
      'id': 'con_abc',
      'token': 'T001',
      'storeId': 'store-2',
      'patient': {'name': 'Meera Nayak', 'age': 34, 'gender': 'Female', 'phone': '9845012345'},
      'symptoms': ['Fever', 'Sore throat'],
      'complaint': 'since yesterday',
      'duration': '1–2 days',
      'allergies': '',
      'vitals': {'bp': '118/76', 'temperature': '100.2'},
      'specialty': 'General Physician',
      'status': 'in_call',
      'createdAt': '2026-10-12T08:00:00.000Z',
      'store': {'id': 'store-2', 'name': 'MedConnect Pharmacy — Kadri', 'city': 'Mangaluru'},
    });
    expect(c.status, ConsultationStatus.inCall);
    expect(c.channelName, 'con_abc');
    expect(c.concern, 'Fever, Sore throat — since yesterday');
    expect(c.store?.shortName, 'Kadri');
    expect(c.vitals.summary, 'BP 118/76 · 100.2°F');
  });

  test('RtcCredentials parses token response', () {
    final r = RtcCredentials.fromJson({
      'appId': 'abc',
      'channelName': 'con_abc',
      'uid': 1001,
      'token': '007eJx...',
      'expiresAt': '2026-10-12T09:00:00.000Z',
    });
    expect(r.uid, 1001);
    expect(r.token, startsWith('007'));
  });

  test('Chat messages round-trip', () {
    final m = ChatMessage(from: 'doctor', text: 'Show your throat', at: DateTime.utc(2026, 10, 12));
    final back = ChatMessage.tryDecode(m.encode());
    expect(back?.text, 'Show your throat');
    expect(back?.from, 'doctor');
    expect(ChatMessage.tryDecode('not json'), isNull);
  });

  test('Formatters', () {
    expect(Fmt.initials('Dr. Ananya Rao'), 'AR');
    expect(Fmt.clock(const Duration(minutes: 3, seconds: 7)), '03:07');
  });
}
