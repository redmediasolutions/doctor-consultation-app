import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// What this device is used as. Chosen once on first launch.
enum DeviceRole { kiosk, doctor, pharmacy, admin }

extension DeviceRoleX on DeviceRole {
  String get label => switch (this) {
        DeviceRole.kiosk => 'Store kiosk',
        DeviceRole.doctor => 'Doctor',
        DeviceRole.pharmacy => 'Pharmacy counter',
        DeviceRole.admin => 'Owner dashboard',
      };

  /// Which logins (GET /api/tele/auth/me → kind) may use this mode.
  ///   kiosk / pharmacy → store staff (their own store) or the owner (picks a store)
  List<String> get allowedKinds => switch (this) {
        DeviceRole.kiosk => const ['staff', 'admin'],
        DeviceRole.pharmacy => const ['staff', 'admin'],
        DeviceRole.doctor => const ['doctor'],
        DeviceRole.admin => const ['admin'],
      };

  String get whoSignsIn => switch (this) {
        DeviceRole.kiosk => "the store's staff login",
        DeviceRole.pharmacy => "the store's staff login",
        DeviceRole.doctor => 'a doctor login',
        DeviceRole.admin => "the owner's login",
      };
}

/// Persists the device role, the login (Firebase tokens + who it is) and the chosen store.
/// The app's root widget listens to this and shows the right screen.
class SessionService extends ChangeNotifier {
  static const _kRole = 'mc.role';
  static const _kStore = 'mc.store';
  static const _kIdToken = 'mc.auth.idToken';
  static const _kRefreshToken = 'mc.auth.refreshToken';
  static const _kExpiry = 'mc.auth.expiry';
  static const _kProfile = 'mc.profile';
  static const _kDoctorAvailable = 'mc.doctor.available';
  static const _kServer = 'mc.server';

  late SharedPreferences _prefs;

  DeviceRole? _role;
  Map<String, dynamic>? _store;
  String? _idToken;
  String? _refreshToken;
  DateTime? _idTokenExpiry;
  Map<String, dynamic>? _profile;
  String _serverUrl = '';

  DeviceRole? get role => _role;

  /// Firebase ID token (use FirebaseAuthService.idToken() to get a fresh one).
  String? get idToken => _idToken;
  String? get refreshToken => _refreshToken;
  DateTime? get idTokenExpiry => _idTokenExpiry;

  /// GET /api/tele/auth/me → { uid, kind, role, fullName, phone, storeId, store?, doctor? }
  Map<String, dynamic>? get profile => _profile;
  bool get isSignedIn => _refreshToken != null && _profile != null;
  String get kind => (_profile?['kind'] as String?) ?? '';

  /// Store this device works for: staff → their own store; owner → the one they picked.
  Map<String, dynamic>? get storeJson {
    if (kind == 'staff') {
      final s = _profile?['store'];
      return s is Map<String, dynamic> ? s : null;
    }
    return _store;
  }

  String? get storeId => storeJson?['id']?.toString();

  /// Gladskin Node.js API, e.g. https://api-12v1.gladskin.in (no /api).
  String get serverUrl => _serverUrl;
  bool get hasServer => _serverUrl.isNotEmpty;

  /// Base URL for API calls, e.g. https://api-12v1.gladskin.in/api/tele
  String get apiBaseUrl => hasServer ? AppConfig.apiBase(_serverUrl) : '';

  bool get doctorAvailable => _prefs.getBool(_kDoctorAvailable) ?? true;
  Future<void> setDoctorAvailable(bool v) => _prefs.setBool(_kDoctorAvailable, v);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _serverUrl = AppConfig.normalizeServerUrl(_prefs.getString(_kServer) ?? AppConfig.defaultServerUrl);
    final r = _prefs.getString(_kRole);
    _role = null;
    for (final e in DeviceRole.values) {
      if (e.name == r) _role = e;
    }
    _store = _readJson(_kStore);
    _profile = _readJson(_kProfile);
    _idToken = _prefs.getString(_kIdToken);
    _refreshToken = _prefs.getString(_kRefreshToken);
    final exp = _prefs.getInt(_kExpiry);
    _idTokenExpiry = exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp);

    // Remove data saved by the old PIN-login version of the app.
    for (final k in ['mc.token', 'mc.kiosk.store']) {
      if (_prefs.containsKey(k)) await _prefs.remove(k);
    }
  }

  Map<String, dynamic>? _readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Saves the server address. Signs out, because logins are checked by that server.
  Future<void> setServerUrl(String url) async {
    final next = AppConfig.normalizeServerUrl(url);
    if (next != _serverUrl) await _clearLogin(notify: false);
    _serverUrl = next;
    await _prefs.setString(_kServer, next);
    notifyListeners();
  }

  Future<void> setRole(DeviceRole role) async {
    _role = role;
    await _prefs.setString(_kRole, role.name);
    notifyListeners();
  }

  /// Owner picks which store this kiosk / counter is for.
  Future<void> setStore(Map<String, dynamic>? store) async {
    _store = store;
    if (store == null) {
      await _prefs.remove(_kStore);
    } else {
      await _prefs.setString(_kStore, jsonEncode(store));
    }
    notifyListeners();
  }

  /// Firebase tokens after OTP sign-in / refresh.
  Future<void> saveAuth({required String idToken, required String refreshToken, required int expiresIn}) async {
    _idToken = idToken;
    _refreshToken = refreshToken;
    _idTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    await _prefs.setString(_kIdToken, idToken);
    await _prefs.setString(_kRefreshToken, refreshToken);
    await _prefs.setInt(_kExpiry, _idTokenExpiry!.millisecondsSinceEpoch);
  }

  /// Who signed in (from the backend). Switches the app to the signed-in screen.
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    _profile = profile;
    await _prefs.setString(_kProfile, jsonEncode(profile));
    notifyListeners();
  }

  Future<void> logout() => _clearLogin();

  Future<void> _clearLogin({bool notify = true}) async {
    _idToken = null;
    _refreshToken = null;
    _idTokenExpiry = null;
    _profile = null;
    _store = null;
    for (final k in [_kIdToken, _kRefreshToken, _kExpiry, _kProfile, _kStore]) {
      await _prefs.remove(k);
    }
    if (notify) notifyListeners();
  }

  /// Forget everything and go back to the "use this device as…" screen.
  Future<void> resetDevice() async {
    _role = null;
    await _prefs.remove(_kRole);
    await _clearLogin();
  }
}
