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

  test('detects deleted events from flag or status', () {
    expect(isEventDeleted({'isDeleted': true}), isTrue);
    expect(isEventDeleted({'status': 'Dihapus'}), isTrue);
    expect(isEventDeleted({'statusAcara': 'deleted'}), isTrue);
    expect(isEventDeleted({'status': 'Aktif'}), isFalse);
  });

  test('builds WIB reminder H-1 using event time', () {
    final reminder = reminderDateTimeFromEventDate(
      '20-06-2026',
      eventTime: '23:00',
    );

    expect(reminder, isNotNull);
    expect(reminder!.year, 2026);
    expect(reminder.month, 6);
    expect(reminder.day, 19);
    expect(reminder.hour, 23);
    expect(reminder.minute, 0);
    expect(formatWibDateTime(reminder), '19 Jun 2026, 23:00 WIB');
  });

  test('builds H-1 reminder five minutes after reference time', () {
    final reminder = reminderDateTimeFromEventDate(
      '21-06-2026',
      eventTime: '13:35',
    );
    final reference = DateTime(2026, 6, 20, 13, 30);

    expect(reminder, isNotNull);
    expect(formatWibDateTime(reminder!), '20 Jun 2026, 13:35 WIB');
    expect(reminder.difference(reference), const Duration(minutes: 5));
  });
  test('formats UTC timestamp into WIB text', () {
    final utcValue = DateTime.utc(2026, 6, 18, 1);

    expect(formatWibDateTime(utcValue), '18 Jun 2026, 08:00 WIB');
  });

  test('skips future reminder inbox notifications for Android popup', () {
    final reference = DateTime(2026, 6, 18, 10);

    expect(
      shouldShowInboxNotificationNow(
        {
          'tipe': 'pengingat_acara',
          'waktu': DateTime(2026, 6, 19, 23),
          'dibaca': false,
        },
        reference: reference,
      ),
      isFalse,
    );

    expect(
      shouldShowInboxNotificationNow(
        {
          'tipe': 'pengingat_acara',
          'waktu': DateTime(2026, 6, 18, 9),
          'dibaca': false,
        },
        reference: reference,
      ),
      isTrue,
    );

    expect(
      shouldShowInboxNotificationNow(
        {
          'tipe': 'donor_selesai',
          'waktu': DateTime(2026, 6, 19, 23),
          'dibaca': false,
        },
        reference: reference,
      ),
      isTrue,
    );
  });
  test('builds reminder button availability state', () {
    expect(
      canRequestEventReminder(
        isLoading: false,
        isCheckingReminder: false,
        isReminderSet: false,
      ),
      isTrue,
    );
    expect(
      canRequestEventReminder(
        isLoading: true,
        isCheckingReminder: false,
        isReminderSet: false,
      ),
      isFalse,
    );
    expect(
      canRequestEventReminder(
        isLoading: false,
        isCheckingReminder: true,
        isReminderSet: false,
      ),
      isFalse,
    );
    expect(
      canRequestEventReminder(
        isLoading: false,
        isCheckingReminder: false,
        isReminderSet: true,
      ),
      isFalse,
    );
    expect(
      reminderButtonText(
        isLoading: false,
        isCheckingReminder: false,
        isReminderSet: true,
      ),
      'Pengingat Aktif',
    );
  });
  test('parses bag counts from stored values', () {
    expect(parseBagCount(2), 2);
    expect(parseBagCount('3 Kantong'), 3);
    expect(formatBagCount(4), '4 Kantong');
  });
}
