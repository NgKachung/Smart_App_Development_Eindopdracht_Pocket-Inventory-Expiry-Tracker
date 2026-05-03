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
  const notificationHour = 9;
  final nu = DateTime.now();

  // Lijstje met momenten waarop we willen waarschuwen
  final waarschuwingsMomenten = [
    {'dagen': 3, 'titel': 'Product bijna over datum!'},
    {'dagen': 1, 'titel': 'Product vervalt morgen!'}, // Extra check toegevoegd
    {'dagen': 0, 'titel': 'Product over datum!'},
  ];

  for (var moment in waarschuwingsMomenten) {
    final scheduledDate = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
      notificationHour,
    ).subtract(Duration(days: moment['dagen'] as int));

    if (scheduledDate.isAfter(nu)) {
      await _scheduleNotification(
        // We maken het ID uniek per type melding
        id: (item.id + moment['dagen'].toString()).hashCode,
        title: moment['titel'] as String,
        body: moment['dagen'] == 0 
            ? '${item.title} is vandaag vervallen.' 
            : '${item.title} vervalt over ${moment['dagen']} dag(en).',
        scheduledDate: scheduledDate,
      );
    }
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
  // 1. Identify the specific variations we created
  final waarschuwingsDagen = [3, 1, 0];
  
  for (var dagen in waarschuwingsDagen) {
    // 2. Re-calculate the EXACT same ID used during scheduling
    final notificationId = (itemId + dagen.toString()).hashCode;
    
    // 3. Tell the phone: "Delete the alarm with this specific ID"
    await flutterLocalNotificationsPlugin.cancel(id: notificationId);
  }
}
}
