import 'package:cloud_firestore/cloud_firestore.dart';
// Убедитесь, что НОВАЯ модель UserModel импортирована из папки /models/
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

class UsersCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Ваш существующий метод addUserCollection.
  // Он создает базовый документ при регистрации.
  // Убедитесь, что он не пытается записать старые поля 'language' или 'progress' так,
  // как они были раньше, так как теперь эта логика в 'languageSettings'.
  Future<void> addUserCollection(
    String id,
    String firstName,
    String lastName,
    String email,
    String birthDate,
    String image, // Это URL изображения или заглушка?
    String? language, // Это поле теперь менее релевантно, т.к. язык выбирается отдельно.
                     // Можно его убрать или передавать null/пустую строку.
  ) async {
    try {
      await _firebaseFirestore.collection("users").doc(id).set({
        // 'id': id, // Поле 'id' внутри документа обычно не нужно, так как ID документа уже есть.
        'firstName': firstName,
        'lastName': lastName,
        'email': email, // Полезно для запросов, хотя email есть и в Auth.
        'birthDate': birthDate,
        'profileImageUrl': image, // Переименовал для ясности, если это URL.
        // 'language': language, // Это поле теперь управляется через 'languageSettings'.
                                // Если оно вам нужно для чего-то другого, оставьте.
        'roleId': 1, // Роль по умолчанию.
        'notificationsEnabled': true, // Уведомления по умолчанию.

        // Базовые поля, которые нужны сразу:
        'lives': 5,
        'lastRestored': Timestamp.now(),
        'registrationDate': Timestamp.now(),
        // НЕ СОЗДАЕМ 'languageSettings' ЗДЕСЬ. Это делается на странице SelectLanguagePage.
      }, SetOptions(merge: true)); // merge: true полезно, если другие процессы могут писать в этот документ.
    } catch (e) {
      print("Error in UsersCollection.addUserCollection: $e");
      // Рассмотрите rethrow e; если хотите обрабатывать ошибку выше.
    }
  }

  // Ваш существующий метод editUserCollection для редактирования профиля.
  Future<void> editUserCollection(
    String id,
    String firstName,
    String lastName, {
    String? birthDate,
    // String? email, // Редактирование email через Firestore без Auth может быть небезопасно.
    String? image, // URL изображения.
    // String? language, // Язык и уровень теперь в 'languageSettings'.
    bool? notificationsEnabled,
  }) async {
    final DocumentReference userDoc = _firebaseFirestore.collection('users').doc(id);
    Map<String, dynamic> dataToUpdate = {
      'firstName': firstName,
      'lastName': lastName,
    };
    if (birthDate != null) dataToUpdate['birthDate'] = birthDate;
    if (image != null) dataToUpdate['profileImageUrl'] = image; // Согласуем имя поля
    if (notificationsEnabled != null) dataToUpdate['notificationsEnabled'] = notificationsEnabled;
    
    try {
      await userDoc.update(dataToUpdate);
    } catch (e) {
      print("Error in UsersCollection.editUserCollection: $e");
      rethrow;
    }
  }

  // Ваш существующий updateUserCollection - идеально подходит для общего обновления.
  // LearnPage будет его использовать для обновления languageSettings, lives, lastRestored.
  Future<void> updateUserCollection(String id, Map<String, dynamic> data) async {
    try {
      await _firebaseFirestore.collection("users").doc(id).update(data);
    } catch (e) {
      print("Error in UsersCollection.updateUserCollection (generic): $e");
      rethrow;
    }
  }

  // Ваш существующий getUser - возвращает DocumentSnapshot. Оставим его, если он используется.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String id) async {
    // Добавим явное приведение типа для соответствия ожиданиям, если где-то это важно
    return await _firebaseFirestore.collection('users').doc(id).get() as DocumentSnapshot<Map<String, dynamic>>;
  }

  // --- МЕТОДЫ, НУЖНЫЕ ДЛЯ LearnPage (использующие НОВУЮ UserModel) ---

  // Метод для получения данных пользователя в виде НОВОЙ UserModel.
  // Этот метод будет использовать LearnPage.
  Future<UserModel?> getUserModel(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firebaseFirestore.collection('users').doc(uid).get() as DocumentSnapshot<Map<String, dynamic>>;
      if (doc.exists && doc.data() != null) {
        // Используем фабричный конструктор из НОВОЙ UserModel (lib/models/user_model.dart)
        return UserModel.fromFirestore(doc);
      }
      return null; // Пользователь не найден
    } catch (e) {
      print("Error in UsersCollection.getUserModel: $e");
      rethrow; // Перебрасываем ошибку для обработки в LearnPage
    }
  }

  // Метод для обновления прогресса конкретного урока в документе пользователя.
  // Этот метод будет вызываться из LearnPage.
  Future<void> updateLessonProgressInUserDoc(String uid, String languageCode, String lessonId, int progress) async {
    // Формируем путь к полю для обновления в Firestore, используя dot-notation.
    String fieldPath = 'languageSettings.learningProgress.$languageCode.lessonsCompleted.$lessonId';
    try {
        await _firebaseFirestore.collection('users').doc(uid).update({
            fieldPath: progress,
        });
    } catch (e) {
        print("Error in UsersCollection.updateLessonProgressInUserDoc: $e");
        rethrow;
    }
  }
}