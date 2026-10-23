# MedConnect App (Flutter)

The **store kiosk and doctor app** for MedConnect, an in-store doctor teleconsultation system. One app,
four modes chosen on each device:

| Mode | Device | What it does |
| --- | --- | --- |
| **Store kiosk** | Tablet in each store | Patient registers, adds symptoms (+ vitals), does a camera check and gives consent, waits with a token, sees the doctor on **Agora video** with chat, then sees the prescription. Resets for the next patient; screen stays on. |
| **Doctor** | Doctor's phone/tablet | Available/Away, live queue from all stores, accept & call, patient details, prescription pad, chat. |
| **Pharmacy counter** | Counter tablet | Prescriptions for that store, mark dispensed. |
| **Owner dashboard** | Owner's phone | Today's numbers, consultation log, doctors, stores. |

It connects to the **Gladskin Node.js API** (shared with the billing app, same MariaDB), under
`/api/tele`. Video goes through Agora. Doctors can also use the web doctor console (doctor-consultation-web);
web and app interoperate.

**Logins** are the same as the Gladskin billing app — mobile number + OTP (MSG91 cloud function → Firebase):

| Mode | Who signs in |
| --- | --- |
| Store kiosk | that store's staff login (`users.role` store_manager / billing_staff) — once per tablet |
| Pharmacy counter | that store's staff login (or the owner, who picks a store) |
| Doctor | a doctor added in the Owner dashboard (`tele_doctors`) |
| Owner dashboard | `users.role = admin` |

Architecture: **MVVM** with `provider`: `data/` (models, repositories) · `viewmodels/` (ChangeNotifier) ·
`views/` (widgets only) · `core/` (config, network, Agora service, session, theme).

---

## Run it

Requirements: Flutter 3.27+ (Dart 3.6+). Xcode for iOS, Android Studio / SDK for Android.

```bash
flutter pub get
flutter run
```

Nothing to configure: the server (`https://api-12v1.gladskin.in`), Firebase Web API key, OTP function URLs and
Agora App ID are already in `lib/core/config/app_config.dart` (all public client values). The app uses
Firebase's REST API, so no `google-services.json` / `GoogleService-Info.plist` is needed. The Agora
certificate is **not** in the app; it lives only on the server.

To point a build at another server: `flutter build apk --dart-define=SERVER_URL=https://your-api.example.com`
(or *Server settings* inside the app).

### Build for the stores

```bash
# Android tablets (install the APK directly or upload the .aab to Play Console)
flutter build apk --release
flutter build appbundle --release

# iPad / iPhone (needs a Mac with Xcode + Apple developer account)
flutter build ipa --release
```

Before publishing, set your own application id and signing:
- Android: `android/app/build.gradle.kts` → `applicationId`, plus a release keystore
  (see https://docs.flutter.dev/deployment/android).
- iOS: open `ios/Runner.xcworkspace` in Xcode → Signing & Capabilities.

The release builds already include camera/microphone permissions and Agora's R8 keep rules.

### Kiosk tablets

Turn on **App pinning** (Android) or **Guided Access** (iPad) so patients can't leave the app. Long-press the
logo on the kiosk welcome screen to change the tablet's store (staff only).

## Logins

Staff and the owner use their existing Gladskin billing logins. Add doctors (name, registration no., mobile
number) in the Owner dashboard — they can sign in right away with that number.

## Project structure

```
lib/
├── main.dart, app.dart            Provider wiring, MaterialApp
├── core/
│   ├── config/app_config.dart     Server URL, Firebase key, OTP URLs, Agora App ID
│   ├── network/api_client.dart    HTTP + Bearer token (retries once after 401) + errors
│   ├── services/firebase_auth_service.dart  OTP → Firebase custom token → ID token (REST, auto-refresh)
│   ├── services/agora_service.dart   Agora engine: join/leave, mute, camera, data-stream chat, token renewal
│   ├── services/session_service.dart Device mode, server, kiosk store, login
│   └── theme/ utils/ constants/
├── data/            models/ + repositories/ (one per API resource)
├── viewmodels/      kiosk/ doctor/ pharmacy/ admin/ auth/ settings/
└── views/           launch/ settings/ role_select/ auth/ kiosk/ doctor/ pharmacy/ admin/ prescription/ widgets/
```

`tool/setup_platforms.dart` re-applies the Android/iOS permission settings if you ever regenerate the platform
folders with `flutter create`.
