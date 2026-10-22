import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// What this device is used as. Chosen once on first launch.
enum DeviceRole { kiosk, doctor, pharmacy, admin }

extension DeviceRoleX on DeviceRole {
  /// Role name the backend expects at /auth/login.
  String get apiRole => switch (this) {
        DeviceRole.doctor => 'doctor',
        DeviceRole.pharmacy => 'staff',
        DeviceRole.admin => 'admin',
        DeviceRole.kiosk => 'kiosk',
      };

  String get label => switch (this) {
        DeviceRole.kiosk => 'Store kiosk',
        DeviceRole.doctor => 'Doctor',
        DeviceRole.pharmacy => 'Pharmacy counter',
        DeviceRole.admin => 'Owner dashboard',
      };
}

/// Persists the device role, the kiosk's store and the staff login.
/// The app's root widget listens to this and shows the right screen.
class SessionService extends ChangeNotifier {
  static const _kRole = 'mc.role';
  static const _kStore = 'mc.kiosk.store';
  static const _kToken = 'mc.token';
  static const _kProfile = 'mc.profile';
  static const _kDoctorAvailable = 'mc.doctor.available';
  static const _kServer = 'mc.server';

  late SharedPreferences _prefs;

  DeviceRole? _role;
  String? _kioskStoreId;
  String? _token;
  Map<String, dynamic>? _profile;
  String _serverUrl = '';

  DeviceRole? get role => _role;
  String? get kioskStoreId => _kioskStoreId;
  String? get token => _token;
  Map<String, dynamic>? get profile => _profile;
  bool get isSignedIn => _token != null && _profile != null;

  /// Deployed web project, e.g. https://medconnect-web.vercel.app (no /api).
  String get serverUrl => _serverUrl;
  bool get hasServer => _serverUrl.isNotEmpty;

  /// Base URL for API calls, e.g. https://medconnect-web.vercel.app/api
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
    _kioskStoreId = _prefs.getString(_kStore);
    _token = _prefs.getString(_kToken);
    final p = _prefs.getString(_kProfile);
    if (p != null) {
      try {
        _profile = jsonDecode(p) as Map<String, dynamic>;
      } catch (_) {
        _profile = null;
      }
    }
  }

  /// Saves the server address. Signs out, because a token only works on the server that issued it.
  Future<void> setServerUrl(String url) async {
    final next = AppConfig.normalizeServerUrl(url);
    if (next != _serverUrl) {
      _token = null;
      _profile = null;
      _kioskStoreId = null;
      await _prefs.remove(_kToken);
      await _prefs.remove(_kProfile);
      await _prefs.remove(_kStore);
    }
    _serverUrl = next;
    await _prefs.setString(_kServer, next);
    notifyListeners();
  }

  Future<void> setRole(DeviceRole role) async {
    _role = role;
    await _prefs.setString(_kRole, role.name);
    notifyListeners();
  }

  Future<void> setKioskStore(String storeId) async {
    _kioskStoreId = storeId;
    await _prefs.setString(_kStore, storeId);
    notifyListeners();
  }

  Future<void> saveLogin(String token, Map<String, dynamic> profile) async {
    _token = token;
    _profile = profile;
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kProfile, jsonEncode(profile));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kProfile);
    notifyListeners();
  }

  /// Forget everything and go back to the "use this device as…" screen.
  Future<void> resetDevice() async {
    _role = null;
    _kioskStoreId = null;
    _token = null;
    _profile = null;
    await _prefs.remove(_kRole);
    await _prefs.remove(_kStore);
    await _prefs.remove(_kToken);
    await _prefs.remove(_kProfile);
    notifyListeners();
  }
}
