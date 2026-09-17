import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

bool _dateFormattingReady = false;

/// Loads the French date symbols once.
///
/// `intl` throws a `LocaleDataException` when a `DateFormat` is built for a
/// locale whose data was never initialized. The app formats deadlines with the
/// `fr` locale everywhere, so this runs during startup — before any page can
/// render.
Future<void> ensureDateFormatting() async {
  if (_dateFormattingReady) return;
  await initializeDateFormatting('fr');
  _dateFormattingReady = true;
}

String money(double value) =>
    NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);

/// Compact representation for large amounts, e.g. `18,5 k $`.
String compactMoney(double value) {
  final absolute = value.abs();
  if (absolute >= 1000000) return '${_trim(value / 1000000)} M \$';
  if (absolute >= 1000) return '${_trim(value / 1000)} k \$';
  return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
}

String _trim(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.toInt()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
}

/// Short relative label for a message: `14:32` today, `Hier`, `il y a 3 j`,
/// then a `12/09` date beyond a week.
String clockLabel(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (diff == 1) return 'Hier';
  if (diff < 7) return 'il y a $diff j';
  return DateFormat('dd/MM').format(time);
}

/// Two-letter initials suitable for avatars.
String initials(String name) {
  final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

/// Short French date used in the hero and project cards, e.g. `3 nov. 2026`.
String formatDate(DateTime value) => DateFormat('d MMM y', 'fr').format(value);

/// Relative urgency of a deadline, e.g. `dans 48 j` or `en retard de 12 j`.
String deadlineHint(DateTime value) {
  final days = value.difference(DateTime.now()).inDays;
  if (days == 0) return 'aujourd’hui';
  if (days > 0) return 'dans $days j';
  return 'dépassée de ${days.abs()} j';
}
