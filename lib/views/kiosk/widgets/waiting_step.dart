import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/agora_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import '../../widgets/common.dart';
import '../../widgets/video_views.dart';

class WaitingStep extends StatelessWidget {
  const WaitingStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    final agora = context.watch<AgoraService>();
    final c = vm.consultation;
    if (c == null) return const SizedBox.shrink();
    final engine = agora.engine;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(children: [
          _PulseDot(),
          SizedBox(width: 10),
          Text('Finding a doctor for you',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        const SizedBox(height: 14),
        const Text('Please stay in front of the tablet.',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15)),
        const SizedBox(height: 10),
        Text(
          'The call starts automatically when a ${c.specialty.toLowerCase()} accepts. Keep this screen open.',
          style: const TextStyle(fontSize: 17, color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: StatCard(icon: Icons.confirmation_number_outlined, label: 'Your token', value: c.token)),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(icon: Icons.people_outline, label: 'Ahead of you', value: '${c.waitingAhead}'),
          ),
        ]),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: 'Cancel your request?',
              message: 'You will leave the queue.',
              confirmLabel: 'Cancel request',
              cancelLabel: 'Keep waiting',
              destructive: true,
            );
            if (ok) await vm.cancelWaiting();
          },
          icon: const Icon(Icons.close),
          label: const Text('Cancel request'),
        ),
      ],
    );

    final preview = AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: AppColors.videoBackground,
          child: engine != null && agora.previewing
              ? LocalVideoView(engine: engine)
              : const Center(child: Icon(Icons.person_outline, color: Colors.white38, size: 64)),
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MaxWidth(
        maxWidth: 1100,
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth > 760) {
            return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: info),
              const SizedBox(width: 32),
              Expanded(child: preview),
            ]);
          }
          return Column(children: [info, const SizedBox(height: 24), preview]);
        }),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Container(
            width: 18 * _c.value,
            height: 18 * _c.value,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 1 - _c.value),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ]),
      ),
    );
  }
}
