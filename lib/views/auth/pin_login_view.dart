import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../../viewmodels/auth/login_view_model.dart';
import '../settings/server_settings_view.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';

/// PIN sign-in for doctor / pharmacy counter / owner.
class PinLoginView extends StatelessWidget {
  const PinLoginView({super.key, required this.role});

  final DeviceRole role;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LoginViewModel(
        role: role,
        auth: ctx.read<AuthRepository>(),
        directory: ctx.read<DirectoryRepository>(),
      )..loadOptions(),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody();

  String _title(DeviceRole r) => switch (r) {
        DeviceRole.doctor => 'Doctor sign in',
        DeviceRole.pharmacy => 'Pharmacy counter',
        DeviceRole.admin => 'Owner dashboard',
        DeviceRole.kiosk => 'Sign in',
      };

  String _description(DeviceRole r) => switch (r) {
        DeviceRole.doctor => 'See patients waiting at the stores and consult over video.',
        DeviceRole.pharmacy => 'Receive prescriptions issued to your store.',
        DeviceRole.admin => 'Consultations, doctors and stores across the chain.',
        DeviceRole.kiosk => '',
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final session = context.read<SessionService>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandLogo(),
                      const SizedBox(height: 22),
                      Text(_title(vm.role), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_description(vm.role), style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 22),
                      if (vm.needsSelection) ...[
                        Text(vm.selectionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        if (vm.loadingOptions)
                          const LinearProgressIndicator()
                        else
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: vm.selectedId,
                                hint: Text('Select ${vm.selectionLabel.toLowerCase()}'),
                                items: [
                                  for (final o in vm.options)
                                    DropdownMenuItem(
                                      value: o.id,
                                      child: Text('${o.label}  ·  ${o.subtitle}', overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: vm.select,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      const Text('PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: vm.pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                        style: const TextStyle(fontSize: 20, letterSpacing: 8),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), hintText: '••••'),
                        onChanged: (_) => vm.onPinChanged(),
                        onSubmitted: (_) => vm.login(),
                      ),
                      if (vm.error != null) ...[
                        const SizedBox(height: 12),
                        ErrorBanner(message: vm.error!, onRetry: vm.options.isEmpty ? vm.loadOptions : null),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: vm.canSubmit ? vm.login : null,
                        child: vm.busy
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: session.resetDevice,
                        child: const Text('Use this device for something else'),
                      ),
                      TextButton.icon(
                        onPressed: () => ServerSettingsView.open(context),
                        icon: const Icon(Icons.dns_outlined, size: 18),
                        label: const Text('Server settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
