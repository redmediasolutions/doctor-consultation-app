import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/agora_service.dart';
import '../../core/services/permission_service.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/consultation.dart';
import '../../data/models/prescription.dart';
import '../../data/repositories/consultation_repository.dart';
import '../base_view_model.dart';

/// One medicine row on the prescription pad.
class MedicineDraft {
  MedicineDraft()
      : name = TextEditingController(),
        duration = TextEditingController(text: '5 days'),
        quantity = TextEditingController(),
        instructions = TextEditingController();

  final TextEditingController name;
  final TextEditingController duration;
  final TextEditingController quantity;
  final TextEditingController instructions;

  /// Focus for the medicine-name autocomplete.
  final FocusNode nameFocus = FocusNode();
  String frequency = '1-0-1';
  String timing = 'After food';

  bool get isFilled => name.text.trim().isNotEmpty;

  Medicine toMedicine() => Medicine(
        name: name.text.trim(),
        frequency: frequency,
        timing: timing,
        duration: duration.text.trim(),
        quantity: quantity.text.trim(),
        instructions: instructions.text.trim(),
      );

  void dispose() {
    name.dispose();
    duration.dispose();
    quantity.dispose();
    instructions.dispose();
    nameFocus.dispose();
  }
}

/// A single live consultation on the doctor's side: video, patient info, chat and the Rx pad.
class DoctorConsultViewModel extends BaseViewModel {
  DoctorConsultViewModel({
    required Consultation consultation,
    required AgoraService agora,
    required ConsultationRepository consultations,
    required PermissionService permissions,
  })  : _consultation = consultation,
        _agora = agora,
        _consultations = consultations,
        _permissions = permissions {
    chiefComplaintController.text = [
      consultation.concern,
      if (consultation.duration.isNotEmpty) '(${consultation.duration})',
    ].where((s) => s.isNotEmpty).join(' ');
  }

  Consultation _consultation;
  final AgoraService _agora;
  final ConsultationRepository _consultations;
  final PermissionService _permissions;

  Consultation get consultation => _consultation;

  final diagnosisController = TextEditingController();
  final chiefComplaintController = TextEditingController();
  final investigationsController = TextEditingController();
  final adviceController = TextEditingController();
  final followUpController = TextEditingController();
  final List<MedicineDraft> medicines = [MedicineDraft()];

  final List<ChatMessage> messages = [];
  bool hasUnreadChat = false;

  bool connecting = false;
  String? videoError;
  bool submitting = false;
  bool showValidation = false;

  /// Set when the patient cancelled / left — the view closes the screen.
  bool patientLeft = false;

  /// Set when the consultation is finished (Rx issued or ended).
  bool finished = false;
  Prescription? issued;

  StreamSubscription<ChatMessage>? _chatSub;

  List<String> get medicineSuggestions => AppConstants.commonMedicines;

  bool get draftValid =>
      diagnosisController.text.trim().isNotEmpty &&
      (medicines.any((m) => m.isFilled) || adviceController.text.trim().isNotEmpty);

  // ---------------------------------------------------------------- video
  Future<void> start() async {
    _chatSub = _agora.chatMessages.listen((m) {
      messages.add(m);
      hasUnreadChat = true;
      notify();
    });
    poll(const Duration(seconds: 4), _watchStatus, immediately: false);
    await connect();
  }

  Future<void> connect() async {
    connecting = true;
    videoError = null;
    notify();
    final denied = await _permissions.requestCallPermissions();
    if (denied != null) {
      videoError = denied;
      connecting = false;
      notify();
      return;
    }
    try {
      final id = _consultation.id;
      final creds = await _consultations.rtcCredentials(id, as: 'doctor');
      await _agora.join(creds, renew: () => _consultations.rtcCredentials(id, as: 'doctor'));
    } catch (e) {
      videoError = describeError(e);
    } finally {
      connecting = false;
      notify();
    }
  }

  Future<void> _watchStatus() async {
    if (finished) return;
    final fresh = await _consultations.get(_consultation.id);
    _consultation = fresh;
    if (fresh.status == ConsultationStatus.cancelled) {
      patientLeft = true;
      finished = true;
      await _agora.leave();
    }
    notify();
  }

  // ------------------------------------------------------------------ chat
  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final m = ChatMessage(from: 'doctor', text: t.length > 400 ? t.substring(0, 400) : t, at: DateTime.now());
    messages.add(m);
    notify();
    _agora.sendChat(m);
  }

  void markChatRead() {
    if (!hasUnreadChat) return;
    hasUnreadChat = false;
    notify();
  }

  // ------------------------------------------------------------ Rx pad
  void touch() => notify();

  void addMedicine() {
    medicines.add(MedicineDraft());
    notify();
  }

  void removeMedicine(int index) {
    if (medicines.length <= 1) return;
    medicines.removeAt(index).dispose();
    notify();
  }

  void setFrequency(int index, String value) {
    medicines[index].frequency = value;
    notify();
  }

  void setTiming(int index, String value) {
    medicines[index].timing = value;
    notify();
  }

  /// Issues the e-prescription (also completes the consultation). Returns an error message or null.
  Future<String?> issuePrescription() async {
    showValidation = true;
    if (!draftValid) {
      notify();
      return 'Add a diagnosis and at least one medicine or advice.';
    }
    submitting = true;
    notify();
    try {
      issued = await _consultations.issuePrescription(
        _consultation.id,
        PrescriptionDraft(
          diagnosis: diagnosisController.text.trim(),
          chiefComplaint: chiefComplaintController.text.trim(),
          medicines: medicines.where((m) => m.isFilled).map((m) => m.toMedicine()).toList(),
          investigations: investigationsController.text.trim(),
          advice: adviceController.text.trim(),
          followUp: followUpController.text.trim(),
        ),
      );
      finished = true;
      await _agora.leave();
      return null;
    } catch (e) {
      return describeError(e);
    } finally {
      submitting = false;
      notify();
    }
  }

  /// Ends without a prescription (e.g. patient needs an in-person visit).
  Future<String?> endWithoutPrescription() async {
    try {
      await _consultations.end(_consultation.id);
      finished = true;
      await _agora.leave();
      notify();
      return null;
    } catch (e) {
      return describeError(e);
    }
  }

  /// Leave the screen but keep the consultation open (doctor can rejoin from the dashboard).
  Future<void> leaveTemporarily() => _agora.leave();

  @override
  void dispose() {
    _chatSub?.cancel();
    if (!finished) _agora.leave();
    diagnosisController.dispose();
    chiefComplaintController.dispose();
    investigationsController.dispose();
    adviceController.dispose();
    followUpController.dispose();
    for (final m in medicines) {
      m.dispose();
    }
    super.dispose();
  }
}
