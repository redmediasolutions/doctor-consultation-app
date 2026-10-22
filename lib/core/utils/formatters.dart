import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _long = DateFormat('EEEE, d MMMM yyyy');
  static final NumberFormat _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String time(DateTime? d) => d == null ? '—' : _time.format(d.toLocal());
  static String date(DateTime? d) => d == null ? '—' : _date.format(d.toLocal());
  static String dateTime(DateTime? d) => d == null ? '—' : '${date(d)}, ${time(d)}';
  static String longDate(DateTime d) => _long.format(d);
  static String inr(num n) => _inr.format(n);

  static String initials(String name) {
    final parts = name
        .replaceFirst(RegExp(r'^Dr\.?\s+', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  static String waitingFor(DateTime? since) {
    if (since == null) return '';
    final s = DateTime.now().difference(since).inSeconds;
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    if (m < 60) return '$m min';
    return '${m ~/ 60}h ${m % 60}m';
  }

  static int minutesBetween(DateTime? a, DateTime? b) {
    if (a == null || b == null) return 0;
    final m = b.difference(a).inMinutes;
    return m < 0 ? 0 : m;
  }

  static String clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// "MedConnect Pharmacy — Kadri" → "Kadri"
  static String shortStore(String? name) {
    if (name == null) return '—';
    final i = name.indexOf('—');
    return i >= 0 ? name.substring(i + 1).trim() : name;
  }
}
