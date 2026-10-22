import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/consultation.dart';
import '../../data/models/doctor.dart';

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.background,
    this.icon,
    this.dot = false,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ConsultationStatusBadge extends StatelessWidget {
  const ConsultationStatusBadge({super.key, required this.status});

  final ConsultationStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ConsultationStatus.waiting => const Pill(label: 'Waiting', color: AppColors.warning),
      ConsultationStatus.inCall => const Pill(label: 'In call', color: AppColors.primary),
      ConsultationStatus.completed => const Pill(label: 'Completed', color: AppColors.success),
      ConsultationStatus.cancelled => const Pill(label: 'Cancelled', color: AppColors.muted),
    };
  }
}

class DoctorStatusBadge extends StatelessWidget {
  const DoctorStatusBadge({super.key, required this.status});

  final DoctorStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      DoctorStatus.online => const Pill(label: 'Available', color: AppColors.success, dot: true),
      DoctorStatus.busy => const Pill(label: 'In consultation', color: AppColors.warning, dot: true),
      DoctorStatus.offline => const Pill(label: 'Offline', color: AppColors.muted, dot: true),
    };
  }
}
