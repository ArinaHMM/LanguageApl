import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class AdminNavigationPage extends StatefulWidget {
  const AdminNavigationPage({Key? key}) : super(key: key);

  @override
  _AdminNavigationPageState createState() => _AdminNavigationPageState();
}

class _AdminNavigationPageState extends State<AdminNavigationPage> {
  User? currentUser;
  String userName = "Администратор"; // Значение по умолчанию

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
          userName = userSnapshot['firstName'] ??
              'Без имени'; // Предположим, что поле name существует
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админская панель'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Отображение имени текущего пользователя
            ListTile(
              title: Text('Привет, Админчик!'),
              enabled: false, // Делаем элемент неактивным
            ),

            ListTile(
              title: const Text('Управление уроками'),
              onTap: () {
                Navigator.pushNamed(
                    context, '/learnadmin'); // Замените на ваш маршрут
              },
            ),
            ListTile(
              title: const Text('Добавить урок'),
              onTap: () {
                Navigator.pushNamed(
                    context, '/admin'); // Замените на ваш маршрут
              },
            ),
            ListTile(
              title: const Text('Добавить урок Elementary'),
              onTap: () {
                Navigator.pushNamed(context, '/upperlesson');
              },
            ),
            ListTile(
              title: const Text('Добавить урок Intermediate'),
              onTap: () {
                Navigator.pushNamed(context, '/upperinterlesson');
              },
            ),
            ListTile(
              title: const Text('Добавить урок Upper Intermediate'),
              onTap: () {
                Navigator.pushNamed(context, '/upperupinterlesson');
              },
            ),
            ListTile(
              title: const Text('Добавить урок  Advanced'),
              onTap: () {
                Navigator.pushNamed(context, '/advancedlesson');
              },
            ),
            ListTile(
              title: const Text('Добавить аудиоурок'),
              onTap: () {
                Navigator.pushNamed(
                    context, '/audiolesson'); // Замените на ваш маршрут
              },
            ),
            ListTile(
              title: const Text('Добавить видеоурок'),
              onTap: () {
                Navigator.pushNamed(
                    context, '/video'); // Замените на ваш маршрут
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
