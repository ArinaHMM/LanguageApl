import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

class AchievementService {
  final UsersCollection _usersCollection = UsersCollection();

  /// Проверяет и выдает достижения, связанные с уроками, после завершения одного из них.
  /// Вызывать в `_handleProgressUpdate` в LearnPage.
  Future<void> checkLessonRelatedAchievements(UserModel user) async {
    // --- 1. Достижение "Первые шаги" ---
    // Проверяем, есть ли у пользователя уже это достижение.
    if (!user.unlockedAchievements.containsKey('first_lesson_completed')) {
      // Это достижение выдается за самый первый пройденный урок в принципе.
      // Считаем общее количество пройденных уроков.
      int totalLessonsCompleted = 0;
      user.languageSettings?.learningProgress.forEach((lang, progress) {
        totalLessonsCompleted += progress.lessonsCompleted.length;
      });

      // Если пройден только один урок, значит, это он и есть.
      if (totalLessonsCompleted == 1) {
        await _unlockAchievement(user.uid, 'first_lesson_completed', 50); // Награда 50 XP
      }
    }

    // --- 2. Достижение "Знаток Английского" (пример) ---
    // Выдается за прохождение 10 уроков английского языка.
    if (!user.unlockedAchievements.containsKey('english_adept_10')) {
      final englishProgress = user.languageSettings?.learningProgress['english'];
      if (englishProgress != null && englishProgress.lessonsCompleted.length >= 10) {
        await _unlockAchievement(user.uid, 'english_adept_10', 100);
      }
    }
  }

  /// Проверяет и выдает достижения, связанные со стриком.
  /// Вызывать ПОСЛЕ обновления стрика (например, в StreakService или после него).
  Future<void> checkStreakAchievements(UserModel user) async {
    final int streak = user.currentStreak;

    // --- 1. Достижение "Недельный марафон" ---
    if (streak >= 7 && !user.unlockedAchievements.containsKey('streak_7_days')) {
      await _unlockAchievement(user.uid, 'streak_7_days', 150);
    }
    
    // --- 2. Достижение "Месяц без пропусков" ---
    if (streak >= 30 && !user.unlockedAchievements.containsKey('streak_30_days')) {
      await _unlockAchievement(user.uid, 'streak_30_days', 500);
    }
  }

  /// Проверяет и выдает достижения, связанные с количеством изучаемых языков.
  /// Вызывать после добавления нового языка для изучения.
  Future<void> checkLanguageAchievements(UserModel user) async {
    final int langCount = user.languageSettings?.learningProgress.length ?? 0;

    // --- 1. Достижение "Полиглот-новичок" ---
    if (langCount >= 2 && !user.unlockedAchievements.containsKey('poliglot_starter')) {
      await _unlockAchievement(user.uid, 'poliglot_starter', 100);
    }
    
    // --- 2. Достижение "Истинный полиглот" ---
    if (langCount >= 4 && !user.unlockedAchievements.containsKey('true_poliglot')) {
      await _unlockAchievement(user.uid, 'true_poliglot', 300);
    }
  }

  /// Приватный метод для записи нового достижения в Firestore и начисления награды.
  Future<void> _unlockAchievement(String userId, String achievementId, int xpReward) async {
    print("Attempting to unlock achievement '$achievementId' for user $userId...");
    
    try {
      // Используем метод из UsersCollection для чистоты кода.
      // Этот метод просто добавляет запись в карту достижений.
      await _usersCollection.unlockAchievement(userId, achievementId);

      // Если за достижение есть награда в XP, начисляем ее.
      if (xpReward > 0) {
        await _usersCollection.updateUserCollection(userId, {
          'totalXp': FieldValue.increment(xpReward),
          // Можно начислять и в недельный XP, если это соответствует вашей логике
          'weeklyXp': FieldValue.increment(xpReward),
        });
        print("Awarded $xpReward XP for achievement '$achievementId'.");
      }
      
      // Здесь можно будет добавить логику отправки Push-уведомления
      // или выдачи предмета в инвентарь.
      
    } catch (e) {
      print("Error in _unlockAchievement service: $e");
    }
  }
}