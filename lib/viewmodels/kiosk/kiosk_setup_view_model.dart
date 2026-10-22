import '../../core/services/session_service.dart';
import '../../data/models/store.dart';
import '../../data/repositories/directory_repository.dart';
import '../base_view_model.dart';

/// One-time tablet setup: which store is this kiosk in?
class KioskSetupViewModel extends BaseViewModel {
  KioskSetupViewModel({required DirectoryRepository directory, required SessionService session})
      : _directory = directory,
        _session = session;

  final DirectoryRepository _directory;
  final SessionService _session;

  List<Store> stores = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notify();
    try {
      stores = await _directory.stores();
    } catch (e) {
      error = describeError(e);
    } finally {
      loading = false;
      notify();
    }
  }

  Future<void> choose(Store store) => _session.setKioskStore(store.id);

  Future<void> changeMode() => _session.resetDevice();
}
