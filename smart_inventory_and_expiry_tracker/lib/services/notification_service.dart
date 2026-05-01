import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/inventory_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback if timezone detection fails
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermissions() async {
    // Android 13+ (API level 33+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  /// Reschedules all notifications for a list of items.
  /// Useful for syncing notifications when the app starts.
  Future<void> rescheduleAllNotifications(List<InventoryItem> items) async {
    await flutterLocalNotificationsPlugin.cancelAll();
    for (final item in items) {
      await scheduleExpiryNotifications(item);
    }
  }

  Future<void> scheduleExpiryNotifications(InventoryItem item) async {
    // We schedule notifications at 09:00 in the morning
    const notificationHour = 9;

    // 1. Almost Expired (3 days before)
    final almostExpiredDate = item.expiryDate.subtract(const Duration(days: 3));
    final scheduledAlmost = DateTime(
      almostExpiredDate.year,
      almostExpiredDate.month,
      almostExpiredDate.day,
      notificationHour,
    );
    
    if (scheduledAlmost.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: item.id.hashCode,
        title: 'Product bijna over datum!',
        body: '${item.title} vervalt over 3 days (${item.expiryDate.toLocal().toString().split(' ')[0]}).',
        scheduledDate: scheduledAlmost,
      );
    }

    // 2. Expired (on the day itself)
    final scheduledExpired = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
      notificationHour,
    );

    if (scheduledExpired.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: (item.id + '_expired').hashCode,
        title: 'Product over datum!',
        body: '${item.title} is vandaag vervallen.',
        scheduledDate: scheduledExpired,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'expiry_channel',
      'Vervaldatums',
      channelDescription: 'Meldingen wanneer producten bijna of over datum zijn',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotifications(String itemId) async {
    await flutterLocalNotificationsPlugin.cancel(id: itemId.hashCode);
    await flutterLocalNotificationsPlugin.cancel(id: (itemId + '_expired').hashCode);
  }
}
