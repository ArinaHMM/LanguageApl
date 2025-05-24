import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Метод для добавления сообщения с возможным изображением
  Future<void> addMessages(
    String chatId,
    String messageText,
    String senderId, {
    String? imageUrl, // Новый параметр для URL изображения
  }) async {
    try {
      // Создаём сообщение
      Map<String, dynamic> messageData = {
        'messageText': messageText,
        'timeStamp': DateTime.now(),
        'senderId': senderId,
      };

      // Если передан URL изображения, добавляем его в сообщение
      if (imageUrl != null && imageUrl.isNotEmpty) {
        messageData['imageUrl'] = imageUrl;
      }

      // Добавляем сообщение в подколлекцию messages
      await _firebaseFirestore.collection("chat").doc(chatId).collection('messages').add(messageData);
    } catch (e) {
      return;
    }
  }

  // Удаление чата и всех его сообщений
  Future<void> deleteChatAndMessages(String chatId) async {
    WriteBatch batch = _firebaseFirestore.batch();
    try {
      // Получаем все сообщения чата
      QuerySnapshot messagesSnapshot = await _firebaseFirestore.collection("chat").doc(chatId).collection('messages').get();
      
      // Удаляем все сообщения
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Удаляем сам чат
      batch.delete(_firebaseFirestore.collection("chat").doc(chatId));

      // Применяем изменения
      await batch.commit();
    } catch (e) {
      return;
    }
  }
}
