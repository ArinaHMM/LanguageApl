import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  // ignore: unused_field

  Future<void> addUserCollection(
    String id,
    String firstName,
    String lastName,
    String email,
    String birthDate,
    String image,
    String language,
  ) async {
    try {
      await _firebaseFirestore.collection("users").doc(id).set({
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'birthDate': birthDate,
        'image': image,
        'language': language,
        'roleId': 1, // Присваиваем роль по умолчанию (1 = пользователь)
        'notificationsEnabled': true, // Добавляем поле для уведомлений
      });
    } catch (e) {
      print(e); // Выводим ошибку в консоль
    }
  }

  Future<void> editUserCollection(
    String id,
    String firstName,
    String lastName, {
    String? birthDate,
    String? email,
    String? image,
    String? language,
    bool? notificationsEnabled, // Добавляем параметр для уведомлений
  }) async {
    final DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(id);

    await userDoc.update({
      'firstName': firstName,
      'lastName': lastName,
      if (birthDate != null) 'birthDate': birthDate,
      if (email != null) 'email': email,
      if (image != null) 'image': image,
      if (language != null) 'language': language,
      if (notificationsEnabled != null)
        'notificationsEnabled':
            notificationsEnabled, // Обновляем поле уведомлений
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String id) async {
    return await _firebaseFirestore.collection('users').doc(id).get();
  }
}
