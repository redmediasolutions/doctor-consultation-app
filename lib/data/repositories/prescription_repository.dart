import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/prescription.dart';

class PrescriptionRepository {
  PrescriptionRepository(this._api);

  final ApiClient _api;

  Future<List<Prescription>> list({bool today = true, bool pendingOnly = false}) async {
    final res = await _api.get('/prescriptions', query: {
      if (today) 'today': '1',
      if (pendingOnly) 'pending': '1',
    }) as List;
    return res.map((e) => Prescription.fromJson(asMap(e))).toList();
  }

  Future<Prescription> get(String id) async =>
      Prescription.fromJson(asMap(await _api.get('/prescriptions/$id')));

  Future<Prescription> setDispensed(String id, bool dispensed) async =>
      Prescription.fromJson(asMap(await _api.patch('/prescriptions/$id', {'dispensed': dispensed})));
}
