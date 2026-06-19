import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'event_utils.dart';

/// Layanan notifikasi lokal untuk menjadwalkan pengingat acara H-1.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'event_reminder_channel',
    'Pengingat Acara Donor',
    channelDescription:
        'Pengingat acara donor darah H-1 sesuai jam pelaksanaan.',
    importance: Importance.max,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;

    ensureWibTimeZoneInitialized();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_red_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Jadwalkan pengingat H-1 pada jam pelaksanaan acara.
  /// Mengembalikan true jika notifikasi berhasil dijadwalkan.
  static Future<bool> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required String eventDate,
    String? eventTime,
  }) async {
    await init();

    final scheduledDateTime = reminderDateTimeFromEventDate(
      eventDate,
      eventTime: eventTime,
    );
    final location = getWibLocation();
    if (scheduledDateTime == null || location == null) return false;

    final scheduled = tz.TZDateTime.from(scheduledDateTime, location);
    if (scheduled.isBefore(tz.TZDateTime.now(location))) {
      return false;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return true;
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: _androidDetails),
    );
  }
}
