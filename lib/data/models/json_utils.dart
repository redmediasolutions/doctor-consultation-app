/// Small helpers so the model `fromJson` constructors stay tolerant of missing fields.
String asString(dynamic v, [String fallback = '']) => v is String ? v : (v == null ? fallback : v.toString());

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? asDate(dynamic v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

List<String> asStringList(dynamic v) => v is List ? v.map((e) => asString(e)).toList() : <String>[];

Map<String, dynamic> asMap(dynamic v) => v is Map<String, dynamic> ? v : <String, dynamic>{};

Map<String, dynamic>? asMapOrNull(dynamic v) => v is Map<String, dynamic> ? v : null;
