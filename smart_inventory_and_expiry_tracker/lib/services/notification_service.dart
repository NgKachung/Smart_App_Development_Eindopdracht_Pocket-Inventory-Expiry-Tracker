import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
  }

  Future<void> scheduleExpiryNotifications(InventoryItem item) async {
    // 1. Bijna over datum (bijv. 3 dagen van tevoren)
    final almostExpiredDate = item.expiryDate.subtract(const Duration(days: 3));
    
    // Voorkom het inplannen van notificaties in het verleden
    if (almostExpiredDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: item.id.hashCode,
        title: 'Product bijna over datum!',
        body: '${item.title} vervalt op ${item.expiryDate.toLocal().toString().split(' ')[0]}.',
        scheduledDate: almostExpiredDate,
      );
    }

    // 2. Over datum (de dag zelf)
    if (item.expiryDate.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: (item.id + '_expired').hashCode,
        title: 'Product over datum!',
        body: '${item.title} is vandaag vervallen.',
        scheduledDate: item.expiryDate,
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
