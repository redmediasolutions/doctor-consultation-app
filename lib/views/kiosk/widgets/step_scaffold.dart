import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/kiosk/kiosk_view_model.dart';

/// Shared frame for the three form steps: progress, title, scrollable body, back/next.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.onNext,
    this.nextEnabled = true,
    this.nextLabel = 'Continue',
    this.backLabel = 'Back',
    this.busy = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onNext;
  final bool nextEnabled;
  final String nextLabel;
  final String backLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<KioskViewModel>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              _Progress(step: context.select<KioskViewModel, KioskStep>((v) => v.step)),
              const SizedBox(height: 14),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(subtitle!, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
                            ),
                        ]),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          child: child,
                        ),
                      ),
                      const Divider(height: 1),
                      Container(
                        color: const Color(0xFFF8FAFB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(children: [
                          TextButton.icon(
                            onPressed: vm.back,
                            icon: const Icon(Icons.arrow_back),
                            label: Text(backLabel, style: const TextStyle(fontSize: 16)),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: nextEnabled && !busy ? onNext : null,
                              icon: busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.arrow_forward),
                              label: Text(nextLabel, style: const TextStyle(fontSize: 17)),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final KioskStep step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Your details', 'Symptoms', 'Confirm'];
    final current = switch (step) {
      KioskStep.details => 0,
      KioskStep.symptoms => 1,
      _ => 2,
    };
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          CircleAvatar(
            radius: 15,
            backgroundColor: i < current
                ? AppColors.success
                : i == current
                    ? AppColors.primary
                    : const Color(0xFFE5EAEE),
            child: i < current
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == current ? Colors.white : AppColors.muted,
                    )),
          ),
          const SizedBox(width: 8),
          Text(labels[i],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: i > current ? AppColors.muted : AppColors.text,
              )),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: i < current ? AppColors.success : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

/// Large tappable option used for gender, duration and specialty.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.large = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: large ? 18 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: large ? 18 : 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.text,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
      );
}
