import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/pages/user/login_page.dart';

void main() {
  testWidgets('login page shows participant and organizer entry points',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(
      find.textContaining('Penyelenggara', findRichText: true),
      findsOneWidget,
    );
  });
}
