import '../../core/network/api_client.dart';
import '../../core/services/session_service.dart';

class AuthRepository {
  AuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionService _session;

  /// Signs in a doctor / pharmacy counter / admin and stores the session on the device.
  Future<void> login({required DeviceRole role, String? id, required String pin}) async {
    final res = await _api.post('/auth/login', {
      'role': role.apiRole,
      if (id != null) 'id': id,
      'pin': pin,
    }) as Map<String, dynamic>;
    await _session.saveLogin(res['token'] as String, res['profile'] as Map<String, dynamic>);
  }

  Future<void> logout() => _session.logout();
}
