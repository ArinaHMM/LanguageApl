import 'dart:math'; // Для генерации случайных чисел
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart'; // Для работы с инвентарем
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UsersCollection _usersCollection = UsersCollection();

  /// Проверяет и обновляет стрик при загрузке. Также сбрасывает дневной XP.
  Future<UserModel> checkAndUpdateStreakOnLoad(UserModel currentUserData) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckDate = currentUserData.lastStreakCheckDate?.toDate();

    if (lastCheckDate != null && _isSameDay(lastCheckDate, today)) {
      return currentUserData; // Проверка уже была сегодня, выходим.
    }

    print("StreakService: Новый день! Запускаем ежедневную проверку.");

    UserModel updatedUserData = currentUserData;
    final Map<String, dynamic> fieldsToUpdate = {};
    bool modelNeedsUpdate = false;

    // 1. Сброс дневного XP
    if (updatedUserData.languageSettings?.learningProgress.values.any((p) => p.dailyXpEarnedToday > 0) ?? false) {
      print("StreakService: Сбрасываем вчерашний XP.");
      updatedUserData = updatedUserData.withResetDailyXp();
      fieldsToUpdate['languageSettings'] = updatedUserData.languageSettings!.toMap();
      modelNeedsUpdate = true;
    }

    // 2. Проверка стрика
    final lastGoalCompletion = currentUserData.lastGoalCompletionDate?.toDate();
    if (lastGoalCompletion != null) {
      final daysDifference = today.difference(DateTime(lastGoalCompletion.year, lastGoalCompletion.month, lastGoalCompletion.day)).inDays;
      if (daysDifference > 1) {
        // Если есть заморозки, используем одну
        // (Предполагаем, что поле streakFreezes уже есть в UserModel)
        if (updatedUserData.streakFreezes > 0) {
          final newFreezeCount = updatedUserData.streakFreezes - 1;
          final yesterday = today.subtract(const Duration(days: 1));
          updatedUserData = updatedUserData.copyWith(
            streakFreezes: newFreezeCount,
            lastGoalCompletionDate: () => Timestamp.fromDate(yesterday),
          );
          fieldsToUpdate['streakFreezes'] = newFreezeCount;
          fieldsToUpdate['lastGoalCompletionDate'] = Timestamp.fromDate(yesterday);
          print("StreakService: Использована заморозка. Осталось: $newFreezeCount.");
        } else { // Иначе сбрасываем стрик
          updatedUserData = updatedUserData.copyWith(currentStreak: 0);
          fieldsToUpdate['currentStreak'] = 0;
          print("StreakService: Стрик сброшен до 0.");
        }
        modelNeedsUpdate = true;
      }
    }
    
    // 3. Обновление даты проверки и запись в Firestore
    updatedUserData = updatedUserData.copyWith(lastStreakCheckDate: () => Timestamp.fromDate(today));
    fieldsToUpdate['lastStreakCheckDate'] = Timestamp.fromDate(today);

    if (modelNeedsUpdate || fieldsToUpdate.length > 1) {
      await _firestore.collection('users').doc(currentUserData.uid).update(fieldsToUpdate);
      print("StreakService: Данные пользователя (${currentUserData.uid}) обновлены.");
    }
    
    return updatedUserData;
  }

  /// Обновляет XP, проверяет дневную цель, обновляет стрик и ВЫДАЕТ НАГРАДУ.
  Future<UserModel?> updateUserXpAndCheckGoal({
    required String userId,
    required UserModel currentUserData,
    required int xpEarned,
    required String forLanguageCode,
  }) async {
    if (xpEarned <= 0) return null;

    final langProgress = currentUserData.languageSettings?.learningProgress[forLanguageCode];
    if (langProgress == null) {
      print("StreakService: Ошибка - нет прогресса для языка '$forLanguageCode'.");
      return null;
    }

    final int xpBefore = langProgress.dailyXpEarnedToday;
    final int newDailyXp = xpBefore + xpEarned;
    final int dailyGoal = currentUserData.dailyGoalXp;

    final bool goalAlreadyMet = xpBefore >= dailyGoal;
    final bool goalAchievedNow = !goalAlreadyMet && (newDailyXp >= dailyGoal);

    final Map<String, dynamic> fieldsToUpdate = {};
    
    // 1. Обновляем все счетчики XP
    fieldsToUpdate['languageSettings.learningProgress.$forLanguageCode.xp'] = FieldValue.increment(xpEarned);
    fieldsToUpdate['languageSettings.learningProgress.$forLanguageCode.dailyXpEarnedToday'] = FieldValue.increment(xpEarned);
    fieldsToUpdate['totalXp'] = FieldValue.increment(xpEarned);
    fieldsToUpdate['weeklyXp'] = FieldValue.increment(xpEarned);

    int newStreakValue = currentUserData.currentStreak;
    InventoryItem? awardedItem; // Переменная для хранения выданной награды

    // 2. Если цель достигнута ИМЕННО СЕЙЧАС
    if (goalAchievedNow) {
      print("StreakService: Дневная цель достигнута!");
      
      // 2.1 Выдаем награду
      awardedItem = _getDailyGoalReward();
      // Вызываем метод для добавления предмета в инвентарь (асинхронно, не блокируем основной поток)
      _usersCollection.addItemToInventory(userId, awardedItem).catchError((e) {
        print("Ошибка при добавлении предмета в инвентарь: $e");
      });
      print("StreakService: Пользователю ${userId} выдан предмет: ${awardedItem.name}");

      // 2.2 Обновляем стрик
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCompletion = currentUserData.lastGoalCompletionDate?.toDate();
      
      if (lastCompletion != null) {
        final daysDifference = today.difference(DateTime(lastCompletion.year, lastCompletion.month, lastCompletion.day)).inDays;
        if (daysDifference == 1) newStreakValue++;
        else if (daysDifference > 1) newStreakValue = 1;
      } else {
        newStreakValue = 1;
      }
      
      print("StreakService: Новый стрик: $newStreakValue.");
      fieldsToUpdate['currentStreak'] = newStreakValue;
      fieldsToUpdate['lastGoalCompletionDate'] = Timestamp.fromDate(today);
    }
    
    // 3. Обновляем все поля в Firestore одним запросом
    await _firestore.collection('users').doc(userId).update(fieldsToUpdate);
    
    // 4. Возвращаем локально обновленную модель
    UserModel updatedModel = currentUserData.withUpdatedXp(
      forLanguage: forLanguageCode, 
      dailyXpToAdd: xpEarned, 
      totalXpToAdd: xpEarned
    ).copyWith(
      weeklyXp: currentUserData.weeklyXp + xpEarned,
      totalXp: currentUserData.totalXp + xpEarned,
    );

    if (goalAchievedNow) {
      updatedModel = updatedModel.copyWith(
        currentStreak: newStreakValue,
        lastGoalCompletionDate: () => Timestamp.now(),
        // Добавляем информацию о награде во временное поле для UI
        awardedItemForUI: awardedItem, 
      );
    }
    
    return updatedModel;
  }

  /// Приватный метод, который определяет, какой предмет выдать в качестве награды.
  InventoryItem _getDailyGoalReward() {
    final random = Random();
    final chance = random.nextInt(100); // Случайное число от 0 до 99

    if (chance < 50) { // 20% шанс на зелье опыта
      return InventoryItem(
        id: 'double_xp_potion_15min',
        quantity: 1,
        name: 'Зелье двойного опыта (15 мин)',
        description: 'Удваивает весь получаемый опыт в течение 15 минут после активации.',
        icon: 'double_xp_icon',
      );
    } else { // 80% шанс на заморозку
      return InventoryItem(
        id: 'streak_freeze',
        quantity: 1,
        name: 'Заморозка стрика',
        description: 'Спасает ваш ударный режим, если вы пропустили один день.',
        icon: 'streak_freeze_icon',
      );
    }
  }

  /// Вспомогательный метод для проверки, что две даты приходятся на один и тот же день.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}