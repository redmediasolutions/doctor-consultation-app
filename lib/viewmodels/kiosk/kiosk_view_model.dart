import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/agora_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/session_service.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/consultation.dart';
import '../../data/models/doctor.dart';
import '../../data/models/patient.dart';
import '../../data/models/prescription.dart';
import '../../data/models/store.dart';
import '../../data/repositories/consultation_repository.dart';
import '../../data/repositories/directory_repository.dart';
import '../../data/repositories/prescription_repository.dart';
import '../base_view_model.dart';

enum KioskStep { welcome, details, symptoms, review, waiting, call, done }

/// The whole patient journey on the store tablet:
/// welcome → details → symptoms → review (camera + consent) → waiting → video call → done.
class KioskViewModel extends BaseViewModel {
  KioskViewModel({
    required this.storeId,
    required DirectoryRepository directory,
    required ConsultationRepository consultations,
    required PrescriptionRepository prescriptions,
    required AgoraService agora,
    required PermissionService permissions,
    required SessionService session,
  })  : _directory = directory,
        _consultations = consultations,
        _prescriptions = prescriptions,
        _agora = agora,
        _permissions = permissions,
        _session = session;

  final String storeId;
  final DirectoryRepository _directory;
  final ConsultationRepository _consultations;
  final PrescriptionRepository _prescriptions;
  final AgoraService _agora;
  final PermissionService _permissions;
  final SessionService _session;

  /// Set by the view to show snackbars.
  void Function(String message)? onNotice;

  // ------------------------------------------------------------------ state
  KioskStep step = KioskStep.welcome;
  Store? store;
  List<Doctor> doctors = [];
  bool doctorsLoaded = false;

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final complaintController = TextEditingController();
  final allergiesController = TextEditingController();
  final bpController = TextEditingController();
  final pulseController = TextEditingController();
  final temperatureController = TextEditingController();
  final spo2Controller = TextEditingController();
  final weightController = TextEditingController();

  String? gender;
  final Set<String> symptoms = <String>{};
  String? duration;
  String specialty = AppConstants.specialties.first;
  bool consent = false;

  bool cameraReady = false;
  bool preparingCamera = false;
  String? cameraError;
  bool submitting = false;

  Consultation? consultation;
  Prescription? prescription;
  final List<ChatMessage> messages = [];
  bool hasUnreadChat = false;
  String? videoError;
  int countdown = AppConstants.kioskResetSeconds;

  Timer? _doctorTimer;
  Timer? _statusTimer;
  Timer? _idleTimer;
  Timer? _countdownTimer;
  StreamSubscription<ChatMessage>? _chatSub;
  bool _joining = false;

  // --------------------------------------------------------------- getters
  List<Doctor> get onlineDoctors => doctors.where((d) => d.isOnline).toList();
  List<Doctor> get availableDoctors => doctors.where((d) => d.status == DoctorStatus.online).toList();

  bool isSpecialtyAvailable(String s) => availableDoctors.any((d) => d.specialty == s);

  bool get noDoctorForSpecialty => !onlineDoctors.any((d) => d.specialty == specialty);

  int? get feeForSpecialty {
    for (final d in [...availableDoctors, ...onlineDoctors, ...doctors]) {
      if (d.specialty == specialty) return d.fee;
    }
    return null;
  }

  String get _phoneDigits => phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get detailsValid {
    final age = int.tryParse(ageController.text.trim());
    return nameController.text.trim().length >= 2 &&
        age != null &&
        age >= 0 &&
        age <= 120 &&
        gender != null &&
        _phoneDigits.length == 10;
  }

  bool get symptomsValid => symptoms.isNotEmpty || complaintController.text.trim().length >= 3;

  bool get canSubmit => consent && cameraReady && !submitting;

  String get concernSummary =>
      [symptoms.join(', '), complaintController.text.trim()].where((s) => s.isNotEmpty).join(' — ');

  // -------------------------------------------------------------- lifecycle
  Future<void> init() async {
    try {
      final stores = await _directory.stores();
      for (final s in stores) {
        if (s.id == storeId) store = s;
      }
      if (store == null) {
        // The saved store was removed on the server — ask staff to pick again.
        await _session.resetDevice();
        return;
      }
    } catch (e) {
      onNotice?.call(describeError(e));
    }
    notify();
    _syncDoctorPolling();
  }

  void _syncDoctorPolling() {
    final shouldPoll = step == KioskStep.welcome ||
        step == KioskStep.details ||
        step == KioskStep.symptoms ||
        step == KioskStep.review;
    if (shouldPoll && _doctorTimer == null) {
      _doctorTimer = poll(const Duration(seconds: 10), () async {
        doctors = await _directory.doctors();
        doctorsLoaded = true;
        notify();
      });
    } else if (!shouldPoll && _doctorTimer != null) {
      cancelTimer(_doctorTimer);
      _doctorTimer = null;
    }
  }

  void _go(KioskStep next) {
    step = next;
    _restartIdleTimer();
    _syncDoctorPolling();
    notify();
  }

  /// Abandoned forms go back to the welcome screen.
  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (step == KioskStep.details || step == KioskStep.symptoms || step == KioskStep.review) {
      _idleTimer = Timer(AppConstants.kioskIdleTimeout, reset);
    }
  }

  /// Called by the view on every tap / keystroke.
  void touch() {
    _restartIdleTimer();
    notify();
  }

  // ------------------------------------------------------------ navigation
  void start() => _go(KioskStep.details);

  void back() {
    switch (step) {
      case KioskStep.details:
        reset();
      case KioskStep.symptoms:
        _go(KioskStep.details);
      case KioskStep.review:
        _go(KioskStep.symptoms);
      default:
        break;
    }
  }

  void next() {
    if (step == KioskStep.details && detailsValid) {
      _go(KioskStep.symptoms);
    } else if (step == KioskStep.symptoms && symptomsValid) {
      _go(KioskStep.review);
      prepareCamera();
    }
  }

  // ---------------------------------------------------------------- form
  void setGender(String g) {
    gender = g;
    touch();
  }

  void toggleSymptom(String s) {
    if (!symptoms.remove(s)) symptoms.add(s);
    touch();
  }

  void setDuration(String d) {
    duration = d;
    touch();
  }

  void setSpecialty(String s) {
    specialty = s;
    touch();
  }

  void setConsent(bool v) {
    consent = v;
    touch();
  }

  // --------------------------------------------------------------- camera
  Future<void> prepareCamera() async {
    preparingCamera = true;
    cameraError = null;
    notify();
    final denied = await _permissions.requestCallPermissions();
    if (denied != null) {
      cameraError = denied;
    } else {
      try {
        await _agora.startPreview();
        cameraReady = true;
      } catch (e) {
        cameraError = describeError(e);
      }
    }
    preparingCamera = false;
    notify();
  }

  Future<void> openSettings() => _permissions.openSettings();

  // ------------------------------------------------------- consultation
  Future<void> submit() async {
    if (!canSubmit) return;
    submitting = true;
    notify();
    try {
      consultation = await _consultations.create(
        storeId: storeId,
        patient: Patient(
          name: nameController.text.trim(),
          age: int.parse(ageController.text.trim()),
          gender: gender!,
          phone: _phoneDigits,
        ),
        symptoms: symptoms.toList(),
        complaint: complaintController.text.trim(),
        duration: duration ?? '',
        allergies: allergiesController.text.trim(),
        vitals: Vitals(
          bp: bpController.text.trim(),
          pulse: pulseController.text.trim(),
          temperature: temperatureController.text.trim(),
          spo2: spo2Controller.text.trim(),
          weight: weightController.text.trim(),
        ),
        specialty: specialty,
        consent: consent,
      );
      _idleTimer?.cancel();
      _go(KioskStep.waiting);
      _statusTimer = poll(const Duration(milliseconds: 2500), _pollStatus);
    } catch (e) {
      onNotice?.call(describeError(e));
    } finally {
      submitting = false;
      notify();
    }
  }

  Future<void> _pollStatus() async {
    final current = consultation;
    if (current == null) return;
    final fresh = await _consultations.get(current.id);
    if (consultation?.id != fresh.id) return; // reset happened meanwhile
    consultation = fresh;

    if (fresh.status == ConsultationStatus.inCall && step == KioskStep.waiting) {
      await _joinCall(fresh);
    } else if (fresh.status == ConsultationStatus.completed) {
      await _finish(fresh);
    } else if (fresh.status == ConsultationStatus.cancelled) {
      onNotice?.call(fresh.cancelReason ?? 'The consultation was cancelled.');
      await reset();
      return;
    }
    notify();
  }

  Future<void> _joinCall(Consultation c) async {
    if (_joining) return;
    _joining = true;
    step = KioskStep.call;
    videoError = null;
    notify();
    try {
      final creds = await _consultations.rtcCredentials(c.id, as: 'patient');
      await _agora.join(creds, renew: () => _consultations.rtcCredentials(c.id, as: 'patient'));
      _chatSub ??= _agora.chatMessages.listen((m) {
        messages.add(m);
        hasUnreadChat = true;
        notify();
      });
    } catch (e) {
      videoError = describeError(e);
    } finally {
      _joining = false;
      notify();
    }
  }

  /// Rejoin the video if the connection dropped.
  Future<void> reconnect() async {
    final c = consultation;
    if (c != null && c.status == ConsultationStatus.inCall) await _joinCall(c);
  }

  Future<void> _finish(Consultation c) async {
    if (step == KioskStep.done) return;
    cancelTimer(_statusTimer);
    _statusTimer = null;
    await _agora.leave();
    final rxId = c.prescriptionId;
    if (rxId != null) {
      try {
        prescription = await _prescriptions.get(rxId);
      } catch (_) {
        prescription = null;
      }
    }
    _startCountdown();
    _go(KioskStep.done);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    countdown = AppConstants.kioskResetSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      countdown -= 1;
      if (countdown <= 0) {
        reset();
      } else {
        notify();
      }
    });
  }

  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final m = ChatMessage(from: 'patient', text: t.length > 400 ? t.substring(0, 400) : t, at: DateTime.now());
    messages.add(m);
    notify();
    _agora.sendChat(m);
  }

  void markChatRead() {
    if (!hasUnreadChat) return;
    hasUnreadChat = false;
    notify();
  }

  Future<void> cancelWaiting() => _cancel('Patient cancelled while waiting');

  Future<void> leaveCall() => _cancel('Patient left the call');

  Future<void> _cancel(String reason) async {
    final c = consultation;
    if (c != null) {
      try {
        await _consultations.cancel(c.id, reason);
      } catch (_) {}
    }
    await reset();
  }

  /// Clears everything for the next patient.
  Future<void> reset() async {
    _idleTimer?.cancel();
    _countdownTimer?.cancel();
    cancelTimer(_statusTimer);
    _statusTimer = null;
    await _chatSub?.cancel();
    _chatSub = null;
    if (isDisposed) return;
    await _agora.leave();

    for (final controller in [
      nameController,
      ageController,
      phoneController,
      complaintController,
      allergiesController,
      bpController,
      pulseController,
      temperatureController,
      spo2Controller,
      weightController,
    ]) {
      controller.clear();
    }
    gender = null;
    symptoms.clear();
    duration = null;
    specialty = AppConstants.specialties.first;
    consent = false;
    cameraReady = false;
    cameraError = null;
    consultation = null;
    prescription = null;
    messages.clear();
    hasUnreadChat = false;
    videoError = null;
    countdown = AppConstants.kioskResetSeconds;
    _go(KioskStep.welcome);
  }

  /// Staff-only: change this tablet's store or mode.
  Future<void> changeDeviceSetup() async {
    await reset();
    await _session.resetDevice();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _countdownTimer?.cancel();
    _chatSub?.cancel();
    final open = consultation;
    if (open != null && (step == KioskStep.waiting || step == KioskStep.call)) {
      _consultations.cancel(open.id, 'Kiosk closed').catchError((_) {});
    }
    _agora.leave();
    for (final controller in [
      nameController,
      ageController,
      phoneController,
      complaintController,
      allergiesController,
      bpController,
      pulseController,
      temperatureController,
      spo2Controller,
      weightController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
