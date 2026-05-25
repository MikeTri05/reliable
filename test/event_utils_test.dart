import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/core/utils/event_utils.dart';

void main() {
  test('parses Indonesian event date format', () {
    expect(parseEventDate('25-05-2026'), DateTime(2026, 5, 25));
    expect(formatEventDate(DateTime(2026, 5, 25)), '25-05-2026');
  });

  test('detects completed events from date time or status', () {
    expect(
      isEventCompleted(
        {
          'tanggalPelaksanaan': '25-05-2026',
          'jamPelaksanaan': '09:00',
        },
        reference: DateTime(2026, 5, 25, 10),
      ),
      isTrue,
    );

    expect(isEventCompleted({'statusAcara': 'Selesai'}), isTrue);
  });

  test('parses bag counts from stored values', () {
    expect(parseBagCount(2), 2);
    expect(parseBagCount('3 Kantong'), 3);
    expect(formatBagCount(4), '4 Kantong');
  });
}
