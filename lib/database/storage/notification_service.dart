// lib/database/collections/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // Для debugPrint
// Для timezone, если будете использовать zonedSchedule для чего-то другого
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'study_reminders_channel';
  static const String _channelName = 'Напоминания о занятиях';
  static const String _channelDescription = 'Периодические напоминания для занятий';

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint('Уведомление с ID $id отменено.');
  }

  static Future<void> init() async {
    // tz.initializeTimeZones(); // Нужно только если используете zonedSchedule с tz.TZDateTime

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Убедитесь, что иконка есть!

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            // Запрос разрешений для iOS, если нужно
            // requestAlertPermission: true,
            // requestBadgePermission: true,
            // requestSoundPermission: true,
            );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS, // Добавим для полноты
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Уведомление нажато (приложение активно): ${details.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createNotificationChannel();
    // Запрос разрешений перенесен в main.dart в функцию requestNotificationPermissions
  }

  static Future<void> _createNotificationChannel() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('Канал уведомлений "$_channelName" создан/обновлен.');
    }
  }

  // Возвращаем имя метода, который используется в main.dart
  static Future<void> showPeriodicNotification() async {
    // Отменяем предыдущее периодическое уведомление с этим ID, чтобы не дублировать
    await _notificationsPlugin.cancel(100); // Уникальный ID 100
    debugPrint('Предыдущее периодическое уведомление (ID 100) отменено перед новым планированием.');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    RepeatInterval repeatInterval = RepeatInterval.everyMinute;

    try {
      await _notificationsPlugin.periodicallyShow(
        100,
        'LingoQuest',
        'Пора позаниматься!',
        repeatInterval,
        notificationDetails,
        // Используем exactAllowWhileIdle, так как разрешения запрашиваются
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'periodic_study_reminder_payload',
      );
      debugPrint('Периодические уведомления "Пора позаниматься!" ЗАПЛАНИРОВАНЫ с интервалом: $repeatInterval (режим: exactAllowWhileIdle)');
    } catch (e) {
      debugPrint('Ошибка при планировании периодического уведомления: $e');
    }
  }

  // Тестовое немедленное уведомление (если нужно для отладки с кнопки)
  static Future<void> showTestNotificationNow() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await _notificationsPlugin.show(
      0, // Другой ID
      'LingoQuest!',
      'Пора заниматься! Заходи скорее в приложение и проходи новые уроки ☺',
      notificationDetails,
      payload: 'test_now_payload',
    );
    debugPrint('Показано немедленное тестовое уведомление (ID 0)');
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Уведомление нажато в фоне: ${notificationResponse.payload}');
}