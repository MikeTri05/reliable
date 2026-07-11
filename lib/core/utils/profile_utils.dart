const List<String> bloodTypeOptions = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

String normalizeEmail(String value) => value.trim().toLowerCase();

bool isSoftDeletedUser(Map<String, dynamic>? data) {
  if (data == null) return false;

  final status = (data['status'] ?? '').toString().toLowerCase();
  return data['isDeleted'] == true ||
      status == 'dihapus' ||
      status == 'deleted';
}

String normalizeBloodType(String? value) {
  final raw = value?.trim().toUpperCase() ?? '';

  if (bloodTypeOptions.contains(raw)) {
    return raw;
  }

  if (['A', 'B', 'AB', 'O'].contains(raw)) {
    return '$raw+';
  }

  return bloodTypeOptions.first;
}
