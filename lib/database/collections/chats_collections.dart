import 'package:cloud_firestore/cloud_firestore.dart';

class Chats {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Добавление чата между двумя пользователями
  Future<void> addChats(String user1, String user2) async {
    // Если чат не существует, создаем его

    DocumentReference chat = _firebaseFirestore.collection("chat").doc();
   await  chat.set({
        'chatId': chat.id,
        'user1id': user1,
        'user2id': user2,
        'isChecked': false,
        'lastMessage': ""
    });
  }

  // Метод для поиска пользователя с ролью 3
  Future<String?> getSupportUser() async {
    try {
      QuerySnapshot userSnapshot = await _firebaseFirestore
          .collection("users")
          .where("roleId", isEqualTo: 3)
          .limit(1) // Предположим, что нам нужен первый найденный пользователь
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.id; // Возвращаем ID пользователя
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<DocumentSnapshot> getChat(String chatId) {
    return _firebaseFirestore.doc(chatId).snapshots().first;
  }
}
