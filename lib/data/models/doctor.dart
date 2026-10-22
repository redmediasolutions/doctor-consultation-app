import 'json_utils.dart';

enum DoctorStatus { online, busy, offline }

DoctorStatus doctorStatusFrom(String s) => switch (s) {
      'online' => DoctorStatus.online,
      'busy' => DoctorStatus.busy,
      _ => DoctorStatus.offline,
    };

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.registrationNo,
    required this.experienceYears,
    required this.languages,
    required this.fee,
    required this.status,
  });

  final String id;
  final String name;
  final String specialty;
  final String qualification;
  final String registrationNo;
  final int experienceYears;
  final List<String> languages;
  final int fee;
  final DoctorStatus status;

  bool get isOnline => status != DoctorStatus.offline;

  factory Doctor.fromJson(Map<String, dynamic> j) => Doctor(
        id: asString(j['id']),
        name: asString(j['name']),
        specialty: asString(j['specialty']),
        qualification: asString(j['qualification']),
        registrationNo: asString(j['registrationNo']),
        experienceYears: asInt(j['experienceYears']),
        languages: asStringList(j['languages']),
        fee: asInt(j['fee']),
        status: doctorStatusFrom(asString(j['status'])),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'qualification': qualification,
        'registrationNo': registrationNo,
        'experienceYears': experienceYears,
        'languages': languages,
        'fee': fee,
        'status': status.name,
      };
}
