import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Service for scheduling local deadline reminders.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'monthly_goals_reminders';
  static const _channelName = 'Deadline Reminders';

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);

    // Create notification channel (Android)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Reminders for upcoming task deadlines',
            importance: Importance.high,
          ),
        );
  }

  /// Schedule a notification at [scheduledDate] with unique [id].
  static Future<void> scheduleDeadlineReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for upcoming task deadlines',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a notification by its [id].
  static Future<void> cancel(int id) => _plugin.cancel(id);

  /// Cancel all notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Schedule both "1 day before" and "on due date" notifications for a task.
  static Future<void> scheduleTaskReminders({
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    // Use hash of taskId for unique int IDs
    final baseId = taskId.hashCode.abs() % 100000;

    // 1 day before
    final dayBefore = deadline.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(DateTime.now())) {
      await scheduleDeadlineReminder(
        id: baseId,
        title: '⏰ Due Tomorrow',
        body: '$taskTitle is due tomorrow.',
        scheduledDate: dayBefore,
      );
    }

    // On the day at 9 AM
    final onDay = DateTime(deadline.year, deadline.month, deadline.day, 9);
    if (onDay.isAfter(DateTime.now())) {
      await scheduleDeadlineReminder(
        id: baseId + 1,
        title: '📅 Due Today',
        body: '$taskTitle is due today!',
        scheduledDate: onDay,
      );
    }
  }
}
