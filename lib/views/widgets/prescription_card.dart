import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/prescription.dart';
import 'brand_logo.dart';

/// The e-prescription, laid out like a printed Rx.
class PrescriptionCard extends StatelessWidget {
  const PrescriptionCard({super.key, required this.rx});

  final Prescription rx;

  @override
  Widget build(BuildContext context) {
    final d = rx.doctor;
    final s = rx.store;
    const label = TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.4);

    Widget field(String title, String value, {bool strong = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title.toUpperCase(), style: label),
            const SizedBox(height: 2),
            Text(value.isEmpty ? '—' : value,
                style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w400, fontSize: 14)),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 20,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 42),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d?.name ?? 'Doctor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(d?.qualification ?? '', style: const TextStyle(color: AppColors.muted)),
                      Text('${d?.specialty ?? ''} · Reg. No. ${d?.registrationNo ?? '—'}',
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('${AppConfig.brandName} Teleconsultation',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(s?.name ?? '', style: const TextStyle(color: AppColors.muted)),
                  Text([s?.address, s?.city].whereType<String>().where((x) => x.isNotEmpty).join(', '),
                      style: const TextStyle(color: AppColors.muted)),
                  Text(s?.phone ?? '', style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 2, color: AppColors.primary),
          const SizedBox(height: 14),

          // Patient
          Wrap(spacing: 28, runSpacing: 12, children: [
            field('Patient', rx.patient.name),
            field('Age / Sex', '${rx.patient.age} y / ${rx.patient.gender}'),
            field('Mobile', rx.patient.phone),
            field('Date', Fmt.dateTime(rx.createdAt)),
            field('Rx No.', rx.rxNo),
            field('Token', rx.token),
          ]),
          const Divider(height: 28),
          if (rx.chiefComplaint.isNotEmpty) ...[
            field('Chief complaints', rx.chiefComplaint),
            const SizedBox(height: 12),
          ],
          field('Provisional diagnosis', rx.diagnosis, strong: true),
          const SizedBox(height: 16),

          // Medicines
          const Text('℞',
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: AppColors.primary)),
          const SizedBox(height: 6),
          if (rx.medicines.isEmpty)
            const Text('No medicines prescribed.', style: TextStyle(color: AppColors.muted))
          else
            for (var i = 0; i < rx.medicines.length; i++) _MedicineRow(index: i + 1, m: rx.medicines[i]),

          if (rx.investigations.isNotEmpty || rx.advice.isNotEmpty || rx.followUp.isNotEmpty) ...[
            const Divider(height: 28),
            Wrap(spacing: 28, runSpacing: 12, children: [
              if (rx.investigations.isNotEmpty)
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: field('Investigations advised', rx.investigations)),
              if (rx.advice.isNotEmpty)
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: field('Advice', rx.advice)),
              if (rx.followUp.isNotEmpty)
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: field('Follow-up', rx.followUp)),
            ]),
          ],

          const Divider(height: 32),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            runSpacing: 10,
            spacing: 20,
            children: [
              const SizedBox(
                width: 380,
                child: Text(
                  'Issued after a video teleconsultation under the Telemedicine Practice Guidelines. '
                  'This is an electronically generated prescription and is valid for a single dispensing.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(d?.name ?? '', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                Text('Digitally signed · ${d?.registrationNo ?? ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.index, required this.m});

  final int index;
  final Medicine m;

  @override
  Widget build(BuildContext context) {
    final details = [m.frequency, m.timing, m.duration, if (m.quantity.isNotEmpty) 'Qty ${m.quantity}']
        .where((x) => x.isNotEmpty)
        .join('  ·  ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 26, child: Text('$index.', style: const TextStyle(color: AppColors.muted))),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (details.isNotEmpty) Text(details, style: const TextStyle(color: AppColors.text)),
            if (m.instructions.isNotEmpty)
              Text(m.instructions, style: const TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic)),
          ]),
        ),
      ]),
    );
  }
}
