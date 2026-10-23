import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/session_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/auth/login_view_model.dart';
import '../settings/server_settings_view.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';

/// Sign in with a registered mobile number + OTP (same logins as the Gladskin billing app).
class OtpLoginView extends StatelessWidget {
  const OtpLoginView({super.key, required this.role});

  final DeviceRole role;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LoginViewModel(role: role, auth: ctx.read<AuthRepository>()),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody();

  String _title(DeviceRole r) => switch (r) {
        DeviceRole.kiosk => 'Set up the store kiosk',
        DeviceRole.doctor => 'Doctor sign in',
        DeviceRole.pharmacy => 'Pharmacy counter',
        DeviceRole.admin => 'Owner dashboard',
      };

  String _description(DeviceRole r) => switch (r) {
        DeviceRole.kiosk =>
          "Sign in once with the store's staff mobile number. The tablet then stays ready for patients.",
        DeviceRole.doctor => 'See patients waiting at the stores and consult over video.',
        DeviceRole.pharmacy => 'Receive prescriptions issued to your store.',
        DeviceRole.admin => 'Consultations, doctors and stores across the chain.',
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final session = context.read<SessionService>();
    final otpStep = vm.step == LoginStep.otp;

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
                      if (!otpStep) ...[
                        const Text('Mobile number', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: vm.phoneController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
                            LengthLimitingTextInputFormatter(16),
                          ],
                          style: const TextStyle(fontSize: 18),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_iphone),
                            hintText: '98765 43210',
                          ),
                          onChanged: (_) => vm.onChanged(),
                          onSubmitted: (_) => vm.sendOtp(),
                        ),
                      ] else ...[
                        Row(children: [
                          Expanded(
                            child: Text.rich(TextSpan(children: [
                              const TextSpan(text: 'Code sent to ', style: TextStyle(color: AppColors.muted)),
                              TextSpan(text: vm.sentTo, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ])),
                          ),
                          TextButton(onPressed: vm.busy ? null : vm.changeNumber, child: const Text('Change')),
                        ]),
                        const SizedBox(height: 6),
                        TextField(
                          controller: vm.otpController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: const TextStyle(fontSize: 22, letterSpacing: 10),
                          decoration: const InputDecoration(hintText: '••••••'),
                          onChanged: (_) => vm.onChanged(),
                          onSubmitted: (_) => vm.verify(),
                        ),
                      ],
                      if (vm.error != null) ...[
                        const SizedBox(height: 12),
                        ErrorBanner(message: vm.error!),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: otpStep ? (vm.canVerify ? vm.verify : null) : (vm.canSend ? vm.sendOtp : null),
                        child: vm.busy
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(otpStep ? 'Verify & sign in' : 'Send OTP'),
                      ),
                      if (otpStep)
                        TextButton(
                          onPressed: vm.busy ? null : vm.sendOtp,
                          child: const Text('Resend OTP'),
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
