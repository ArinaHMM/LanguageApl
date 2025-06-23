import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart'; // Для UserRoles
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart'; // Для получения UserModel

class AdminAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UsersCollection _usersCollection = UsersCollection(); // Для получения роли пользователя

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        print("Firebase Auth returned null user after sign in attempt.");
        return null;
      }

      UserModel? userModel = await _usersCollection.getUserModel(userCredential.user!.uid);

      if (userModel == null) {
        print("User document not found in Firestore for UID: ${userCredential.user!.uid}. Signing out.");
        await _firebaseAuth.signOut();
        return null;
      }

      if (userModel.role == UserRoles.admin || userModel.role == UserRoles.support) {
        print("User ${userModel.email} signed in successfully with role: ${userModel.role}");
        return userCredential.user; // Успешный вход для админа или поддержки
      } else {
        print("User ${userModel.email} has role '${userModel.role}', which is not authorized for this panel. Signing out.");
        await _firebaseAuth.signOut();
        return null; // Не авторизованная роль
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException on sign in: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Generic error during sign in: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Проверка, является ли ТЕКУЩИЙ аутентифицированный пользователь админом (по коллекции 'admins')
  // Эта логика может быть избыточной, если роль 'admin' в UserModel является единственным источником правды
  Future<bool> isAdmin(User? user) async {
    if (user == null) return false;
    // Вариант 1: Проверка по коллекции 'admins' (как у вас было)
    // try {
    //   DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    //   return adminDoc.exists;
    // } catch (e) {
    //   print("Error checking admin status by 'admins' collection: $e");
    //   return false;
    // }

    // Вариант 2: Проверка по полю 'role' в документе пользователя (рекомендуется для консистентности)
    UserModel? userModel = await _usersCollection.getUserModel(user.uid);
    return userModel?.role == UserRoles.admin;
  }
  
  // Новая функция для проверки роли поддержки
  Future<bool> isSupport(User? user) async {
    if (user == null) return false;
    UserModel? userModel = await _usersCollection.getUserModel(user.uid);
    return userModel?.role == UserRoles.support;
  }


  Future<UserCredential?> createAuthUserWithSecondaryApp(String email, String password) async {
    // ... (код метода как в предыдущем ответе) ...
    String secondaryAppName = 'lingoQuestSecondaryAuthApp-${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondaryApp;

    try {
      FirebaseOptions options = Firebase.app().options;
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: options,
      );
      FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await secondaryAuth.signOut();
      print("Signed out new user from secondary app session.");
      // Опционально удалить secondaryApp, но с осторожностью
      // if (secondaryApp != null) {
      //   await secondaryApp.delete();
      // }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Error creating auth user with secondary app: ${e.code} - ${e.message}");
      if (secondaryApp != null) { /* await secondaryApp.delete(); */ } // Попытка удалить в случае ошибки
      rethrow;
    } catch (e) {
      print("Generic error creating auth user with secondary app: $e");
      if (secondaryApp != null) { /* await secondaryApp.delete(); */ }
      rethrow;
    }
    // finally { // Блок finally здесь может быть проблематичным для удаления, если ошибка в try
    //   if (secondaryApp != null) {
    //     try {
    //       await secondaryApp.delete();
    //       print("Secondary Firebase app '$secondaryAppName' deleted.");
    //     } catch (e) {
    //       print("Error deleting secondary Firebase app '$secondaryAppName': $e");
    //     }
    //   }
    // }
  }
  // --- МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ КОЛЛЕКЦИЕЙ 'admins' ---
  Future<void> grantAdminRole(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('admins').doc(uid).set({});
      print("Admin role granted to user $uid.");
    } catch (e) {
      print("Error granting admin role to $uid: $e");
      rethrow;
    }
  }

  Future<void> revokeAdminRole(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('admins').doc(uid).delete();
      print("Admin role revoked from user $uid.");
    } catch (e) {
      print("Error revoking admin role from $uid: $e");
      rethrow;
    }
  }

  Future<bool> isUidAdmin(String uid) async {
    if (uid.isEmpty) return false;
    try {
      DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(uid).get();
      return adminDoc.exists;
    } catch (e) {
      print("Error checking if UID $uid is admin: $e");
      return false;
    }
  }
}