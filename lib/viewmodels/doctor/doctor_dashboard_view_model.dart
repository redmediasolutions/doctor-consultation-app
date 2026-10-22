import 'dart:async';

import '../../core/network/api_client.dart';
import '../../core/services/session_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/consultation.dart';
import '../../data/models/doctor.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../base_view_model.dart';

enum QueueFilter { all, mySpecialty }

/// Doctor home: availability, live queue from all stores, today's history.
class DoctorDashboardViewModel extends BaseViewModel {
  DoctorDashboardViewModel({
    required this.doctor,
    required SessionService session,
    required DirectoryRepository directory,
    required ConsultationRepository consultations,
    required AuthRepository auth,
  })  : _session = session,
        _directory = directory,
        _consultations = consultations,
        _auth = auth,
        available = session.doctorAvailable;

  final Doctor doctor;
  final SessionService _session;
  final DirectoryRepository _directory;
  final ConsultationRepository _consultations;
  final AuthRepository _auth;

  /// View hooks.
  void Function(int newCount)? onNewPatients;
  void Function(String message)? onNotice;

  bool available;
  bool inConsultation = false;
  QueueFilter filter = QueueFilter.all;

  List<Consultation> active = [];
  List<Consultation> history = [];
  bool loading = true;
  String? error;

  final Set<String> _seen = <String>{};
  bool _firstLoad = true;
  Timer? _heartbeat;

  String get presence => inConsultation ? 'busy' : (available ? 'online' : 'offline');

  List<Consultation> get waiting {
    final list = active
        .where((c) => c.status == ConsultationStatus.waiting)
        .where((c) => filter == QueueFilter.all || c.specialty == doctor.specialty)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// A call this doctor accepted but never finished (e.g. app was closed).
  Consultation? get myOpenCall {
    for (final c in active) {
      if (c.status == ConsultationStatus.inCall && c.doctorId == doctor.id) return c;
    }
    return null;
  }

  List<Consultation> get completedToday =>
      history.where((c) => c.status == ConsultationStatus.completed).toList();

  int get prescriptionsToday => completedToday.where((c) => c.prescriptionId != null).length;

  String get avgCallText {
    final done = completedToday;
    if (done.isEmpty) return '—';
    final total = done.fold<int>(0, (s, c) => s + Fmt.minutesBetween(c.acceptedAt, c.endedAt));
    return '${(total / done.length).round()} min';
  }

  void start() {
    _heartbeat = poll(const Duration(seconds: 15), _beat);
    poll(const Duration(seconds: 3), _loadQueue);
    poll(const Duration(seconds: 15), _loadHistory);
  }

  Future<void> _beat() async {
    try {
      await _directory.heartbeat(presence);
    } catch (e) {
      await _handleError(e);
    }
  }

  Future<void> _loadQueue() async {
    try {
      active = await _consultations.list(status: 'active');
      error = null;
      final ids = waiting.map((c) => c.id).toList();
      final fresh = ids.where((id) => !_seen.contains(id)).length;
      if (!_firstLoad && fresh > 0 && available && !inConsultation) onNewPatients?.call(fresh);
      _seen.addAll(ids);
      _firstLoad = false;
    } catch (e) {
      error = describeError(e);
      await _handleError(e);
    } finally {
      loading = false;
      notify();
    }
  }

  Future<void> _loadHistory() async {
    try {
      history = await _consultations.list(doctorId: 'me', today: true);
      notify();
    } catch (e) {
      await _handleError(e);
    }
  }

  Future<void> refresh() async {
    await Future.wait([_loadQueue(), _loadHistory()]);
  }

  Future<void> setAvailable(bool value) async {
    available = value;
    await _session.setDoctorAvailable(value);
    notify();
    await _beat();
  }

  void setFilter(QueueFilter f) {
    filter = f;
    notify();
  }

  /// Takes a waiting patient. Returns the updated consultation, or null if someone else got there first.
  Future<Consultation?> accept(Consultation c) async {
    try {
      final updated = await _consultations.accept(c.id);
      return updated;
    } catch (e) {
      onNotice?.call(describeError(e));
      await _loadQueue();
      return null;
    }
  }

  Future<void> setInConsultation(bool value) async {
    inConsultation = value;
    notify();
    await _beat();
    if (!value) await refresh();
  }

  Future<void> logout() async {
    cancelTimer(_heartbeat);
    try {
      await _directory.heartbeat('offline');
    } catch (_) {}
    await _auth.logout();
  }

  Future<void> changeMode() async {
    await logout();
    await _session.resetDevice();
  }

  Future<void> _handleError(Object e) async {
    if (e is ApiException && e.isUnauthorised && !isDisposed) {
      onNotice?.call('Your session expired. Please sign in again.');
      await _auth.logout();
    }
  }
}
