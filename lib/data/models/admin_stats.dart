import 'json_utils.dart';

class StoreStat {
  const StoreStat({
    required this.storeId,
    required this.name,
    required this.city,
    required this.total,
    required this.completed,
    required this.waiting,
  });

  final String storeId;
  final String name;
  final String city;
  final int total;
  final int completed;
  final int waiting;

  factory StoreStat.fromJson(Map<String, dynamic> j) => StoreStat(
        storeId: asString(j['storeId']),
        name: asString(j['name']),
        city: asString(j['city']),
        total: asInt(j['total']),
        completed: asInt(j['completed']),
        waiting: asInt(j['waiting']),
      );
}

class AdminStats {
  const AdminStats({
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.waiting,
    required this.inCall,
    required this.prescriptions,
    required this.avgWaitMin,
    required this.avgCallMin,
    required this.consultationFees,
    required this.doctorsOnline,
    required this.doctorsTotal,
    required this.byStore,
  });

  final int total;
  final int completed;
  final int cancelled;
  final int waiting;
  final int inCall;
  final int prescriptions;
  final double avgWaitMin;
  final double avgCallMin;
  final int consultationFees;
  final int doctorsOnline;
  final int doctorsTotal;
  final List<StoreStat> byStore;

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    final t = asMap(j['today']);
    final stores = j['byStore'];
    return AdminStats(
      total: asInt(t['total']),
      completed: asInt(t['completed']),
      cancelled: asInt(t['cancelled']),
      waiting: asInt(t['waiting']),
      inCall: asInt(t['inCall']),
      prescriptions: asInt(t['prescriptions']),
      avgWaitMin: asDouble(t['avgWaitMin']),
      avgCallMin: asDouble(t['avgCallMin']),
      consultationFees: asInt(t['consultationFees']),
      doctorsOnline: asInt(j['doctorsOnline']),
      doctorsTotal: asInt(j['doctorsTotal']),
      byStore: stores is List ? stores.map((s) => StoreStat.fromJson(asMap(s))).toList() : const [],
    );
  }
}
