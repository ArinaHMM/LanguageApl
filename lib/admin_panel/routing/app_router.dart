// lib/admin_panel/routing/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';

// Модели и коллекции
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';

// Сервис аутентификации
import '../auth/admin_auth_service.dart';

// lib/admin_panel/routing/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_addUserPage.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_managecontentpage.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_users.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/lessons_management/admin_manage_lessons_page.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/support_panel/SupportChatPage.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/support_panel/SupportDashBoard.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/support_panel/SupportLayout.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart'; // Для UserRoles
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart'; // Для UsersCollection

// Импорты страниц Админки
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_login_page.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/dashboard/admin_dashboard_page.dart';
import 'package:flutter_languageapplicationmycourse_2/admin_panel/layout/admin_layout.dart';
// ------------------------------------

// Импорты ваших страниц добавления уроков (если они используются в админке)
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/add_audio.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/add_exercise_page.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/learn_module.dart';

import '../auth/admin_auth_service.dart'; // Ваш AdminAuthService
import 'package:go_router/go_router.dart';
// Ключи навигаторов
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'AppRoot');
final GlobalKey<NavigatorState> _shellNavigatorKeyAdmin = GlobalKey<NavigatorState>(debugLabel: 'AdminShell');
final GlobalKey<NavigatorState> _shellNavigatorKeySupport = GlobalKey<NavigatorState>(debugLabel: 'SupportShell');

// Классы для РОУТОВ и ИМЕН РОУТОВ
class AdminRoutes {
  static const String login = '/login';
  static const String dashboard = '/admin/dashboard';
  static const String addInteractiveLesson = '/admin/lessons/interactive/add';
  static const String addAudioWordBankLesson = '/admin/lessons/audio/add';
  static const String manageLessons = '/admin/manage-lessons';
  static const String manageUsers = '/admin/users/manage';
  static const String addUser = '/admin/users/add';
  static const String addContent = '/admin/content/add';
  static const String manageContent = '/admin/content/manage';
}

class AdminRouteNames {
  static const String login = 'login'; // Имя для страницы входа
  static const String dashboard = 'admin-dashboard';
  static const String addInteractiveLesson = 'admin-add-interactive-lesson';
  static const String addAudioWordBankLesson = 'admin-add-audio-word-bank-lesson';
  static const String manageLessons = 'admin-manage-lessons';
  static const String manageUsers = 'admin-manage-users';
  static const String addUser = 'admin-add-user';
  static const String addContent = 'admin-add-content';
  static const String manageContent = 'admin-manage-content';
}

class SupportRoutes {
  static const String dashboard = '/support/dashboard';
  static const String chatWithUserBase = '/support/chat'; // Базовый путь для чатов
  static String chatWithUser(String userId) => '$chatWithUserBase/$userId'; // Путь с параметром
}

class SupportRouteNames {
  static const String dashboard = 'support-dashboard';
  static const String chatWithUser = 'support-chat-user';
}

// ПРИМЕР: Маршруты для обычных пользователей (если они не используют GoRouter)
// Если пользовательская часть приложения использует свою систему навигации, этот класс не нужен здесь.
// Если и пользовательская часть использует этот же GoRouter, то определите ее пути здесь.
class UserAppRoutes {
  static const String learn = '/learn'; // ЗАМЕНИТЕ НА АКТУАЛЬНЫЙ ГЛАВНЫЙ ПУТЬ ПОЛЬЗОВАТЕЛЯ
  // static const String profile = '/profile';
  // ... и т.д.
}
class UserAppRouteNames {
  static const String learn = 'user-learn';
  // static const String profile = 'user-profile';
}


class AppRouter {
  static final AdminAuthService _authService = AdminAuthService();
  static final UsersCollection _usersCollection = UsersCollection();

  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AdminRoutes.login, // Всегда начинаем с логина, redirect разберется
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      // --- ОБЩАЯ СТРАНИЦА ВХОДА ---
      GoRoute(
        path: AdminRoutes.login,
        name: AdminRouteNames.login,
        builder: (context, state) => const AdminLoginPage(),
      ),

      // --- ПРИМЕР: ГЛАВНЫЙ МАРШРУТ ДЛЯ ОБЫЧНЫХ ПОЛЬЗОВАТЕЛЕЙ ---
      // Этот маршрут должен быть определен, если ваш redirect будет на него ссылаться
      // Убедитесь, что YourLearnPage существует и импортирована
      // GoRoute(
      //   path: UserAppRoutes.learn,
      //   name: UserAppRouteNames.learn,
      //   builder: (context, state) => const LearnPage(), // Замените LearnPage на вашу страницу
      // ),
      // ---------------------------------------------------------

      // ShellRoute для Админки
      ShellRoute(
        navigatorKey: _shellNavigatorKeyAdmin,
        builder: (context, state, child) => AdminLayout(child: child),
        routes: <RouteBase>[
          GoRoute(path: AdminRoutes.dashboard, name: AdminRouteNames.dashboard, builder: (context, state) => const AdminDashboardPage()),
          GoRoute(path: AdminRoutes.addInteractiveLesson, name: AdminRouteNames.addInteractiveLesson, builder: (context, state) => const AdminAddInteractiveLessonPage()),
          GoRoute(path: AdminRoutes.addAudioWordBankLesson, name: AdminRouteNames.addAudioWordBankLesson, builder: (context, state) => const AdminAddAudioWordBankLessonPage()),
          GoRoute(path: AdminRoutes.manageLessons, name: AdminRouteNames.manageLessons, builder: (context, state) => const AdminManageLessonsPage()),
          GoRoute(path: AdminRoutes.manageUsers, name: AdminRouteNames.manageUsers, builder: (context, state) => const AdminManageUsersPage()),
          GoRoute(path: AdminRoutes.addUser, name: AdminRouteNames.addUser, builder: (context, state) => const AdminAddUserPage()),
          GoRoute(path: AdminRoutes.addContent, name: AdminRouteNames.addContent, builder: (context, state) => const AdminAddContentPage()),
          GoRoute(path: AdminRoutes.manageContent, name: AdminRouteNames.manageContent, builder: (context, state) => const AdminManageContentPage()),
        ],
      ),

      // ShellRoute для Поддержки
      ShellRoute(
        navigatorKey: _shellNavigatorKeySupport,
        builder: (context, state, child) => SupportLayout(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: SupportRoutes.dashboard,
            name: SupportRouteNames.dashboard,
            builder: (context, state) => const SupportDashboardPage(),
          ),
          GoRoute(
            path: '${SupportRoutes.chatWithUserBase}/:userId', // Пример: /support/chat/someUserId
            name: SupportRouteNames.chatWithUser,
            builder: (context, state) {
              final userId = state.pathParameters['userId'];
              final userEmail = (state.extra as Map<String, dynamic>?)?['userEmail'] as String?;
              if (userId == null) {
                return const Center(child: Text("Ошибка: ID пользователя не найден для чата"));
              }
              return SupportChatPage(userId: userId, userEmail: userEmail);
            },
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      final bool loggedIn = _authService.currentUser != null;
      UserModel? userModel;
      String? userRole;

      if (loggedIn) {
        try {
            userModel = await _usersCollection.getUserModel(_authService.currentUser!.uid);
            userRole = userModel?.role;
        } catch (e) {
            print("Error fetching userModel in redirect for UID ${_authService.currentUser!.uid}: $e");
            // Если не удалось получить userModel, это проблема, разлогиниваем
            await _authService.signOut();
            // После signOut, loggedIn станет false в следующем цикле redirect
            // и пользователь будет перенаправлен на логин.
            // Не возвращаем путь здесь, чтобы избежать двойного редиректа в одном цикле.
            // GoRouterRefreshStream обработает изменение authStateChanges.
            return AdminRoutes.login; // Явное указание на логин
        }
      }

      final String currentLocation = state.matchedLocation; // Или state.uri.toString() для полного URI
      final bool onLoginPage = currentLocation == AdminRoutes.login;

      print("[GoRouter Redirect] LoggedIn: $loggedIn, Role: $userRole, Location: $currentLocation, OnLoginPage: $onLoginPage");

      if (!loggedIn) {
        if (onLoginPage) {
          print("[GoRouter Redirect] Not logged in, already on login page. No redirect.");
          return null;
        }
        // Если пользователь не аутентифицирован и не на странице логина,
        // всегда перенаправляем на страницу входа.
        print("[GoRouter Redirect] Not logged in, redirecting to ${AdminRoutes.login} from $currentLocation");
        return AdminRoutes.login;
      }

      // Пользователь аутентифицирован (loggedIn == true)
      if (userModel == null && loggedIn) {
        // Этого не должно произойти, если try-catch выше отработал,
        // но на всякий случай - если залогинен, но модель не загрузилась
        print("[GoRouter Redirect] Logged in but userModel is null. Forcing sign out.");
        await _authService.signOut();
        return AdminRoutes.login; // После signOut, попадет в !loggedIn и на логин
      }
      
      // Если пользователь залогинен и находится на странице логина
      if (onLoginPage) {
        if (userRole == UserRoles.admin) {
          print("[GoRouter Redirect] Logged in as ADMIN on login page, redirecting to ${AdminRoutes.dashboard}");
          return AdminRoutes.dashboard;
        }
        if (userRole == UserRoles.support) {
          print("[GoRouter Redirect] Logged in as SUPPORT on login page, redirecting to ${SupportRoutes.dashboard}");
          return SupportRoutes.dashboard;
        }
        // Если это обычный пользователь (UserRoles.user) на странице входа админки/поддержки,
        // перенаправляем его на его главный экран.
        if (userRole == UserRoles.user) {
            print("[GoRouter Redirect] Logged in as USER on admin/support login page, redirecting to ${UserAppRoutes.learn}");
            return UserAppRoutes.learn; // ЗАМЕНИТЕ НА ВАШ ГЛАВНЫЙ ПУТЬ ДЛЯ USER
        }
        // Если роль не опознана или что-то пошло не так
        print("[GoRouter Redirect] Logged in with UNKNOWN_ROLE ($userRole) on login page. Signing out.");
        await _authService.signOut();
        return AdminRoutes.login; // После signOut, попадет в !loggedIn и на логин
      }

      // Пользователь аутентифицирован и НЕ на странице логина
      // Проверяем доступ к защищенным секциям
      if (userRole == UserRoles.admin) {
        if (!currentLocation.startsWith('/admin') && !currentLocation.startsWith(UserAppRoutes.learn) /* Исключаем пользовательские пути, если админ может их посещать */) {
            // Если админ не на админском пути и не на пользовательском (если ему можно)
            // и не на пути поддержки (если ему туда тоже можно)
            // можно считать это "блужданием" и вернуть на дашборд админа
            // Но если /support/ для админа разрешен, то это условие нужно изменить
           if (currentLocation.startsWith('/support')) { // Админ на странице поддержки
               print("[GoRouter Redirect] ADMIN ($userRole) on SUPPORT path ($currentLocation). Allowing.");
               return null;
           }
            print("[GoRouter Redirect] ADMIN ($userRole) on unexpected non-admin/non-user path ($currentLocation). Redirecting to ${AdminRoutes.dashboard}.");
            return AdminRoutes.dashboard;
        }
      } else if (userRole == UserRoles.support) {
        if (currentLocation.startsWith('/admin')) {
          print("[GoRouter Redirect] SUPPORT ($userRole) trying admin path. Redirecting to ${SupportRoutes.dashboard}.");
          return SupportRoutes.dashboard;
        }
        if (!currentLocation.startsWith('/support') && !currentLocation.startsWith(UserAppRoutes.learn)) {
           if (currentLocation.startsWith('/admin')) { // Уже обработано выше, но для ясности
               print("[GoRouter Redirect] SUPPORT ($userRole) on admin path ($currentLocation). Redirecting to ${SupportRoutes.dashboard}.");
               return SupportRoutes.dashboard;
           }
            print("[GoRouter Redirect] SUPPORT ($userRole) on unexpected non-support/non-user path ($currentLocation). Redirecting to ${SupportRoutes.dashboard}.");
            return SupportRoutes.dashboard;
        }
      } else if (userRole == UserRoles.user) {
        if (currentLocation.startsWith('/admin') || currentLocation.startsWith('/support')) {
          print("[GoRouter Redirect] USER ($userRole) trying admin/support path. Redirecting to ${UserAppRoutes.learn}.");
          return UserAppRoutes.learn;
        }
        // Если пользователь на '/', но его домашняя страница '/learn'
        if (currentLocation == '/' && UserAppRoutes.learn != '/') {
             print("[GoRouter Redirect] USER ($userRole) on root path. Redirecting to ${UserAppRoutes.learn}.");
             return UserAppRoutes.learn;
        }
      } else {
        // Неизвестная роль или userModel был null, но loggedIn был true (обработано выше try-catch)
        // Этот блок может быть достигнут, если userModel.role равен null или не соответствует ни одной из известных ролей
        print("[GoRouter Redirect] Logged in, but role is UNKNOWN ($userRole) or userModel issue. Path: $currentLocation. Signing out.");
        await _authService.signOut();
        return AdminRoutes.login;
      }
      
      print("[GoRouter Redirect] End of checks for ($currentLocation). Role: $userRole. No redirect needed.");
      return null; // Нет редиректа, если все проверки пройдены
    },
    refreshListenable: GoRouterRefreshStream(_authService.authStateChanges),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // Первоначальное уведомление
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
      print("GoRouterRefreshStream: Auth state changed, notifying listeners.");
      notifyListeners();
    });
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}