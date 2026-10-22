import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badges.dart';

class KioskHeader extends StatefulWidget {
  const KioskHeader({super.key});

  @override
  State<KioskHeader> createState() => _KioskHeaderState();
}

class _KioskHeaderState extends State<KioskHeader> {
  late final Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  Future<void> _staffMenu(KioskViewModel vm) async {
    final ok = await confirmDialog(
      context,
      title: 'Change kiosk setup?',
      message: 'Staff only. This tablet will forget its store and show the setup screen.',
      confirmLabel: 'Change setup',
    );
    if (ok) await vm.changeDeviceSetup();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    final online = vm.onlineDoctors.length;
    final onWelcome = vm.step == KioskStep.welcome;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Long-press the logo for the staff menu.
          Flexible(
            child: GestureDetector(
              onLongPress: onWelcome ? () => _staffMenu(vm) : null,
              child: BrandLogo(subtitle: vm.store?.name ?? ''),
            ),
          ),
          const SizedBox(width: 12),
          if (onWelcome && vm.doctorsLoaded)
            online > 0
                ? Pill(label: '$online doctor${online > 1 ? 's' : ''} online', color: AppColors.success, dot: true)
                : const Pill(label: 'Doctors offline', color: AppColors.muted, dot: true),
          const SizedBox(width: 14),
          Text(Fmt.time(_now), style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
