import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/doctor/doctor_consult_view_model.dart';

/// Prescription pad used during the call.
class RxForm extends StatelessWidget {
  const RxForm({super.key, required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorConsultViewModel>();
    final diagnosisMissing = vm.showValidation && vm.diagnosisController.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Chief complaints'),
        TextField(
          controller: vm.chiefComplaintController,
          minLines: 1,
          maxLines: 3,
          onChanged: (_) => vm.touch(),
        ),
        const SizedBox(height: 14),
        const _Label('Provisional diagnosis *'),
        TextField(
          controller: vm.diagnosisController,
          decoration: InputDecoration(
            hintText: 'e.g. Acute viral upper respiratory infection',
            errorText: diagnosisMissing ? 'Required' : null,
          ),
          onChanged: (_) => vm.touch(),
        ),
        const SizedBox(height: 18),
        Row(children: [
          const Expanded(child: _Label('Medicines')),
          TextButton.icon(onPressed: vm.addMedicine, icon: const Icon(Icons.add), label: const Text('Add medicine')),
        ]),
        for (var i = 0; i < vm.medicines.length; i++) _MedicineEditor(index: i, draft: vm.medicines[i]),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(10)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Schedule X and NDPS-listed drugs cannot be prescribed by teleconsultation. Prescribe only what is '
                'appropriate without a physical examination.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        const _Label('Investigations'),
        TextField(
          controller: vm.investigationsController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. CBC, CRP'),
          onChanged: (_) => vm.touch(),
        ),
        const SizedBox(height: 14),
        const _Label('Advice'),
        TextField(
          controller: vm.adviceController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Rest, fluids, warm saline gargles…'),
          onChanged: (_) => vm.touch(),
        ),
        const SizedBox(height: 14),
        const _Label('Follow-up'),
        TextField(
          controller: vm.followUpController,
          decoration: const InputDecoration(hintText: 'e.g. After 3 days if fever persists'),
          onChanged: (_) => vm.touch(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: vm.submitting ? null : onSubmit,
            icon: vm.submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            label: const Text('Issue prescription & end consultation'),
          ),
        ),
      ],
    );
  }
}

class _MedicineEditor extends StatelessWidget {
  const _MedicineEditor({required this.index, required this.draft});

  final int index;
  final MedicineDraft draft;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DoctorConsultViewModel>();

    Widget dropdown(String value, List<String> items, ValueChanged<String> onChanged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: items.contains(value) ? value : items.first,
            items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RawAutocomplete<String>(
              textEditingController: draft.name,
              focusNode: draft.nameFocus,
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                if (q.length < 2) return const Iterable<String>.empty();
                return AppConstants.commonMedicines.where((m) => m.toLowerCase().contains(q)).take(8);
              },
              onSelected: (_) => vm.touch(),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(hintText: 'Medicine name & strength'),
                onChanged: (_) => vm.touch(),
                onSubmitted: (_) => onFieldSubmitted(),
              ),
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260, maxWidth: 380),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final o in options) ListTile(dense: true, title: Text(o), onTap: () => onSelected(o)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: vm.medicines.length > 1 ? () => vm.removeMedicine(index) : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ]),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, box) {
          final cols = box.maxWidth > 520 ? 4 : 2;
          final w = (box.maxWidth - (cols - 1) * 8) / cols;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(width: w, child: dropdown(draft.frequency, AppConstants.frequencies, (v) => vm.setFrequency(index, v))),
            SizedBox(width: w, child: dropdown(draft.timing, AppConstants.timings, (v) => vm.setTiming(index, v))),
            SizedBox(
              width: w,
              child: TextField(
                controller: draft.duration,
                decoration: const InputDecoration(hintText: 'Duration'),
                onChanged: (_) => vm.touch(),
              ),
            ),
            SizedBox(
              width: w,
              child: TextField(
                controller: draft.quantity,
                decoration: const InputDecoration(hintText: 'Qty (e.g. 10 tabs)'),
                onChanged: (_) => vm.touch(),
              ),
            ),
          ]);
        }),
        const SizedBox(height: 8),
        TextField(
          controller: draft.instructions,
          decoration: const InputDecoration(hintText: 'Instructions (optional) — e.g. stop if rash appears'),
          onChanged: (_) => vm.touch(),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
