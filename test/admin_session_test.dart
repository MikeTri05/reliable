import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/core/session/admin_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves admin session without storing password', () async {
    await AdminSession.save(adminDocumentId: 'admin-1');

    expect(await AdminSession.isLoggedIn(), isTrue);
    expect(await AdminSession.getAdminDocumentId(), 'admin-1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('admin_password'), isNull);
    expect(prefs.getString('password'), isNull);
  });

  test('clears admin session', () async {
    await AdminSession.save(adminDocumentId: 'admin-1');

    await AdminSession.clear();

    expect(await AdminSession.isLoggedIn(), isFalse);
    expect(await AdminSession.getAdminDocumentId(), isNull);
  });
}
