// lib/pages/LearnPage.dart
import 'dart:async';
import 'dart:math' as math; // Для min и Transform.rotate
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/lessons_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/models/audiolessons_service.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/audioplayerpage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/lesson_player_page.dart';
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

  UserModel? _currentUserData;
  String _currentLearningLanguage = 'english'; // Язык по умолчанию
  List<Lesson> _allLessonsForCurrentLanguage = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _lives = 5;
  Timer? _lifeRestoreTimer;
  final ValueNotifier<int> _remainingTimeForLifeNotifier =
      ValueNotifier<int>(0);
  bool _isAdmin = false;

  // --- НОВАЯ ЦВЕТОВАЯ ПАЛИТРА И СТИЛИ ---
  final Color primaryOrange = const Color(0xFFFFA726); // Яркий оранжевый
  final Color accentYellow =
      const Color(0xFFFFE082); // Очень светло-желтый/персиковый для фона
  final Color darkOrange =
      const Color(0xFFF57C00); // Темнее оранжевый для акцентов
  final Color textOnOrange = Colors.white;
  final Color textOnWhite =
      const Color(0xFF3A3A3A); // Темно-серый для текста на светлом фоне
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
    };

    _pageFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageFadeAnimation =
        CurvedAnimation(parent: _pageFadeController, curve: Curves.easeInOut);

    _sectionAppearControllers = [];
    _sectionAppearAnimations = [];

    _initializePage();
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
    // Сбрасываем анимации секций перед новой загрузкой
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
        'upperupinterlessons'
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
    final BuildContext currentContext = context;
    bool dialogShown = false;
    if (mounted) {
      try {
        showDialog(
            context: currentContext,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) =>
                Center(child: CircularProgressIndicator(color: primaryOrange)));
        dialogShown = true;
      } catch (e) {
        print("Error showing deduct life dialog: $e");
      }
    }
    bool canProceed = await _deductLife();
    if (dialogShown && mounted) {
      try {
        if (Navigator.canPop(currentContext)) {
          Navigator.pop(currentContext);
        }
      } catch (e) {
        print("Error popping deduct life dialog: $e");
      }
    }
    if (!mounted || !canProceed) return;
    Widget lessonViewerPage;
    if (lesson.lessonType == 'audioWordBankSentence' ||
        lesson.collectionName == _audioWordBankService.collectionName) {
      lessonViewerPage = LessonPlayerAudioPage(
          lesson: lesson, onProgressUpdated: _handleProgressUpdate);
    } else {
      lessonViewerPage = LessonPlayerPage(
          lesson: lesson, onProgressUpdated: _handleProgressUpdate);
    }
    Future.microtask(() {
      if (mounted) {
        Navigator.push(currentContext,
                MaterialPageRoute(builder: (routeContext) => lessonViewerPage))
            .then((_) {
          if (mounted) {
            _initializePage(isLanguageChange: false);
          }
        });
      }
    });
  }

  void _handleProgressUpdate(String lessonId, int newProgress) async {
    if (_currentUserData == null || !mounted) return;
    UserModel updatedUserDataLocally = _currentUserData!
        .updateLessonProgress(_currentLearningLanguage, lessonId, newProgress);
    if (mounted)
      setState(() {
        _currentUserData = updatedUserDataLocally;
      });
    await _usersCollection.updateLessonProgressInUserDoc(
        _currentUserData!.uid, _currentLearningLanguage, lessonId, newProgress);
    if (newProgress >= 100) await _checkAndAdvanceLevel();
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
    if (currentLevel == "" || currentLevel.toLowerCase() == "begginer") {
      currentLevelIndex = -1;
    }
    if (currentLevelIndex == -1 &&
        currentLevel != "" &&
        currentLevel.toLowerCase() != "begginer") {
      print("Текущий уровень '$currentLevel' не найден. Повышение невозможно.");
      return;
    }
    if (currentLevelIndex >= _levelOrder.length - 1) {
      print("Пользователь уже на максимальном уровне.");
      return;
    }
    String nextLevel = _levelOrder[currentLevelIndex + 1];
    try {
      await _usersCollection.updateUserLevel(
          _currentUserData!.uid, _currentLearningLanguage, nextLevel);
      final langSettings = _currentUserData!.languageSettings;
      if (langSettings != null) {
        final learningProg =
            langSettings.learningProgress[_currentLearningLanguage];
        if (learningProg != null) {
          final updatedLangProg = learningProg.copyWith(level: nextLevel);
          final newLearningProgressMap = Map<String, UserLanguageProgress>.from(
              langSettings.learningProgress);
          newLearningProgressMap[_currentLearningLanguage] = updatedLangProg;
          final updatedSettings =
              langSettings.copyWith(learningProgress: newLearningProgressMap);
          if (mounted) {
            setState(() {
              _currentUserData =
                  _currentUserData!.copyWith(languageSettings: updatedSettings);
            });
          }
        }
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
      if (mounted)
        Toast.show("Ошибка при повышении уровня.", duration: Toast.lengthShort);
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
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCustomAppBar(
      bool canShowLanguageSelector, List<String> availableLangsForSelector) {
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ]),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: canShowLanguageSelector ? 0 : 40),
                Expanded(
                  child: Center(
                    child: _isLoading || _currentUserData == null
                        ? Text("LingoQuest",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textOnOrange))
                        : Text(
                            _getLanguageDisplayName(_currentLearningLanguage),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textOnOrange,
                                letterSpacing: 0.5),
                          ),
                  ),
                ),
                if (canShowLanguageSelector)
                  SizedBox(
                    width: 130,
                    child: LanguageSelectorWidget(
                      // Убираем несуществующие параметры
                      availableLanguages: availableLangsForSelector,
                      currentLanguageCode: _currentLearningLanguage,
                      onLanguageSelected: _onLanguageChanged,
                      // textColor: textOnOrange, // УБРАНО
                      // dropdownColor: darkOrange.withOpacity(0.9), // УБРАНО
                      // iconColor: textOnOrange.withOpacity(0.8), // УБРАНО
                    ),
                  )
                else if (_currentUserData != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                        _getLanguageDisplayName(_currentLearningLanguage,
                            short: true),
                        style: TextStyle(
                            color: textOnOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  )
                else
                  const SizedBox(width: 40),
                if (_currentUserData != null) _buildLivesIndicator(),
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
            Navigator.pushReplacementNamed(context, '/chats');
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
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat_rounded, color: selectedColor),
            label: 'Чаты'),
        BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
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
