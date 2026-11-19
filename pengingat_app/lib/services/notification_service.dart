import 'package:flutter/foundation.dart';
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

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        // fallback if timezone not found
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      await _plugin.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: handleAction,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static Future<void> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Request permission error: $e');
    }
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
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
        actions: [
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

  /// Schedule a quest notification (crash-safe)
  static Future<bool> scheduleQuest(Quest quest) async {
    if (quest.id == null || quest.isCompleted || !quest.isAlarmEnabled) {
      return false;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(quest.dateTime, tz.local);

      // Skip if one-time and already past
      if (quest.repeatType == RepeatType.once &&
          scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return false;
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
      return true;
    } catch (e) {
      debugPrint('Schedule quest error: $e');
      return false;
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static Future<void> snooze(int id, String title) async {
    try {
      final snoozeTime = tz.TZDateTime.now(tz.local)
          .add(const Duration(minutes: snoozeMinutes));

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
    } catch (e) {
      debugPrint('Snooze error: $e');
    }
  }

  static Future<void> handleAction(NotificationResponse response) async {
    final id = response.id;
    if (id == null) return;

    try {
      if (response.actionId == actionDone) {
        await cancel(id);
      } else if (response.actionId == actionSnooze) {
        await snooze(id, response.payload ?? 'Quest');
      }
    } catch (e) {
      debugPrint('Handle action error: $e');
    }
  }
}
