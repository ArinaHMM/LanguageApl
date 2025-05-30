// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ДОБАВЛЕНО: Класс для управления ролями ---
class UserRoles {
  static const String user = 'user';
  static const String admin = 'admin';
  static const String support = 'support';

  static List<String> get allRoles => [user, admin, support];

  static String displayRole(String? role) {
    switch (role) {
      case admin: return 'Администратор';
      case support: return 'Поддержка';
      case user: return 'Пользователь';
      default: return 'Неизвестная роль';
    }
  }
}
// --- КОНЕЦ ДОБАВЛЕНИЯ ---


// Модель для языкового прогресса пользователя
class UserLanguageProgress {
  final String level;
  final int xp;
  final Map<String, int> lessonsCompleted; // {lessonId: progressPercentage}

  UserLanguageProgress({
    required this.level,
    this.xp = 0,
    this.lessonsCompleted = const {},
  });

  factory UserLanguageProgress.fromMap(Map<String, dynamic> map) {
    return UserLanguageProgress(
      level: map['level'] as String? ?? 'NotStarted',
      xp: map['xp'] as int? ?? 0,
      lessonsCompleted: (map['lessonsCompleted'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'xp': xp,
      'lessonsCompleted': lessonsCompleted,
    };
  }

  UserLanguageProgress copyWith({
    String? level,
    int? xp,
    Map<String, int>? lessonsCompleted,
  }) {
    return UserLanguageProgress(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
    );
  }
}

// Модель для языковых настроек пользователя
class UserLanguageSettings {
  final String currentLearningLanguage;
  final String interfaceLanguage;
  final Map<String, UserLanguageProgress> learningProgress; // {languageCode: UserLanguageProgress}

  UserLanguageSettings({
    required this.currentLearningLanguage,
    required this.interfaceLanguage,
    required this.learningProgress,
  });

  factory UserLanguageSettings.fromMap(Map<String, dynamic> map) {
    String currentLang = map['currentLearningLanguage'] as String? ?? 'english';
    String interfaceLang = map['interfaceLanguage'] as String? ?? 'russian';

    Map<String, UserLanguageProgress> progressMap = {};
    if (map['learningProgress'] != null && map['learningProgress'] is Map) {
      (map['learningProgress'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map) {
          progressMap[key] = UserLanguageProgress.fromMap(value as Map<String, dynamic>);
        }
      });
    }
    
    if (!progressMap.containsKey(currentLang)) {
      // print("UserLanguageSettings.fromMap: Запись о прогрессе для currentLearningLanguage ('$currentLang') отсутствует. Создаю новую.");
      progressMap[currentLang] = UserLanguageProgress(level: 'NotStarted', xp: 0, lessonsCompleted: const {});
    }

    return UserLanguageSettings(
      currentLearningLanguage: currentLang,
      interfaceLanguage: interfaceLang,
      learningProgress: progressMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLearningLanguage': currentLearningLanguage,
      'interfaceLanguage': interfaceLanguage,
      'learningProgress': learningProgress.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  UserLanguageSettings copyWith({
    String? currentLearningLanguage,
    String? interfaceLanguage,
    Map<String, UserLanguageProgress>? learningProgress,
  }) {
    return UserLanguageSettings(
      currentLearningLanguage: currentLearningLanguage ?? this.currentLearningLanguage,
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
      learningProgress: learningProgress ?? this.learningProgress,
    );
  }
}

// Основная модель пользователя
class UserModel { 
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String? profileImageUrl;
  final int lives;
  final Timestamp lastRestored;
  final Timestamp registrationDate;
  final UserLanguageSettings? languageSettings;
  final String role; // <-- НОВОЕ ПОЛЕ ДЛЯ РОЛИ

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.profileImageUrl,
    required this.lives,
    required this.lastRestored,
    required this.registrationDate,
    this.languageSettings,
    this.role = UserRoles.user, // <-- Значение по умолчанию для роли
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("User document data is null for ID: ${doc.id}");
    }
    
    UserLanguageSettings? parsedLanguageSettings;
    if (data.containsKey('languageSettings') && data['languageSettings'] != null) {
      if (data['languageSettings'] is Map) {
        try {
          parsedLanguageSettings = UserLanguageSettings.fromMap(Map<String, dynamic>.from(data['languageSettings']));
        } catch (e, s) {
          print("UserModel.fromFirestore: ОШИБКА парсинга languageSettings для пользователя ${doc.id}. Error: $e, Stack: $s. Data: ${data['languageSettings']}");
        }
      } else {
        // print("UserModel.fromFirestore: Поле languageSettings для пользователя ${doc.id} не является Map. Тип: ${data['languageSettings'].runtimeType}. Оставляем null.");
      }
    } else {
      // print("UserModel.fromFirestore: Поле languageSettings отсутствует или null для пользователя ${doc.id}. Устанавливаем languageSettings в null.");
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      birthDate: data['birthDate'] as String? ?? '', // Предполагаем, что это строка
      profileImageUrl: data['profileImageUrl'] as String?,
      lives: data['lives'] as int? ?? 5,
      lastRestored: data['lastRestored'] as Timestamp? ?? Timestamp.now(),
      registrationDate: data['registrationDate'] as Timestamp? ?? Timestamp.now(),
      languageSettings: parsedLanguageSettings,
      role: data['role'] as String? ?? UserRoles.user, // <-- Чтение роли из Firestore
    );
  }

  // Метод для преобразования в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid, // Часто uid является ID документа, но иногда его дублируют в полях
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'lives': lives,
      'lastRestored': lastRestored,
      'registrationDate': registrationDate,
      if (languageSettings != null) 'languageSettings': languageSettings!.toMap(),
      'role': role, // <-- Запись роли в Firestore
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? profileImageUrl, // Для nullable полей, передача null обнулит значение
    int? lives,
    Timestamp? lastRestored,
    Timestamp? registrationDate,
    UserLanguageSettings? languageSettings,
    bool setToNullLanguageSettings = false,
    String? role, // <-- Добавлено поле role в copyWith
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      profileImageUrl: profileImageUrl == null && (this.profileImageUrl != null && uid == null) 
                        ? this.profileImageUrl // Сохраняем старое значение если не передано новое и это не создание нового объекта через copyWith только с uid
                        : profileImageUrl, // Иначе используем переданное (может быть null)
      lives: lives ?? this.lives,
      lastRestored: lastRestored ?? this.lastRestored,
      registrationDate: registrationDate ?? this.registrationDate,
      languageSettings: setToNullLanguageSettings 
                          ? null 
                          : (languageSettings ?? this.languageSettings),
      role: role ?? this.role, // <-- Обновление роли через copyWith
    );
  }
    
  UserModel updateLessonProgress(String languageCode, String lessonId, int progress) {
    // print("UserModel.updateLessonProgress: Начало. Язык: $languageCode, Урок ID: $lessonId, Прогресс: $progress");
    if (languageSettings == null) {
      // print("UserModel.updateLessonProgress: ВНИМАНИЕ! languageSettings is null. Невозможно обновить прогресс. Возвращается текущий объект UserModel.");
      return this; 
    }

    final newLearningProgressMap = Map<String, UserLanguageProgress>.from(languageSettings!.learningProgress);
    UserLanguageProgress langProgressToUpdate = newLearningProgressMap[languageCode] ?? 
                                              UserLanguageProgress(level: 'NotStarted', lessonsCompleted: {});
    // print("UserModel.updateLessonProgress: Прогресс для языка '$languageCode' до обновления: Уровень ${langProgressToUpdate.level}, Завершено: ${langProgressToUpdate.lessonsCompleted}");

    final newLessonsCompleted = Map<String, int>.from(langProgressToUpdate.lessonsCompleted);
    newLessonsCompleted[lessonId] = progress;

    final newLangProgress = langProgressToUpdate.copyWith(lessonsCompleted: newLessonsCompleted);
    // print("UserModel.updateLessonProgress: Прогресс для языка '$languageCode' ПОСЛЕ обновления: Уровень ${newLangProgress.level}, Завершено: ${newLangProgress.lessonsCompleted}");

    newLearningProgressMap[languageCode] = newLangProgress;
    final newLanguageSettings = languageSettings!.copyWith(learningProgress: newLearningProgressMap);
    // print("UserModel.updateLessonProgress: newLanguageSettings.currentLearningLanguage: ${newLanguageSettings.currentLearningLanguage}");
    // print("UserModel.updateLessonProgress: newLanguageSettings.learningProgress содержит $languageCode: ${newLanguageSettings.learningProgress.containsKey(languageCode)}");
    
    UserModel result = copyWith(languageSettings: newLanguageSettings);
    // print("UserModel.updateLessonProgress: Конец. languageSettings в результирующем UserModel is null: ${result.languageSettings == null}");
    return result;
  }
}