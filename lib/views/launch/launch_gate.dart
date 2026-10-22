import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/doctor.dart';
import '../../data/models/store.dart';
import '../admin/admin_view.dart';
import '../auth/pin_login_view.dart';
import '../doctor/doctor_dashboard_view.dart';
import '../kiosk/kiosk_setup_view.dart';
import '../kiosk/kiosk_view.dart';
import '../pharmacy/pharmacy_view.dart';
import '../role_select/role_select_view.dart';
import '../settings/server_settings_view.dart';

/// Root of the app. Shows the right screen for how this device is set up:
/// role picker → (kiosk store setup | PIN login) → the role's home screen.
class LaunchGate extends StatelessWidget {
  const LaunchGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final role = session.role;

    final Widget screen;
    if (!session.hasServer) {
      screen = const ServerSettingsView(firstRun: true);
    } else if (role == null) {
      screen = const RoleSelectView();
    } else if (role == DeviceRole.kiosk) {
      final storeId = session.kioskStoreId;
      screen = storeId == null ? const KioskSetupView() : KioskView(key: ValueKey(storeId), storeId: storeId);
    } else if (!session.isSignedIn) {
      screen = PinLoginView(key: ValueKey(role), role: role);
    } else {
      final profile = session.profile!;
      screen = switch (role) {
        DeviceRole.doctor => DoctorDashboardView(key: ValueKey(session.token), doctor: Doctor.fromJson(profile)),
        DeviceRole.pharmacy => PharmacyView(key: ValueKey(session.token), store: Store.fromJson(profile)),
        DeviceRole.admin => AdminView(key: ValueKey(session.token)),
        DeviceRole.kiosk => const SizedBox.shrink(),
      };
    }

    return Stack(
      children: [
        screen,
        if (!AppConfig.isAgoraConfigured) const _ConfigWarning(),
      ],
    );
  }
}

/// Visible reminder while the Agora App ID placeholder hasn't been replaced.
class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: SafeArea(
        child: Material(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agora App ID not set — video calls are disabled. '
                  'Add it in lib/core/config/app_config.dart (see README).',
                  style: TextStyle(color: AppColors.text),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
