import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../network/api_client.dart';
import 'session_service.dart';

/// Mobile OTP login, the same flow as the Gladskin admin website:
///
///   1. sendOtp   → Gladskin cloud function (MSG91)             → reqId
///   2. verifyOtp → Gladskin cloud function                      → Firebase custom token
///   3. Firebase (REST)  custom token → ID token + refresh token
///   4. The ID token goes to the Node backend as `Authorization: Bearer …`
///
/// Uses Firebase's REST API, so the app needs no google-services.json / GoogleService-Info.plist.
/// ID tokens last 1 hour; [idToken] refreshes them automatically with the refresh token.
class FirebaseAuthService {
  FirebaseAuthService(this._session, {http.Client? client}) : _http = client ?? http.Client();

  final SessionService _session;
  final http.Client _http;
  static const _timeout = Duration(seconds: 20);

  Future<String>? _refreshing;

  /// "98450 12345" → "+919845012345"
  static String toE164(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
    return '${AppConfig.countryCode}${cleaned.replaceFirst(RegExp(r'^0'), '')}';
  }

  /// Sends the OTP. Returns the request id needed by [verifyOtp].
  Future<String> sendOtp(String phoneNumber) async {
    final data = await _postJson(AppConfig.otpSendUrl, {'phoneNumber': phoneNumber}, 'Failed to send OTP.');
    final reqId = data['reqId'];
    if (reqId is! String || reqId.isEmpty) throw ApiException('Failed to send OTP.');
    return reqId;
  }

  /// Checks the OTP and signs in to Firebase. Saves the tokens on the device.
  Future<void> verifyOtp({required String phoneNumber, required String otp, required String reqId}) async {
    final data = await _postJson(
      AppConfig.otpVerifyUrl,
      {'phoneNumber': phoneNumber, 'otp': otp, 'reqId': reqId},
      'Invalid OTP.',
    );
    final customToken = data['token'];
    if (customToken is! String || customToken.isEmpty) throw ApiException('Invalid OTP.');

    final res = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${AppConfig.firebaseApiKey}',
      {'token': customToken, 'returnSecureToken': true},
      'Could not sign in. Please try again.',
      firebase: true,
    );
    await _session.saveAuth(
      idToken: res['idToken'] as String,
      refreshToken: res['refreshToken'] as String,
      expiresIn: int.tryParse('${res['expiresIn']}') ?? 3600,
    );
  }

  /// A valid ID token (refreshed when < 5 minutes left, or when [forceRefresh]). null = signed out.
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (_session.refreshToken == null) return null;
    final expiry = _session.idTokenExpiry;
    final fresh = expiry != null && expiry.isAfter(DateTime.now().add(const Duration(minutes: 5)));
    if (!forceRefresh && fresh && _session.idToken != null) return _session.idToken;

    // One refresh at a time even if several requests ask together.
    final pending = _refreshing ??= _refresh();
    try {
      return await pending;
    } on ApiException catch (e) {
      // Refresh token revoked / user deleted → the login is over.
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 403) {
        await _session.logout();
        return null;
      }
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  Future<String> _refresh() async {
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('https://securetoken.googleapis.com/v1/token?key=${AppConfig.firebaseApiKey}'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'grant_type': 'refresh_token', 'refresh_token': _session.refreshToken!},
          )
          .timeout(_timeout);
    } catch (_) {
      throw ApiException('Cannot reach the login service. Check the internet connection.');
    }
    final data = _decode(res);
    if (res.statusCode != 200 || data == null) {
      throw ApiException('Your login has expired. Please sign in again.', statusCode: res.statusCode);
    }
    final idToken = data['id_token'] as String;
    await _session.saveAuth(
      idToken: idToken,
      refreshToken: data['refresh_token'] as String,
      expiresIn: int.tryParse('${data['expires_in']}') ?? 3600,
    );
    return idToken;
  }

  Future<Map<String, dynamic>> _postJson(String url, Map<String, dynamic> body, String fallback,
      {bool firebase = false}) async {
    if (url.isEmpty) throw ApiException('Login service URL is not configured.');
    final http.Response res;
    try {
      res = await _http
          .post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException('The login service is taking too long. Check the internet connection.');
    } catch (_) {
      throw ApiException('Unable to connect to the login service. Check the internet connection.');
    }

    final data = _decode(res);
    final ok = res.statusCode >= 200 && res.statusCode < 300 && data != null && (firebase || data['success'] == true);
    if (!ok) {
      String message = fallback;
      if (data != null) {
        final m = data['message'] ?? data['error'];
        if (m is String && m.isNotEmpty) message = m;
        if (m is Map && m['message'] is String) message = 'Sign-in failed (${m['message']}).';
      }
      throw ApiException(message, statusCode: res.statusCode);
    }
    return data;
  }

  Map<String, dynamic>? _decode(http.Response res) {
    try {
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }
}
