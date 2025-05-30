// lib/main_admin.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Для StreamBuilder
import 'firebase_options.dart';
import 'admin_panel/routing/app_router.dart'; // Импортируем наш роутер
// Заглушки или реальные импорты для страниц, если они не вызываются только через GoRouter
// import 'admin_panel/auth/admin_login_page.dart';
// import 'admin_panel/dashboard/admin_dashboard_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AdminAppRoot()); // Изменили на AdminAppRoot для интеграции GoRouter
}

class AdminAppRoot extends StatelessWidget {
  const AdminAppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Используем routerConfig из GoRouter
    return MaterialApp.router(
      title: 'LingoQuest Панель Сотрудников',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange, // Немного изменил цвет для примера
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepOrange,
          accentColor: Colors.amber, // Добавил accentColor
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Здесь можно определить более детальную тему для админки
        // Например, стили для AppBar, кнопок, карточек и т.д.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange, // Цвет AppBar
          foregroundColor: Colors.white,      // Цвет текста и иконок в AppBar
          elevation: 4.0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrangeAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
           style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.deepOrange),
            foregroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 2.0),
          ),
          labelStyle: const TextStyle(color: Colors.deepOrange),
        ),
        // Можно добавить стили для NavigationRail, Drawer и т.д.
      ),
      routerConfig: AppRouter.router, // Передаем конфигурацию роутера
      debugShowCheckedModeBanner: false,
    );
  }
}

// Старый AdminApp и AdminHomePage теперь не нужны здесь,
// так как GoRouter будет управлять тем, что отображается.
// AdminHomePage (или AdminDashboardPage) будет вызываться через GoRouter,
// а AuthWrapper (если вы его использовали ранее для простого MaterialApp.home)
// теперь не нужен, так как логика редиректа встроена в GoRouter.

// ----- Важно: -----
// Убедитесь, что в файле lib/admin_panel/routing/app_router.dart:
// 1. Правильно импортированы все страницы (AdminLoginPage, AdminDashboardPage,
//    AdminAddInteractiveLessonPage, AdminAddAudioWordBankLessonPage, AdminLayout).
// 2. В GoRouter определены маршруты для этих страниц.
// 3. Логика redirect в GoRouter корректно обрабатывает состояние аутентификации
//    и проверку роли администратора (через AdminAuthService.isAdmin).
// 4. ShellRoute настроен для использования AdminLayout, если вы хотите общий Scaffold.