import '../../core/network/api_client.dart';
import '../../core/services/session_service.dart';
import '../../data/models/consultation.dart';
import '../../data/models/prescription.dart';
import '../../data/models/store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../base_view_model.dart';

/// Pharmacy counter: today's prescriptions for this store + who is at the kiosk.
class PharmacyViewModel extends BaseViewModel {
  PharmacyViewModel({
    required this.store,
    required PrescriptionRepository prescriptions,
    required ConsultationRepository consultations,
    required AuthRepository auth,
    required SessionService session,
  })  : _prescriptions = prescriptions,
        _consultations = consultations,
        _auth = auth,
        _session = session;

  final Store store;
  final PrescriptionRepository _prescriptions;
  final ConsultationRepository _consultations;
  final AuthRepository _auth;
  final SessionService _session;

  /// View hooks.
  void Function(Prescription rx)? onNewPrescription;
  void Function(String message)? onNotice;

  List<Prescription> prescriptions = [];
  List<Consultation> atKiosk = [];
  bool loading = true;
  String? error;
  Set<String>? _known;

  List<Prescription> get pending => prescriptions.where((p) => !p.dispensed).toList();
  List<Prescription> get dispensed => prescriptions.where((p) => p.dispensed).toList();

  void start() {
    poll(const Duration(seconds: 4), _load);
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _prescriptions.list(today: true),
        _consultations.list(status: 'active'),
      ]);
      prescriptions = results[0] as List<Prescription>;
      atKiosk = results[1] as List<Consultation>;
      error = null;

      final known = _known;
      if (known != null) {
        for (final rx in prescriptions) {
          if (!known.contains(rx.id)) onNewPrescription?.call(rx);
        }
      }
      _known = prescriptions.map((p) => p.id).toSet();
    } catch (e) {
      error = describeError(e);
      if (e is ApiException && e.isUnauthorised) {
        onNotice?.call('Your session expired. Please sign in again.');
        await _auth.logout();
      }
    } finally {
      loading = false;
      notify();
    }
  }

  /// Returns the updated prescription, or null on error (error shown via [onNotice]).
  Future<Prescription?> setDispensed(Prescription rx, bool value) async {
    try {
      final updated = await _prescriptions.setDispensed(rx.id, value);
      prescriptions = [for (final p in prescriptions) p.id == updated.id ? updated : p];
      notify();
      onNotice?.call(value ? 'Token ${rx.token} marked as dispensed' : 'Moved back to pending');
      return updated;
    } catch (e) {
      onNotice?.call(describeError(e));
      return null;
    }
  }

  Future<void> logout() => _auth.logout();

  Future<void> changeMode() async {
    await _auth.logout();
    await _session.resetDevice();
  }
}
