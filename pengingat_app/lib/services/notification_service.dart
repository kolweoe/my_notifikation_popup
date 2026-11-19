import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

/// Dipanggil saat tombol aksi ditekan ketika aplikasi ditutup.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse r) {
  NotificationService.handleAction(r);
}

class NotificationService {
  static const actionDone = 'done';
  static const actionSnooze = 'snooze';
  static const snoozeMenit = 10;

  static Future<void> _initTz() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  }

  static Future<void> init() async {
    await _initTz();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> requestPermissions() async {
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
  }

  static NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          'pengingat_channel',
          'Pengingat',
          channelDescription: 'Notifikasi pengingat tugas dan jadwal',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
          actions: const [
            AndroidNotificationAction(actionDone, 'Selesai'),
            AndroidNotificationAction(actionSnooze, 'Tunda 10 mnt'),
          ],
        ),
      );

  static Future<void> schedule(Reminder r) async {
    if (r.id == null || r.done) return;
    final when = tz.TZDateTime.from(r.dateTime, tz.local);
    DateTimeComponents? match;
    if (r.repeat == Repeat.daily) match = DateTimeComponents.time;
    if (r.repeat == Repeat.weekly) match = DateTimeComponents.dayOfWeekAndTime;
    if (match == null && when.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      r.id!,
      r.title,
      r.note.isEmpty ? r.category : r.note,
      when,
      _details(),
      payload: r.title,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> handleAction(NotificationResponse r) async {
    final id = r.id;
    if (id == null) return;
    if (r.actionId == actionDone) {
      await _plugin.cancel(id);
    } else if (r.actionId == actionSnooze) {
      await _initTz();
      final at = tz.TZDateTime.now(tz.local)
          .add(const Duration(minutes: snoozeMenit));
      await _plugin.zonedSchedule(
        id,
        r.payload ?? 'Pengingat',
        'Ditunda $snoozeMenit menit',
        at,
        _details(),
        payload: r.payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
