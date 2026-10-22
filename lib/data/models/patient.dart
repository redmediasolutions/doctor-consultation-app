import 'json_utils.dart';

class Patient {
  const Patient({required this.name, required this.age, required this.gender, required this.phone});

  final String name;
  final int age;
  final String gender; // Male | Female | Other
  final String phone;

  String get summary => '$age y · $gender';

  factory Patient.fromJson(Map<String, dynamic> j) => Patient(
        name: asString(j['name']),
        age: asInt(j['age']),
        gender: asString(j['gender'], 'Other'),
        phone: asString(j['phone']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'age': age, 'gender': gender, 'phone': phone};
}

class Vitals {
  const Vitals({this.bp = '', this.pulse = '', this.temperature = '', this.spo2 = '', this.weight = ''});

  final String bp;
  final String pulse;
  final String temperature;
  final String spo2;
  final String weight;

  bool get isEmpty => [bp, pulse, temperature, spo2, weight].every((v) => v.isEmpty);

  /// Short one-line summary for queue tiles.
  String get summary => [
        if (bp.isNotEmpty) 'BP $bp',
        if (pulse.isNotEmpty) 'Pulse $pulse',
        if (temperature.isNotEmpty) '$temperature°F',
        if (spo2.isNotEmpty) 'SpO₂ $spo2%',
      ].join(' · ');

  factory Vitals.fromJson(Map<String, dynamic> j) => Vitals(
        bp: asString(j['bp']),
        pulse: asString(j['pulse']),
        temperature: asString(j['temperature']),
        spo2: asString(j['spo2']),
        weight: asString(j['weight']),
      );

  Map<String, dynamic> toJson() =>
      {'bp': bp, 'pulse': pulse, 'temperature': temperature, 'spo2': spo2, 'weight': weight};
}
