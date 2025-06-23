// lib/pages/LearnPage.dart
// ignore_for_file: unnecessary_null_comparison, file_names

import 'dart:async';
import 'dart:math' as math; // Для min и Transform.rotate
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/lessons_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/models/StreakService.dart';
import 'package:flutter_languageapplicationmycourse_2/models/app_data.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/models/audiolessons_service.dart';
import 'package:flutter_languageapplicationmycourse_2/models/voice_model.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/AchievementsPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/SpeakingPracticePage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/audioplayerpage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/lesson_player_page.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/InventoryPage.dart';
import 'package:flutter_languageapplicationmycourse_2/widget/language_selector_widget.dart';
import 'package:toast/toast.dart'; // Вы используете этот пакет

class LearnPage extends StatefulWidget {
  const LearnPage({Key? key}) : super(key: key);

  @override
  _LearnPageState createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> with TickerProviderStateMixin {
  final UsersCollection _usersCollection = UsersCollection();
  final LessonsCollection _lessonsCollection = LessonsCollection();
  final AudioWordBankLessonsService _audioWordBankService =
      AudioWordBankLessonsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreakService _streakService = StreakService();
  UserModel? _currentUserData;
  String _currentLearningLanguage = 'english'; // Язык по умолчанию
  List<Lesson> _allLessonsForCurrentLanguage = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentStreak = 0;
  // ignore: unused_field
  int _streakFreezes = 0;
// Для отображения прогресса дневной цели
  int _dailyXpEarnedToday = 0;
  int _dailyGoalXp = 50; // Будет загружаться из _currentUserData
  int _lives = 5;
  Timer? _lifeRestoreTimer;
  final ValueNotifier<int> _remainingTimeForLifeNotifier =
      ValueNotifier<int>(0);
  bool _isAdmin = false;

  final Color primaryOrange = const Color(0xFFFFA726);
  final Color accentYellow = const Color(0xFFFFE082);
  final Color darkOrange = const Color(0xFFF57C00);
  final Color textOnOrange = Colors.white;
  final Color textOnWhite = const Color(0xFF3A3A3A);
  final Color subtleShadow = Colors.black.withOpacity(0.12);

  final List<String> _levelOrder = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Upper Intermediate',
    'Advanced'
  ];
  late final Map<String, Color> _levelColors;
  late final Map<String, IconData> _levelIcons;

  late AnimationController _pageFadeController;
  late Animation<double> _pageFadeAnimation;
  late List<AnimationController> _sectionAppearControllers;
  late List<Animation<double>> _sectionAppearAnimations;

  int _bottomNavSelectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _levelColors = {
      'Beginner': const Color.fromARGB(255, 226, 178, 33),
      'Elementary': const Color.fromARGB(255, 209, 133, 18),
      'Intermediate': primaryOrange, // Используем наш основной оранжевый
      'Upper Intermediate': const Color.fromARGB(255, 194, 83, 49),
      'Advanced': const Color.fromARGB(255, 156, 37, 35),
      'Прочее': const Color.fromARGB(255, 138, 151, 158),
    };

    _levelIcons = {
      'Beginner': Icons.emoji_people_rounded,
      'Elementary': Icons.school_rounded,
      'Intermediate': Icons.auto_stories_rounded,
      'Upper Intermediate': Icons.menu_book_rounded,
      'Advanced': Icons.military_tech_rounded,
      'Прочее': Icons.explore_rounded,
      'speaking_pronunciation': Icons.record_voice_over_rounded,
    };

    _pageFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageFadeAnimation =
        CurvedAnimation(parent: _pageFadeController, curve: Curves.easeInOut);

    _sectionAppearControllers = []; // Инициализируем как пустой список
    _sectionAppearAnimations = [];
    _initializePageAndStreak();
  }

  void _updateLocalStateWithUserModel(UserModel userData) {
    if (!mounted) return;

    setState(() {
      _currentUserData = userData;
      _currentLearningLanguage =
          userData.languageSettings!.currentLearningLanguage;
      _lives = userData.lives;
      _isAdmin = userData.email == 'admin@mail.ru';
      _currentStreak = userData.currentStreak;
      _streakFreezes = userData.streakFreezes;
      _dailyGoalXp = userData.dailyGoalXp;
      _dailyXpEarnedToday = userData
              .languageSettings
              ?.learningProgress[_currentLearningLanguage]
              ?.dailyXpEarnedToday ??
          0;
    });
  }

  Future<void> _initializePageAndStreak() async {
    await _initializePage();
    _buildStreakIndicator(); // Ваш существующий метод

    // Затем, если данные пользователя загружены, проверяем и обновляем стрик
    if (_currentUserData != null && mounted) {
      final userAfterStreakCheck =
          await _streakService.checkAndUpdateStreakOnLoad(
        _currentUserData!,
      );
      _updateLocalStateWithUserModel(userAfterStreakCheck);
      if (userAfterStreakCheck != null && mounted) {
        setState(() {
          _currentUserData = userAfterStreakCheck;
          _currentStreak = _currentUserData!.currentStreak;
          _streakFreezes = _currentUserData!.streakFreezes;
          _dailyGoalXp = _currentUserData!.dailyGoalXp;
          _dailyXpEarnedToday = _currentUserData!
                  .languageSettings
                  ?.learningProgress[_currentLearningLanguage]
                  ?.dailyXpEarnedToday ??
              0;
        });
      } else if (mounted && _currentUserData != null) {
        // Добавил проверку _currentUserData != null
        _dailyXpEarnedToday = _currentUserData!
                .languageSettings
                ?.learningProgress[_currentLearningLanguage]
                ?.dailyXpEarnedToday ??
            0;
        // Если dailyXpEarnedToday изменился (например, был сброшен сервисом),
        // то нужно вызвать setState, чтобы UI обновился.
        // Но если он не изменился, лишний setState не нужен.
        // Для простоты можно оставить setState, или добавить проверку.
        if (mounted) setState(() {});
      }
    }
  }

  void _initSectionAnimations(int count) {
    // Dispose old controllers before creating new ones
    for (var controller in _sectionAppearControllers) {
      controller.dispose();
    }
    _sectionAppearControllers = List.generate(
        count,
        (index) => AnimationController(
            duration: const Duration(milliseconds: 450), vsync: this));
    _sectionAppearAnimations = _sectionAppearControllers
        .map((controller) => CurvedAnimation(
                parent: controller,
                curve: Curves
                    .easeOutBack) // easeOutBack для "выпрыгивающего" эффекта
            )
        .toList();
  }

  void _playSectionAnimations() {
    for (int i = 0; i < _sectionAppearControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        // Немного уменьшил задержку
        if (mounted &&
            i < _sectionAppearControllers.length &&
            !_sectionAppearControllers[i].isAnimating) {
          _sectionAppearControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _lifeRestoreTimer?.cancel();
    _remainingTimeForLifeNotifier.dispose();
    _pageFadeController.dispose();
    _sectionAppearControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _initializePage({bool isLanguageChange = false}) async {
    if (!mounted) return;
    if (!isLanguageChange) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    _pageFadeController.reset();
    for (var controller in _sectionAppearControllers) {
      controller.reset();
    }

    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _handleUnauthenticatedUser();
      if (!isLanguageChange && mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      UserModel? userData =
          await _usersCollection.getUserModel(firebaseUser.uid);
      if (!mounted) return;
      if (userData == null ||
          userData.languageSettings == null ||
          !userData.languageSettings!.learningProgress.containsKey(
              userData.languageSettings!.currentLearningLanguage)) {
        _handleMissingLanguageSettings();
        if (!isLanguageChange && mounted) setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _currentUserData = userData;
        _currentLearningLanguage =
            _currentUserData!.languageSettings!.currentLearningLanguage;
        _lives = _currentUserData!.lives;
        _isAdmin = _currentUserData!.email == 'admin@mail.ru';
        _currentStreak = _currentUserData!.currentStreak;
        _streakFreezes = _currentUserData!.streakFreezes;
        _dailyGoalXp = _currentUserData!.dailyGoalXp;
        _dailyXpEarnedToday = _currentUserData!
                .languageSettings
                ?.learningProgress[_currentLearningLanguage]
                ?.dailyXpEarnedToday ??
            0;
        if (isLanguageChange) _allLessonsForCurrentLanguage = [];
      });

      _initializeLifeTimer(
          _currentUserData!.lives, _currentUserData!.lastRestored);
      await _fetchLessonsForCurrentLanguage();

      if (mounted) {
        final levelsToDisplay = _getLevelsToDisplay(_groupLessonsByLevel());
        _initSectionAnimations(
            levelsToDisplay.length); // Инициализируем ДО setState

        setState(() {
          _isLoading = false;
        });
        _pageFadeController.forward();
        _playSectionAnimations(); // Запускаем анимации секций
      }
    } catch (e, s) {
      print(
          "--- LearnPage: _initializePage - КРИТИЧЕСКАЯ ОШИБКА: $e\nStack: $s ---");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Ошибка загрузки данных. Пожалуйста, попробуйте позже.";
          _isLoading = false;
        });
      }
    }
  }

  void _handleUnauthenticatedUser() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    });
  }

  void _handleMissingLanguageSettings() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(
            context, '/selectLanguage', (route) => false);
    });
  }

  Future<void> _fetchLessonsForCurrentLanguage() async {
    if (_currentUserData == null || !mounted) return;
    List<Lesson> fetchedLessons = [];
    try {
      final standardLessonCollections = [
        'interactiveLessons',
        'addlessons',
        'upperlessons',
        'audiolessons',
        'videolessons',
        'advancedlessons',
        'upperinterlessons',
        'upperupinterlessons',
        'voice_lessons'
      ];
      for (String collectionName in standardLessonCollections) {
        try {
          List<Lesson> lessonsFromStdCollection = await _lessonsCollection
              .getLessons(collectionName, _currentLearningLanguage);
          fetchedLessons.addAll(lessonsFromStdCollection);
        } catch (e) {
          print(
              "Error fetching from standard collection '$collectionName' for $_currentLearningLanguage: $e");
        }
      }
      try {
        List<Lesson> audioWordBankLessons = await _audioWordBankService
            .getAudioWordBankLessons(_currentLearningLanguage);
        fetchedLessons.addAll(audioWordBankLessons);
      } catch (e) {
        print(
            "Error fetching from AudioWordBankService for $_currentLearningLanguage: $e");
      }

      fetchedLessons.sort((a, b) => (a.orderIndex).compareTo(b.orderIndex));
      if (mounted) {
        setState(() {
          _allLessonsForCurrentLanguage = fetchedLessons;
        });
      }
    } catch (e, s) {
      print(
          "Error in _fetchLessonsForCurrentLanguage for $_currentLearningLanguage: $e\nStack: $s");
      if (mounted)
        setState(() {
          _errorMessage = "Не удалось загрузить список уроков.";
        });
    }
  }

  void _initializeLifeTimer(int currentLives, Timestamp lastRestored) {
    _lifeRestoreTimer?.cancel();
    if (!mounted) return;
    DateTime lastRestoredTime = lastRestored.toDate();
    const Duration lifeRestoreInterval = Duration(minutes: 5);
    if (currentLives < 5) {
      DateTime nextRestoreTime = lastRestoredTime.add(lifeRestoreInterval);
      int secondsToNextRestore =
          nextRestoreTime.difference(DateTime.now()).inSeconds;
      if (secondsToNextRestore <= 0) {
        _handleInstantRestore();
      } else {
        _remainingTimeForLifeNotifier.value = secondsToNextRestore;
        _lifeRestoreTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_remainingTimeForLifeNotifier.value > 0) {
            _remainingTimeForLifeNotifier.value--;
          } else {
            timer.cancel();
            _restoreLife();
          }
        });
      }
    } else {
      _remainingTimeForLifeNotifier.value = 0;
    }
  }

  Future<void> _handleInstantRestore() async {
    if (_currentUserData == null || !mounted) return;
    DateTime lastRestoredTime = _currentUserData!.lastRestored.toDate();
    const Duration lifeRestoreInterval = Duration(minutes: 5);
    int totalMinutesPassed =
        DateTime.now().difference(lastRestoredTime).inMinutes;
    int livesToPotentiallyRestore =
        totalMinutesPassed ~/ lifeRestoreInterval.inMinutes;
    if (livesToPotentiallyRestore > 0 && _currentUserData!.lives < 5) {
      int currentLivesInDb = _currentUserData!.lives;
      int newLivesValue =
          (currentLivesInDb + livesToPotentiallyRestore).clamp(0, 5);
      if (newLivesValue > currentLivesInDb) {
        Timestamp newLastRestoredTimestamp = Timestamp.fromDate(lastRestoredTime
            .add(lifeRestoreInterval * (newLivesValue - currentLivesInDb)));
        if (newLivesValue == 5) newLastRestoredTimestamp = Timestamp.now();
        await _usersCollection.updateUserCollection(_currentUserData!.uid,
            {'lives': newLivesValue, 'lastRestored': newLastRestoredTimestamp});
        if (mounted) {
          _lives = newLivesValue;
          _currentUserData = _currentUserData!.copyWith(
              lives: newLivesValue, lastRestored: newLastRestoredTimestamp);
          setState(() {});
        }
        _initializeLifeTimer(newLivesValue, newLastRestoredTimestamp);
      } else {
        _initializeLifeTimer(
            _currentUserData!.lives, _currentUserData!.lastRestored);
      }
    } else {
      _initializeLifeTimer(
          _currentUserData!.lives, _currentUserData!.lastRestored);
    }
  }

  Future<void> _restoreLife() async {
    if (_currentUserData == null || _lives >= 5 || !mounted) return;
    int newLivesValue = _lives + 1;
    Timestamp newLastRestored = Timestamp.now();
    await _usersCollection.updateUserCollection(_currentUserData!.uid,
        {'lives': newLivesValue, 'lastRestored': newLastRestored});
    if (mounted) {
      _lives = newLivesValue;
      _currentUserData = _currentUserData!
          .copyWith(lives: newLivesValue, lastRestored: newLastRestored);
      setState(() {});
      _initializeLifeTimer(newLivesValue, newLastRestored);
    }
  }

  Future<bool> _deductLife() async {
    if (!mounted || _currentUserData == null) return false;
    if (_lives <= 0) {
      Toast.show("Недостаточно жизней!",
          duration: Toast.lengthShort, gravity: Toast.center);
      return false;
    }
    int newLivesValue = _lives - 1;
    Timestamp timeOfDeduction = Timestamp.now();
    bool success = false;
    try {
      Map<String, dynamic> updateData = {'lives': newLivesValue};
      bool shouldUpdateLastRestored =
          (_currentUserData!.lives == 5 && newLivesValue < 5);
      if (shouldUpdateLastRestored)
        updateData['lastRestored'] = timeOfDeduction;
      await _usersCollection.updateUserCollection(
          _currentUserData!.uid, updateData);
      if (mounted) {
        _lives = newLivesValue;
        _currentUserData = _currentUserData!.copyWith(
            lives: newLivesValue,
            lastRestored: shouldUpdateLastRestored
                ? timeOfDeduction
                : _currentUserData!.lastRestored);
        setState(() {});
        _initializeLifeTimer(newLivesValue, _currentUserData!.lastRestored);
      }
      success = true;
    } catch (e) {
      print("Error deducting life: $e");
      if (mounted)
        Toast.show("Ошибка при списании жизни.",
            duration: Toast.lengthShort, gravity: Toast.center);
    }
    return success;
  }

  Future<void> _onLanguageChanged(String newLanguageCode) async {
    if (_currentUserData == null ||
        newLanguageCode == _currentLearningLanguage ||
        !mounted) return;
    if (mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              Center(child: CircularProgressIndicator(color: primaryOrange)));
    }
    try {
      await _usersCollection.updateUserCollection(_currentUserData!.uid,
          {'languageSettings.currentLearningLanguage': newLanguageCode});
      await _initializePage(isLanguageChange: true);
    } catch (e, s) {
      print("Error changing language: $e\nStack: $s");
      if (mounted)
        Toast.show("Ошибка смены языка", duration: Toast.lengthShort);
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _navigateToLesson(Lesson lesson) async {
    if (!mounted) return;
    final BuildContext currentNavContext =
        context; // Используем другое имя для ясности
    bool dialogShown = false;

    // 1. Показываем индикатор загрузки (если нужно перед списанием жизней)
    if (mounted) {
      try {
        showDialog(
            context: currentNavContext,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) =>
                Center(child: CircularProgressIndicator(color: primaryOrange)));
        dialogShown = true;
      } catch (e) {
        print("Error showing loading dialog: $e");
      }
    }

    // 2. Списываем жизнь
    bool canProceed = await _deductLife();

    // 3. Закрываем диалог загрузки
    if (dialogShown && mounted && Navigator.canPop(currentNavContext)) {
      try {
        Navigator.pop(currentNavContext);
      } catch (e) {
        print("Error popping loading dialog: $e");
      }
    }

    // 4. Проверяем, можно ли продолжать (есть ли жизни)
    if (!mounted || !canProceed) {
      // _deductLife уже должен был показать Toast, если жизней нет
      return;
    }

    // 5. Определяем, какую страницу урока открыть
    Widget? lessonViewerPage; // Используем nullable тип

    print(
        "LearnPage: Navigating to lesson ID: ${lesson.id}, Type='${lesson.lessonType}', Collection='${lesson.collectionName}'");

    if (lesson.lessonType == 'speaking_pronunciation') {
      // --- ЛОГИКА ДЛЯ УПРАЖНЕНИЙ НА ГОВОРЕНИЕ ---
      if (lesson.textToSpeak == null || lesson.textToSpeak!.isEmpty) {
        print(
            "Error: textToSpeak is missing for speaking exercise ${lesson.id}");
        if (mounted)
          Toast.show("Ошибка данных урока: отсутствует текст для произношения.",
              duration: Toast.lengthLong, gravity: Toast.center);
        return; // Не переходим, если нет текста
      }

      final speakingExercise = SpeakingExercise(
        id: lesson.id,
        type: lesson.lessonType,
        targetLanguage: lesson.targetLanguage,
        level: lesson.requiredLevel,
        textToSpeak: lesson.textToSpeak!,
        audioUrlExample: lesson.audioUrlExample,
        title: lesson.title,
        orderIndex: lesson.orderIndex,
        createdAt: lesson.createdAt,
        isPublished: true,
      );

      lessonViewerPage = SpeakingPracticePage(
        exercise: speakingExercise,
        onNext: () {
          print(
              "Speaking exercise '${lesson.title}' (ID: ${lesson.id}) 'Next' pressed by user.");
          if (Navigator.canPop(currentNavContext)) {
            Navigator.pop(currentNavContext);
          }
          _handleProgressUpdate(lesson.id, 100); // Помечаем как пройденное
        },
      );
    } else if (lesson.lessonType == 'audioWordBankSentence' ||
        (lesson.collectionName == _audioWordBankService.collectionName &&
            _audioWordBankService.collectionName.isNotEmpty)) {
      // Добавил проверку, что collectionName не пустой
      // --- ВАША СУЩЕСТВУЮЩАЯ ЛОГИКА ДЛЯ AudioWordBank ---
      lessonViewerPage = LessonPlayerAudioPage(
          lesson: lesson, onProgressUpdated: _handleProgressUpdate);
    } else if (lesson.exercises.isNotEmpty ||
        lesson.lessonType == 'interactive' ||
        lesson.lessonType == 'chooseTranslation') {
      // Расширил условие для стандартных уроков
      // --- ВАША СУЩЕСТВУЮЩАЯ ЛОГИКА ДЛЯ ОБЫЧНЫХ УРОКОВ ---
      // (Предполагаем, что LessonPlayerPage обрабатывает уроки с exercises или известные типы)
      lessonViewerPage = LessonPlayerPage(
          lesson: lesson, onProgressUpdated: _handleProgressUpdate);
    } else {
      // Если тип урока не определен или для него нет обработчика
      print(
          "LearnPage: Unhandled lesson type: '${lesson.lessonType}' for lesson '${lesson.title}' (ID: ${lesson.id}).");
      if (mounted)
        Toast.show("Невозможно открыть урок данного типа.",
            duration: Toast.lengthLong, gravity: Toast.center);
      return;
    }

    // 6. Выполняем навигацию, если страница урока была создана
    if (lessonViewerPage != null) {
      Future.microtask(() {
        if (mounted) {
          Navigator.push(
                  currentNavContext,
                  MaterialPageRoute(
                      builder: (routeContext) => lessonViewerPage!))
              .then((lessonCompletionResult) {
            // Получаем результат со страницы урока
            if (mounted) {
              print(
                  "Returned from lesson '${lesson.title}' (ID: ${lesson.id}). Result: $lessonCompletionResult");
              _initializePage(isLanguageChange: false); // Обновляем LearnPage
            }
          });
        }
      });
    }
  }

  void _handleProgressUpdate(String lessonId, int newProgress,
      {int xpForThisAction = 10}) async {
    if (_currentUserData == null || !mounted) return;

    // 1. Определяем, нужно ли начислять XP
    final bool shouldEarnXp = newProgress >= 100 &&
        (_currentUserData!
                    .languageSettings
                    ?.learningProgress[_currentLearningLanguage]
                    ?.lessonsCompleted[lessonId] ??
                0) <
            100;

    int xpToAward = shouldEarnXp ? xpForThisAction : 0;
    if (xpToAward > 0 && _currentUserData!.isDoubleXpActive) {
      xpToAward *= 2;
      print("Двойной опыт активен! Будет начислено: $xpToAward XP");
      // Можно показать временный SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("x2 XP! Вы получили $xpToAward очков опыта!"),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    // 2. Обновляем ТОЛЬКО прогресс урока в Firestore. XP пока не трогаем.
    await _usersCollection.updateLessonProgressInUserDoc(
        _currentUserData!.uid, _currentLearningLanguage, lessonId, newProgress);

    // 3. Локально обновляем модель, чтобы передать ее в сервис
    UserModel modelForService = _currentUserData!.withUpdatedLessonProgress(
        languageCode: _currentLearningLanguage,
        lessonId: lessonId,
        newProgress: newProgress);

    // 4. Если XP заработан, вызываем StreakService для начисления и проверки цели
    if (xpToAward > 0) {
      print("LearnPage: Урок пройден, начисляем $xpToAward XP...");

      final userAfterGoalCheck = await _streakService.updateUserXpAndCheckGoal(
        userId: modelForService.uid,
        currentUserData:
            modelForService, // Передаем модель с уже обновленным прогрессом урока
        xpEarned: xpToAward,
        forLanguageCode: _currentLearningLanguage,
      );

      // 5. Применяем финальную, самую свежую модель от сервиса
      if (userAfterGoalCheck != null && mounted) {
        print(
            "LearnPage: Получены обновленные данные от StreakService. XP сегодня: ${userAfterGoalCheck.languageSettings?.learningProgress[_currentLearningLanguage]?.dailyXpEarnedToday}");
        _updateLocalStateWithUserModel(userAfterGoalCheck);
        await AchievementService()
            .checkLessonRelatedAchievements(userAfterGoalCheck);
        if (userAfterGoalCheck.awardedItemForUI != null) {
          _showRewardDialog(userAfterGoalCheck.awardedItemForUI!);
        }
      }
    } else {
      // Если XP не заработан, просто обновляем локальную модель
      if (mounted) _updateLocalStateWithUserModel(modelForService);
    }

    // 6. После всех обновлений проверяем, не пора ли повысить уровень
    await _checkAndAdvanceLevel();
  }

  void _showRewardDialog(InventoryItem awardedItem) {
    // Получаем иконку для предмета
    final IconData itemIcon = AppData.itemIcons[awardedItem.icon] ??
        AppData.itemIcons['default_icon']!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text("Цель достигнута!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Вы получаете награду:", textAlign: TextAlign.center),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryOrange.withOpacity(0.1),
              child: Icon(itemIcon, size: 45, color: primaryOrange),
            ),
            SizedBox(height: 12),
            Text(
              awardedItem.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "+${awardedItem.quantity} в инвентарь",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Отлично!",
                style: TextStyle(
                    color: primaryOrange, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildStreakIndicator() {
    if (_currentUserData == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: _currentStreak > 0
                  ? Colors.orangeAccent.shade700
                  : Colors.grey.shade400,
              size: 22),
          const SizedBox(width: 4),
          Text("$_currentStreak",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _currentStreak > 0
                      ? textOnOrange.withOpacity(0.9)
                      : Colors.grey.shade300)),
          if (_currentUserData!.streakFreezes > 0) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: "Доступно заморозок: ${_currentUserData!.streakFreezes}",
              child: Icon(Icons.ac_unit_rounded,
                  color: Colors.lightBlue.shade200, size: 19),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDailyGoalProgress() {
    if (_currentUserData == null || _dailyGoalXp <= 0)
      return const SizedBox.shrink();
    double progress = (_dailyXpEarnedToday / _dailyGoalXp).clamp(0.0, 1.0);
    bool goalMet = _dailyXpEarnedToday >= _dailyGoalXp;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Дневная цель:",
                style: TextStyle(
                    fontSize: 14, color: textOnOrange.withOpacity(0.85)),
              ),
              Text(
                "$_dailyXpEarnedToday / $_dailyGoalXp XP",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textOnOrange),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: accentYellow.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
                goalMet ? Colors.green.shade400 : primaryOrange),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          if (goalMet)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade300, size: 16),
                  const SizedBox(width: 4),
                  Text("Цель достигнута!",
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade300)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Future<void> _checkAndAdvanceLevel() async {
    if (_currentUserData == null || !mounted) return;
    final UserLanguageSettings? langSettings =
        _currentUserData!.languageSettings;
    if (langSettings == null) return;
    final UserLanguageProgress? langProgress =
        langSettings.learningProgress[_currentLearningLanguage];
    if (langProgress == null) return;
    final String currentUserLevel = langProgress.level;
    if (currentUserLevel == _levelOrder.last) return;
    final lessonsForCurrentUserLevel = _allLessonsForCurrentLanguage
        .where((lesson) =>
            lesson.requiredLevel == currentUserLevel &&
            lesson.targetLanguage == _currentLearningLanguage)
        .toList();
    if (lessonsForCurrentUserLevel.isEmpty) {
      if (currentUserLevel != "" &&
          currentUserLevel.toLowerCase() != "begginer" &&
          currentUserLevel != _levelOrder.first) {
        await _advanceToNextLevel(currentUserLevel);
      }
      return;
    }
    final Map<String, int> userLessonProgress = langProgress.lessonsCompleted;
    bool allLessonsInCurrentLevelCompleted = lessonsForCurrentUserLevel
        .every((lesson) => (userLessonProgress[lesson.id] ?? 0) >= 100);
    if (allLessonsInCurrentLevelCompleted) {
      await _advanceToNextLevel(currentUserLevel);
    }
  }

  Future<void> _advanceToNextLevel(String currentLevel) async {
    if (_currentUserData == null || !mounted) return;

    int currentLevelIndex = _levelOrder.indexOf(currentLevel);

    // Обработка начального состояния или "begginer"
    if (currentLevel.isEmpty || currentLevel.toLowerCase() == "begginer") {
      // Используйте "beginner", если это правильное написание
      currentLevelIndex =
          -1; // Это позволит nextLevel стать первым элементом _levelOrder
    } else if (currentLevelIndex == -1) {
      // Если уровень не пустой, не "begginer", но не найден в _levelOrder
      print(
          "Текущий уровень '$currentLevel' не найден в _levelOrder. Повышение невозможно.");
      return;
    }

    if (currentLevelIndex >= _levelOrder.length - 1) {
      print(
          "Пользователь уже на максимальном уровне (${_levelOrder.last}) или уровень некорректен для повышения.");
      return;
    }

    String nextLevel = _levelOrder[currentLevelIndex + 1];
    print(
        "Advancing user ${_currentUserData!.uid} for language $_currentLearningLanguage from '$currentLevel' (index: $currentLevelIndex) to '$nextLevel'");

    try {
      await _usersCollection.updateUserLevel(
          _currentUserData!.uid, _currentLearningLanguage, nextLevel);

      // Обновляем локальные данные _currentUserData
      UserLanguageSettings? currentLangSettings =
          _currentUserData!.languageSettings;
      UserModel? updatedUserData;

      if (currentLangSettings != null) {
        UserLanguageProgress? currentLangProgress =
            currentLangSettings.learningProgress[_currentLearningLanguage];

        if (currentLangProgress != null) {
          final updatedLangProg =
              currentLangProgress.copyWith(level: nextLevel);
          final newLearningProgressMap = Map<String, UserLanguageProgress>.from(
              currentLangSettings.learningProgress);
          newLearningProgressMap[_currentLearningLanguage] = updatedLangProg;
          final updatedSettings = currentLangSettings.copyWith(
              learningProgress: newLearningProgressMap);

          updatedUserData = _currentUserData!.copyWith(
            languageSettings: () => updatedSettings, // <--- ИСПРАВЛЕНИЕ ЗДЕСЬ
          );
        } else {
          // Если нет прогресса для текущего языка, создаем его с новым уровнем
          print(
              "LearnPage: No learning progress found for $_currentLearningLanguage. Creating new with level $nextLevel.");
          final newLangProgForLevel = UserLanguageProgress(
              level: nextLevel, xp: 0, lessonsCompleted: {});
          final updatedSettings =
              currentLangSettings.copyWith(learningProgress: {
            ...currentLangSettings
                .learningProgress, // Сохраняем прогресс по другим языкам
            _currentLearningLanguage: newLangProgForLevel,
          });
          updatedUserData = _currentUserData!
              .copyWith(languageSettings: () => updatedSettings);
        }
      } else {
        // Если languageSettings вообще null, создаем их с нуля
        print(
            "LearnPage: User languageSettings is null. Creating new settings with level $nextLevel for $_currentLearningLanguage.");
        final newLangProgForLevel =
            UserLanguageProgress(level: nextLevel, xp: 0, lessonsCompleted: {});
        final newOverallSettings = UserLanguageSettings(
            currentLearningLanguage: _currentLearningLanguage,
            interfaceLanguage:
                'russian', // или другой язык интерфейса по умолчанию
            learningProgress: {
              _currentLearningLanguage: newLangProgForLevel,
            });
        updatedUserData = _currentUserData!
            .copyWith(languageSettings: () => newOverallSettings);
      }

      if (mounted && updatedUserData != null) {
        setState(() {
          _currentUserData = updatedUserData;
          // _currentStreak, _lives и т.д. уже должны быть актуальны, если они часть _currentUserData
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              title: Row(children: [
                Icon(Icons.emoji_events_rounded, color: accentYellow, size: 32),
                const SizedBox(width: 12),
                Text("Новый Уровень!",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textOnWhite))
              ]),
              content: Text(
                  "Поздравляем! Вы достигли уровня: $nextLevel по ${_getLanguageDisplayName(_currentLearningLanguage)}!",
                  style: TextStyle(
                      fontSize: 16, color: textOnWhite.withOpacity(0.8))),
              actions: [
                TextButton(
                    child: Text("Продолжить Путь!",
                        style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    onPressed: () => Navigator.pop(context))
              ]),
        );
      }
    } catch (e, s) {
      print("Error advancing user level: $e\nStack: $s");
      if (mounted) {
        Toast.show("Ошибка при повышении уровня.",
            duration: Toast.lengthShort, gravity: Toast.center);
      }
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    if (!_isAdmin || _currentUserData == null || !mounted) return;
    bool confirmDelete = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  title: const Text("Удалить урок?"),
                  content: Text(
                      "Вы уверены, что хотите удалить урок '${lesson.title}' (${lesson.collectionName})? Это действие необратимо."),
                  actions: <Widget>[
                    TextButton(
                        child: const Text("Отмена",
                            style: TextStyle(color: Colors.grey)),
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false)),
                    TextButton(
                        child: Text("Удалить",
                            style: TextStyle(color: Colors.red[700])),
                        onPressed: () => Navigator.of(dialogContext).pop(true)),
                  ],
                )) ??
        false;
    if (confirmDelete) {
      try {
        if (lesson.collectionName == _audioWordBankService.collectionName) {
          await _audioWordBankService.deleteAudioWordBankLesson(lesson.id);
        } else {
          await _lessonsCollection.deleteLessonFromCollection(
              lesson.collectionName, lesson.id);
        }
        if (mounted)
          Toast.show("Урок '${lesson.title}' удален.",
              duration: Toast.lengthShort);
        await _fetchLessonsForCurrentLanguage();
      } catch (e) {
        if (mounted)
          Toast.show("Ошибка удаления урока.", duration: Toast.lengthShort);
        print("Error deleting lesson: $e");
      }
    }
  }
  // Конец ваших существующих методов

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    final currentUser = _currentUserData;
    final langSettings = currentUser?.languageSettings;
    final learningProgressMap = langSettings?.learningProgress;
    bool canShowLanguageSelector = (learningProgressMap?.keys.length ?? 0) > 1;
    List<String> availableLangsForSelector = [];
    if (canShowLanguageSelector && learningProgressMap != null) {
      availableLangsForSelector = learningProgressMap.keys.toList();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                accentYellow.withOpacity(0.7),
                primaryOrange.withOpacity(0.8),
                darkOrange.withOpacity(0.95)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.5, 1.0]),
        ),
        child: Column(
          children: [
            _buildCustomAppBar(
                canShowLanguageSelector, availableLangsForSelector),
            _buildDailyGoalProgress(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // lib/pages/LearnPage.dart -> внутри класса _LearnPageState

  Widget _buildCustomAppBar(
      bool canShowLanguageSelector, List<String> availableLangsForSelector) {
    // ================== НОВАЯ ЛОГИКА ЗДЕСЬ ==================
    // Если идет загрузка, показываем максимально простой AppBar
    if (_isLoading) {
      return Material(
        elevation: 3.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                darkOrange,
                primaryOrange,
                accentYellow.withOpacity(0.8)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Text(
                "LingoQuest",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textOnOrange,
                ),
              ),
            ),
          ),
        ),
      );
    }
    // =======================================================

    // Если загрузка завершена, строим полный AppBar
    return Material(
      elevation: 3.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkOrange, primaryOrange, accentYellow.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // 1. Левая группа
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStreakIndicator(),
                    if (_currentUserData != null &&
                        _currentUserData!.isDoubleXpActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Tooltip(
                          message: "Двойной опыт активен!",
                          child: Icon(
                            Icons.flash_on_rounded,
                            color: Colors.yellow.shade600,
                            size: 26,
                            shadows: const [
                              Shadow(color: Colors.black38, blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // 2. Центральный элемент
                Expanded(
                  child: Center(
                    child: Text(
                      _getLanguageDisplayName(_currentLearningLanguage),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textOnOrange,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // 3. Правая группа
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canShowLanguageSelector)
                      SizedBox(
                        width: 130,
                        child: LanguageSelectorWidget(
                          availableLanguages: availableLangsForSelector,
                          currentLanguageCode: _currentLearningLanguage,
                          onLanguageSelected: _onLanguageChanged,
                        ),
                      )
                    else if (_currentUserData != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                            _getLanguageDisplayName(_currentLearningLanguage,
                                short: true),
                            style: TextStyle(
                                color: textOnOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                    if (_currentUserData != null) _buildLivesIndicator(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivesIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded,
              color: Colors.redAccent.shade100, size: 22), // Ярче сердце
          const SizedBox(width: 6),
          Text("$_lives",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textOnOrange)),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: _remainingTimeForLifeNotifier,
            builder: (context, timeLeft, child) {
              if (_lives >= 5 || timeLeft <= 0) return const SizedBox.shrink();
              final minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
              final seconds = (timeLeft % 60).toString().padLeft(2, '0');
              return Text("$minutes:$seconds",
                  style: TextStyle(
                      fontSize: 13, color: textOnOrange.withOpacity(0.9)));
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String code, {bool short = false}) {
    if (code.isEmpty) return short ? "??" : "Язык не выбран";
    if (short) {
      switch (code.toLowerCase()) {
        case 'english':
          return 'EN';
        case 'spanish':
          return 'ES';
        case 'german':
          return 'DE';
        default:
          return code.toUpperCase().substring(0, math.min(2, code.length));
      }
    } else {
      switch (code.toLowerCase()) {
        case 'english':
          return 'Английский';
        case 'spanish':
          return 'Испанский';
        case 'german':
          return 'Немецкий';
        default:
          return code[0].toUpperCase() + code.substring(1);
      }
    }
  }

  Map<String, List<Lesson>> _groupLessonsByLevel() {
    Map<String, List<Lesson>> lessonsByLevelMap = {};
    for (var lesson in _allLessonsForCurrentLanguage) {
      String levelKey = _levelOrder.contains(lesson.requiredLevel)
          ? lesson.requiredLevel
          : 'Прочее';
      lessonsByLevelMap.putIfAbsent(levelKey, () => []).add(lesson);
    }
    return lessonsByLevelMap;
  }

  List<String> _getLevelsToDisplay(
      Map<String, List<Lesson>> lessonsByLevelMap) {
    List<String> levelsToDisplay = List.from(_levelOrder);
    if (lessonsByLevelMap.containsKey('Прочее') &&
        (lessonsByLevelMap['Прочее']?.isNotEmpty ?? false)) {
      if (!levelsToDisplay.contains('Прочее')) {
        levelsToDisplay.add('Прочее');
      }
    }
    return levelsToDisplay;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
          child:
              CircularProgressIndicator(color: accentYellow, strokeWidth: 4));
    }
    if (_errorMessage != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_very_dissatisfied_rounded,
                        color: Colors.white.withOpacity(0.7), size: 80),
                    const SizedBox(height: 20),
                    Text(_errorMessage!,
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      label: const Text("Попробовать снова",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      onPressed: () => _initializePage(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    )
                  ])));
    }
    if (_currentUserData == null) {
      return const Center(
          child: Text("Нет данных пользователя.",
              style: TextStyle(fontSize: 16, color: Colors.white70)));
    }

    final lessonsByLevelMap = _groupLessonsByLevel();
    final levelsToDisplay = _getLevelsToDisplay(lessonsByLevelMap);
    final String userCurrentLevel = _currentUserData!.languageSettings
            ?.learningProgress[_currentLearningLanguage]?.level ??
        '';
    final Map<String, int> userLessonProgress = _currentUserData!
            .languageSettings
            ?.learningProgress[_currentLearningLanguage]
            ?.lessonsCompleted ??
        {};

    List<Widget> adventurePathWidgets = [];
    bool previousLevelConsideredUnlocked = true;

    for (int i = 0; i < levelsToDisplay.length; i++) {
      String levelName = levelsToDisplay[i];
      final lessonsInThisLevel = lessonsByLevelMap[levelName] ?? [];
      bool isLevelGloballyAccessibleByUser =
          _isLevelEffectivelyAccessible(userCurrentLevel, levelName);
      bool currentSectionEffectivelyUnlocked =
          isLevelGloballyAccessibleByUser && previousLevelConsideredUnlocked;

      Widget sectionWidget = _AdventureLevelSection(
        levelName: levelName, lessons: lessonsInThisLevel,
        userLevel: userCurrentLevel,
        userLessonProgress: userLessonProgress,
        isEffectivelyUnlocked: currentSectionEffectivelyUnlocked,
        onLessonTap: _navigateToLesson, isAdmin: _isAdmin,
        onDeleteLesson: _deleteLesson,
        levelColor: _levelColors[levelName] ?? accentYellow, // Цвет уровня
        levelIcon: _levelIcons[levelName] ?? Icons.flag_circle_rounded,
      );

      if (i < _sectionAppearAnimations.length) {
        // Проверяем, что анимация для этой секции существует
        sectionWidget = ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0)
              .animate(_sectionAppearAnimations[i]),
          child: FadeTransition(
              opacity: _sectionAppearAnimations[i], child: sectionWidget),
        );
      }
      adventurePathWidgets.add(sectionWidget);

      if (currentSectionEffectivelyUnlocked && lessonsInThisLevel.isNotEmpty) {
        previousLevelConsideredUnlocked = lessonsInThisLevel
            .every((l) => (userLessonProgress[l.id] ?? 0) >= 100);
      } else if (!currentSectionEffectivelyUnlocked) {
        previousLevelConsideredUnlocked = false;
      }

      if (i < levelsToDisplay.length - 1) {
        String nextLevelNameInDisplay = levelsToDisplay[i + 1];
        bool isNextLevelTheoreticallyAccessible = _isLevelEffectivelyAccessible(
            userCurrentLevel, nextLevelNameInDisplay);
        adventurePathWidgets.add(_PathConnector(
          isUnlocked: previousLevelConsideredUnlocked &&
              isNextLevelTheoreticallyAccessible,
          color: _levelColors[nextLevelNameInDisplay] ?? darkOrange,
        ));
      }
    }

    if (adventurePathWidgets.whereType<_AdventureLevelSection>().isEmpty &&
        !_isLoading) {
      adventurePathWidgets.add(Center(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 90, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 20),
                    Text(
                        "Уроки для '${_getLanguageDisplayName(_currentLearningLanguage)}' в разработке!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            color: textOnOrange.withOpacity(0.8),
                            fontWeight: FontWeight.w500)),
                  ]))));
    }

    return FadeTransition(
      opacity: _pageFadeAnimation,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12.0, 15.0, 12.0, 80.0),
        children: adventurePathWidgets,
      ),
    );
  }

  bool _isLevelEffectivelyAccessible(
      String userCurrentLevel, String requiredLessonLevel) {
    int userLevelIndex = _levelOrder.indexOf(userCurrentLevel);
    int requiredLevelIndex = _levelOrder.indexOf(requiredLessonLevel);
    if (requiredLevelIndex == -1) {
      if (requiredLessonLevel == 'Прочее') return true;
      return false;
    }
    if (userCurrentLevel.isEmpty ||
        userCurrentLevel.toLowerCase() == "begginer") {
      return requiredLevelIndex <= 0;
    }
    if (userLevelIndex == -1) {
      return false;
    }
    return userLevelIndex >= requiredLevelIndex;
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    Color selectedColor = darkOrange;
    Color unselectedColor = primaryOrange.withOpacity(0.7);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _bottomNavSelectedIndex,
      onTap: (index) {
        if (!mounted || (_bottomNavSelectedIndex == index && index == 0))
          return;
        setState(() {
          _bottomNavSelectedIndex = index;
        });
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/games');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/league');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/modules_view');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: Colors.white,
      elevation: 15.0, // Увеличим тень
      iconSize: 28, // Немного больше иконки
      selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 12, color: selectedColor),
      unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500, fontSize: 11.5, color: unselectedColor),
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.terrain_outlined),
            activeIcon: Icon(Icons.terrain_rounded, color: selectedColor),
            label: 'Путь'),
        BottomNavigationBarItem(
            icon: Icon(Icons.extension_outlined),
            activeIcon: Icon(Icons.extension_rounded, color: selectedColor),
            label: 'Игры'), // puzzle
        BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield, color: selectedColor),
            label: 'Лига'),
        BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book, color: selectedColor),
            label: 'Материал'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_circle_outlined),
            activeIcon:
                Icon(Icons.person_pin_circle_rounded, color: selectedColor),
            label: 'Профиль'),
      ],
    );
  }
}

// ---- ВИДЖЕТ ДЛЯ СЕКЦИИ УРОВНЯ НА КАРТЕ (_AdventureLevelSection) ----
class _AdventureLevelSection extends StatelessWidget {
  final String levelName;
  final List<Lesson> lessons;
  final String userLevel;
  final Map<String, int> userLessonProgress;
  final bool isEffectivelyUnlocked;
  final Function(Lesson lesson) onLessonTap;
  final bool isAdmin;
  final Function(Lesson lesson) onDeleteLesson;
  final Color levelColor;
  final IconData levelIcon;

  const _AdventureLevelSection({
    Key? key,
    required this.levelName,
    required this.lessons,
    required this.userLevel,
    required this.userLessonProgress,
    required this.isEffectivelyUnlocked,
    required this.onLessonTap,
    required this.isAdmin,
    required this.onDeleteLesson,
    required this.levelColor,
    required this.levelIcon,
  }) : super(key: key);

  static const List<String> _levelOrderStatic = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Upper Intermediate',
    'Advanced'
  ];

  @override
  Widget build(BuildContext context) {
    // Цвета для заголовка и иконки секции
    final Color titleColor =
        isEffectivelyUnlocked ? Colors.white : Colors.grey.shade300;
    final Color iconColor =
        isEffectivelyUnlocked ? levelColor : Colors.grey.shade400;
    final Color iconBgColor = isEffectivelyUnlocked
        ? Colors.white.withOpacity(0.2)
        : Colors.grey.withOpacity(0.1);

    if (lessons.isEmpty &&
        levelName != _AdventureLevelSection._levelOrderStatic.first &&
        !isEffectivelyUnlocked) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0, top: 12.0),
      padding: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
            colors: isEffectivelyUnlocked
                // Используем darken/lighten или withOpacity вместо .shadeX00
                ? [levelColor.lighten(0.1), levelColor.darken(0.1)]
                : [
                    Colors.blueGrey.shade200.withOpacity(0.3),
                    Colors.blueGrey.shade300.withOpacity(0.2)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color:
                  Colors.black.withOpacity(isEffectivelyUnlocked ? 0.25 : 0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 8))
        ],
      ),
      child: Container(
        // Внутренний контейнер для основного фона
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isEffectivelyUnlocked
              ? levelColor.withOpacity(0.85)
              : Colors.blueGrey.shade200.withOpacity(0.4),
          borderRadius: BorderRadius.circular(27),
        ),
        child: Column(
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(1, 1))
                    ]),
                child: Icon(levelIcon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(levelName,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          shadows: [
                            Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 3,
                                offset: Offset(1, 1))
                          ]))),
              if (!isEffectivelyUnlocked)
                Icon(Icons.lock_rounded,
                    color: Colors.white.withOpacity(0.5), size: 32),
            ]),
            if (lessons.isNotEmpty ||
                (lessons.isEmpty && isEffectivelyUnlocked))
              Divider(
                  height: 35,
                  thickness: 1,
                  color: Colors.white.withOpacity(0.2)),
            if (lessons.isEmpty && isEffectivelyUnlocked)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Text("Уроки скоро появятся здесь!",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                          fontSize: 16)))
            else if (!isEffectivelyUnlocked)
              Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 10.0),
                  child: Text(
                      "Завершите предыдущие этапы, чтобы открыть эти знания!",
                      style: TextStyle(
                          color: Colors.yellow.shade100,
                          fontWeight: FontWeight.w500,
                          fontSize: 15),
                      textAlign: TextAlign.center))
            else
              LayoutBuilder(// Используем LayoutBuilder для адаптивного Wrap
                  builder: (context, constraints) {
                int crossAxisCount = (constraints.maxWidth / 100)
                    .floor(); // Примерно 100px на элемент
                if (crossAxisCount < 2) crossAxisCount = 2; // Минимум 2 в ряд
                if (crossAxisCount > 4) crossAxisCount = 4; // Максимум 4 в ряд

                return Wrap(
                  spacing: (constraints.maxWidth - (crossAxisCount * 75)) /
                          (crossAxisCount > 1 ? crossAxisCount - 1 : 1) -
                      2, // Динамический spacing
                  runSpacing: 20.0,
                  alignment: WrapAlignment.start, // Начинаем слева
                  children: lessons.map((lesson) {
                    final progress = userLessonProgress[lesson.id] ?? 0;
                    return _AdventureLessonNode(
                      lesson: lesson,
                      progress: progress,
                      isAccessible: isEffectivelyUnlocked,
                      userLevel: userLevel,
                      onTap: () => onLessonTap(lesson),
                      isAdmin: isAdmin,
                      onDelete: () => onDeleteLesson(lesson),
                      baseColor: levelColor,
                    );
                  }).toList(),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ---- ВИДЖЕТ ДЛЯ УЗЛА УРОКА НА КАРТЕ (_AdventureLessonNode) ----
class _AdventureLessonNode extends StatelessWidget {
  final Lesson lesson;
  final int progress;
  final bool isAccessible;
  final String userLevel;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback onDelete;
  final Color baseColor;

  const _AdventureLessonNode({
    Key? key,
    required this.lesson,
    required this.progress,
    required this.isAccessible,
    required this.userLevel,
    required this.onTap,
    required this.isAdmin,
    required this.onDelete,
    required this.baseColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCompleted = progress >= 100;
    IconData lessonTypeIcon;
    switch (lesson.lessonType.toLowerCase()) {
      case 'interactive':
      case 'choosetranslation':
        lessonTypeIcon = Icons.touch_app_rounded;
        break;
      case 'audiolesson':
        lessonTypeIcon = Icons.headphones_rounded;
        break;
      case 'videolesson':
        lessonTypeIcon = Icons.play_circle_filled_rounded;
        break;
      case 'newaudiocollection':
      case 'audiowordbanksentence':
        lessonTypeIcon = Icons.mic_external_on_rounded;
        break;
      case 'speaking_pronunciation': // <--- НАШ НОВЫЙ ТИП
        lessonTypeIcon = Icons.record_voice_over_rounded;
        break;
      default:
        lessonTypeIcon = Icons.sticky_note_2_rounded;
    }
    IconData statusIconData =
        isCompleted ? Icons.verified_user_rounded : Icons.star_half_rounded;

    bool isLessonActuallyAccessible;
    if (isAccessible) {
      int userLevelIndex =
          _AdventureLevelSection._levelOrderStatic.indexOf(userLevel);
      int requiredLessonLevelIndex = _AdventureLevelSection._levelOrderStatic
          .indexOf(lesson.requiredLevel);
      if (requiredLessonLevelIndex == -1 && lesson.requiredLevel != 'Прочее') {
        isLessonActuallyAccessible = false;
      } else if (lesson.requiredLevel == 'Прочее') {
        isLessonActuallyAccessible = true;
      } else if (userLevel.isEmpty || userLevel.toLowerCase() == "begginer") {
        isLessonActuallyAccessible = requiredLessonLevelIndex <= 0;
      } else if (userLevelIndex == -1) {
        isLessonActuallyAccessible = false;
      } else {
        isLessonActuallyAccessible = userLevelIndex >= requiredLessonLevelIndex;
      }
    } else {
      isLessonActuallyAccessible = false;
    }

    final Color nodeColor = isLessonActuallyAccessible
        ? (isCompleted ? Colors.green.shade500 : baseColor)
        : Colors.blueGrey.shade300;
    final Color iconColor =
        isLessonActuallyAccessible ? Colors.white : Colors.blueGrey.shade100;
    final Color textColor = isLessonActuallyAccessible
        ? Colors.white.withOpacity(0.95)
        : Colors.blueGrey.shade100.withOpacity(0.8);

    return Opacity(
      opacity: isLessonActuallyAccessible ? 1.0 : 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            // Дополнительный SizedBox для тени и InkWell
            width: 80, height: 80,
            child: Material(
              // Material для InkWell и тени
              color: Colors.transparent,
              elevation: isLessonActuallyAccessible ? 6.0 : 0.0,
              shadowColor: nodeColor.withOpacity(0.5),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isLessonActuallyAccessible ? onTap : null,
                borderRadius: BorderRadius.circular(40),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.15),
                child: Container(
                  width: 75, height: 75, // Немного больше сам узел
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        // Градиент для узла
                        colors: isLessonActuallyAccessible
                            ? [nodeColor.lighten(0.1), nodeColor.darken(0.1)]
                            : [
                                nodeColor.withOpacity(0.7),
                                nodeColor.withOpacity(0.5)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    border: Border.all(
                        color: Colors.white.withOpacity(
                            isLessonActuallyAccessible ? 0.5 : 0.2),
                        width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                          isLessonActuallyAccessible
                              ? lessonTypeIcon
                              : Icons.lock_rounded,
                          color: iconColor,
                          size: 36), // Крупнее иконка
                      if (isLessonActuallyAccessible &&
                          !isCompleted &&
                          progress > 0)
                        Positioned(
                          child: SizedBox(
                            width: 73,
                            height: 73,
                            child: CircularProgressIndicator(
                              value: progress / 100,
                              strokeWidth: 4,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.lightGreenAccent.shade200),
                            ),
                          ),
                        ),
                      if (isLessonActuallyAccessible && isCompleted)
                        Positioned(
                            top: 5,
                            right: 5,
                            child: Icon(statusIconData,
                                color: Colors.yellowAccent.shade100,
                                size: 22)) // Ярче статус
                      else if (isLessonActuallyAccessible &&
                          !isCompleted &&
                          progress == 0)
                        Positioned(
                            top: 5,
                            right: 5,
                            child: Icon(statusIconData,
                                color: Colors.white.withOpacity(0.5),
                                size: 18)),

                      if (isAdmin && isLessonActuallyAccessible)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(10),
                              child: CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.red.withOpacity(0.7),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.white, size: 13))),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 85,
            child: Text(lesson.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    shadows: [
                      Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 1,
                          offset: Offset(0, 1))
                    ])),
          ),
        ],
      ),
    );
  }
}

// ---- ВИДЖЕТ ДЛЯ СОЕДИНИТЕЛЬНОЙ ТРОПИНКИ МЕЖДУ УРОВНЯМИ (_PathConnector и _PathPainter) ----
class _PathConnector extends StatelessWidget {
  final bool isUnlocked;
  final Color color;
  const _PathConnector(
      {Key? key, required this.isUnlocked, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 70, // Длиннее
        width: 80, // Шире для более выраженного изгиба
        child: CustomPaint(
            painter: _PathPainter(
                isUnlocked: isUnlocked,
                pathColor: color.withOpacity(isUnlocked ? 0.9 : 0.5))));
  }
}

class _PathPainter extends CustomPainter {
  final bool isUnlocked;
  final Color pathColor;
  _PathPainter({required this.isUnlocked, required this.pathColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 // Толще
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width / 2, 0);

    // Случайный изгиб для "живости"
    double controlPointXOffset =
        (math.Random().nextDouble() * 40.0) - 20.0; // от -20 до +20

    if (isUnlocked) {
      path.cubicTo(
          size.width / 2 + controlPointXOffset,
          size.height * 0.33, // Первая контрольная точка
          size.width / 2 - controlPointXOffset,
          size.height * 0.66, // Вторая контрольная точка (зеркально)
          size.width / 2,
          size.height // Конечная точка
          );
      canvas.drawPath(path, paint);

      // Добавляем пунктир поверх сплошной линии для текстуры
      final dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      double dashLength = 4;
      double gapLength = 3;
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0;
        bool draw = true;
        while (distance < metric.length) {
          if (draw) {
            canvas.drawPath(
                metric.extractPath(distance, distance + dashLength), dashPaint);
          }
          distance +=
              (draw ? dashLength : gapLength) + gapLength; // чередование
          draw = !draw;
        }
      }
    } else {
      // Пунктир для заблокированного
      paint.strokeWidth = 4; // Тоньше для заблокированного
      double dashHeight = 6;
      double dashSpace = 5;
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(Offset(size.width / 2, startY),
            Offset(size.width / 2, startY + dashHeight), paint);
        startY += dashHeight + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.isUnlocked != isUnlocked ||
      oldDelegate.pathColor != pathColor;
}

// Расширения для Color для удобства затемнения/осветления
extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
