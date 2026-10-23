import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/services/agora_service.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/services/permission_service.dart';
import 'core/services/session_service.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/consultation_repository.dart';
import 'data/repositories/directory_repository.dart';
import 'data/repositories/prescription_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = SessionService();
  await session.init();

  final firebase = FirebaseAuthService(session);
  final api = ApiClient(
    baseUrlReader: () => session.apiBaseUrl,
    tokenReader: firebase.idToken,
    // Login no longer valid (revoked / deactivated) → back to the sign-in screen.
    onUnauthorised: session.logout,
  );

  runApp(
    MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider<SessionService>.value(value: session),
        Provider<ApiClient>.value(value: api),
        Provider<FirebaseAuthService>.value(value: firebase),
        ChangeNotifierProvider<AgoraService>(create: (_) => AgoraService()),
        Provider<PermissionService>(create: (_) => PermissionService()),
        // Repositories (Model layer)
        Provider<AuthRepository>(create: (_) => AuthRepository(api, firebase, session)),
        Provider<DirectoryRepository>(create: (_) => DirectoryRepository(api)),
        Provider<ConsultationRepository>(create: (_) => ConsultationRepository(api)),
        Provider<PrescriptionRepository>(create: (_) => PrescriptionRepository(api)),
        Provider<AdminRepository>(create: (_) => AdminRepository(api)),
      ],
      child: const MedConnectApp(),
    ),
  );
}
