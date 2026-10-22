import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';
import 'step_scaffold.dart';

class DetailsStep extends StatelessWidget {
  const DetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskViewModel>();
    const big = TextStyle(fontSize: 20);

    Widget nameField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Full name'),
          TextField(
            controller: vm.nameController,
            textCapitalization: TextCapitalization.words,
            style: big,
            decoration: const InputDecoration(hintText: 'e.g. Suresh Shetty'),
            onChanged: (_) => vm.touch(),
          ),
        ]);

    Widget ageField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Age (years)'),
          TextField(
            controller: vm.ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            style: big,
            decoration: const InputDecoration(hintText: 'e.g. 42'),
            onChanged: (_) => vm.touch(),
          ),
        ]);

    Widget phoneField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FieldLabel('Mobile number'),
          TextField(
            controller: vm.phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            style: big,
            decoration: const InputDecoration(
              hintText: '10-digit mobile',
              prefixText: '+91  ',
              prefixStyle: TextStyle(fontSize: 20, color: AppColors.muted),
            ),
            onChanged: (_) => vm.touch(),
          ),
        ]);

    return StepScaffold(
      title: 'Your details',
      subtitle: 'This appears on your prescription.',
      backLabel: 'Cancel',
      nextEnabled: vm.detailsValid,
      onNext: vm.next,
      child: LayoutBuilder(builder: (context, c) {
        final twoCols = c.maxWidth > 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameField(),
            const SizedBox(height: 20),
            if (twoCols)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ageField()),
                const SizedBox(width: 20),
                Expanded(child: phoneField()),
              ])
            else ...[
              ageField(),
              const SizedBox(height: 20),
              phoneField(),
            ],
            const SizedBox(height: 20),
            const FieldLabel('Gender'),
            Row(children: [
              for (final g in const ['Male', 'Female', 'Other']) ...[
                Expanded(
                  child: ChoiceTile(label: g, large: true, selected: vm.gender == g, onTap: () => vm.setGender(g)),
                ),
                if (g != 'Other') const SizedBox(width: 12),
              ],
            ]),
          ],
        );
      }),
    );
  }
}
