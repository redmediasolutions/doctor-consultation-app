import '../../core/network/api_client.dart';
import '../models/doctor.dart';
import '../models/json_utils.dart';
import '../models/store.dart';

/// Stores and doctors.
class DirectoryRepository {
  DirectoryRepository(this._api);

  final ApiClient _api;

  Future<List<Store>> stores() async {
    final list = await _api.get('/stores') as List;
    return list.map((e) => Store.fromJson(asMap(e))).toList();
  }

  Future<List<Doctor>> doctors() async {
    final list = await _api.get('/doctors') as List;
    return list.map((e) => Doctor.fromJson(asMap(e))).toList();
  }

  /// Doctor app presence ping: "online" | "busy" | "offline".
  Future<Doctor> heartbeat(String status) async {
    final res = await _api.post('/doctors/heartbeat', {'status': status});
    return Doctor.fromJson(asMap(res));
  }
}
