import '../../core/network/api_client.dart';
import '../models/consultation.dart';
import '../models/json_utils.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../models/rtc_credentials.dart';

class ConsultationRepository {
  ConsultationRepository(this._api);

  final ApiClient _api;

  /// Kiosk: request a consultation.
  Future<Consultation> create({
    required String storeId,
    required Patient patient,
    required List<String> symptoms,
    required String complaint,
    required String duration,
    required String allergies,
    required Vitals vitals,
    required String specialty,
    required bool consent,
  }) async {
    final res = await _api.post('/consultations', {
      'storeId': storeId,
      'patient': patient.toJson(),
      'symptoms': symptoms,
      'complaint': complaint,
      'duration': duration,
      'allergies': allergies,
      'vitals': vitals.toJson(),
      'specialty': specialty,
      'consent': consent,
    });
    return Consultation.fromJson(asMap(res));
  }

  Future<Consultation> get(String id) async =>
      Consultation.fromJson(asMap(await _api.get('/consultations/$id')));

  /// Staff/doctor/admin list. [status] may be "active" (waiting + in call).
  Future<List<Consultation>> list({String? status, bool today = false, String? doctorId}) async {
    final res = await _api.get('/consultations', query: {
      if (status != null) 'status': status,
      if (today) 'today': '1',
      if (doctorId != null) 'doctorId': doctorId,
    }) as List;
    return res.map((e) => Consultation.fromJson(asMap(e))).toList();
  }

  Future<Consultation> accept(String id) async =>
      Consultation.fromJson(asMap(await _api.patch('/consultations/$id', {'action': 'accept'})));

  Future<Consultation> end(String id) async =>
      Consultation.fromJson(asMap(await _api.patch('/consultations/$id', {'action': 'end'})));

  Future<void> cancel(String id, String reason) async {
    await _api.patch('/consultations/$id', {'action': 'cancel', 'reason': reason});
  }

  /// Agora token for this consultation's channel. [as] is "patient" or "doctor".
  Future<RtcCredentials> rtcCredentials(String id, {required String as}) async =>
      RtcCredentials.fromJson(asMap(await _api.get('/consultations/$id/rtc', query: {'as': as})));

  Future<Prescription> issuePrescription(String id, PrescriptionDraft draft) async =>
      Prescription.fromJson(asMap(await _api.post('/consultations/$id/prescription', draft.toJson())));
}
