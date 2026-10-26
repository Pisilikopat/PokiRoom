// lib/core/utils/date_format.dart
import 'time_format.dart';

const _months = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

/// "26 Eki 2026 · 14:32" (hatıra damgası)
String formatStamp(DateTime t) {
  final l = t.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year} · ${formatClock(l)}';
}
