import 'package:flutter/widgets.dart';

import '../../core/services/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../base_view_model.dart';

enum LoginStep { phone, otp }

/// Mobile-number OTP sign-in for every mode (kiosk staff, doctor, pharmacy counter, owner).
class LoginViewModel extends BaseViewModel {
  LoginViewModel({required this.role, required AuthRepository auth}) : _auth = auth;

  final DeviceRole role;
  final AuthRepository _auth;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  LoginStep step = LoginStep.phone;
  String _reqId = '';
  String sentTo = '';
  bool busy = false;
  String? error;

  bool get canSend => !busy && phoneController.text.replaceAll(RegExp(r'\D'), '').length >= 10;
  bool get canVerify => !busy && otpController.text.trim().length >= 4;

  void onChanged() => notify();

  Future<void> sendOtp() async {
    if (!canSend) return;
    busy = true;
    error = null;
    notify();
    try {
      final (reqId, phone) = await _auth.sendOtp(phoneController.text);
      _reqId = reqId;
      sentTo = phone;
      otpController.clear();
      step = LoginStep.otp;
    } catch (e) {
      error = describeError(e);
    } finally {
      busy = false;
      notify();
    }
  }

  /// On success the app root switches to the signed-in screen by itself.
  Future<void> verify() async {
    if (!canVerify) return;
    busy = true;
    error = null;
    notify();
    try {
      await _auth.verifyOtp(role: role, phone: sentTo, otp: otpController.text.trim(), reqId: _reqId);
    } catch (e) {
      error = describeError(e);
      otpController.clear();
    } finally {
      busy = false;
      notify();
    }
  }

  void changeNumber() {
    step = LoginStep.phone;
    error = null;
    notify();
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
