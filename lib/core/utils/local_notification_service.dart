import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
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
    channelDescription: 'Pengingat acara donor darah H-1 sebelum pelaksanaan.',
    importance: Importance.max,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Biarkan default UTC jika lokasi tidak tersedia.
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_red_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Jadwalkan pengingat H-1 pukul 08:00 sebelum tanggal pelaksanaan.
  /// Mengembalikan true jika notifikasi berhasil dijadwalkan.
  static Future<bool> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required String eventDate,
  }) async {
    await init();

    final parsed = parseEventDate(eventDate);
    if (parsed == null) return false;

    final reminderDate = parsed.subtract(const Duration(days: 1));
    final scheduled = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      8,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
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
