import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badges.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    final available = vm.availableDoctors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Pill(
                label: 'Registered doctors · Private & secure',
                icon: Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(height: 18),
              const Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Talk to a doctor '),
                  TextSpan(text: 'right here.', style: TextStyle(color: AppColors.primary)),
                ]),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 12),
              const Text(
                '${AppConfig.tagline}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 78,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                  ),
                  onPressed: vm.start,
                  icon: const Icon(Icons.medical_services_outlined, size: 28),
                  label: const Text('Consult a doctor now', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(height: 14),
              if (vm.doctorsLoaded)
                Text(
                  available.isNotEmpty
                      ? '${available.length} doctor${available.length > 1 ? 's' : ''} available now'
                      : 'No doctor is free right now — you can still join the queue.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
              if (available.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 4, children: [
                  for (final d in available.take(5))
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: InitialsAvatar(name: d.name, radius: 18),
                    ),
                ]),
              ],
              const SizedBox(height: 40),
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 760 ? 3 : 1;
                final w = (c.maxWidth - (cols - 1) * 14) / cols;
                const steps = [
                  (Icons.person_outline, 'Tell us about you', "Name, age and what's bothering you"),
                  (Icons.videocam_outlined, 'See a doctor on video', 'Usually within a few minutes'),
                  (Icons.medication_outlined, 'Collect your medicines', 'Prescription goes straight to the counter'),
                ];
                return Wrap(spacing: 14, runSpacing: 14, children: [
                  for (var i = 0; i < steps.length; i++)
                    SizedBox(
                      width: w,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(steps[i].$1, color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('STEP ${i + 1}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.6)),
                                Text(steps[i].$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                Text(steps[i].$3, style: const TextStyle(color: AppColors.muted)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ]);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
