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
