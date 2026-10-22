import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../../viewmodels/admin/admin_view_model.dart';
import '../prescription/prescription_page.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import '../widgets/status_badges.dart';

/// Owner dashboard.
class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AdminViewModel(
        admin: ctx.read<AdminRepository>(),
        consultations: ctx.read<ConsultationRepository>(),
        directory: ctx.read<DirectoryRepository>(),
        auth: ctx.read<AuthRepository>(),
        session: ctx.read<SessionService>(),
      )..start(),
      child: const _AdminBody(),
    );
  }
}

class _AdminBody extends StatefulWidget {
  const _AdminBody();

  @override
  State<_AdminBody> createState() => _AdminBodyState();
}

class _AdminBodyState extends State<_AdminBody> {
  @override
  void initState() {
    super.initState();
    context.read<AdminViewModel>().onNotice = (m) => showNotice(context, m);
  }

  Future<void> _reset(AdminViewModel vm) async {
    final ok = await confirmDialog(
      context,
      title: 'Reset demo data?',
      message: 'Deletes all consultations and prescriptions and restores the demo stores and doctors.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (ok) await vm.resetDemoData();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final s = vm.stats;
    final maxStore = (s?.byStore ?? []).fold<int>(1, (m, x) => x.total > m ? x.total : m);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandLogo(subtitle: 'Owner dashboard', size: 34),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: vm.refresh, icon: const Icon(Icons.refresh)),
          AccountMenu(
            onSignOut: vm.logout,
            onChangeMode: vm.changeMode,
            extra: [
              PopupMenuItem(
                value: () => _reset(vm),
                child: const ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('Reset demo data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          MaxWidth(
            maxWidth: 1200,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Today', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text(Fmt.longDate(DateTime.now()), style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 14),
              if (vm.error != null) ...[ErrorBanner(message: vm.error!, onRetry: vm.refresh), const SizedBox(height: 12)],
              if (vm.loading && s == null)
                const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
              else ...[
                StatGrid(minTileWidth: 170, children: [
                  StatCard(icon: Icons.people_outline, label: 'Consultations', value: '${s?.total ?? 0}'),
                  StatCard(icon: Icons.task_alt, label: 'Completed', value: '${s?.completed ?? 0}'),
                  StatCard(
                    icon: Icons.podcasts,
                    label: 'Live now',
                    value: '${s?.inCall ?? 0} / ${s?.waiting ?? 0}',
                    highlight: (s?.waiting ?? 0) > 0,
                  ),
                  StatCard(icon: Icons.schedule, label: 'Avg. wait', value: '${s?.avgWaitMin ?? 0} min'),
                  StatCard(
                    icon: Icons.medical_services_outlined,
                    label: 'Doctors online',
                    value: '${s?.doctorsOnline ?? 0} / ${s?.doctorsTotal ?? 0}',
                  ),
                  StatCard(icon: Icons.currency_rupee, label: 'Consult fees', value: Fmt.inr(s?.consultationFees ?? 0)),
                ]),
                const SizedBox(height: 4),
                const Text('Live now = in call / waiting', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'By store',
                  subtitle: 'Consultations today (completed / total)',
                  child: Column(children: [
                    for (final b in s?.byStore ?? const [])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            Expanded(
                              child: Text(Fmt.shortStore(b.name), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Text('${b.completed}/${b.total}${b.waiting > 0 ? '  · ${b.waiting} waiting' : ''}',
                                style: const TextStyle(color: AppColors.muted)),
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: b.total / maxStore,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFEEF2F5),
                            ),
                          ),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Consultations',
                  subtitle: 'Today',
                  trailing: DropdownButton<String?>(
                    value: vm.storeFilter,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All stores')),
                      for (final st in vm.stores)
                        DropdownMenuItem<String?>(value: st.id, child: Text(st.shortName)),
                    ],
                    onChanged: vm.setStoreFilter,
                  ),
                  child: vm.filteredConsultations.isEmpty
                      ? const EmptyState(icon: Icons.event_note_outlined, title: 'No consultations yet today')
                      : Column(children: [
                          for (final c in vm.filteredConsultations)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primarySoft,
                                child: Text(c.token,
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ),
                              title: Text('${c.patient.name} · ${c.patient.summary}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                c.store?.shortName ?? '',
                                c.doctor?.name ?? 'No doctor yet',
                                Fmt.time(c.createdAt),
                                if (c.acceptedAt != null && c.endedAt != null)
                                  '${Fmt.minutesBetween(c.acceptedAt, c.endedAt)} min',
                              ].join(' · ')),
                              trailing: c.prescriptionId != null
                                  ? TextButton(
                                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                        builder: (_) => PrescriptionPage(prescriptionId: c.prescriptionId!),
                                      )),
                                      child: const Text('Rx'),
                                    )
                                  : ConsultationStatusBadge(status: c.status),
                            ),
                        ]),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Doctor panel',
                  subtitle: 'Availability updates live from the doctor app',
                  trailing: FilledButton.icon(
                    onPressed: () => _showAddDoctor(context, vm),
                    icon: const Icon(Icons.add),
                    label: const Text('Add doctor'),
                  ),
                  child: Column(children: [
                    for (final d in vm.doctors)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: InitialsAvatar(name: d.name),
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${d.specialty} · ${d.registrationNo} · ${Fmt.inr(d.fee)}\n${d.languages.join(', ')}',
                        ),
                        isThreeLine: true,
                        trailing: DoctorStatusBadge(status: d.status),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Stores',
                  subtitle: 'Set up each store tablet once from the app (Store kiosk mode)',
                  trailing: FilledButton.icon(
                    onPressed: () => _showAddStore(context, vm),
                    icon: const Icon(Icons.add),
                    label: const Text('Add store'),
                  ),
                  child: Column(children: [
                    for (final st in vm.stores)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                        title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${st.address}, ${st.city}\nPharmacist ${st.pharmacistName} · DL ${st.drugLicenseNo} · ${st.phone}',
                        ),
                        isThreeLine: true,
                      ),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

Future<void> _showAddDoctor(BuildContext context, AdminViewModel vm) async {
  final name = TextEditingController();
  final reg = TextEditingController();
  final qual = TextEditingController();
  final exp = TextEditingController();
  final fee = TextEditingController(text: '200');
  final langs = TextEditingController(text: 'English, Kannada');
  final pin = TextEditingController();
  var specialty = AppConstants.specialties.first;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Add doctor'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'Only add doctors with a valid State Medical Council / NMC registration.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              _DialogField(controller: name, label: 'Full name'),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Specialty'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: specialty,
                    isDense: true,
                    isExpanded: true,
                    items: [for (final sp in AppConstants.specialties) DropdownMenuItem(value: sp, child: Text(sp))],
                    onChanged: (v) => setState(() => specialty = v ?? specialty),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _DialogField(controller: reg, label: 'Registration no. (e.g. KMC 12345)'),
              _DialogField(controller: qual, label: 'Qualification'),
              _DialogField(controller: exp, label: 'Experience (years)', number: true),
              _DialogField(controller: fee, label: 'Fee (₹)', number: true),
              _DialogField(controller: langs, label: 'Languages (comma separated)'),
              _DialogField(controller: pin, label: 'Login PIN (4–6 digits)', number: true),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await vm.addDoctor({
                'name': name.text.trim(),
                'specialty': specialty,
                'registrationNo': reg.text.trim(),
                'qualification': qual.text.trim(),
                'experienceYears': int.tryParse(exp.text.trim()) ?? 0,
                'fee': int.tryParse(fee.text.trim()) ?? 0,
                'languages': langs.text.trim(),
                'pin': pin.text.trim(),
              });
              if (ok && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save doctor'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showAddStore(BuildContext context, AdminViewModel vm) async {
  final fields = {
    'name': TextEditingController(),
    'address': TextEditingController(),
    'city': TextEditingController(),
    'phone': TextEditingController(),
    'pharmacistName': TextEditingController(),
    'drugLicenseNo': TextEditingController(),
    'staffPin': TextEditingController(),
  };
  const labels = {
    'name': 'Store name',
    'address': 'Address',
    'city': 'City',
    'phone': 'Phone',
    'pharmacistName': 'Pharmacist',
    'drugLicenseNo': 'Drug licence no.',
    'staffPin': 'Counter staff PIN',
  };

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add store'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final e in fields.entries)
              _DialogField(controller: e.value, label: labels[e.key]!, number: e.key == 'staffPin'),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final ok = await vm.addStore({for (final e in fields.entries) e.key: e.value.text.trim()});
            if (ok && ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save store'),
        ),
      ],
    ),
  );
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.controller, required this.label, this.number = false});

  final TextEditingController controller;
  final String label;
  final bool number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
