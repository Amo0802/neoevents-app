import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Define initialization settings for Android and iOS
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          // Navigate to event details or any other action
        }
      },
    );

    // Request notification permissions for iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Schedule a notification for 24 hours before an event
  Future<int> scheduleEventNotification(Event event) async {
    // Create unique ID for the notification based on event ID
    final int notificationId = event.id.hashCode;

    // Calculate the time 24 hours before the event
    final notificationTime = tz.TZDateTime.from(
      event.startDateTime.subtract(const Duration(hours: 24)),
      tz.local,
    );

    // Skip if the notification time is in the past
    if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return notificationId;
    }

    // Configure the notification content
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'event_reminders',
      'Event Reminders',
      channelDescription: 'Notifications for upcoming events',
      importance: Importance.high,
      priority: Priority.high,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Upcoming Event: ${event.name}',
      'Your event starts tomorrow at ${_formatTime(event.startDateTime)}. Get ready!',
      notificationTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Use DateTimeComponents instead of UILocalNotificationDateInterpretation
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'event_${event.id}',
    );

    return notificationId;
  }

  // Cancel a scheduled notification
  Future<void> cancelEventNotification(Event event) async {
    final int notificationId = event.id.hashCode;
    await _notificationsPlugin.cancel(notificationId);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Helper method to format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}