import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// --- Класс для управления ролями ---
class UserRoles {
  static const String user = 'user';
  static const String admin = 'admin';
  static const String support = 'support';

  static List<String> get allRoles => [user, admin, support];

  static String displayRole(String? role) {
    switch (role) {
      case admin:
        return 'Администратор';
      case support:
        return 'Поддержка';
      case user:
        return 'Пользователь';
      default:
        return 'Неизвестная роль (${role ?? 'null'})';
    }
  }
}

// --- Модель для языкового прогресса пользователя (сделана неизменяемой) ---
class UserLanguageProgress {
  final String level;
  final int xp;
  final Map<String, int> lessonsCompleted; // {lessonId: progressPercentage}
  final int dailyXpEarnedToday;

  const UserLanguageProgress({
    // ИЗМЕНЕНИЕ: Конструктор теперь const
    required this.level,
    this.xp = 0,
    this.lessonsCompleted = const {},
    this.dailyXpEarnedToday = 0,
  });

  factory UserLanguageProgress.fromMap(Map<String, dynamic> map) {
    return UserLanguageProgress(
      level: map['level'] as String? ?? 'Beginner',
      xp: map['xp'] as int? ?? 0,
      lessonsCompleted: (map['lessonsCompleted'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          const {},
      dailyXpEarnedToday: map['dailyXpEarnedToday'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'xp': xp,
      'lessonsCompleted': lessonsCompleted,
      'dailyXpEarnedToday': dailyXpEarnedToday,
    };
  }

  UserLanguageProgress copyWith({
    String? level,
    int? xp,
    Map<String, int>? lessonsCompleted,
    int? dailyXpEarnedToday,
  }) {
    return UserLanguageProgress(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      dailyXpEarnedToday: dailyXpEarnedToday ?? this.dailyXpEarnedToday,
    );
  }
}

@immutable
class InventoryItem {
  final String id; // Уникальный ID предмета, например, "streak_freeze"
  final int quantity; // Количество этого предмета у пользователя
  final String name; // Отображаемое имя, например, "Заморозка стрика"
  final String description; // Описание для UI
  final String icon; // Ключ для иконки, например, "streak_freeze_icon"

  const InventoryItem ({
    required this.id,
    required this.quantity,
    required this.name,
    required this.description,
    required this.icon,
  });
   InventoryItem copyWith({
    String? id,
    int? quantity,
    String? name,
    String? description,
    String? icon,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }


  // Фабричный конструктор для создания объекта из данных Firestore
  factory InventoryItem.fromMap(String id, Map<String, dynamic> data) {
    return InventoryItem(
      id: id,
      quantity: data['quantity'] as int? ?? 0,
      name: data['name'] as String? ?? 'Неизвестный предмет',
      description: data['description'] as String? ?? 'Нет описания.',
      icon: data['icon'] as String? ?? 'default_icon',
    );
  }

  // Метод для преобразования объекта в Map для записи в Firestore
  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }
}

// --- Модель для языковых настроек пользователя ---
class UserLanguageSettings {
  final String currentLearningLanguage;
  final String interfaceLanguage;
  final Map<String, UserLanguageProgress> learningProgress;

  const UserLanguageSettings({
    // ИЗМЕНЕНИЕ: Конструктор теперь const
    required this.currentLearningLanguage,
    required this.interfaceLanguage,
    required this.learningProgress,
  });

  factory UserLanguageSettings.empty(
      {String defaultLang = 'english',
      String defaultInterfaceLang = 'russian'}) {
    return UserLanguageSettings(
      currentLearningLanguage: defaultLang,
      interfaceLanguage: defaultInterfaceLang,
      learningProgress: {defaultLang: UserLanguageProgress(level: 'Beginner')},
    );
  }

  factory UserLanguageSettings.fromMap(Map<String, dynamic> map) {
    String currentLang = map['currentLearningLanguage'] as String? ?? 'english';
    String interfaceLang = map['interfaceLanguage'] as String? ?? 'russian';

    Map<String, UserLanguageProgress> progressMap = {};
    if (map['learningProgress'] != null && map['learningProgress'] is Map) {
      (map['learningProgress'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map) {
          progressMap[key] =
              UserLanguageProgress.fromMap(value as Map<String, dynamic>);
        }
      });
    }

    if (!progressMap.containsKey(currentLang)) {
      progressMap[currentLang] = UserLanguageProgress(level: 'Beginner');
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
      'learningProgress':
          learningProgress.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  UserLanguageSettings copyWith({
    String? currentLearningLanguage,
    String? interfaceLanguage,
    Map<String, UserLanguageProgress>? learningProgress,
  }) {
    return UserLanguageSettings(
      currentLearningLanguage:
          currentLearningLanguage ?? this.currentLearningLanguage,
      interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
      learningProgress: learningProgress ?? this.learningProgress,
    );
  }
}

// --- Основная модель пользователя ---
@immutable // ИЗМЕНЕНИЕ: Аннотация для обозначения неизменяемости класса
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final Timestamp? doubleXpBuffExpiresAt;
  final String lastName;
  final String birthDate;
  final Map<String, Timestamp> unlockedAchievements;
  final InventoryItem? awardedItemForUI;
  final String? profileImageUrl;
  final int lives;
  final Timestamp lastRestored;
  final Timestamp registrationDate;
  final UserLanguageSettings? languageSettings;
  final String role;
  final List<InventoryItem> inventory;
  final Timestamp? lastGoalChangeDate;

  // Поля для целей и стриков
  final int dailyGoalXp;
  final int currentStreak;
  final Timestamp? lastGoalCompletionDate;
  final int streakFreezes;
  final Timestamp? lastStreakCheckDate;
  final String? leagueId; // ID лиги, в которой состоит пользователь
  final int weeklyXp; // XP, заработанный за текущую неделю
  final int totalXp;

  const UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    this.lastGoalChangeDate,
    required this.lastName,
    required this.birthDate,
    this.doubleXpBuffExpiresAt,
    this.profileImageUrl,
    required this.lives,
    this.awardedItemForUI,
    this.inventory = const [],
    required this.lastRestored,
    required this.registrationDate,
    this.languageSettings,
    this.role = UserRoles.user,
    this.unlockedAchievements = const {},
    this.dailyGoalXp = 50,
    this.currentStreak = 0,
    this.lastGoalCompletionDate,
    this.streakFreezes = 0,
    this.lastStreakCheckDate,
    this.leagueId,
    this.weeklyXp = 0,
    this.totalXp = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("User document data is null for ID: ${doc.id}");
    }

    UserLanguageSettings? parsedLanguageSettings;
    if (data.containsKey('languageSettings') &&
        data['languageSettings'] != null) {
      if (data['languageSettings'] is Map) {
        try {
          parsedLanguageSettings = UserLanguageSettings.fromMap(
              Map<String, dynamic>.from(data['languageSettings']));
        } catch (e, s) {
          print(
              "UserModel.fromFirestore: ОШИБКА парсинга languageSettings для пользователя ${doc.id}. Error: $e, Stack: $s. Data: ${data['languageSettings']}");
          parsedLanguageSettings = UserLanguageSettings.empty();
        }
      }
    }
    List<InventoryItem> parsedInventory = [];
    if (data['inventory'] != null && data['inventory'] is Map) {
      final inventoryMap = data['inventory'] as Map<String, dynamic>;
      inventoryMap.forEach((itemId, itemData) {
        if (itemData is Map) {
          parsedInventory.add(
              InventoryItem.fromMap(itemId, itemData as Map<String, dynamic>));
        }
      });
    }
    final unlockedAchievementsData =
        data['unlockedAchievements'] as Map<String, dynamic>?;
    final Map<String, Timestamp> parsedAchievements =
        unlockedAchievementsData?.map(
              (key, value) => MapEntry(key, value as Timestamp),
            ) ??
            {};
    return UserModel(
      uid: doc.id,
      doubleXpBuffExpiresAt: data['doubleXpBuffExpiresAt'] as Timestamp?,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      birthDate: data['birthDate'] as String? ?? '',
      profileImageUrl:
          data['image'] as String? ?? data['profileImageUrl'] as String?,
      lives: data['lives'] as int? ?? 5,
      lastRestored: data['lastRestored'] as Timestamp? ?? Timestamp.now(),
      registrationDate:
          data['registrationDate'] as Timestamp? ?? Timestamp.now(),
      languageSettings: parsedLanguageSettings,
      role: data['role'] as String? ?? UserRoles.user,
      dailyGoalXp: data['dailyGoalXp'] as int? ?? 50,
      currentStreak: data['currentStreak'] as int? ?? 0,
      lastGoalCompletionDate: data['lastGoalCompletionDate'] as Timestamp?,
      streakFreezes: data['streakFreezes'] as int? ?? 0,
      lastStreakCheckDate: data['lastStreakCheckDate'] as Timestamp?,
      leagueId: data['leagueId'] as String?,
      weeklyXp: data['weeklyXp'] as int? ?? 0,
      totalXp: data['totalXp'] as int? ?? 0,
      inventory: parsedInventory,
      lastGoalChangeDate: data['lastGoalChangeDate'] as Timestamp?,
      unlockedAchievements: parsedAchievements,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> inventoryMap = {
      for (var item in inventory) item.id: item.toMap()
    };
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate,
      if (profileImageUrl != null) 'image': profileImageUrl,
      'role': role,
      'lives': lives,
       if (lastGoalChangeDate != null) 'lastGoalChangeDate': lastGoalChangeDate,
      'lastRestored': lastRestored,
      'registrationDate': registrationDate,
      if (leagueId != null) 'leagueId': leagueId,
      'weeklyXp': weeklyXp,
      'totalXp': totalXp,
      'inventory': inventoryMap,
      if (languageSettings != null)
        'languageSettings': languageSettings!.toMap(),
      'dailyGoalXp': dailyGoalXp,
      'currentStreak': currentStreak,
      'unlockedAchievements': unlockedAchievements,
      if (lastGoalCompletionDate != null)
        'lastGoalCompletionDate': lastGoalCompletionDate,
      'streakFreezes': streakFreezes,
      if (lastStreakCheckDate != null)
        'lastStreakCheckDate': lastStreakCheckDate,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    Map<String, Timestamp>? unlockedAchievements,
    String? birthDate,
    InventoryItem? awardedItemForUI,
    ValueGetter<String?>? profileImageUrl,
    int? lives,
    ValueGetter<Timestamp?>? doubleXpBuffExpiresAt,
    Timestamp? lastRestored,
    Timestamp? registrationDate,
    ValueGetter<UserLanguageSettings?>? languageSettings,
    String? role,
    List<InventoryItem>? inventory,
    int? dailyGoalXp,
    int? currentStreak,
    ValueGetter<Timestamp?>? lastGoalCompletionDate,
    int? streakFreezes,
    ValueGetter<Timestamp?>? lastStreakCheckDate,
    ValueGetter<String?>? leagueId,
    int? weeklyXp,
    int? totalXp,
    ValueGetter<Timestamp?>? lastGoalChangeDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      inventory: inventory ?? this.inventory,
      doubleXpBuffExpiresAt: doubleXpBuffExpiresAt != null
          ? doubleXpBuffExpiresAt()
          : this.doubleXpBuffExpiresAt,
      profileImageUrl:
          profileImageUrl != null ? profileImageUrl() : this.profileImageUrl,
      lives: lives ?? this.lives,
      awardedItemForUI: awardedItemForUI ?? this.awardedItemForUI,
      lastRestored: lastRestored ?? this.lastRestored,
      registrationDate: registrationDate ?? this.registrationDate,
      leagueId: leagueId != null ? leagueId() : this.leagueId,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      totalXp: totalXp ?? this.totalXp,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      languageSettings:
          languageSettings != null ? languageSettings() : this.languageSettings,
      role: role ?? this.role,
      dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      lastGoalCompletionDate: lastGoalCompletionDate != null
          ? lastGoalCompletionDate()
          : this.lastGoalCompletionDate,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      lastStreakCheckDate: lastStreakCheckDate != null
          ? lastStreakCheckDate()
          : this.lastStreakCheckDate,
      lastGoalChangeDate: lastGoalChangeDate != null // Новое поле
          ? lastGoalChangeDate()
          : this.lastGoalChangeDate,
    );
  }

  bool get isDoubleXpActive {
    if (doubleXpBuffExpiresAt == null) return false;
    // Бафф активен, если его время окончания еще не наступило
    return doubleXpBuffExpiresAt!.toDate().isAfter(DateTime.now());
  }
  bool get canChangeGoalToday {
    if (lastGoalChangeDate == null) return true;
    final now = DateTime.now();
    final lastChange = lastGoalChangeDate!.toDate();
    return !(now.year == lastChange.year &&
        now.month == lastChange.month &&
        now.day == lastChange.day);
  }
    UserModel withUpdatedGoal({
    required int newGoal,
    required int rewardItems,
    required Timestamp changeDate,
  }) {
    // Создаем новый инвентарь с добавленными предметами
    List<InventoryItem> newInventory = List.from(inventory);
    
    // Ищем предмет "reward_item" в инвентаре
    int rewardItemIndex = newInventory.indexWhere((item) => item.id == 'reward_item');
    
    if (rewardItemIndex != -1) {
      // Если предмет уже есть - увеличиваем количество
      final existingItem = newInventory[rewardItemIndex];
      newInventory[rewardItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + rewardItems,
      );
    } else {
      // Если предмета нет - добавляем новый
      newInventory.add(InventoryItem(
        id: 'reward_item',
        quantity: rewardItems,
        name: 'Награда за цель',
        description: 'Получено за установку новой цели XP',
        icon: 'reward_icon',
      ));
    }

    return copyWith(
      dailyGoalXp: newGoal,
      lastGoalChangeDate: () => changeDate,
      inventory: newInventory,
    );
  }

  /// **(ВАШ СТАРЫЙ МЕТОД, ПЕРЕИМЕНОВАН)**
  /// Возвращает новую модель UserModel с обновленным прогрессом по уроку и начисленными XP.
  UserModel withUpdatedLessonProgress({
    required String languageCode,
    required String lessonId,
    required int newProgress,
    int xpEarned = 0,
  }) {
    if (languageSettings == null) return this;

    final langProgress = languageSettings!.learningProgress[languageCode] ??
        UserLanguageProgress(level: 'Beginner');

    final newLessonsCompleted =
        Map<String, int>.from(langProgress.lessonsCompleted);
    newLessonsCompleted[lessonId] = newProgress;

    // Используем copyWith для обновления прогресса языка
    final updatedLangProgress = langProgress.copyWith(
      lessonsCompleted: newLessonsCompleted,
      xp: langProgress.xp + xpEarned,
      dailyXpEarnedToday: langProgress.dailyXpEarnedToday + xpEarned,
    );

    final newLearningProgressMap = Map<String, UserLanguageProgress>.from(
        languageSettings!.learningProgress);
    newLearningProgressMap[languageCode] = updatedLangProgress;

    final newLanguageSettings =
        languageSettings!.copyWith(learningProgress: newLearningProgressMap);

    return copyWith(languageSettings: () => newLanguageSettings);
  }

  /// **(ВАШ СТАРЫЙ МЕТОД, УЛУЧШЕН И ПЕРЕИМЕНОВАН)**
  /// Возвращает новую модель UserModel, где для всех языков сброшен счетчик `dailyXpEarnedToday`.
  UserModel withResetDailyXp() {
    if (languageSettings == null) {
      return this;
    }

    final newLearningProgressMap = Map<String, UserLanguageProgress>.from(
        languageSettings!.learningProgress);

    newLearningProgressMap.updateAll(
      (key, progress) => progress.copyWith(dailyXpEarnedToday: 0),
    );

    final updatedSettings =
        languageSettings!.copyWith(learningProgress: newLearningProgressMap);

    return copyWith(languageSettings: () => updatedSettings);
  }

  /// **(НОВЫЙ МЕТОД)**
  /// Возвращает новую модель UserModel с обновленными XP (без изменения прогресса уроков).
  /// Нужен для чистого начисления XP из StreakService.
  UserModel withUpdatedXp({
    required String forLanguage,
    required int dailyXpToAdd,
    required int totalXpToAdd,
  }) {
    if (languageSettings == null ||
        !languageSettings!.learningProgress.containsKey(forLanguage)) {
      return this;
    }

    final langProgress = languageSettings!.learningProgress[forLanguage]!;

    final updatedProgress = langProgress.copyWith(
      dailyXpEarnedToday: langProgress.dailyXpEarnedToday + dailyXpToAdd,
      xp: langProgress.xp + totalXpToAdd,
    );

    final newLearningProgressMap = Map<String, UserLanguageProgress>.from(
        languageSettings!.learningProgress);
    newLearningProgressMap[forLanguage] = updatedProgress;

    final updatedSettings =
        languageSettings!.copyWith(learningProgress: newLearningProgressMap);

    return copyWith(languageSettings: () => updatedSettings);
  }

  // --- Сохраняем ваши старые методы, но делаем их "обертками" над новыми,
  // --- чтобы не ломать существующий код, который мог их вызывать.

  @Deprecated(
      'Используйте withUpdatedLessonProgress для ясности. Этот метод будет удален.')
  UserModel updateLessonProgress(
      String languageCode, String lessonId, int progress,
      {int xpEarned = 0}) {
    return withUpdatedLessonProgress(
        languageCode: languageCode,
        lessonId: lessonId,
        newProgress: progress,
        xpEarned: xpEarned);
  }

  @Deprecated(
      'Используйте withResetDailyXp, который сбрасывает XP для всех языков. Этот метод будет удален.')
  UserModel resetDailyXp(String languageCode) {
    // Старая логика работала только для одного языка, но для совместимости оставим ее.
    if (languageSettings == null ||
        languageSettings!.learningProgress[languageCode] == null) {
      return this;
    }
    final newLearningProgressMap = Map<String, UserLanguageProgress>.from(
        languageSettings!.learningProgress);
    final langProgress = newLearningProgressMap[languageCode]!;
    newLearningProgressMap[languageCode] =
        langProgress.copyWith(dailyXpEarnedToday: 0);

    return copyWith(
        languageSettings: () => languageSettings!
            .copyWith(learningProgress: newLearningProgressMap));
  }
}
