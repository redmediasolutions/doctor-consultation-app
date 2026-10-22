import 'doctor.dart';
import 'json_utils.dart';
import 'patient.dart';
import 'store.dart';

enum ConsultationStatus { waiting, inCall, completed, cancelled }

ConsultationStatus consultationStatusFrom(String s) => switch (s) {
      'waiting' => ConsultationStatus.waiting,
      'in_call' => ConsultationStatus.inCall,
      'completed' => ConsultationStatus.completed,
      _ => ConsultationStatus.cancelled,
    };

class Consultation {
  const Consultation({
    required this.id,
    required this.token,
    required this.storeId,
    required this.patient,
    required this.symptoms,
    required this.complaint,
    required this.duration,
    required this.allergies,
    required this.vitals,
    required this.specialty,
    required this.status,
    required this.createdAt,
    this.doctorId,
    this.prescriptionId,
    this.acceptedAt,
    this.endedAt,
    this.cancelReason,
    this.doctor,
    this.store,
    this.waitingAhead = 0,
  });

  final String id;

  /// Short token shown to the patient, e.g. "T014".
  final String token;
  final String storeId;
  final Patient patient;
  final List<String> symptoms;
  final String complaint;
  final String duration;
  final String allergies;
  final Vitals vitals;
  final String specialty;
  final ConsultationStatus status;
  final DateTime createdAt;
  final String? doctorId;
  final String? prescriptionId;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final String? cancelReason;
  final Doctor? doctor;
  final Store? store;
  final int waitingAhead;

  /// The Agora channel for this consultation is its id.
  String get channelName => id;

  String get concern => [symptoms.join(', '), complaint].where((s) => s.isNotEmpty).join(' — ');

  factory Consultation.fromJson(Map<String, dynamic> j) {
    final doctor = asMapOrNull(j['doctor']);
    final store = asMapOrNull(j['store']);
    return Consultation(
      id: asString(j['id']),
      token: asString(j['token']),
      storeId: asString(j['storeId']),
      patient: Patient.fromJson(asMap(j['patient'])),
      symptoms: asStringList(j['symptoms']),
      complaint: asString(j['complaint']),
      duration: asString(j['duration']),
      allergies: asString(j['allergies']),
      vitals: Vitals.fromJson(asMap(j['vitals'])),
      specialty: asString(j['specialty'], 'General Physician'),
      status: consultationStatusFrom(asString(j['status'])),
      createdAt: asDate(j['createdAt']) ?? DateTime.now(),
      doctorId: j['doctorId'] as String?,
      prescriptionId: j['prescriptionId'] as String?,
      acceptedAt: asDate(j['acceptedAt']),
      endedAt: asDate(j['endedAt']),
      cancelReason: j['cancelReason'] as String?,
      doctor: doctor == null ? null : Doctor.fromJson(doctor),
      store: store == null ? null : Store.fromJson(store),
      waitingAhead: asInt(j['waitingAhead']),
    );
  }
}
