# MedConnect Flutter app

See the main [README](../README.md) for the full picture and [AGORA_SETUP.md](../AGORA_SETUP.md) for Agora.

```bash
dart run tool/setup_platforms.dart   # first time only: creates android/ & ios/ + camera/mic permissions
flutter run
```

Placeholders to fill in: **`lib/core/config/app_config.dart`**, which holds `apiBaseUrl` and `agoraAppId`.
Until the Agora App ID is set, the app shows a yellow warning bar and video calls are disabled.

Switch a device's mode: **⋮ → Use device as…** (doctor/pharmacy/owner), or long-press the logo on the kiosk
welcome screen (staff only).

Unit tests: `flutter test`.
