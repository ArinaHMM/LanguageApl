// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
          {},
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
    return UserLanguageSettings(
      currentLearningLanguage: map['currentLearningLanguage'] as String? ?? 'english',
      interfaceLanguage: map['interfaceLanguage'] as String? ?? 'russian',
      learningProgress: (map['learningProgress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, UserLanguageProgress.fromMap(value as Map<String, dynamic>)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLearningLanguage': currentLearningLanguage,
      'interfaceLanguage': interfaceLanguage,
      'learningProgress': learningProgress.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class UserModel { // Это НОВАЯ UserModel для LearnPage
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
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      birthDate: data['birthDate'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?, // Убедитесь, что это поле есть в Firestore или обрабатывайте null
      lives: data['lives'] as int? ?? 5,
      lastRestored: data['lastRestored'] as Timestamp? ?? Timestamp.now(),
      registrationDate: data['registrationDate'] as Timestamp? ?? Timestamp.now(),
      languageSettings: data.containsKey('languageSettings') && data['languageSettings'] != null
          ? UserLanguageSettings.fromMap(data['languageSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? profileImageUrl,
    int? lives,
    Timestamp? lastRestored,
    Timestamp? registrationDate,
    UserLanguageSettings? languageSettings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lives: lives ?? this.lives,
      lastRestored: lastRestored ?? this.lastRestored,
      registrationDate: registrationDate ?? this.registrationDate,
      languageSettings: languageSettings ?? this.languageSettings,
    );
  }
    // Метод для удобного обновления прогресса урока локально
  UserModel updateLessonProgress(String languageCode, String lessonId, int progress) {
    if (languageSettings == null) return this;

    final langProgress = languageSettings!.learningProgress[languageCode];
    if (langProgress == null) return this;

    final newLessonsCompleted = Map<String, int>.from(langProgress.lessonsCompleted);
    newLessonsCompleted[lessonId] = progress;

    final newLangProgress = langProgress.copyWith(lessonsCompleted: newLessonsCompleted);
    
    final newLearningProgressMap = Map<String, UserLanguageProgress>.from(languageSettings!.learningProgress);
    newLearningProgressMap[languageCode] = newLangProgress;

    final newLanguageSettings = UserLanguageSettings(
        currentLearningLanguage: languageSettings!.currentLearningLanguage,
        interfaceLanguage: languageSettings!.interfaceLanguage,
        learningProgress: newLearningProgressMap,
    );
    return copyWith(languageSettings: newLanguageSettings);
  }
}