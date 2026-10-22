import 'doctor.dart';
import 'json_utils.dart';
import 'patient.dart';
import 'store.dart';

class Medicine {
  const Medicine({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.timing = '',
    this.duration = '',
    this.quantity = '',
    this.instructions = '',
  });

  final String name;
  final String dosage;
  final String frequency;
  final String timing;
  final String duration;
  final String quantity;
  final String instructions;

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        name: asString(j['name']),
        dosage: asString(j['dosage']),
        frequency: asString(j['frequency']),
        timing: asString(j['timing']),
        duration: asString(j['duration']),
        quantity: asString(j['quantity']),
        instructions: asString(j['instructions']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'timing': timing,
        'duration': duration,
        'quantity': quantity,
        'instructions': instructions,
      };
}

class Prescription {
  const Prescription({
    required this.id,
    required this.rxNo,
    required this.token,
    required this.consultationId,
    required this.doctorId,
    required this.storeId,
    required this.patient,
    required this.diagnosis,
    required this.chiefComplaint,
    required this.medicines,
    required this.investigations,
    required this.advice,
    required this.followUp,
    required this.createdAt,
    required this.dispensed,
    this.dispensedAt,
    this.doctor,
    this.store,
  });

  final String id;
  final String rxNo;
  final String token;
  final String consultationId;
  final String doctorId;
  final String storeId;
  final Patient patient;
  final String diagnosis;
  final String chiefComplaint;
  final List<Medicine> medicines;
  final String investigations;
  final String advice;
  final String followUp;
  final DateTime createdAt;
  final bool dispensed;
  final DateTime? dispensedAt;
  final Doctor? doctor;
  final Store? store;

  factory Prescription.fromJson(Map<String, dynamic> j) {
    final doctor = asMapOrNull(j['doctor']);
    final store = asMapOrNull(j['store']);
    final meds = j['medicines'];
    return Prescription(
      id: asString(j['id']),
      rxNo: asString(j['rxNo']),
      token: asString(j['token']),
      consultationId: asString(j['consultationId']),
      doctorId: asString(j['doctorId']),
      storeId: asString(j['storeId']),
      patient: Patient.fromJson(asMap(j['patient'])),
      diagnosis: asString(j['diagnosis']),
      chiefComplaint: asString(j['chiefComplaint']),
      medicines: meds is List ? meds.map((m) => Medicine.fromJson(asMap(m))).toList() : const [],
      investigations: asString(j['investigations']),
      advice: asString(j['advice']),
      followUp: asString(j['followUp']),
      createdAt: asDate(j['createdAt']) ?? DateTime.now(),
      dispensed: j['dispensed'] == true,
      dispensedAt: asDate(j['dispensedAt']),
      doctor: doctor == null ? null : Doctor.fromJson(doctor),
      store: store == null ? null : Store.fromJson(store),
    );
  }
}

/// What the doctor submits from the prescription pad.
class PrescriptionDraft {
  const PrescriptionDraft({
    required this.diagnosis,
    required this.chiefComplaint,
    required this.medicines,
    required this.investigations,
    required this.advice,
    required this.followUp,
  });

  final String diagnosis;
  final String chiefComplaint;
  final List<Medicine> medicines;
  final String investigations;
  final String advice;
  final String followUp;

  Map<String, dynamic> toJson() => {
        'diagnosis': diagnosis,
        'chiefComplaint': chiefComplaint,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'investigations': investigations,
        'advice': advice,
        'followUp': followUp,
      };
}
