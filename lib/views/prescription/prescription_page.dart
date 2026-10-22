import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/prescription.dart';
import '../../data/repositories/prescription_repository.dart';
import '../widgets/common.dart';
import '../widgets/prescription_card.dart';

/// Full-screen prescription. Pass [prescription] directly or a [prescriptionId] to load.
/// The pharmacy counter passes [onSetDispensed] to show the dispense button.
class PrescriptionPage extends StatefulWidget {
  const PrescriptionPage({super.key, this.prescription, this.prescriptionId, this.onSetDispensed})
      : assert(prescription != null || prescriptionId != null);

  final Prescription? prescription;
  final String? prescriptionId;
  final Future<Prescription?> Function(Prescription rx, bool dispensed)? onSetDispensed;

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  Prescription? _rx;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rx = widget.prescription;
    if (_rx == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rx = await context.read<PrescriptionRepository>().get(widget.prescriptionId!);
      if (mounted) setState(() => _rx = rx);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _toggle() async {
    final rx = _rx;
    final handler = widget.onSetDispensed;
    if (rx == null || handler == null) return;
    setState(() => _busy = true);
    final updated = await handler(rx, !rx.dispensed);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (updated != null) _rx = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rx = _rx;
    return Scaffold(
      appBar: AppBar(title: Text(rx == null ? 'Prescription' : 'Prescription · ${rx.rxNo}')),
      body: rx == null
          ? Center(
              child: _error != null
                  ? Padding(padding: const EdgeInsets.all(20), child: ErrorBanner(message: _error!, onRetry: _load))
                  : const CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: MaxWidth(maxWidth: 900, child: PrescriptionCard(rx: rx)),
            ),
      bottomNavigationBar: rx != null && widget.onSetDispensed != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 54,
                  child: rx.dispensed
                      ? OutlinedButton.icon(
                          onPressed: _busy ? null : _toggle,
                          icon: const Icon(Icons.undo),
                          label: const Text('Mark not dispensed'),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: _busy ? null : _toggle,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Mark dispensed'),
                        ),
                ),
              ),
            )
          : null,
    );
  }
}
