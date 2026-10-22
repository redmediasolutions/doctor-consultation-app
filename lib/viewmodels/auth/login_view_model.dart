import 'package:flutter/widgets.dart';

import '../../core/services/session_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../base_view_model.dart';

class LoginOption {
  const LoginOption({required this.id, required this.label, this.subtitle = ''});
  final String id;
  final String label;
  final String subtitle;
}

/// PIN sign-in for doctors, pharmacy counters and the owner.
class LoginViewModel extends BaseViewModel {
  LoginViewModel({
    required this.role,
    required AuthRepository auth,
    required DirectoryRepository directory,
  })  : _auth = auth,
        _directory = directory;

  final DeviceRole role;
  final AuthRepository _auth;
  final DirectoryRepository _directory;

  final TextEditingController pinController = TextEditingController();

  List<LoginOption> options = [];
  String? selectedId;
  bool loadingOptions = false;
  bool busy = false;
  String? error;

  /// Doctors pick their name; pharmacy counters pick their store; admin needs only a PIN.
  bool get needsSelection => role != DeviceRole.admin;

  String get selectionLabel => role == DeviceRole.doctor ? 'Doctor' : 'Store';

  bool get canSubmit => !busy && pinController.text.isNotEmpty && (!needsSelection || selectedId != null);

  Future<void> loadOptions() async {
    if (!needsSelection) return;
    loadingOptions = true;
    error = null;
    notify();
    try {
      if (role == DeviceRole.doctor) {
        final doctors = await _directory.doctors();
        options = doctors.map((d) => LoginOption(id: d.id, label: d.name, subtitle: d.specialty)).toList();
      } else {
        final stores = await _directory.stores();
        options = stores.map((s) => LoginOption(id: s.id, label: Fmt.shortStore(s.name), subtitle: s.city)).toList();
      }
    } catch (e) {
      error = describeError(e);
    } finally {
      loadingOptions = false;
      notify();
    }
  }

  void select(String? id) {
    selectedId = id;
    notify();
  }

  void onPinChanged() => notify();

  /// Returns true on success; the app root then switches to the signed-in screen.
  Future<bool> login() async {
    if (!canSubmit) return false;
    busy = true;
    error = null;
    notify();
    try {
      await _auth.login(role: role, id: selectedId, pin: pinController.text.trim());
      return true;
    } catch (e) {
      error = describeError(e);
      pinController.clear();
      return false;
    } finally {
      busy = false;
      notify();
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }
}
