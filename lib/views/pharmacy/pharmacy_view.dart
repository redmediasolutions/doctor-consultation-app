import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/consultation.dart';
import '../../data/models/prescription.dart';
import '../../data/models/store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../../viewmodels/pharmacy/pharmacy_view_model.dart';
import '../prescription/prescription_page.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import '../widgets/status_badges.dart';

class PharmacyView extends StatelessWidget {
  const PharmacyView({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PharmacyViewModel(
        store: store,
        prescriptions: ctx.read<PrescriptionRepository>(),
        consultations: ctx.read<ConsultationRepository>(),
        auth: ctx.read<AuthRepository>(),
        session: ctx.read<SessionService>(),
      )..start(),
      child: const _PharmacyBody(),
    );
  }
}

class _PharmacyBody extends StatefulWidget {
  const _PharmacyBody();

  @override
  State<_PharmacyBody> createState() => _PharmacyBodyState();
}

class _PharmacyBodyState extends State<_PharmacyBody> {
  @override
  void initState() {
    super.initState();
    final vm = context.read<PharmacyViewModel>();
    vm.onNotice = (m) => showNotice(context, m);
    vm.onNewPrescription = (rx) => showNotice(context, 'New prescription · Token ${rx.token} — ${rx.patient.name}');
  }

  void _open(Prescription rx) {
    final vm = context.read<PharmacyViewModel>();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PrescriptionPage(prescription: rx, onSetDispensed: vm.setDispensed),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PharmacyViewModel>();

    final list = DefaultTabController(
      length: 2,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          const ListTile(
            title: Text("Today's prescriptions", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            subtitle: Text('Issued by doctors for patients at this store. Updates automatically.'),
          ),
          TabBar(tabs: [
            Tab(text: 'To dispense (${vm.pending.length})'),
            Tab(text: 'Dispensed (${vm.dispensed.length})'),
          ]),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(children: [
                    _RxList(
                      items: vm.pending,
                      empty: 'No prescriptions waiting. New ones pop up here.',
                      onOpen: _open,
                      onDispense: (rx) => vm.setDispensed(rx, true),
                    ),
                    _RxList(items: vm.dispensed, empty: 'Nothing dispensed yet today.', onOpen: _open),
                  ]),
          ),
        ]),
      ),
    );

    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(
        title: 'At the kiosk now',
        subtitle: 'Patients waiting or on a call',
        child: vm.atKiosk.isEmpty
            ? const Text('Kiosk is free.', style: TextStyle(color: AppColors.muted))
            : Column(children: [for (final c in vm.atKiosk) _KioskRow(c: c)]),
      ),
      const SizedBox(height: 12),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Counter checklist', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('1. Match the token and patient name.'),
            Text("2. Verify the doctor's registration number on the Rx."),
            Text('3. Collect the consultation fee, dispense, then mark as dispensed.'),
          ]),
        ),
      ),
    ]);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: BrandLogo(subtitle: 'Counter · ${vm.store.shortName}', size: 34),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: vm.refresh, icon: const Icon(Icons.refresh)),
          AccountMenu(onSignOut: vm.logout, onChangeMode: vm.changeMode),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (vm.error != null) ...[ErrorBanner(message: vm.error!, onRetry: vm.refresh), const SizedBox(height: 12)],
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              if (box.maxWidth > 900) {
                return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: list),
                  const SizedBox(width: 16),
                  SizedBox(width: 320, child: SingleChildScrollView(child: side)),
                ]);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (vm.atKiosk.isNotEmpty) ...[
                  for (final c in vm.atKiosk) _KioskRow(c: c),
                  const SizedBox(height: 8),
                ],
                Expanded(child: list),
              ]);
            }),
          ),
        ]),
      ),
    );
  }
}

class _RxList extends StatelessWidget {
  const _RxList({required this.items, required this.empty, required this.onOpen, this.onDispense});

  final List<Prescription> items;
  final String empty;
  final void Function(Prescription rx) onOpen;
  final void Function(Prescription rx)? onDispense;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(icon: Icons.inbox_outlined, title: empty);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RxTile(rx: items[i], onOpen: onOpen, onDispense: onDispense),
    );
  }
}

class _RxTile extends StatelessWidget {
  const _RxTile({required this.rx, required this.onOpen, this.onDispense});

  final Prescription rx;
  final void Function(Prescription rx) onOpen;
  final void Function(Prescription rx)? onDispense;

  @override
  Widget build(BuildContext context) {
    final names = rx.medicines.map((m) => m.name).join(', ');
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onOpen(rx),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                const Text('TOKEN', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                Text(rx.token, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(rx.patient.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(rx.patient.summary, style: const TextStyle(color: AppColors.muted)),
                  if (rx.dispensed)
                    Pill(label: 'Dispensed ${Fmt.time(rx.dispensedAt)}', color: AppColors.success, icon: Icons.check),
                ]),
                const SizedBox(height: 3),
                Text(
                  '${rx.medicines.length} medicine${rx.medicines.length == 1 ? '' : 's'} — ${names.isEmpty ? 'advice only' : names}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text('${rx.doctor?.name ?? ''} · ${Fmt.time(rx.createdAt)} · ${rx.rxNo}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            if (onDispense != null) ...[
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => onDispense!(rx),
                child: const Text('Dispense'),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _KioskRow extends StatelessWidget {
  const _KioskRow({required this.c});

  final Consultation c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${c.token} · ${c.patient.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              c.status == ConsultationStatus.inCall
                  ? (c.doctor?.name ?? 'With doctor')
                  : 'waiting ${Fmt.waitingFor(c.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ]),
        ),
        ConsultationStatusBadge(status: c.status),
      ]),
    );
  }
}
