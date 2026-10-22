import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import '../../widgets/common.dart';
import '../../widgets/prescription_card.dart';

class DoneStep extends StatelessWidget {
  const DoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    final rx = vm.prescription;
    final token = vm.consultation?.token ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MaxWidth(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 14,
              spacing: 14,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: AppColors.success, size: 36),
                  ),
                  const SizedBox(width: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Consultation complete', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      Text(
                        rx != null
                            ? 'Show token $token at the counter to collect your medicines.'
                            : 'The doctor did not issue a prescription. Please speak to the pharmacist if you need help.',
                        style: const TextStyle(fontSize: 16, color: AppColors.muted),
                      ),
                    ]),
                  ),
                ]),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: vm.reset,
                    child: Text('Done  (${vm.countdown}s)', style: const TextStyle(fontSize: 17)),
                  ),
                ),
              ],
            ),
            if (rx != null) ...[
              const SizedBox(height: 20),
              PrescriptionCard(rx: rx),
            ],
          ],
        ),
      ),
    );
  }
}
