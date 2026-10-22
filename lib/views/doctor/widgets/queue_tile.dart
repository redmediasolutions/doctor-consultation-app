import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/consultation.dart';
import '../../widgets/status_badges.dart';

class QueueTile extends StatelessWidget {
  const QueueTile({
    super.key,
    required this.consultation,
    required this.position,
    required this.matchesSpecialty,
    required this.onAccept,
    this.disabled = false,
    this.accepting = false,
  });

  final Consultation consultation;
  final int position;
  final bool matchesSpecialty;
  final VoidCallback onAccept;
  final bool disabled;
  final bool accepting;

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final vitals = c.vitals.summary;

    final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(c.patient.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        Text(c.patient.summary, style: const TextStyle(color: AppColors.muted)),
        Pill(
          label: c.specialty,
          color: matchesSpecialty ? AppColors.primary : AppColors.muted,
        ),
      ]),
      const SizedBox(height: 4),
      Text(
        [c.concern, if (c.duration.isNotEmpty) '· ${c.duration}'].join(' '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 6),
      Wrap(spacing: 12, runSpacing: 4, children: [
        _Meta(icon: Icons.storefront_outlined, text: c.store?.shortName ?? '—'),
        _Meta(icon: Icons.schedule, text: 'waiting ${Fmt.waitingFor(c.createdAt)}'),
        if (vitals.isNotEmpty) _Meta(icon: Icons.monitor_heart_outlined, text: vitals),
        if (c.allergies.isNotEmpty)
          Text('Allergy: ${c.allergies}',
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    ]);

    final button = FilledButton.icon(
      onPressed: disabled || accepting ? null : onAccept,
      icon: accepting
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.video_call_outlined),
      label: const Text('Accept & call'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final avatar = CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySoft,
          child: Text('$position', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        );
        if (box.maxWidth > 560) {
          return Row(children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: details),
            const SizedBox(width: 12),
            button,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: details),
          ]),
          const SizedBox(height: 12),
          button,
        ]);
      }),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppColors.muted),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ]);
  }
}
