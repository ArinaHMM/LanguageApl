// lib/support_panel/layout/support_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Предполагаем, что AdminAuthService используется и для сотрудников поддержки,
// либо у вас есть аналогичный SupportAuthService.
import 'package:flutter_languageapplicationmycourse_2/admin_panel/auth/admin_auth_service.dart';
// Импортируем определения маршрутов поддержки из app_router.dart
import 'package:flutter_languageapplicationmycourse_2/admin_panel/routing/app_router.dart';

class SupportLayout extends StatefulWidget {
  final Widget child; // Контент текущей страницы поддержки
  const SupportLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<SupportLayout> createState() => _SupportLayoutState();
}

class _SupportLayoutState extends State<SupportLayout> {
  // Используем AdminAuthService. Если у вас есть отдельный сервис для поддержки, замените.
  final AdminAuthService _authService = AdminAuthService();

  // Элементы меню для панели поддержки
  // Вы можете добавить сюда больше элементов по мере роста функционала
  final List<({IconData icon, String label, String route, String name})>
      _menuItems = [
    (
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Активные чаты',
      route: SupportRoutes.dashboard,
      name: SupportRouteNames.dashboard
    ),
    // Пример других возможных пунктов меню:
    // (
    //   icon: Icons.quiz_outlined,
    //   label: 'База знаний (FAQ)',
    //   route: '/support/faq', // Определите этот путь в SupportRoutes
    //   name: 'support-faq'
    // ),
    // (
    //   icon: Icons.bar_chart_rounded,
    //   label: 'Статистика поддержки',
    //   route: '/support/stats', // Определите этот путь в SupportRoutes
    //   name: 'support-stats'
    // ),
  ];

  void _onItemTapped(String routeName, BuildContext context) {
    // Используем context.goNamed для навигации по имени, если имена определены
    // Или context.go(routePath) для навигации по пути
    final route = _menuItems.firstWhere((item) => item.name == routeName,
        orElse: () => _menuItems.first);
    context.go(route.route);
  }

  int _calculateSelectedIndex(GoRouter router) {
    final route =
        router.routerDelegate.currentConfiguration.matches.lastOrNull?.route;
    final String? currentRouteName = route is GoRoute ? route.name : null;
    final String currentLocationPath =
        router.routerDelegate.currentConfiguration.uri.toString();

    if (currentRouteName != null) {
      final index =
          _menuItems.indexWhere((item) => item.name == currentRouteName);
      if (index != -1) return index;
    }
    // Фоллбэк на проверку по пути, если имя не совпало (например, для параметризованных роутов без точного имени в _menuItems)
    final pathIndex = _menuItems
        .indexWhere((item) => currentLocationPath.startsWith(item.route));
    return pathIndex != -1 ? pathIndex : 0;
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final int currentSelectedIndex = _calculateSelectedIndex(router);

    // Для веб-интерфейса можно использовать NavigationRail или более широкое боковое меню,
    // если ширина экрана позволяет. Drawer хорошо подходит для мобильных и узких веб-экранов.
    bool useDrawer = MediaQuery.of(context).size.width < 700; // Примерный порог

    Widget navigationWidget;
    if (useDrawer) {
      navigationWidget = Drawer(/* ... как было ... */);
    } else {
      navigationWidget = NavigationRail(
        selectedIndex: currentSelectedIndex,
        onDestinationSelected: (int index) {
          _onItemTapped(_menuItems[index].name, context);
        },
        labelType: NavigationRailLabelType.all,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 2,
        extended: MediaQuery.of(context).size.width > 950, // Порог для extended
        minExtendedWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Icon(Icons.support_agent_rounded,
              size: 36, color: Colors.blueGrey.shade700),
        ),
        destinations: _menuItems.map((item) {
          return NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.icon),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(item.label),
            ),
          );
        }).toList(),
        selectedIconTheme: IconThemeData(color: Colors.blueGrey.shade800),
        unselectedIconTheme: IconThemeData(color: Colors.blueGrey.shade500),
        selectedLabelTextStyle: TextStyle(
            color: Colors.blueGrey.shade900, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: Colors.blueGrey.shade700),
        // --- ДОБАВЛЯЕМ КНОПКУ ВЫХОДА В TRAILING ---
        trailing: Expanded(
          // Expanded, чтобы кнопка была внизу
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: IconButton(
                icon:
                    Icon(Icons.logout_rounded, color: Colors.blueGrey.shade600),
                tooltip: 'Выйти',
                iconSize: 28,
                onPressed: () async {
                  await _authService.signOut();
                  // GoRouter redirect обработает переход на логин
                },
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: useDrawer
          ? AppBar(
              title: const Text('LingoQuest Поддержка'),
              backgroundColor: Colors.blueGrey.shade800, // Цвет фона AppBar
              foregroundColor: Colors
                  .white, // <--- УСТАНАВЛИВАЕТ ЦВЕТ ДЛЯ ИКОНОК И ТЕКСТА (кроме title)
              iconTheme: const IconThemeData(
                  color: Colors
                      .white), // <--- ЯВНО ДЛЯ ИКОНОК (включая иконку drawer'а)
              actionsIconTheme: const IconThemeData(
                  color: Colors.white), // <--- ЯВНО ДЛЯ ИКОНОК В actions
              actions: [
                IconButton(
                  icon: const Icon(Icons
                      .logout_rounded), // Цвет иконки теперь будет белым из-за actionsIconTheme или foregroundColor
                  tooltip: 'Выйти',
                  onPressed: () async {
                    await _authService.signOut();
                  },
                ),
              ],
            )
          : null,
      drawer: useDrawer ? navigationWidget : null,
      body: Row(
        children: [
          if (!useDrawer) navigationWidget,
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
