import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/agora_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import '../../widgets/status_badges.dart';
import '../../widgets/video_views.dart';
import 'step_scaffold.dart';

/// Camera check, summary and teleconsultation consent.
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    final fee = vm.feeForSpecialty;

    final camera = _CameraCheck(vm: vm);
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            _Row('Patient', '${vm.nameController.text.trim()}, ${vm.ageController.text} y, ${vm.gender ?? ''}'),
            _Row('Mobile', '+91 ${vm.phoneController.text}'),
            _Row('Concern', vm.concernSummary),
            _Row('Doctor', vm.specialty),
            if (fee != null) _Row('Consultation fee', '${Fmt.inr(fee)} · pay at counter', last: true),
          ]),
        ),
        if (vm.doctorsLoaded && vm.noDoctorForSpecialty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
            child: Text(
              "No ${vm.specialty} is online right now. You'll be placed in the queue for the next available doctor.",
            ),
          ),
        ],
        const SizedBox(height: 14),
        Material(
          color: const Color(0xFFF8FAFB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: CheckboxListTile(
            value: vm.consent,
            onChanged: (v) => vm.setConsent(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            title: const Text(
              'I agree to a video consultation with a registered medical practitioner. I understand the doctor may '
              'ask me to visit a clinic in person if needed, and my details will be shared with the doctor and '
              'this pharmacy.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ],
    );

    return StepScaffold(
      title: 'Ready to see the doctor',
      subtitle: 'Check your camera, then connect.',
      nextLabel: vm.submitting ? 'Connecting…' : 'Connect to doctor',
      nextEnabled: vm.canSubmit,
      busy: vm.submitting,
      onNext: vm.submit,
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth > 720) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: camera),
            const SizedBox(width: 24),
            Expanded(child: summary),
          ]);
        }
        return Column(children: [camera, const SizedBox(height: 20), summary]);
      }),
    );
  }
}

class _CameraCheck extends StatelessWidget {
  const _CameraCheck({required this.vm});

  final KioskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final agora = context.watch<AgoraService>();
    final engine = agora.engine;

    Widget inner;
    if (vm.cameraReady && engine != null && agora.previewing) {
      inner = Stack(fit: StackFit.expand, children: [
        LocalVideoView(engine: engine),
        const Positioned(
          top: 10,
          left: 10,
          child: Pill(label: 'Camera & mic ready', color: Colors.white, background: Colors.black54, dot: true),
        ),
      ]);
    } else if (vm.cameraError != null) {
      inner = Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 36),
          const SizedBox(height: 10),
          Text(vm.cameraError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, children: [
            FilledButton.tonal(onPressed: vm.prepareCamera, child: const Text('Try again')),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              onPressed: vm.openSettings,
              child: const Text('Open settings'),
            ),
          ]),
        ]),
      );
    } else {
      inner = const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.white70),
          SizedBox(height: 12),
          Text('Starting camera…', style: TextStyle(color: Colors.white)),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(color: AppColors.videoBackground, child: inner),
        ),
      ),
      const SizedBox(height: 8),
      const Text('Sit so your face is clearly visible. Speak normally.',
          style: TextStyle(color: AppColors.muted)),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.muted))),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
