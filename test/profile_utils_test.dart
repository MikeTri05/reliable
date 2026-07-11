import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/core/utils/profile_utils.dart';

void main() {
  test('normalizes email for duplicate checks', () {
    expect(normalizeEmail(' USER@Example.COM '), 'user@example.com');
  });

  test('normalizes legacy blood type into rhesus-positive option', () {
    expect(normalizeBloodType('A'), 'A+');
    expect(normalizeBloodType('ab-'), 'AB-');
    expect(normalizeBloodType('unknown'), 'A+');
  });

  test('detects soft deleted users', () {
    expect(isSoftDeletedUser({'isDeleted': true}), isTrue);
    expect(isSoftDeletedUser({'status': 'Dihapus'}), isTrue);
    expect(isSoftDeletedUser({'status': 'deleted'}), isTrue);
    expect(isSoftDeletedUser({'status': 'Pending'}), isFalse);
    expect(isSoftDeletedUser(null), isFalse);
  });
}
