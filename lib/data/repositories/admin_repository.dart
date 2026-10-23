import '../../core/network/api_client.dart';
import '../models/admin_stats.dart';
import '../models/json_utils.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<AdminStats> stats() async => AdminStats.fromJson(asMap(await _api.get('/admin/stats')));

  Future<void> addDoctor(Map<String, dynamic> doctor) async {
    await _api.post('/doctors', doctor);
  }

  /// e.g. {'isActive': false} to stop a doctor signing in.
  Future<void> updateDoctor(String id, Map<String, dynamic> changes) async {
    await _api.patch('/doctors/$id', changes);
  }
}
