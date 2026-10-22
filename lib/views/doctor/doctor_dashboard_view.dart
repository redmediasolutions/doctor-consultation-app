import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/consultation.dart';
import '../../data/models/doctor.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../../viewmodels/doctor/doctor_dashboard_view_model.dart';
import '../prescription/prescription_page.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import '../widgets/status_badges.dart';
import 'doctor_consult_view.dart';
import 'widgets/queue_tile.dart';

class DoctorDashboardView extends StatelessWidget {
  const DoctorDashboardView({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => DoctorDashboardViewModel(
        doctor: doctor,
        session: ctx.read<SessionService>(),
        directory: ctx.read<DirectoryRepository>(),
        consultations: ctx.read<ConsultationRepository>(),
        auth: ctx.read<AuthRepository>(),
      )..start(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  String? _accepting;

  @override
  void initState() {
    super.initState();
    final vm = context.read<DoctorDashboardViewModel>();
    vm.onNotice = (m) => showNotice(context, m);
    vm.onNewPatients = (n) => showNotice(context, n == 1 ? 'New patient waiting' : '$n new patients waiting');
  }

  Future<void> _accept(Consultation c) async {
    final vm = context.read<DoctorDashboardViewModel>();
    setState(() => _accepting = c.id);
    final updated = await vm.accept(c);
    if (!mounted) return;
    setState(() => _accepting = null);
    if (updated != null) await _openConsult(updated);
  }

  Future<void> _openConsult(Consultation c) async {
    final vm = context.read<DoctorDashboardViewModel>();
    await vm.setInConsultation(true);
    if (!mounted) return;
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => DoctorConsultView(consultation: c)),
    );
    await vm.setInConsultation(false);
    if (mounted && message != null) showNotice(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DoctorDashboardViewModel>();
    final d = vm.doctor;
    final openCall = vm.myOpenCall;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandLogo(subtitle: 'Doctor console', size: 34),
        actions: [
          _AvailabilitySwitch(vm: vm),
          AccountMenu(
            onSignOut: vm.logout,
            onChangeMode: vm.changeMode,
            extra: [
              PopupMenuItem(
                value: vm.refresh,
                child: const ListTile(
                    leading: Icon(Icons.refresh), title: Text('Refresh'), contentPadding: EdgeInsets.zero),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MaxWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  InitialsAvatar(name: d.name, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('${d.specialty} · ${d.registrationNo}', style: const TextStyle(color: AppColors.muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                StatGrid(children: [
                  StatCard(
                    icon: Icons.people_outline,
                    label: 'Waiting now',
                    value: '${vm.waiting.length}',
                    highlight: vm.waiting.isNotEmpty,
                  ),
                  StatCard(icon: Icons.task_alt, label: 'Seen today', value: '${vm.completedToday.length}'),
                  StatCard(icon: Icons.timer_outlined, label: 'Avg. call', value: vm.avgCallText),
                  StatCard(icon: Icons.description_outlined, label: 'Prescriptions', value: '${vm.prescriptionsToday}'),
                ]),
                if (openCall != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(child: Text('You have an unfinished consultation with ${openCall.patient.name}.')),
                      FilledButton(onPressed: () => _openConsult(openCall), child: const Text('Rejoin')),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Patient queue',
                  subtitle: 'Live from all stores · oldest first',
                  trailing: SegmentedButton<QueueFilter>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(value: QueueFilter.all, label: Text('All')),
                      ButtonSegment(value: QueueFilter.mySpecialty, label: Text(d.specialty)),
                    ],
                    selected: {vm.filter},
                    onSelectionChanged: (s) => vm.setFilter(s.first),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (!vm.available)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                        child: const Text(
                          "You're set to Away. Switch to Available to appear online at the stores.",
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    if (vm.error != null && vm.active.isEmpty)
                      ErrorBanner(message: vm.error!, onRetry: vm.refresh)
                    else if (vm.loading)
                      const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                    else if (vm.waiting.isEmpty)
                      const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No patients waiting',
                        message: 'New requests from the store tablets appear here automatically.',
                      )
                    else
                      for (var i = 0; i < vm.waiting.length; i++)
                        QueueTile(
                          consultation: vm.waiting[i],
                          position: i + 1,
                          matchesSpecialty: vm.waiting[i].specialty == d.specialty,
                          disabled: openCall != null || _accepting != null,
                          accepting: _accepting == vm.waiting[i].id,
                          onAccept: () => _accept(vm.waiting[i]),
                        ),
                  ]),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: "Today's consultations",
                  child: vm.history.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('None yet.', style: TextStyle(color: AppColors.muted)),
                        )
                      : Column(children: [
                          for (final c in vm.history.take(20))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: InitialsAvatar(name: c.patient.name, radius: 18),
                              title: Text(c.patient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${c.store?.shortName ?? ''} · ${Fmt.time(c.acceptedAt ?? c.createdAt)}'),
                              trailing: c.prescriptionId != null
                                  ? TextButton(
                                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                        builder: (_) => PrescriptionPage(prescriptionId: c.prescriptionId!),
                                      )),
                                      child: const Text('View Rx'),
                                    )
                                  : ConsultationStatusBadge(status: c.status),
                            ),
                        ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilitySwitch extends StatelessWidget {
  const _AvailabilitySwitch({required this.vm});

  final DoctorDashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    final busy = vm.inConsultation;
    final color = busy ? AppColors.warning : (vm.available ? AppColors.success : AppColors.muted);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          busy ? 'In consultation' : (vm.available ? 'Available' : 'Away'),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        Switch(value: vm.available, onChanged: busy ? null : vm.setAvailable),
      ]),
    );
  }
}
