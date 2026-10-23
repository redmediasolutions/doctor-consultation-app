import '../../core/network/api_client.dart';
import '../../core/services/session_service.dart';
import '../../data/models/admin_stats.dart';
import '../../data/models/consultation.dart';
import '../../data/models/doctor.dart';
import '../../data/models/store.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../base_view_model.dart';

/// Owner dashboard: today's numbers across all stores, consultation log, doctors and stores.
class AdminViewModel extends BaseViewModel {
  AdminViewModel({
    required AdminRepository admin,
    required ConsultationRepository consultations,
    required DirectoryRepository directory,
    required AuthRepository auth,
    required SessionService session,
  })  : _admin = admin,
        _consultations = consultations,
        _directory = directory,
        _auth = auth,
        _session = session;

  final AdminRepository _admin;
  final ConsultationRepository _consultations;
  final DirectoryRepository _directory;
  final AuthRepository _auth;
  final SessionService _session;

  void Function(String message)? onNotice;

  AdminStats? stats;
  List<Consultation> consultations = [];
  List<Doctor> doctors = [];
  List<Store> stores = [];
  String? storeFilter; // null = all stores
  bool loading = true;
  String? error;

  List<Consultation> get filteredConsultations =>
      storeFilter == null ? consultations : consultations.where((c) => c.storeId == storeFilter).toList();

  void start() {
    poll(const Duration(seconds: 5), _load);
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _admin.stats(),
        _consultations.list(today: true),
        _directory.doctors(),
        _directory.stores(),
      ]);
      stats = results[0] as AdminStats;
      consultations = results[1] as List<Consultation>;
      doctors = results[2] as List<Doctor>;
      stores = results[3] as List<Store>;
      error = null;
    } catch (e) {
      error = describeError(e);
      if (e is ApiException && e.isUnauthorised) await _auth.logout();
    } finally {
      loading = false;
      notify();
    }
  }

  void setStoreFilter(String? storeId) {
    storeFilter = storeId;
    notify();
  }

  Future<bool> addDoctor(Map<String, dynamic> data) async {
    try {
      await _admin.addDoctor(data);
      onNotice?.call('Doctor added — they can sign in with their mobile number');
      await _load();
      return true;
    } catch (e) {
      onNotice?.call(describeError(e));
      return false;
    }
  }

  Future<void> logout() => _auth.logout();

  Future<void> changeMode() async {
    await _auth.logout();
    await _session.resetDevice();
  }
}
