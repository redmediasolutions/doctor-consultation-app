import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/services/agora_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/session_service.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../viewmodels/kiosk/kiosk_view_model.dart';
import '../widgets/common.dart';
import 'widgets/call_step.dart';
import 'widgets/details_step.dart';
import 'widgets/done_step.dart';
import 'widgets/kiosk_header.dart';
import 'widgets/review_step.dart';
import 'widgets/symptoms_step.dart';
import 'widgets/waiting_step.dart';
import 'widgets/welcome_step.dart';

/// Patient-facing kiosk on the store tablet.
class KioskView extends StatelessWidget {
  const KioskView({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => KioskViewModel(
        storeId: storeId,
        directory: ctx.read<DirectoryRepository>(),
        consultations: ctx.read<ConsultationRepository>(),
        prescriptions: ctx.read<PrescriptionRepository>(),
        agora: ctx.read<AgoraService>(),
        permissions: ctx.read<PermissionService>(),
        session: ctx.read<SessionService>(),
      )..init(),
      child: const _KioskBody(),
    );
  }
}

class _KioskBody extends StatefulWidget {
  const _KioskBody();

  @override
  State<_KioskBody> createState() => _KioskBodyState();
}

class _KioskBodyState extends State<_KioskBody> {
  @override
  void initState() {
    super.initState();
    context.read<KioskViewModel>().onNotice = (m) => showNotice(context, m);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();

    final Widget content = switch (vm.step) {
      KioskStep.welcome => const WelcomeStep(),
      KioskStep.details => const DetailsStep(),
      KioskStep.symptoms => const SymptomsStep(),
      KioskStep.review => const ReviewStep(),
      KioskStep.waiting => const WaitingStep(),
      KioskStep.call => const CallStep(),
      KioskStep.done => const DoneStep(),
    };

    return PopScope(
      canPop: false, // the kiosk never navigates away
      child: Scaffold(
        body: SafeArea(
          child: Listener(
            onPointerDown: (_) => vm.touch(),
            child: Column(
              children: [
                const KioskHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(key: ValueKey(vm.step), child: content),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
