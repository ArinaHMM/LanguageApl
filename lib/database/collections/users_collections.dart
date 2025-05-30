// lib/database/collections/users_collections.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Убедитесь, что UserModel и UserRoles импортированы
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

class UsersCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // Легаси метод, если все еще используется
  Future<void> addUserCollection(
    String id,
    String firstName,
    String lastName,
    String email,
    String birthDate,
    String image,
    String? language,
  ) async {
    try {
      final initialLanguageSettings = UserLanguageSettings(
        currentLearningLanguage: language ?? 'english',
        interfaceLanguage: 'russian', // Пример языка интерфейса
        learningProgress: {
          (language ?? 'english'): UserLanguageProgress(level: 'NotStarted', xp: 0, lessonsCompleted: const {})
        },
      );
      await _firebaseFirestore.collection("users").doc(id).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'birthDate': birthDate,
        'profileImageUrl': image,
        // 'roleId': 1, // Заменено на строковую роль
        'role': UserRoles.user, // Роль по умолчанию
        'notificationsEnabled': true, // Убедитесь, что это поле есть в UserModel, если оно сохраняется
        'lives': 5,
        'lastRestored': Timestamp.now(),
        'registrationDate': Timestamp.now(),
        'languageSettings': initialLanguageSettings.toMap(),
      }, SetOptions(merge: true));
      print("User document created/merged for $id using addUserCollection.");
    } catch (e) {
      print("Error in UsersCollection.addUserCollection: $e");
    }
  }

  // --- НОВЫЙ МЕТОД ДЛЯ СОЗДАНИЯ ДОКУМЕНТА ПОЛЬЗОВАТЕЛЯ ---
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String role,
    String firstName = '', // Значение по умолчанию, если не передано
    String lastName = '',  // Значение по умолчанию, если не передано
    String birthDate = '', // Значение по умолчанию, если не передано
    String? profileImageUrl, // Опциональный параметр
    String initialLearningLanguage = 'english', // Язык по умолчанию
    String initialInterfaceLanguage = 'russian', // Язык интерфейса по умолчанию
  }) async {
    // Создаем экземпляр UserModel, используя данные, переданные в метод
    final newUser = UserModel(
      uid: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      profileImageUrl: profileImageUrl,
      role: role, // Используем переданную роль
      lives: 5, // Начальное значение жизней
      lastRestored: Timestamp.now(), // Текущее время как время последнего восстановления
      registrationDate: Timestamp.now(), // Текущее время как дата регистрации
      languageSettings: UserLanguageSettings( // Начальные языковые настройки
        currentLearningLanguage: initialLearningLanguage,
        interfaceLanguage: initialInterfaceLanguage,
        learningProgress: {
          // Создаем запись о прогрессе для начального языка обучения
          initialLearningLanguage: UserLanguageProgress(level: 'NotStarted', xp: 0, lessonsCompleted: const {})
        },
      ),
      // Убедитесь, что UserModel принимает все эти параметры в конструкторе
      // и имеет соответствующие поля
    );
    try {
      // Записываем данные нового пользователя в Firestore, используя toFirestore() из UserModel
      await _firebaseFirestore.collection(_collectionName).doc(uid).set(newUser.toFirestore());
      print("User document created for $uid with role $role using createUserDocument. Email: $email");
    } catch (e) {
      print("Error creating user document for $uid (Email: $email): $e");
      rethrow; // Перебрасываем ошибку для обработки на более высоком уровне (в UI)
    }
  }
  // --- КОНЕЦ МЕТОДА createUserDocument ---

  Future<void> editUserCollection(
    String id,
    String firstName,
    String lastName, {
    String? birthDate,
    String? image,
    bool? notificationsEnabled,
  }) async {
    final DocumentReference userDoc = _firebaseFirestore.collection('users').doc(id);
    Map<String, dynamic> dataToUpdate = {
      'firstName': firstName,
      'lastName': lastName,
    };
    if (birthDate != null) dataToUpdate['birthDate'] = birthDate;
    if (image != null) dataToUpdate['profileImageUrl'] = image;
    // if (notificationsEnabled != null) dataToUpdate['notificationsEnabled'] = notificationsEnabled; // Убедитесь, что UserModel это поддерживает

    try {
      await userDoc.update(dataToUpdate);
    } catch (e) {
      print("Error in UsersCollection.editUserCollection: $e");
      rethrow;
    }
  }

  Future<void> updateUserCollection(String id, Map<String, dynamic> data) async {
    try {
      await _firebaseFirestore.collection("users").doc(id).update(data);
    } catch (e) {
      print("Error in UsersCollection.updateUserCollection (generic): $e");
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String id) async {
    return await _firebaseFirestore.collection('users').doc(id).get(); // as DocumentSnapshot<Map<String, dynamic>> не нужен
  }

  Future<UserModel?> getUserModel(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await _firebaseFirestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Error in UsersCollection.getUserModel for $uid: $e");
      return null; // Возвращаем null в случае ошибки, вместо rethrow
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firebaseFirestore.collection(_collectionName).get();
      List<UserModel> users = [];
      for (var doc in querySnapshot.docs) {
        try {
          if (doc.exists && doc.data() != null) {
            users.add(UserModel.fromFirestore(doc));
          } else {
            print("Skipping document ${doc.id} due to missing data in getAllUsers.");
          }
        } catch (e) {
          print("Error parsing user document ${doc.id} in getAllUsers: $e. Skipping this user.");
        }
      }
      return users;
    } catch (e) {
      print("Error in UsersCollection.getAllUsers: $e");
      return [];
    }
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    if (!UserRoles.allRoles.contains(newRole)) {
      final errorMsg = "Invalid role '$newRole' provided for user $uid in updateUserRole.";
      print(errorMsg);
      throw ArgumentError(errorMsg);
    }
    try {
      await _firebaseFirestore.collection(_collectionName).doc(uid).update({'role': newRole});
      print("Role for user $uid updated to $newRole in updateUserRole.");
    } catch (e) {
      print("Error in UsersCollection.updateUserRole for $uid: $e");
      rethrow;
    }
  }

  Future<void> deleteUserDocument(String uid) async {
    try {
      await _firebaseFirestore.collection(_collectionName).doc(uid).delete();
      print("User document $uid deleted from Firestore in deleteUserDocument.");
    } catch (e) {
      print("Error in UsersCollection.deleteUserDocument for $uid: $e");
      rethrow;
    }
  }

  Future<void> updateLessonProgressInUserDoc(String uid, String languageCode, String lessonId, int progress) async {
    String fieldPath = 'languageSettings.learningProgress.$languageCode.lessonsCompleted.$lessonId';
    try {
        await _firebaseFirestore.collection(_collectionName).doc(uid).update({
            fieldPath: progress,
        });
    } catch (e) {
        print("Error in UsersCollection.updateLessonProgressInUserDoc for $uid: $e");
        rethrow;
    }
  }

  Future<void> updateUserLevel(String uid, String languageCode, String newLevel) async {
    String fieldPath = 'languageSettings.learningProgress.$languageCode.level';
    try {
      await _firebaseFirestore.collection(_collectionName).doc(uid).update({
        fieldPath: newLevel,
      });
      print("User $uid level updated to $newLevel for language $languageCode");
    } catch (e) {
      print("Error in UsersCollection.updateUserLevel for $uid: $e");
      rethrow;
    }
  }
}