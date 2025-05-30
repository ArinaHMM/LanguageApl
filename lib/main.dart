import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/AuthPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/SplashScreen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:permission_handler/permission_handler.dart';

import 'Themes/theme.dart';
import 'database/auth/model.dart'; // Ваша UserModel
import 'database/auth/service.dart';
import 'database/collections/notification_service.dart';
import 'providers/user_provider.dart';
import 'routes/routes.dart';

// Импорты страниц для AuthWrapper
import 'package:flutter_languageapplicationmycourse_2/pages/LearnPage.dart'; // Главный экран после входа

// Убедитесь, что firebase_options.dart существует, ЕСЛИ вы используете DefaultFirebaseOptions.currentPlatform
// Если нет, то явное указание FirebaseOptions, как ниже, является правильным.
// import 'firebase_options.dart'; // Закомментировано, так как вы предоставляете опции явно

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('main: WidgetsFlutterBinding.ensureInitialized() called.');

  // --- ИСПОЛЬЗУЕМ ВАШИ ЯВНЫЕ FIREBASE OPTIONS ---
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDg6WHmxqIAYKI_asV9lboLhxPEZD2WfnM', // Убедитесь, что ключ актуален
      appId: '1:343134865969:android:6a3d07a714fcb87c0de310',
      messagingSenderId: '343134865969',
      projectId: 'languageapl',
      storageBucket: 'languageapl.appspot.com',
      // Добавьте другие необходимые параметры, если они есть (например, authDomain, databaseURL для Realtime Database)
    ),
  );
  debugPrint('main: Firebase.initializeApp() with explicit options complete.');
  // --------------------------------------------------

  await requestNotificationPermissions();
  debugPrint('main: requestNotificationPermissions() complete.');

  // Опционально: инициализация и планирование уведомлений
  // await NotificationService.init();
  // await NotificationService.showPeriodicNotification();

  runApp(const MyAppRoot());
  debugPrint('main: runApp() complete.');
}

Future<void> requestNotificationPermissions() async {
  debugPrint('Requesting notification permissions...');
  PermissionStatus notificationStatus = await Permission.notification.status;
  debugPrint('Initial Notification permission status: $notificationStatus');
  if (!notificationStatus.isGranted) {
    notificationStatus = await Permission.notification.request();
    debugPrint('Notification permission status after request: $notificationStatus');
  }

  PermissionStatus exactAlarmStatus = await Permission.scheduleExactAlarm.status;
  debugPrint('Initial scheduleExactAlarm permission status: $exactAlarmStatus');
  if (!exactAlarmStatus.isGranted) {
    exactAlarmStatus = await Permission.scheduleExactAlarm.request();
    debugPrint('scheduleExactAlarm permission status after request: $exactAlarmStatus');
  }
  debugPrint('Notification permissions request finished.');
}

class MyAppRoot extends StatelessWidget {
  const MyAppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<fb_auth.User?>.value(
          value: fb_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: fb_auth.FirebaseAuth.instance.currentUser,
          catchError: (_, error) {
            debugPrint("Error in fb_auth.User? StreamProvider: $error");
            return null;
          },
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LingoQuest',
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: routes,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb_auth.User?>(
      stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("AuthWrapper (StreamBuilder): Auth state is WAITING. Showing SplashScreen.");
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          debugPrint("AuthWrapper (StreamBuilder): Error in authStateChanges stream: ${snapshot.error}. Showing AuthPage as fallback.");
          return const AuthPage();
        }

        final fb_auth.User? firebaseUser = snapshot.data;

        if (firebaseUser != null) {
          debugPrint("AuthWrapper (StreamBuilder): User is LOGGED IN (UID: ${firebaseUser.uid}). Showing LearnPage.");
          return const LearnPage(); // ЗАМЕНИТЕ LearnPage() на ваш главный экран
        } else {
          debugPrint("AuthWrapper (StreamBuilder): User is NOT logged in. Showing AuthPage.");
          return const AuthPage();
        }
      },
    );
  }
}