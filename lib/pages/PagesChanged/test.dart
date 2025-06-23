// lib/test_notification_page.dart (или ваш путь)
import 'package:flutter/material.dart';
// Убедитесь, что этот путь к вашему NotificationService корректен
import 'package:flutter_languageapplicationmycourse_2/database/storage/notification_service.dart';

class TestNotificationPage extends StatelessWidget {
  const TestNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест Уведомлений'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Перед тестом убедитесь, что:\n1. В системных настройках РАЗРЕШЕНЫ уведомления для этого приложения и канал "Напоминания о занятиях" ВКЛЮЧЕН.\n2. В системных настройках батареи ОТКЛЮЧЕНА оптимизация ("Без ограничений").',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  print('--- КНОПКА: ТЕСТ НЕМЕДЛЕННОГО УВЕДОМЛЕНИЯ ---');
                  // Сначала отменяем предыдущее тестовое уведомление с ID 0, на всякий случай
                  await NotificationService.cancelNotification(0);
                  // В вашем NotificationService метод называется showTestNotification()
                  // Если вы хотите использовать showTestNotificationNow(), переименуйте его в NotificationService
                  // или используйте существующее имя. Сейчас я предполагаю, что вы хотите вызвать showTestNotification().
                  // Если showTestNotificationNow() это тот, что вы хотите, измените вызов ниже.
                  await NotificationService.showTestNotificationNow(); // ИЛИ await NotificationService.showTestNotificationNow();
                  print('--- КНОПКА: Запрос на показ немедленного уведомления отправлен ---');
                },
                // Название кнопки должно соответствовать тому, какой метод вы вызываете
                child: const Text('Показать НЕмедленное Тест-Уведомление (showTestNotification)'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  print('--- КНОПКА: ТЕСТ ПЕРИОДИЧЕСКОГО УВЕДОМЛЕНИЯ ---');
                  // Сначала отменяем все предыдущие периодические уведомления с ID 100
                  await NotificationService.cancelNotification(100);
                  await NotificationService.showPeriodicNotification();
                  print('--- КНОПКА: Запрос на планирование периодического уведомления отправлен. Ждите ~1-2 мин. (для exact) ---');
                },
                child: const Text('Запланировать Периодическое (1 мин, exactAllowWhileIdle)'),
              ),
              const SizedBox(height: 20),
              const Text(
                'После нажатия "Запланировать Периодическое", переведите приложение в фон или заблокируйте экран.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}