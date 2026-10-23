import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../settings/server_settings_view.dart';
import '../widgets/common.dart';

/// First launch: choose what this device is for. Saved on the device.
class RoleSelectView extends StatelessWidget {
  const RoleSelectView({super.key});

  static const _options = [
    (DeviceRole.kiosk, Icons.tablet_android_outlined, 'Patients',
        'Runs on the tablet in each store (signed in with the store login). Patients see a doctor on video.'),
    (DeviceRole.doctor, Icons.medical_services_outlined, 'Doctors',
        'Live queue from all stores, video consultation and e-prescriptions.'),
    (DeviceRole.pharmacy, Icons.local_pharmacy_outlined, 'Store staff',
        'Prescriptions arrive at the counter instantly. Mark them as dispensed.'),
    (DeviceRole.admin, Icons.insights_outlined, 'Owner',
        "Today's consultations across all stores, doctors and wait times."),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MaxWidth(
            maxWidth: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(subtitle: AppConfig.chainName),
                const SizedBox(height: 36),
                const Text(
                  'A doctor in every store, one tap away.',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15),
                ),
                const SizedBox(height: 8),
                const Text('How will this device be used?', style: TextStyle(fontSize: 16, color: AppColors.muted)),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (context, c) {
                  final twoCols = c.maxWidth > 620;
                  final w = twoCols ? (c.maxWidth - 14) / 2 : c.maxWidth;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final o in _options)
                        SizedBox(
                          width: w,
                          child: _RoleCard(
                            icon: o.$2,
                            title: o.$1.label,
                            audience: o.$3,
                            description: o.$4,
                            onTap: () => session.setRole(o.$1),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Icon(Icons.dns_outlined, size: 16, color: AppColors.muted),
                    Text('Server: ${session.serverUrl}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    TextButton(onPressed: () => ServerSettingsView.open(context), child: const Text('Change')),
                  ],
                ),
                const Text(
                  'Everyone signs in with their registered mobile number (OTP) — the same logins as the Gladskin '
                  'billing app. Doctors are added from the Owner dashboard.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.audience,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String audience;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(audience, style: const TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
            ]),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}
