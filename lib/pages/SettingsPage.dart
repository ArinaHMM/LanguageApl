import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkTheme = false; // Переменная для темы
  bool _notificationsEnabled = true; // Переменная для уведомлений
  int _selectedIndex = 3; // Индекс для вкладки "Настройки"
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserSettings(); // Загрузка настроек пользователя при инициализации
  }

  Future<void> _loadUserSettings() async {
    String currentUserId = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await _firebaseFirestore.collection('users').doc(currentUserId).get();

    if (userDoc.exists) {
      setState(() {
        //_isDarkTheme = userDoc['isDarkTheme'] ?? false; // Получаем сохраненное состояние темы
        _notificationsEnabled = userDoc['notificationsEnabled'] ?? true; // Получаем сохраненное состояние уведомлений
      });
    }
  }

  Future<void> _updateNotificationSetting(bool value) async {
    String currentUserId = _auth.currentUser!.uid;

    // Обновляем состояние уведомлений в Firestore
    await _firebaseFirestore.collection('users').doc(currentUserId).update({
      'notificationsEnabled': value,
    });
  }

  // Метод для обработки выбора элемента навигации
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Обновляем индекс выбранного элемента
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/learn');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/games');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Future<void> _contactSupport() async {
    String currentUserId = _auth.currentUser!.uid;

    // Получаем данные текущего пользователя
    DocumentSnapshot userDoc = await _firebaseFirestore.collection('users').doc(currentUserId).get();
    int roleId = userDoc['roleId'];

    if (roleId == 3) {
      // Если роль пользователя - поддержка, перенаправляем на страницу с чатами
      Navigator.pushReplacementNamed(context, '/chat');
    } else {
      // Обычная логика для других пользователей
      String? supportUserId = await getSupportUser();

      if (supportUserId != null) {
        // Поиск существующего чата
        QuerySnapshot chatSnapshot = await _firebaseFirestore
            .collection("chat")
            .where('user1id', isEqualTo: currentUserId)
            .where('user2id', isEqualTo: supportUserId)
            .get();

        // Если чат не найден, создаём новый
        if (chatSnapshot.docs.isEmpty) {
          DocumentReference chat = _firebaseFirestore.collection("chat").doc();
          await chat.set({
            'chatId': chat.id,
            'user1id': currentUserId,
            'user2id': supportUserId,
            'isChecked': false,
            'lastMessage': ""
          });

          // Переход в экран чата
          Navigator.pushNamed(context, '/chat', arguments: chat.id);
        } else {
          // Чат уже существует, переходим в него
          Navigator.pushNamed(context, '/chat', arguments: chatSnapshot.docs.first.id);
        }
      } else {
        // Если пользователь поддержки не найден
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь поддержки не найден.')),
        );
      }
    }
  }

  // Метод для поиска пользователя с ролью 3
  Future<String?> getSupportUser() async {
    try {
      QuerySnapshot userSnapshot = await _firebaseFirestore
          .collection("users")
          .where("roleId", isEqualTo: 3)
          .limit(1) // Предполагается, что нам нужен первый найденный пользователь
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.id; // Возвращаем ID пользователя
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Настройки"),
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pushReplacementNamed(context, '/profile');
        //   },
        // ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Переключатель темы (светлая/темная)
          // ListTile(
          //   leading: const Icon(Icons.brightness_6),
          //   title: const Text("Тема приложения"),
          //   subtitle: Text(_isDarkTheme ? "Тёмная" : "Светлая"),
          //   trailing: Switch(
          //     value: _isDarkTheme,
          //     onChanged: (bool value) {
          //       setState(() {
          //         _isDarkTheme = value;
          //       });
          //     },
          //   ),
          // ),
          const Divider(),

          // Переключатель уведомлений
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Уведомления"),
            subtitle: Text(_notificationsEnabled ? "Включены" : "Отключены"),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                  _updateNotificationSetting(value); // Сохраняем состояние в Firestore
                });
              },
            ),
          ),
          const Divider(),

          // Кнопка "Связаться с поддержкой"
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Связаться с поддержкой"),
            onTap: _contactSupport, // Метод для создания или перехода в чат
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Учиться',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.gamepad),
          label: 'Играть',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Уведомления',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Настройки',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Профиль',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.green[700],
      onTap: _onItemTapped,
    );
  }
}
