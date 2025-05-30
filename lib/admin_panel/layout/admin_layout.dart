// lib/admin_panel/layout/admin_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/admin_auth_service.dart'; // Для выхода
import '../routing/app_router.dart'; // Для AdminRoutes

class AdminLayout extends StatefulWidget {
  final Widget child; // Контент текущей страницы
  const AdminLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final AdminAuthService _authService = AdminAuthService();

  final List<({IconData icon, String label, String route})> _menuItems = [
    (
      icon: Icons.dashboard_rounded,
      label: 'Дашборд',
      route: AdminRoutes.dashboard
    ),
    (
      icon: Icons.add_box_rounded,
      label: 'Добавить инт. урок',
      route: AdminRoutes.addInteractiveLesson
    ),
    (
      icon: Icons.audiotrack_rounded,
      label: 'Добавить аудио урок',
      route: AdminRoutes.addAudioWordBankLesson
    ),
    (
      icon: Icons.book,
      label: 'Главная страница с уроками',
      route: AdminRoutes.manageLessons
    ),
    (
      icon: Icons.edit_document, // Или Icons.article_outlined, Icons.list_alt
      label: 'Управление контентом',
      route: AdminRoutes.manageContent
    ),
    (
      icon: Icons.note_add_rounded,
      label: 'Добавить учебный контент',
      route: AdminRoutes.addContent
    ),
    (
      icon: Icons.man,
      label: 'Пользователи',
      route: AdminRoutes.manageUsers
    )
    
    
  ];

  void _onItemTapped(int index, BuildContext context) {
    if (index < _menuItems.length) {
      context.go(_menuItems[index].route);
    }
  }

  int _calculateSelectedIndex(String currentLocation) {
    final index =
        _menuItems.indexWhere((item) => currentLocation.startsWith(item.route));
    return index != -1 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    final int currentSelectedIndex = _calculateSelectedIndex(currentLocation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LingoQuest Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Админ-панель',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            for (int i = 0; i < _menuItems.length; i++)
              ListTile(
                leading: Icon(_menuItems[i].icon),
                title: Text(_menuItems[i].label),
                selected: currentSelectedIndex == i,
                onTap: () {
                  Navigator.pop(context); // Закрывает Drawer
                  _onItemTapped(i, context); // Навигация
                },
              ),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}
