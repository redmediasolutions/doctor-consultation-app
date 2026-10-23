import '../../core/network/api_client.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/session_service.dart';
import '../models/json_utils.dart';

/// Mobile OTP sign-in (same as the Gladskin admin app), then the Node backend
/// decides who this is: owner, store staff or doctor (GET /api/tele/auth/me).
class AuthRepository {
  AuthRepository(this._api, this._firebase, this._session);

  final ApiClient _api;
  final FirebaseAuthService _firebase;
  final SessionService _session;

  /// Sends the OTP. Returns (reqId, phone in +91… format).
  Future<(String, String)> sendOtp(String phone) async {
    final e164 = FirebaseAuthService.toE164(phone);
    if (e164.replaceAll(RegExp(r'\D'), '').length < 12) {
      throw ApiException('Enter a valid 10-digit mobile number.');
    }
    return (await _firebase.sendOtp(e164), e164);
  }

  /// Checks the OTP, signs in, and makes sure this login may use [role] on this device.
  Future<void> verifyOtp({
    required DeviceRole role,
    required String phone,
    required String otp,
    required String reqId,
  }) async {
    await _firebase.verifyOtp(phoneNumber: phone, otp: otp, reqId: reqId);

    Map<String, dynamic> user;
    try {
      final res = asMap(await _api.get('/auth/me'));
      user = asMap(res['user'] ?? res);
    } catch (_) {
      await _session.logout();
      rethrow;
    }

    final kind = asString(user['kind']);
    if (!role.allowedKinds.contains(kind)) {
      await _session.logout();
      final who = switch (kind) {
        'doctor' => 'a doctor',
        'staff' => 'store staff',
        'admin' => 'the owner',
        _ => 'someone else',
      };
      throw ApiException('This number is registered as $who. ${role.label} needs ${role.whoSignsIn}.');
    }
    await _session.saveProfile(user);
  }

  /// Re-reads who is signed in (e.g. a doctor's details changed).
  Future<void> refreshProfile() async {
    final res = asMap(await _api.get('/auth/me'));
    await _session.saveProfile(asMap(res['user'] ?? res));
  }

  Future<void> logout() async {
    if (_session.kind == 'doctor') {
      try {
        await _api.post('/doctors/heartbeat', {'status': 'offline'});
      } catch (_) {
        // Going offline is best-effort; the server marks silent doctors offline anyway.
      }
    }
    await _session.logout();
  }
}
