/// ---------------------------------------------------------------------------
///  MedConnect app configuration
/// ---------------------------------------------------------------------------
///
/// Server address: the deployed **medconnect-web** (Next.js) site, e.g.
/// `https://medconnect-web.vercel.app`. Three ways to set it:
///   1. Leave it empty — each device asks for it once on first launch
///      (Settings → Server can change it later).
///   2. Put it in [defaultServerUrl] below before building the APK/IPA.
///   3. `flutter build apk --dart-define=SERVER_URL=https://your-site.vercel.app`
///
/// The Agora **App Certificate** is never in the app — the server signs a
/// short-lived token for every call.
class AppConfig {
  AppConfig._();

  /// Your deployed web project URL (without /api). Empty = ask on first launch.
  static const String defaultServerUrl = String.fromEnvironment('SERVER_URL', defaultValue: '');

  /// Agora Console → project → App ID (not secret). Same value as the web project.
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '91a5d012fb4b490b94732cf3b1371a95',
  );

  static bool get isAgoraConfigured => agoraAppId.length == 32;

  /// "medconnect.vercel.app", "https://x.com/", "http://192.168.1.5:3000/api" → "https://…" without trailing / or /api.
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
    if (url.endsWith('/api')) url = url.substring(0, url.length - 4);
    return url;
  }

  /// API base for a server URL: `https://site` → `https://site/api`.
  static String apiBase(String serverUrl) => '${normalizeServerUrl(serverUrl)}/api';

  // ---- Branding ----
  static const String brandName = 'MedConnect';
  static const String chainName = 'MedConnect Pharmacy';
  static const String tagline = 'Instant doctor consultations at your neighbourhood pharmacy';
}
