/// Clinical lists and timings used across the app.
class AppConstants {
  AppConstants._();

  static const List<String> specialties = [
    'General Physician',
    'Paediatrics',
    'Dermatology',
    'Gynaecology',
    'ENT',
    'Orthopaedics',
  ];

  static const List<String> commonSymptoms = [
    'Fever',
    'Cold & cough',
    'Sore throat',
    'Headache',
    'Body ache',
    'Stomach pain',
    'Acidity',
    'Loose motions',
    'Vomiting',
    'Skin rash',
    'Allergy',
    'Joint pain',
    'Back pain',
    'BP check',
    'Sugar / diabetes',
    'Eye irritation',
  ];

  static const List<String> durations = [
    'Today',
    '1–2 days',
    '3–5 days',
    '1 week',
    'More than a week',
  ];

  static const List<String> frequencies = [
    '1-0-0',
    '0-1-0',
    '0-0-1',
    '1-0-1',
    '1-1-1',
    '1-1-1-1',
    '0-0-0-1 (SOS)',
    'Once a week',
  ];

  static const List<String> timings = [
    'After food',
    'Before food',
    'With food',
    'Empty stomach',
    'At bedtime',
    'As needed',
  ];

  /// Autocomplete suggestions on the prescription pad (doctors can type anything).
  static const List<String> commonMedicines = [
    'Paracetamol 500 mg tablet',
    'Paracetamol 650 mg tablet',
    'Ibuprofen 400 mg tablet',
    'Cetirizine 10 mg tablet',
    'Levocetirizine 5 mg tablet',
    'Montelukast 10 mg + Levocetirizine 5 mg tablet',
    'Fexofenadine 120 mg tablet',
    'Pantoprazole 40 mg tablet',
    'Omeprazole 20 mg capsule',
    'Rabeprazole 20 mg + Domperidone 30 mg capsule',
    'Domperidone 10 mg tablet',
    'Ondansetron 4 mg tablet',
    'ORS sachet',
    'Racecadotril 100 mg capsule',
    'Amoxicillin 500 mg capsule',
    'Amoxicillin 500 mg + Clavulanic acid 125 mg tablet',
    'Azithromycin 500 mg tablet',
    'Cefixime 200 mg tablet',
    'Doxycycline 100 mg capsule',
    'Metronidazole 400 mg tablet',
    'Dextromethorphan cough syrup',
    'Ambroxol + Guaifenesin syrup',
    'Vitamin C 500 mg tablet',
    'Zinc 50 mg tablet',
    'Vitamin D3 60,000 IU capsule',
    'Calcium + Vitamin D3 tablet',
    'Diclofenac gel',
    'Clotrimazole 1% cream',
    'Mupirocin 2% ointment',
    'Calamine lotion',
    'Carboxymethylcellulose 0.5% eye drops',
    'Saline nasal spray',
    'Metformin 500 mg tablet',
    'Amlodipine 5 mg tablet',
    'Telmisartan 40 mg tablet',
  ];

  /// Kiosk returns to the welcome screen this long after a consultation ends.
  static const int kioskResetSeconds = 90;

  /// An abandoned kiosk form resets after this much inactivity.
  static const Duration kioskIdleTimeout = Duration(minutes: 3);

  /// Fixed Agora user ids inside a consultation channel (must match backend RTC_UID).
  static const int patientRtcUid = 1001;
  static const int doctorRtcUid = 2001;
}
