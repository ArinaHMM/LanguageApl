import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _notificationsEnabled = true; // Переменная для состояния уведомлений

  // Метод для получения состояния уведомлений текущего пользователя
  Future<void> _getUserNotificationSettings() async {
    String currentUserId = _auth.currentUser!.uid;

    // Получаем данные текущего пользователя
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUserId).get();

    setState(() {
      _notificationsEnabled = userDoc['notificationsEnabled'] ??
          true; // Измените ключ на тот, который вы используете для хранения состояния уведомлений
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserNotificationSettings(); // Получаем настройки уведомлений при инициализации
  }

  // Метод для создания нового уведомления
  Future<void> createNotification(
      String userId, String title, String message) async {
    // Создаем ссылку на новый документ в коллекции notifications
    final notificationRef = _firestore.collection('notifications').doc();

    // Сохраняем уведомление с ID документа в базе
    await notificationRef.set({
      'id': notificationRef.id, // ID самого уведомления
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Метод для удаления уведомления
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Виджет для отображения уведомлений
  Widget _buildNotificationItem(DocumentSnapshot document) {
    return Dismissible(
      key: Key(document.id),
      onDismissed: (direction) {
        deleteNotification(document.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Уведомление удалено')),
        );
      },
      background: Container(color: Colors.red),
      child: ListTile(
        title: Text(document['title'] ?? 'Без названия'),
        subtitle: Text(document['message'] ?? 'Без сообщения'),
        trailing: Text(
          document['timestamp'] != null
              ? (document['timestamp'] is Timestamp
                  ? (document['timestamp'] as Timestamp).toDate().toString()
                  : document['timestamp'])
              : '',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
                context, '/profile'); // Возврат на предыдущую страницу
          },
        ),
      ),
      body: _notificationsEnabled
          ? StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('userId',
                      isEqualTo: _auth.currentUser!
                          .uid) // Фильтруем уведомления по текущему пользователю
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                final notifications = snapshot.data!.docs;

                if (notifications.isEmpty) {
                  return const Center(child: Text('Нет уведомлений'));
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(notifications[index]);
                  },
                );
              },
            )
          : const Center(
              child: Text(
                  'Уведомления отключены')), // Сообщение, если уведомления отключены
    );
  }
}
