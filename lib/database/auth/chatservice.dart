// lib/database/collections/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UsersCollection _usersCollection = UsersCollection();

  Future<DocumentSnapshot> getOrCreateChatWithSupport(String userId, String supportId) async {
    String chatId;
    String u1, u2;

    if (userId.compareTo(supportId) < 0) {
      chatId = '${userId}_$supportId';
      u1 = userId;
      u2 = supportId;
    } else {
      chatId = '${supportId}_$userId';
      u1 = supportId;
      u2 = userId;
    }

    final chatDocRef = _firestore.collection('support_chats').doc(chatId);
    DocumentSnapshot chatDoc = await chatDocRef.get();

    if (!chatDoc.exists) {
      print("Chat document $chatId does not exist. Creating new one...");
      UserModel? user = await _usersCollection.getUserModel(userId);
      // UserModel? supportUser = await _usersCollection.getUserModel(supportId); // Если нужно имя/email поддержки

      await chatDocRef.set({
        'chatId': chatId, // <--- ИСПОЛЬЗУЕМ camelCase
        'user1id': u1,
        'user2id': u2,
        'participants': [u1, u2], // Дополнительное поле для запросов, если нужно
        'userEmail': user?.email ?? 'Клиент', // Денормализуем email клиента
        // 'supportDisplayName': supportUser?.firstName ?? 'Поддержка', // Можно денормализовать имя поддержки
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageText': 'Чат создан',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': null, // Изначально нет отправителя
        'isReadBySupport': true, // Поддержка "видит" чат при создании
        'isReadByUser': false,   // Пользователь еще не видел
        'unreadCountBySupport': 0,
        'unreadCountByUser': 0, // Изначально 0, или 1 если первое сообщение от поддержки
      });
      chatDoc = await chatDocRef.get(); // Получаем созданный документ
      print("Chat document $chatId created.");
    } else {
      print("Chat document $chatId already exists.");
    }
    return chatDoc;
  }
}