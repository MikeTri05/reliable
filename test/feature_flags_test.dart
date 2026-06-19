import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/core/constants/feature_flags.dart';

void main() {
  test('user delete feature flag is disabled by default', () {
    expect(enableUserDelete, isFalse);
  });
}
