/// ---------------------------------------------------------------------------
///  MedConnect app configuration
/// ---------------------------------------------------------------------------
///
/// Everything below is already filled in for the Gladskin backend, so the app
/// works as soon as it is installed. Values can be overridden at build time:
///   flutter build apk --dart-define=SERVER_URL=https://api.example.com
///
/// None of these are secrets: the Firebase Web API key and the OTP function
/// URLs are public client values (the same ones the Gladskin admin website uses),
/// and the Agora **App Certificate** is never in the app — the server signs a
/// short-lived token for every call.
class AppConfig {
  AppConfig._();

  /// Gladskin Node.js API (without /api). MedConnect routes live under /api/tele.
  static const String defaultServerUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://api-12v1.gladskin.in',
  );

  /// Agora Console → project → App ID (not secret). Same value as the server.
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '91a5d012fb4b490b94732cf3b1371a95',
  );

  static bool get isAgoraConfigured => agoraAppId.length == 32;

  // ---- Login: mobile OTP (MSG91 cloud functions) → Firebase (same project as Gladskin) ----

  /// Firebase Web API key (public; same as NEXT_PUBLIC_FIREBASE_API_KEY).
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDV8aDfUef3jeGmbO8teUDP6abexIs_xJY',
  );

  static const String otpSendUrl = String.fromEnvironment(
    'OTP_SEND_URL',
    defaultValue: 'https://sendgladskinotp-zkhqe3r4ta-uc.a.run.app',
  );

  static const String otpVerifyUrl = String.fromEnvironment(
    'OTP_VERIFY_URL',
    defaultValue: 'https://verifygladskinotp-zkhqe3r4ta-uc.a.run.app',
  );

  /// Mobile numbers without a country code get this one.
  static const String countryCode = '+91';

  /// "api.example.com", "https://x.com/", "http://192.168.1.5:4002/api" → "https://…" without trailing / or /api.
  static String normalizeServerUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final local = RegExp(r'^(localhost|127\.|10\.|192\.168\.|172\.)').hasMatch(url);
      url = '${local ? 'http' : 'https'}://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api/tele')) url = url.substring(0, url.length - 9);
    if (url.endsWith('/api')) url = url.substring(0, url.length - 4);
    return url;
  }

  /// API base for a server URL: `https://site` → `https://site/api/tele`.
  static String apiBase(String serverUrl) => '${normalizeServerUrl(serverUrl)}/api/tele';

  // ---- Branding ----
  static const String brandName = 'MedConnect';
  static const String chainName = 'MedConnect Pharmacy';
  static const String tagline = 'Instant doctor consultations at your neighbourhood pharmacy';
}
