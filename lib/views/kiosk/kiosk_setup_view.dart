import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/directory_repository.dart';
import '../../viewmodels/kiosk/kiosk_setup_view_model.dart';
import '../settings/server_settings_view.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';

/// Asked once per tablet: which store is this kiosk in?
class KioskSetupView extends StatelessWidget {
  const KioskSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => KioskSetupViewModel(
        directory: ctx.read<DirectoryRepository>(),
        session: ctx.read<SessionService>(),
      )..load(),
      child: const _SetupBody(),
    );
  }
}

class _SetupBody extends StatelessWidget {
  const _SetupBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KioskSetupViewModel>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MaxWidth(
            maxWidth: 760,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandLogo(subtitle: 'Store setup'),
                    const SizedBox(height: 22),
                    const Text('Which store is this device for?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                      "You're signed in as the owner, so pick the store once. (Store staff logins go straight to their own store.)",
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    if (vm.loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (vm.error != null)
                      ErrorBanner(message: vm.error!, onRetry: vm.load)
                    else
                      for (final s in vm.stores)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([s.address, s.city].where((x) => x.isNotEmpty).join(', ')),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => vm.choose(s),
                            ),
                          ),
                        ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: vm.signOut, child: const Text('Sign out')),
                    TextButton(onPressed: vm.changeMode, child: const Text('Use this device for something else')),
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
    );
  }
}
