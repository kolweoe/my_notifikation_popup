import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/quest.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleAction(response);
}

class NotificationService {
  static const String actionDone = 'done';
  static const String actionSnooze = 'snooze';
  static const int snoozeMinutes = 10;

  static const String channelId = 'remindo_alarm_channel';
  static const String channelName = 'Remindo Alarm';

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static NotificationDetails _details({String? soundPath}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifikasi quest dan pengingat harian Remindo',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        sound: soundPath != null
            ? UriAndroidNotificationSound(soundPath)
            : null,
        actions: const [
          AndroidNotificationAction(
            actionDone,
            'Selesai',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionSnooze,
            'Tunda 10 menit',
            showsUserInterface: true,
          ),
        ],
      ),
    );
  }

  /// Schedule a quest notification
  static Future<void> scheduleQuest(Quest quest) async {
    if (quest.id == null || quest.isCompleted || !quest.isAlarmEnabled) return;

    final scheduledDate = tz.TZDateTime.from(quest.dateTime, tz.local);

    // Skip if one-time and already past
    if (quest.repeatType == RepeatType.once &&
        scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    DateTimeComponents? matchComponents;
    if (quest.repeatType == RepeatType.daily) {
      matchComponents = DateTimeComponents.time;
    } else if (quest.repeatType == RepeatType.weekly) {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    await _plugin.zonedSchedule(
      quest.id!,
      quest.title,
      quest.note.isEmpty ? 'Waktunya mengerjakan quest!' : quest.note,
      scheduledDate,
      _details(),
      payload: quest.id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> snooze(int id, String title) async {
    final snoozeTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: snoozeMinutes));

    await _plugin.zonedSchedule(
      id,
      title,
      'Ditunda $snoozeMinutes menit',
      snoozeTime,
      _details(),
      payload: id.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> handleAction(NotificationResponse response) async {
    final id = response.id;
    if (id == null) return;

    if (response.actionId == actionDone) {
      await cancel(id);
      // Note: completeQuest should be called from UI layer with full Quest object
    } else if (response.actionId == actionSnooze) {
      await snooze(id, response.payload ?? 'Quest');
    }
  }
}
