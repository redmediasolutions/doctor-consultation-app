import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import 'step_scaffold.dart';

class SymptomsStep extends StatelessWidget {
  const SymptomsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();

    return StepScaffold(
      title: 'What brings you in today?',
      subtitle: 'Tap all that apply. The doctor will ask more on the call.',
      nextEnabled: vm.symptomsValid,
      onNext: vm.next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in AppConstants.commonSymptoms)
                _SymptomChip(label: s, selected: vm.symptoms.contains(s), onTap: () => vm.toggleSymptom(s)),
            ],
          ),
          const SizedBox(height: 24),
          const FieldLabel('Describe your problem (optional)'),
          TextField(
            controller: vm.complaintController,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(hintText: 'e.g. Fever since yesterday night with mild headache'),
            onChanged: (_) => vm.touch(),
          ),
          const SizedBox(height: 22),
          const FieldLabel('Since when?'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final d in AppConstants.durations)
              ChoiceTile(label: d, selected: vm.duration == d, onTap: () => vm.setDuration(d)),
          ]),
          const SizedBox(height: 22),
          const FieldLabel('Any medicine allergies?'),
          TextField(
            controller: vm.allergiesController,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(hintText: 'e.g. Penicillin — or leave blank'),
            onChanged: (_) => vm.touch(),
          ),
          const SizedBox(height: 22),
          const FieldLabel('Which doctor do you need?'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final s in AppConstants.specialties)
              ChoiceTile(
                label: s,
                selected: vm.specialty == s,
                onTap: () => vm.setSpecialty(s),
                trailing: vm.isSpecialtyAvailable(s)
                    ? Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      )
                    : null,
              ),
          ]),
          const SizedBox(height: 22),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
                title: const Text('Vitals — pharmacist can fill these (optional)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    _VitalField(label: 'BP (mmHg)', hint: '120/80', controller: vm.bpController, onChanged: vm.touch),
                    _VitalField(label: 'Pulse (/min)', hint: '78', controller: vm.pulseController, onChanged: vm.touch),
                    _VitalField(
                        label: 'Temp (°F)', hint: '98.6', controller: vm.temperatureController, onChanged: vm.touch),
                    _VitalField(label: 'SpO₂ (%)', hint: '98', controller: vm.spo2Controller, onChanged: vm.touch),
                    _VitalField(label: 'Weight (kg)', hint: '65', controller: vm.weightController, onChanged: vm.touch),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  const _SymptomChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  const _VitalField({required this.label, required this.hint, required this.controller, required this.onChanged});

  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint),
          onChanged: (_) => onChanged(),
        ),
      ]),
    );
  }
}
