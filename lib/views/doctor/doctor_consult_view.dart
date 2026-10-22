import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/agora_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/consultation.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../viewmodels/doctor/doctor_consult_view_model.dart';
import '../widgets/call_stage.dart';
import '../widgets/chat_panel.dart';
import '../widgets/common.dart';
import '../widgets/status_badges.dart';
import 'widgets/patient_summary.dart';
import 'widgets/rx_form.dart';

/// Live consultation: video on one side, patient / prescription / chat on the other.
/// Pops with a message for the dashboard snackbar.
class DoctorConsultView extends StatelessWidget {
  const DoctorConsultView({super.key, required this.consultation});

  final Consultation consultation;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DoctorConsultViewModel(
        consultation: consultation,
        agora: ctx.read<AgoraService>(),
        consultations: ctx.read<ConsultationRepository>(),
        permissions: ctx.read<PermissionService>(),
      )..start(),
      child: const _ConsultBody(),
    );
  }
}

class _ConsultBody extends StatefulWidget {
  const _ConsultBody();

  @override
  State<_ConsultBody> createState() => _ConsultBodyState();
}

class _ConsultBodyState extends State<_ConsultBody> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late final DoctorConsultViewModel _vm;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<DoctorConsultViewModel>();
    _vm.addListener(_onVmChanged);
    _tabs.addListener(() {
      if (_tabs.index == 2) _vm.markChatRead();
    });
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (_closing || !_vm.finished) return;
    _closing = true;
    final name = _vm.consultation.patient.name;
    final String message;
    if (_vm.patientLeft) {
      message = '$name left the consultation';
    } else if (_vm.issued != null) {
      message = 'Prescription ${_vm.issued!.rxNo} sent to ${_vm.consultation.store?.shortName ?? 'the store'}';
    } else {
      message = 'Consultation with $name ended';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(message);
    });
  }

  Future<void> _issue() async {
    final error = await _vm.issuePrescription();
    if (error != null && mounted) showNotice(context, error, error: true);
  }

  Future<void> _hangUp() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End the consultation?'),
        content: const Text(
          'To send medicines, issue the prescription from the Prescription tab — that also ends the call.\n\n'
          'End without a prescription when the patient needs an in-person visit or no medicine is required.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'leave'), child: const Text('Leave, rejoin later')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'rx'), child: const Text('Write prescription')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, 'end'),
            child: const Text('End without Rx'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'rx') {
      _tabs.animateTo(1);
    } else if (choice == 'end') {
      final error = await _vm.endWithoutPrescription();
      if (error != null && mounted) showNotice(context, error, error: true);
    } else if (choice == 'leave') {
      _closing = true;
      await _vm.leaveTemporarily();
      if (mounted) Navigator.of(context).pop('You left the call. Rejoin from the dashboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorConsultViewModel>();
    final agora = context.watch<AgoraService>();
    final c = vm.consultation;

    final stage = VideoCallStage(
      remoteLabel: c.patient.name,
      remoteSubtitle: '${c.patient.summary} · ${c.store?.shortName ?? ''}',
      since: c.acceptedAt,
      waitingText: vm.videoError ?? 'Calling the store tablet…',
      hangUpLabel: 'End',
      onHangUp: _hangUp,
      onReconnect: vm.connect,
    );

    final statusRow = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (agora.connection == CallConnection.connected && agora.remoteUid != null)
        const Pill(label: 'Connected', color: AppColors.success, icon: Icons.podcasts)
      else if (agora.connection == CallConnection.failed || vm.videoError != null)
        const Pill(label: 'Disconnected', color: AppColors.danger, icon: Icons.podcasts)
      else
        const Pill(label: 'Connecting', color: AppColors.warning, icon: Icons.podcasts),
      Pill(label: 'Token ${c.token}', color: AppColors.text, background: Colors.white),
      Pill(label: c.store?.shortName ?? '', color: AppColors.text, background: Colors.white, icon: Icons.storefront),
      if (vm.videoError != null || agora.connection == CallConnection.failed)
        TextButton.icon(
          onPressed: vm.connecting ? null : vm.connect,
          icon: const Icon(Icons.refresh),
          label: const Text('Reconnect video'),
        ),
    ]);

    final panel = Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        TabBar(
          controller: _tabs,
          tabs: [
            const Tab(icon: Icon(Icons.person_outline), text: 'Patient'),
            const Tab(icon: Icon(Icons.description_outlined), text: 'Prescription'),
            Tab(
              icon: Badge(isLabelVisible: vm.hasUnreadChat, child: const Icon(Icons.chat_bubble_outline)),
              text: 'Chat',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            ListView(padding: const EdgeInsets.all(16), children: [
              PatientSummary(consultation: c),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _tabs.animateTo(1),
                icon: const Icon(Icons.edit_note),
                label: const Text('Write prescription'),
              ),
            ]),
            ListView(padding: const EdgeInsets.all(16), children: [RxForm(onSubmit: _issue)]),
            ChatPanel(messages: vm.messages, me: 'doctor', onSend: vm.sendChat),
          ]),
        ),
      ]),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hangUp();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Consultation · ${c.patient.name}'),
          actions: [
            IconButton(tooltip: 'End / leave', onPressed: _hangUp, icon: const Icon(Icons.close)),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            if (box.maxWidth >= 1000) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: stage),
                      const SizedBox(height: 10),
                      statusRow,
                    ]),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(width: 480, child: panel),
                ]),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(height: box.maxHeight * 0.42, child: stage),
                const SizedBox(height: 8),
                statusRow,
                const SizedBox(height: 8),
                Expanded(child: panel),
              ]),
            );
          }),
        ),
      ),
    );
  }
}
