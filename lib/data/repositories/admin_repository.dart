import '../../core/network/api_client.dart';
import '../models/admin_stats.dart';
import '../models/json_utils.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<AdminStats> stats() async => AdminStats.fromJson(asMap(await _api.get('/admin/stats')));

  Future<void> resetDemoData() async {
    await _api.post('/admin/reset');
  }

  Future<void> addDoctor(Map<String, dynamic> doctor) async {
    await _api.post('/doctors', doctor);
  }

  Future<void> addStore(Map<String, dynamic> store) async {
    await _api.post('/stores', store);
  }
}
