import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

DateTime? parseEventDate(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;

  final parts = raw.split('-');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return DateTime.tryParse(raw);
}

String formatEventDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day-$month-$year';
}

String formatEventTime(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

var _wibTimeZoneInitialized = false;
tz.Location? _wibLocation;

bool ensureWibTimeZoneInitialized() {
  if (_wibTimeZoneInitialized && _wibLocation != null) return true;

  try {
    tzdata.initializeTimeZones();
    _wibLocation = tz.getLocation('Asia/Jakarta');
    tz.setLocalLocation(_wibLocation!);
    _wibTimeZoneInitialized = true;
    return true;
  } catch (_) {
    _wibLocation = null;
    _wibTimeZoneInitialized = false;
    return false;
  }
}

tz.Location? getWibLocation() {
  return ensureWibTimeZoneInitialized() ? _wibLocation : null;
}

DateTime toWib(DateTime value) {
  final location = getWibLocation();
  if (location == null) return value.toLocal();
  return tz.TZDateTime.from(value, location);
}

String formatWibDateTime(DateTime value) {
  final wib = toWib(value);
  return '${DateFormat('dd MMM yyyy, HH:mm').format(wib)} WIB';
}

DateTime? reminderDateTimeFromEventDate(
  String? eventDate, {
  String? eventTime,
}) {
  final parsed = parseEventDate(eventDate);
  final location = getWibLocation();
  if (parsed == null || location == null) return null;

  var hour = 8;
  var minute = 0;
  final rawTime = eventTime?.trim() ?? '';
  final timeParts = rawTime.split(':');
  if (timeParts.length == 2) {
    final parsedHour = int.tryParse(timeParts[0]);
    final parsedMinute = int.tryParse(timeParts[1]);
    if (parsedHour != null &&
        parsedMinute != null &&
        parsedHour >= 0 &&
        parsedHour <= 23 &&
        parsedMinute >= 0 &&
        parsedMinute <= 59) {
      hour = parsedHour;
      minute = parsedMinute;
    }
  }

  final eventDateTimeWib = tz.TZDateTime(
    location,
    parsed.year,
    parsed.month,
    parsed.day,
    hour,
    minute,
  );
  return eventDateTimeWib.subtract(const Duration(days: 1));
}

DateTime? parseEventDateTime(String? dateValue, String? timeValue) {
  final date = parseEventDate(dateValue);
  if (date == null) return null;

  final rawTime = timeValue?.trim() ?? '';
  final timeParts = rawTime.split(':');
  if (timeParts.length != 2) return date;

  final hour = int.tryParse(timeParts[0]);
  final minute = int.tryParse(timeParts[1]);
  if (hour == null || minute == null) return date;

  return DateTime(date.year, date.month, date.day, hour, minute);
}

bool isEventCompleted(
  Map<String, dynamic> data, {
  DateTime? reference,
}) {
  final status =
      (data['statusAcara'] ?? data['status'] ?? '').toString().toLowerCase();
  if (status == 'selesai' || status == 'completed') {
    return true;
  }

  final eventDateTime = parseEventDateTime(
    data['tanggalPelaksanaan']?.toString(),
    data['jamPelaksanaan']?.toString(),
  );
  if (eventDateTime == null) return false;

  return eventDateTime.isBefore(reference ?? DateTime.now());
}

int parseBagCount(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return 0;

  final match = RegExp(r'\d+').firstMatch(raw);
  if (match == null) return 0;

  return int.tryParse(match.group(0) ?? '') ?? 0;
}

String formatBagCount(int count) {
  return '$count Kantong';
}
