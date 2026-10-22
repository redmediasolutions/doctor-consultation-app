import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/consultation.dart';
import '../../widgets/common.dart';

/// Patient details shown to the doctor during the call.
class PatientSummary extends StatelessWidget {
  const PatientSummary({super.key, required this.consultation});

  final Consultation consultation;

  @override
  Widget build(BuildContext context) {
    final c = consultation;
    final v = c.vitals;
    const heading = TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.6, fontWeight: FontWeight.w600);

    final vitals = [
      ('BP', v.bp, 'mmHg'),
      ('Pulse', v.pulse, '/min'),
      ('Temp', v.temperature, '°F'),
      ('SpO₂', v.spo2, '%'),
      ('Weight', v.weight, 'kg'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        InitialsAvatar(name: c.patient.name, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.patient.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('${c.patient.age} years · ${c.patient.gender} · +91 ${c.patient.phone}',
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
      ]),
      const SizedBox(height: 18),
      const Text('PRESENTING COMPLAINT', style: heading),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final s in c.symptoms)
          Chip(label: Text(s), visualDensity: VisualDensity.compact, backgroundColor: AppColors.primarySoft),
      ]),
      if (c.complaint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(c.complaint)),
      if (c.duration.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Duration: ${c.duration}', style: const TextStyle(color: AppColors.muted)),
        ),
      const SizedBox(height: 18),
      const Text('VITALS (RECORDED AT STORE)', style: heading),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final item in vitals)
          Container(
            width: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.$1, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              Text(
                item.$2.isEmpty ? '—' : '${item.$2} ${item.$3}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ]),
          ),
      ]),
      const SizedBox(height: 18),
      _Box(
        title: 'ALLERGIES',
        child: Text(
          c.allergies.isEmpty ? 'None reported' : c.allergies,
          style: TextStyle(
            color: c.allergies.isEmpty ? AppColors.text : AppColors.danger,
            fontWeight: c.allergies.isEmpty ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 10),
      _Box(
        title: 'STORE',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.store?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${c.store?.address ?? ''}, ${c.store?.city ?? ''} · Pharmacist ${c.store?.pharmacistName ?? ''}',
              style: const TextStyle(color: AppColors.muted)),
        ]),
      ),
    ]);
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.6, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        child,
      ]),
    );
  }
}
