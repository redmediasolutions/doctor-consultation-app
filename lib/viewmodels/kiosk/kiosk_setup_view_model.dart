import '../../core/services/session_service.dart';
import '../../data/models/store.dart';
import '../../data/repositories/directory_repository.dart';
import '../base_view_model.dart';

/// Owner signed in on a kiosk tablet / pharmacy counter: which store is it for?
/// (Store staff skip this — their login already belongs to one store.)
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

  Future<void> choose(Store store) => _session.setStore(store.toJson());

  Future<void> changeMode() => _session.resetDevice();

  Future<void> signOut() => _session.logout();
}
