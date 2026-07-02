import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'event_utils.dart';

/// Layanan notifikasi lokal untuk menjadwalkan pengingat acara H-1.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final Set<String> _shownImmediateNotificationKeys = <String>{};
  static final Map<String, DateTime> _shownImmediateNotificationContents =
      <String, DateTime>{};
  static const Duration _immediateNotificationDedupeWindow =
      Duration(seconds: 10);
  static const AndroidScheduleMode reminderAndroidScheduleMode =
      AndroidScheduleMode.exactAllowWhileIdle;
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

  static int stableNotificationId(String key) {
    final normalized = key.trim().isEmpty ? 'notification' : key.trim();
    var hash = 0;
    for (final codeUnit in normalized.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  static String inboxNotificationKey(String notificationDocId) {
    final normalized = notificationDocId.trim();
    if (normalized.isEmpty) return 'inbox_notification';
    return 'inbox_$normalized';
  }

  static String notificationContentKey({
    required String title,
    required String body,
  }) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedBody = body.trim().toLowerCase();
    return '$normalizedTitle|$normalizedBody';
  }

  static Future<void> showInboxNotification({
    required String notificationKey,
    required String title,
    required String body,
  }) async {
    final normalizedKey = notificationKey.trim().isEmpty
        ? '${title.trim()}_${body.trim()}'
        : notificationKey.trim();
    if (!_shownImmediateNotificationKeys.add(normalizedKey)) return;

    final safeTitle = title.trim().isEmpty ? 'Notifikasi' : title.trim();
    final safeBody =
        body.trim().isEmpty ? 'Ada pesan baru untuk Anda.' : body.trim();

    final now = DateTime.now();
    _shownImmediateNotificationContents.removeWhere(
      (_, shownAt) =>
          now.difference(shownAt) > _immediateNotificationDedupeWindow,
    );

    final contentKey = notificationContentKey(title: safeTitle, body: safeBody);
    final lastShownAt = _shownImmediateNotificationContents[contentKey];
    if (lastShownAt != null &&
        now.difference(lastShownAt) <= _immediateNotificationDedupeWindow) {
      return;
    }
    _shownImmediateNotificationContents[contentKey] = now;

    await showNow(
      id: stableNotificationId(normalizedKey),
      title: safeTitle,
      body: safeBody,
    );
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

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exactAlarmAllowed = await androidImpl?.requestExactAlarmsPermission();
    if (exactAlarmAllowed == false) return false;

    await _plugin.cancel(id);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: _androidDetails),
        androidScheduleMode: reminderAndroidScheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (_) {
      return false;
    }
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

  static Future<void> cancelNotification(int id) async {
    await init();
    await _plugin.cancel(id);
  }
}
