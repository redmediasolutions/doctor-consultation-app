import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/settings/server_settings_view_model.dart';
import '../widgets/brand_logo.dart';

/// Where the app finds the MedConnect web project (its API).
/// Shown on first launch when no address is built in, and from "Server settings".
class ServerSettingsView extends StatelessWidget {
  const ServerSettingsView({super.key, this.firstRun = false});

  final bool firstRun;

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsView()));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ServerSettingsViewModel(session: ctx.read<SessionService>()),
      child: _Body(firstRun: firstRun),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.firstRun});

  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ServerSettingsViewModel>();
    final ok = vm.ok;

    return Scaffold(
      appBar: firstRun ? null : AppBar(title: const Text('Server settings')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (firstRun) ...[const BrandLogo(), const SizedBox(height: 22)],
                      const Text('Connect to your MedConnect server',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter the address of the MedConnect website (the Next.js project), '
                        'for example medconnect-web.vercel.app',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: vm.urlController,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.dns_outlined),
                          hintText: 'https://medconnect-web.vercel.app',
                        ),
                        onChanged: (_) => vm.onChanged(),
                        onSubmitted: (_) => vm.test(),
                      ),
                      if (vm.message != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ok == true ? AppColors.successSoft : AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(
                              ok == true ? Icons.check_circle_outline : Icons.error_outline,
                              color: ok == true ? AppColors.success : AppColors.danger,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(vm.message!)),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: vm.testing || vm.saving ? null : vm.test,
                            child: vm.testing && !vm.saving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Test connection'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: vm.testing || vm.saving
                                ? null
                                : () async {
                                    final saved = await vm.save();
                                    if (saved && !firstRun && context.mounted) Navigator.of(context).pop();
                                  },
                            child: vm.saving
                                ? const SizedBox(
                                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save'),
                          ),
                        ),
                      ]),
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
