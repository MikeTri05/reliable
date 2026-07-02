import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reliable_emergency_donor/core/utils/local_notification_service.dart';

void main() {
  group('LocalNotificationService', () {
    test('builds stable positive notification ids', () {
      final first =
          LocalNotificationService.stableNotificationId('reminder_event_1');
      final second =
          LocalNotificationService.stableNotificationId('reminder_event_1');
      final different =
          LocalNotificationService.stableNotificationId('reminder_event_2');

      expect(first, second);
      expect(first, isPositive);
      expect(first, isNot(different));
    });

    test('builds consistent inbox notification keys', () {
      expect(
        LocalNotificationService.inboxNotificationKey('reminder_event_1'),
        'inbox_reminder_event_1',
      );
      expect(
        LocalNotificationService.inboxNotificationKey(''),
        'inbox_notification',
      );
    });

    test('builds consistent content keys', () {
      expect(
        LocalNotificationService.notificationContentKey(
          title: ' Pengingat Donor Darah ',
          body: ' Besok ada acara donor. ',
        ),
        LocalNotificationService.notificationContentKey(
          title: 'pengingat donor darah',
          body: 'besok ada acara donor.',
        ),
      );
    });

    test('uses exact alarm mode for event reminders', () {
      expect(
        LocalNotificationService.reminderAndroidScheduleMode,
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });
    test('uses fallback id for blank keys', () {
      expect(LocalNotificationService.stableNotificationId(''), isPositive);
      expect(
        LocalNotificationService.stableNotificationId(''),
        LocalNotificationService.stableNotificationId('notification'),
      );
    });
  });
}
