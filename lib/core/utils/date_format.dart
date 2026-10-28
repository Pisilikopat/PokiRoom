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

const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// "Az önce", "5 dk önce", "2 sa önce", "Dün 14:20", "Cum 09:05", "12 Eki 2026 • 18:30"
String formatRelative(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final l = t.toLocal();
  final diff = n.difference(l);
  if (diff.inSeconds < 45) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';

  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(l.year, l.month, l.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return '${diff.inHours} sa önce';
  if (days == 1) return 'Dün ${formatClock(l)}';
  if (days < 7) return '${_weekdays[l.weekday - 1]} ${formatClock(l)}';
  return formatStamp(l);
}
