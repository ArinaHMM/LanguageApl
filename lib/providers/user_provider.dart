// flutter_languageapplicationmycourse_2/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
// ИМПОРТИРУЕМ ПОЛНОЦЕННЫЙ UserModel ИЗ models/user_model.dart
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUserModel; // Теперь это ваш полноценный UserModel
  fb_auth.User? _firebaseUser;   // Объект пользователя Firebase Auth (можно оставить для прямого доступа)

  UserProvider(); // Конструктор

  // Геттер для доступа к данным UserModel
  UserModel? get currentUser => _currentUserModel;

  // Геттер для доступа к объекту пользователя Firebase Auth
  fb_auth.User? get firebaseUser => _firebaseUser;

  // Основной метод для обновления данных пользователя.
  // Вызывается из ChangeNotifierProxyProvider, когда данные из StreamProvider (AuthService) изменяются.
  void updateUserModel(UserModel? newUserModel, {fb_auth.User? newFirebaseUser}) {
    bool modelChanged = _currentUserModel != newUserModel;
    bool firebaseUserChanged = (newFirebaseUser != null && _firebaseUser != newFirebaseUser);

    if (modelChanged) {
      _currentUserModel = newUserModel;
    }

    if (firebaseUserChanged) {
      _firebaseUser = newFirebaseUser;
    } else if (newUserModel != null && _firebaseUser == null && newUserModel.uid.isNotEmpty) {
      // Если _firebaseUser не был передан, но есть newUserModel,
      // и _firebaseUser еще не установлен, можно попытаться его синхронизировать,
      // но лучше, если newFirebaseUser всегда передается вместе с newUserModel, если он доступен.
      // _firebaseUser = newFirebaseUser; // Это уже обработано выше.
      // Возможно, стоит проверить FirebaseAuth.instance.currentUser, если newFirebaseUser не передан.
    }

    if (modelChanged || firebaseUserChanged) {
      notifyListeners();
    }
  }

  // Метод для прямой установки пользователя Firebase Auth.
  // Используйте с осторожностью, так как это может рассинхронизировать _currentUserModel,
  // если _currentUserModel не обновляется соответствующим образом.
  void setFirebaseUser(fb_auth.User? user) {
    if (_firebaseUser != user) {
      _firebaseUser = user;
      if (user == null) {
        // Если пользователь вышел, также очищаем _currentUserModel
        _currentUserModel = null;
      } else {
        // Если пользователь вошел, но у нас нет _currentUserModel,
        // это означает, что ProxyProvider еще не отработал или AuthService
        // еще не предоставил UserModel. В идеале, updateUserModel должен
        // вызываться с актуальным UserModel.
        // Можно попробовать загрузить UserModel здесь, если это необходимо,
        // но это дублирует логику AuthService.
        //
        // Если у вас есть конструктор UserModel.fromFirebase(user) И он создает
        // UserModel С НАСТРОЙКАМИ (что маловероятно без обращения к Firestore),
        // то можно было бы его использовать. Но ваш UserModel.fromFirestore
        // требует DocumentSnapshot.
        //
        // Лучше всего, если этот метод используется только для обновления _firebaseUser,
        // а _currentUserModel обновляется через updateUserModel.
        // Если _currentUserModel?.uid не совпадает с user.uid, то это проблема.
        if (_currentUserModel != null && _currentUserModel!.uid != user.uid) {
          // Это указывает на рассинхронизацию, _currentUserModel нужно обновить.
          // Временное решение - обнулить, чтобы ProxyProvider его точно обновил.
          _currentUserModel = null;
        }
      }
      notifyListeners();
    }
  }

  // Метод для обновления прогресса урока напрямую через провайдер (если нужно)
  // Это пример, если вы хотите иметь такой метод в провайдере.
  // Обычно обновление прогресса происходит на странице урока, а затем данные
  // синхронизируются обратно в провайдер через _handleProgressUpdate -> updateUserModel.
  void updateLessonProgress(String languageCode, String lessonId, int progress) {
    if (_currentUserModel == null || _currentUserModel!.languageSettings == null) return;

    // Используем метод из UserModel для обновления
    UserModel updatedModel = _currentUserModel!.updateLessonProgress(languageCode, lessonId, progress);

    if (_currentUserModel != updatedModel) {
      _currentUserModel = updatedModel;
      notifyListeners();
    }
  }
}