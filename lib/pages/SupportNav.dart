import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class SupportNavigationPage extends StatefulWidget {
  const SupportNavigationPage({Key? key}) : super(key: key);

  @override
  _SupportNavigationPageState createState() => _SupportNavigationPageState();
}

class _SupportNavigationPageState extends State<SupportNavigationPage> {
  User? currentUser;
  String userName = "Поддержка"; // Значение по умолчанию

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final String id = currentUser!.uid;

      // Получаем данные пользователя из Firestore
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (userSnapshot.exists) {
        setState(() {
          userName = userSnapshot['firstName'] ?? 'Без имени'; // Предположим, что поле name существует
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support - панель'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Отображение имени текущего пользователя
            ListTile(
              title: Text('Привет, Саппортик!'),
              enabled: false, // Делаем элемент неактивным
            ),
          
            ListTile(
              title: const Text('Чаты'),
              onTap: () {
                Navigator.pushNamed(context, '/chat'); // Замените на ваш маршрут
              },
            ),
           
            ListTile(
              title: const Text('Настройки'),
              onTap: () {
                Navigator.pushNamed(context, '/settings'); // Замените на ваш маршрут
              },
            ),
            ListTile(
              title: const Text('Выход'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
          ],
        ),
      ),
    );
  }
}
