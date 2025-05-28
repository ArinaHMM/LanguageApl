// lib/pages/LearnPage.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ваши адаптированные классы для работы с Firestore
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart'; // Убедитесь, что методы обновлены
import 'package:flutter_languageapplicationmycourse_2/database/collections/lessons_collections.dart'; // Убедитесь, что методы обновлены

// Модели данных (предполагается, что они адаптированы)
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';

// Страница урока (должна уметь обрабатывать разные типы уроков)
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/lesson_player_page.dart';


// Виджеты
import 'package:flutter_languageapplicationmycourse_2/widget/language_selector_widget.dart'; // Если он у вас есть и адаптирован

// Пакеты
import 'package:toast/toast.dart';

// ВАЖНО: Импорты ВАШИХ старых страниц уроков (LessonPage1 и т.д.) здесь НЕ НУЖНЫ,
// так как вся логика перехода должна вести на универсальный LessonPlayerPage или аналогичный.

class LearnPage extends StatefulWidget {
  const LearnPage({Key? key}) : super(key: key);

  @override
  _LearnPageState createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> with TickerProviderStateMixin {
  final UsersCollection _usersCollection = UsersCollection();
  final LessonsCollection _lessonsCollection = LessonsCollection(); // Ваш класс для получения уроков
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUserData;
  String _currentLearningLanguage = 'english'; // Язык по умолчанию
  List<Lesson> _allLessonsForCurrentLanguage = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _lives = 5; // Начальное значение по умолчанию
  Timer? _lifeRestoreTimer;
  final ValueNotifier<int> _remainingTimeForLifeNotifier = ValueNotifier<int>(0);
  bool _isAdmin = false;

  // Порядок и стили уровней
  final List<String> _levelOrder = ['Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'];
  final Map<String, Color> _levelColors = {
    'Beginner': Colors.lightBlue[400]!,
    'Elementary': Colors.green[500]!,
    'Intermediate': Colors.orange[600]!,
    'Upper Intermediate': Colors.purple[500]!,
    'Advanced': Colors.red[600]!,
    'Прочее': Colors.grey[600]!, // Для уроков без четкого уровня или кастомных
  };
   final Map<String, IconData> _levelIcons = { // Иконки для каждого уровня
    'Beginner': Icons.child_friendly_outlined,
    'Elementary': Icons.school_outlined,
    'Intermediate': Icons.auto_stories_outlined,
    'Upper Intermediate': Icons.menu_book_sharp,
    'Advanced': Icons.workspace_premium_outlined,
    'Прочее': Icons.category_outlined,
  };

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _bottomNavSelectedIndex = 0; // Для BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600), // Увеличено для более плавной анимации
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _initializePage();
  }

  Future<void> _initializePage({bool isLanguageChange = false}) async {
    if (!mounted) return;
    if (!isLanguageChange) { // Полная перезагрузка только если это не смена языка
      setState(() { _isLoading = true; _errorMessage = null; });
    }
    _fadeController.reset(); // Сбрасываем анимацию

    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _handleUnauthenticatedUser();
      return;
    }

    try {
      // 1. Получаем данные пользователя
      UserModel? userData = await _usersCollection.getUserModel(firebaseUser.uid);
      if (!mounted) return;

      if (userData == null || userData.languageSettings == null || userData.languageSettings!.learningProgress.isEmpty) {
        // Если нет настроек языка (например, новый пользователь, который пропустил выбор)
        _handleMissingLanguageSettings();
        return;
      }
      
      _currentUserData = userData;
      // Устанавливаем текущий язык обучения из данных пользователя
      _currentLearningLanguage = _currentUserData!.languageSettings!.currentLearningLanguage;
      _lives = _currentUserData!.lives;
      _isAdmin = _currentUserData!.email == 'admin@mail.ru'; // Проверка на админа

      // 2. Инициализируем таймер жизней
      _initializeLifeTimer(_currentUserData!.lives, _currentUserData!.lastRestored);

      // 3. Загружаем уроки для текущего языка
      await _fetchLessonsForCurrentLanguage();
      
      if (mounted) {
         _fadeController.forward(); // Запускаем анимацию появления контента
      }

    } catch (e) {
      print("Error initializing LearnPage: $e");
      if (mounted) {
        setState(() { _errorMessage = "Ошибка загрузки данных. Попробуйте позже."; });
      }
    } finally {
      if (mounted && !isLanguageChange) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _handleUnauthenticatedUser() {
     if (!mounted) return;
    // Если пользователь не аутентифицирован, перенаправляем на страницу входа
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    });
  }

  void _handleMissingLanguageSettings() {
    if (!mounted) return;
    // Если у пользователя нет настроек языка, перенаправляем на страницу выбора языка
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/selectLanguage', (route) => false);
    });
  }
  
  Future<void> _fetchLessonsForCurrentLanguage() async {
    if (_currentUserData == null || !mounted) return;
    // Очищаем предыдущие уроки перед загрузкой новых (для корректной смены языка)
    if (mounted) setState(() { _allLessonsForCurrentLanguage = []; });

    try {
      List<Lesson> fetchedLessons = [];
      // Список коллекций, из которых нужно загружать уроки
      final lessonCollectionsToFetch = [
        // 'lessons', // Ваша старая коллекция, если она есть и содержит уроки
        'interactiveLessons', // Новая коллекция из админки
        'addlessons',
        'upperlessons', // Убедитесь, что для этих коллекций в Firestore у уроков есть поля targetLanguage и requiredLevel
        'audiolessons',
        'videolessons',
        'advancedlessons',
        'upperinterlessons',
        'upperupinterlessons'
        // Добавьте другие ваши коллекции уроков сюда
      ];
      
      for (String collectionName in lessonCollectionsToFetch) {
        // Предполагаем, что getLessonsFromCollection фильтрует по targetLanguage
        fetchedLessons.addAll(await _lessonsCollection.getLessons(collectionName, _currentLearningLanguage));
      }
      
      // Опционально: Сортировка уроков, например, по orderIndex, если он есть
      // fetchedLessons.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));

      if (mounted) {
        setState(() { _allLessonsForCurrentLanguage = fetchedLessons; });
      }
    } catch (e) {
      print("Error fetching lessons for $_currentLearningLanguage: $e");
      if (mounted) setState(() { _errorMessage = "Ошибка загрузки уроков."; });
    }
  }

  // --- Логика жизней (оставляем как есть, если она работала) ---
  void _initializeLifeTimer(int currentLives, Timestamp lastRestored) {
    _lifeRestoreTimer?.cancel();
    if (!mounted) return;

    DateTime lastRestoredTime = lastRestored.toDate();
    // Убедитесь, что у вас есть константа или переменная для интервала восстановления
    const Duration lifeRestoreInterval = Duration(minutes: 5); // Например, 5 минут

    if (currentLives < 5) {
      DateTime nextRestoreTime = lastRestoredTime.add(lifeRestoreInterval);
      int secondsToNextRestore = nextRestoreTime.difference(DateTime.now()).inSeconds;

      if (secondsToNextRestore <= 0) {
        // Если время уже прошло, пытаемся восстановить жизни на основе прошедшего времени
        _handleInstantRestore();
      } else {
        _remainingTimeForLifeNotifier.value = secondsToNextRestore;
        _lifeRestoreTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) { timer.cancel(); return; } // Проверка, что виджет еще существует
          if (_remainingTimeForLifeNotifier.value > 0) {
            _remainingTimeForLifeNotifier.value--;
          } else {
            timer.cancel();
            _restoreLife();
          }
        });
      }
    } else {
       _remainingTimeForLifeNotifier.value = 0; // Если жизней полно, таймер не нужен
    }
  }
  
  Future<void> _handleInstantRestore() async {
    if (_currentUserData == null || !mounted) return;

    DateTime lastRestoredTime = _currentUserData!.lastRestored.toDate();
    const Duration lifeRestoreInterval = Duration(minutes: 5); // Должно совпадать с _initializeLifeTimer
    int totalMinutesPassed = DateTime.now().difference(lastRestoredTime).inMinutes;
    int livesToPotentiallyRestore = totalMinutesPassed ~/ lifeRestoreInterval.inMinutes;

    if (livesToPotentiallyRestore > 0 && _currentUserData!.lives < 5) {
      int currentLivesInDb = _currentUserData!.lives;
      int newLives = (currentLivesInDb + livesToPotentiallyRestore).clamp(0, 5);
      
      if (newLives > currentLivesInDb) {
        // Обновляем lastRestored только на то количество интервалов, сколько жизней было реально восстановлено
        // Это важно, чтобы не "терять" время, если восстановлено меньше, чем могло бы быть
        Timestamp newLastRestoredTimestamp = Timestamp.fromDate(
            lastRestoredTime.add(lifeRestoreInterval * (newLives - currentLivesInDb))
        );
        // Если все 5 жизней восстановлены, то lastRestored можно поставить текущее время,
        // чтобы следующий отсчет начался с нуля, когда жизнь потратится.
        if (newLives == 5) {
            newLastRestoredTimestamp = Timestamp.now();
        }

        await _usersCollection.updateUserCollection(_currentUserData!.uid, {
          'lives': newLives,
          'lastRestored': newLastRestoredTimestamp, 
        });
        if(mounted) {
          setState(() {
            _lives = newLives;
            // Обновляем локальный _currentUserData, чтобы он был консистентен
            _currentUserData = _currentUserData!.copyWith(lives: newLives, lastRestored: newLastRestoredTimestamp);
          });
        }
        _initializeLifeTimer(newLives, newLastRestoredTimestamp); // Перезапускаем таймер с новым временем
      } else {
         // Если расчетное количество жизней не увеличивает текущее, просто перезапускаем таймер
         _initializeLifeTimer(_currentUserData!.lives, _currentUserData!.lastRestored);
      }
    } else {
       _initializeLifeTimer(_currentUserData!.lives, _currentUserData!.lastRestored);
    }
  }

  Future<void> _restoreLife() async {
    if (_currentUserData == null || _lives >= 5 || !mounted) return;

    int newLives = _lives + 1;
    Timestamp newLastRestored = Timestamp.now(); // Время фактического восстановления

    await _usersCollection.updateUserCollection(_currentUserData!.uid, {
      'lives': newLives,
      'lastRestored': newLastRestored,
    });

    if (mounted) {
      setState(() {
        _lives = newLives;
        _currentUserData = _currentUserData!.copyWith(lives: newLives, lastRestored: newLastRestored);
      });
      _initializeLifeTimer(newLives, newLastRestored); // Перезапуск таймера
    }
  }

  Future<bool> _deductLife() async {
    if (_currentUserData == null || _lives <= 0 || !mounted) {
      if (mounted && _lives <=0) Toast.show("Недостаточно жизней!", duration: Toast.lengthShort);
      return false;
    }

    int newLives = _lives - 1;
    // Время списания жизни. Если жизней было 5, то это время станет новой точкой отсчета для восстановления.
    Timestamp timeOfDeduction = Timestamp.now(); 

    try {
      await _usersCollection.updateUserCollection(_currentUserData!.uid, {
        'lives': newLives,
        // Обновляем lastRestored, чтобы таймер начал отсчет с момента траты жизни,
        // если это была первая потраченная жизнь из полных 5.
        // Если жизней было меньше 5, lastRestored не меняется, т.к. таймер уже идет.
        if (_lives == 5) 'lastRestored': timeOfDeduction,
      });

      if (mounted) {
        setState(() {
          _lives = newLives;
          _currentUserData = _currentUserData!.copyWith(
            lives: newLives,
            lastRestored: (_lives == 5) ? timeOfDeduction : _currentUserData!.lastRestored // Обновляем локально, если нужно
          );
        });
        _initializeLifeTimer(newLives, (_lives == 5 && newLives < 5) ? timeOfDeduction : _currentUserData!.lastRestored);
      }
      return true;
    } catch (e) {
      if (mounted) Toast.show("Ошибка при списании жизни.", duration: Toast.lengthShort);
      return false;
    }
  }

  // --- Смена языка ---
  Future<void> _onLanguageChanged(String newLanguageCode) async {
    if (_currentUserData == null || newLanguageCode == _currentLearningLanguage || !mounted) return;
    
    // Показываем индикатор загрузки на время смены языка
    if (mounted) {
      // Не используем setState здесь, чтобы не перерисовывать весь экран ради индикатора
      // Вместо этого, индикатор будет частью логики, если _isLoading = true
      // Но для быстрой смены языка можно показать диалог
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: Colors.white)), // Цвет для лучшей видимости, если фон темный
      );
    }

    try {
      await _usersCollection.updateUserCollection(_currentUserData!.uid, {
        'languageSettings.currentLearningLanguage': newLanguageCode,
      });
      // Перезагружаем всю страницу с новыми данными для выбранного языка
      await _initializePage(isLanguageChange: true); // isLanguageChange: true, чтобы не показывать основной лоадер
    } catch (e) {
      if (mounted) Toast.show("Ошибка смены языка", duration: Toast.lengthShort);
    } finally {
      if (mounted) {
        Navigator.pop(context); // Закрываем диалог загрузки
        // setState(() { _isLoading = false; }); // _initializePage сам управляет _isLoading
      }
    }
  }
  
  // --- Навигация на урок ---
  void _navigateToLesson(Lesson lesson) async {
      if (!mounted) return;

      bool canProceed = await _deductLife(); 
      if (!canProceed) {
          return; 
      }
      
      print("Navigating to lesson: ${lesson.title} (ID: ${lesson.id}, Collection: ${lesson.collectionName})");
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonPlayerPage( // ВАШ УНИВЕРСАЛЬНЫЙ ПЛЕЕР УРОКОВ
              lesson: lesson,
              onProgressUpdated: _handleProgressUpdate, // Коллбэк для обновления прогресса
            ),
          ),
        ).then((_) {
          // Вызывается после возврата со страницы урока
          if (mounted) {
            // Можно обновить данные, если это необходимо
            // setState(() {}); // Например, для обновления жизней, если они восстановились во время урока
          }
        });
      }
  }

  // --- Обновление прогресса ---
  void _handleProgressUpdate(String lessonId, int newProgress) async {
    if (_currentUserData == null || !mounted) return;

    // Оптимистичное обновление UI
    if (mounted) {
      setState(() {
        _currentUserData = _currentUserData!.updateLessonProgress(_currentLearningLanguage, lessonId, newProgress);
      });
    }
    // Обновление в Firestore
    await _usersCollection.updateLessonProgressInUserDoc(
        _currentUserData!.uid, _currentLearningLanguage, lessonId, newProgress);
  }
  
  // --- Удаление урока (для админа) ---
  Future<void> _deleteLesson(Lesson lesson) async {
    if (!_isAdmin || _currentUserData == null || !mounted) return;

    bool confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
              title: Text("Удалить урок?"),
              content: Text("Вы уверены, что хотите удалить урок '${lesson.title}' из коллекции '${lesson.collectionName}'? Это действие необратимо."),
              actions: <Widget>[
                TextButton(child: Text("Отмена"), onPressed: () => Navigator.of(dialogContext).pop(false)),
                TextButton(child: Text("Удалить", style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(dialogContext).pop(true)),
              ],
            )) ?? false;

    if (confirmDelete) {
      try {
        // Используем collectionName из объекта Lesson для удаления из правильной коллекции
        await _lessonsCollection.deleteLessonFromCollection(lesson.collectionName, lesson.id);
        if (mounted) Toast.show("Урок '${lesson.title}' удален.", duration: Toast.lengthShort);
        // Перезагружаем уроки для текущего языка
        await _fetchLessonsForCurrentLanguage();
      } catch (e) {
        if (mounted) Toast.show("Ошибка удаления урока.", duration: Toast.lengthShort);
        print("Error deleting lesson: $e");
      }
    }
  }

  @override
  void dispose() {
    _lifeRestoreTimer?.cancel();
    _remainingTimeForLifeNotifier.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // --- Методы для UI ---
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context); // Для пакета toast

    // Определяем, нужно ли показывать селектор языка в AppBar
    bool canShowLanguageSelector = false;
    List<String> availableLangsForSelector = [];

    if (_currentUserData != null &&
        _currentUserData!.languageSettings != null &&
        _currentUserData!.languageSettings!.learningProgress.isNotEmpty) {
      // Показываем селектор, если доступно больше одного языка для изучения
      canShowLanguageSelector = _currentUserData!.languageSettings!.learningProgress.keys.length > 1;
      if (canShowLanguageSelector) {
        availableLangsForSelector = _currentUserData!.languageSettings!.learningProgress.keys.toList();
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _isLoading 
            ? Text("Загрузка...", style: TextStyle(fontSize: 18, color: Colors.white))
            : Text(
                _getLanguageDisplayName(_currentLearningLanguage), 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)
              ),
        backgroundColor: const Color.fromARGB(255, 0, 167, 28), // Немного другой оттенок зеленого
        elevation: 0, // Плоский AppBar для "карточного" стиля
        automaticallyImplyLeading: false, // Убираем кнопку "назад" по умолчанию
        actions: [
          _buildLivesIndicator(), // Индикатор жизней
          // Селектор языка, если доступно несколько
          if (canShowLanguageSelector)
             LanguageSelectorWidget( // Ваш кастомный виджет для выбора языка
                availableLanguages: availableLangsForSelector,
                currentLanguageCode: _currentLearningLanguage,
                onLanguageSelected: _onLanguageChanged, // Метод для смены языка
             )
          // Если только один язык, можно просто показать его код или короткое название
          else if (_currentUserData != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(child: Text(_getLanguageDisplayName(_currentLearningLanguage, short: true), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLivesIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right:12.0, left: 8.0), // Небольшие отступы
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: Colors.pinkAccent[100], size: 24),
          const SizedBox(width: 5),
          Text("$_lives", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: _remainingTimeForLifeNotifier,
            builder: (context, timeLeft, child) {
              if (_lives >= 5 || timeLeft <= 0) return SizedBox.shrink(); // Не показывать таймер, если жизни полны или время 0
              final minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
              final seconds = (timeLeft % 60).toString().padLeft(2, '0');
              return Text("$minutes:$seconds", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)));
            },
          ),
        ],
      ),
    );
  }
  
  String _getLanguageDisplayName(String code, {bool short = false}) {
    // Преобразуйте коды языков в отображаемые имена
    if (short) {
        switch (code.toLowerCase()) {
            case 'english': return 'EN';
            case 'spanish': return 'ES';
            case 'german': return 'DE';
            // Добавьте другие языки
            default: return code.isNotEmpty ? code.toUpperCase().substring(0, (code.length > 1 ? 2:1) ) : "";
        }
    }
    switch (code.toLowerCase()) {
        case 'english': return 'Английский';
        case 'spanish': return 'Испанский';
        case 'german': return 'Немецкий';
        // Добавьте другие языки
        default: return code; // По умолчанию показываем код
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.teal[700], strokeWidth: 3));
    }

    if (_errorMessage != null) {
       return Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red[600], size: 70),
              SizedBox(height: 20),
              Text(_errorMessage!, style: TextStyle(fontSize: 18, color: Colors.red[800], fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh_rounded),
                label: Text("Попробовать снова", style: TextStyle(fontSize: 16)),
                onPressed: () => _initializePage(), // Повторная инициализация
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600], // Цвет кнопки
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              )
            ],
          ),
        )
      );
    }

    if (_currentUserData == null) {
      // Это состояние не должно достигаться, если _handleUnauthenticatedUser работает правильно
      return const Center(child: Text("Нет данных пользователя. Пожалуйста, перезапустите приложение.", style: TextStyle(fontSize: 16)));
    }

    // Группируем уроки по требуемому уровню
    Map<String, List<Lesson>> lessonsByLevelMap = {};
    for (var lesson in _allLessonsForCurrentLanguage) {
      // Используем requiredLevel урока для группировки
      String levelKey = _levelOrder.contains(lesson.requiredLevel) ? lesson.requiredLevel : 'Прочее';
      lessonsByLevelMap.putIfAbsent(levelKey, () => []).add(lesson);
    }
    
    // Получаем текущий уровень пользователя для активного языка
    final userCurrentLevel = _currentUserData!.languageSettings!.learningProgress[_currentLearningLanguage]?.level ?? 'NotStarted';
    final userLessonProgress = _currentUserData!.languageSettings!.learningProgress[_currentLearningLanguage]?.lessonsCompleted ?? {};

    List<Widget> adventurePathWidgets = [];
    bool previousLevelConsideredUnlocked = true; // Начинаем с того, что "нулевой" уровень (до Beginner) пройден

    for (String levelName in _levelOrder) {
      final lessonsInThisLevel = lessonsByLevelMap[levelName] ?? [];
      // Доступен ли этот уровень В ПРИНЦИПЕ по уровню пользователя (независимо от прохождения предыдущих)
      bool isLevelGloballyAccessibleByUser = _isLevelEffectivelyAccessible(userCurrentLevel, levelName);
      
      // Эффективно ли разблокирована текущая секция (уровень пользователя позволяет И предыдущий уровень пройден)
      bool currentSectionEffectivelyUnlocked = isLevelGloballyAccessibleByUser && previousLevelConsideredUnlocked;

      // Пропускаем рендеринг секции 'Прочее', если в ней нет уроков
      if (levelName == 'Прочее' && lessonsInThisLevel.isEmpty) {
        continue;
      }

      adventurePathWidgets.add(
        _AdventureLevelSection(
          levelName: levelName,
          lessons: lessonsInThisLevel,
          userLevel: userCurrentLevel, // Текущий уровень пользователя для этого языка
          userLessonProgress: userLessonProgress, // Прогресс по урокам для этого языка
          isEffectivelyUnlocked: currentSectionEffectivelyUnlocked,
          onLessonTap: _navigateToLesson,
          isAdmin: _isAdmin,
          onDeleteLesson: _deleteLesson,
          levelColor: _levelColors[levelName] ?? Colors.grey,
          levelIcon: _levelIcons[levelName] ?? Icons.error_outline,
        )
      );
      
      // Логика для разблокировки следующего уровня:
      // Следующий уровень считается доступным, если:
      // 1. Текущий уровень был эффективно разблокирован.
      // 2. Все уроки в текущем эффективно разблокированном уровне пройдены (progress >= 100).
      // Если в текущем разблокированном уровне нет уроков, то доступность следующего зависит от предыдущего.
      if (currentSectionEffectivelyUnlocked && lessonsInThisLevel.isNotEmpty) {
          bool allLessonsInThisLevelDone = lessonsInThisLevel.every((l) => (userLessonProgress[l.id] ?? 0) >= 100);
          previousLevelConsideredUnlocked = allLessonsInThisLevelDone;
      } else if (!currentSectionEffectivelyUnlocked) {
          // Если текущая секция заблокирована, то и все последующие тоже будут считаться заблокированными с точки зрения "прохождения"
          previousLevelConsideredUnlocked = false;
      }
      // Если уроков в текущем разблокированном уровне нет, то previousLevelConsideredUnlocked не меняется,
      // и доступность следующего уровня будет зависеть от того, был ли пройден предыдущий уровень с уроками.

      // Добавляем соединитель пути, если это не последний уровень в _levelOrder
      if (levelName != _levelOrder.last && _levelOrder.indexOf(levelName) < _levelOrder.length -1) {
        // Определяем, будет ли следующий уровень доступен по уровню пользователя
        String nextLevelName = _levelOrder[_levelOrder.indexOf(levelName) + 1];
        bool isNextLevelAccessibleByLevel = _isLevelEffectivelyAccessible(userCurrentLevel, nextLevelName);
        
        adventurePathWidgets.add(
          _PathConnector(
            // Соединитель "разблокирован", если текущий уровень пройден И следующий уровень доступен по знаниям
            isUnlocked: currentSectionEffectivelyUnlocked && previousLevelConsideredUnlocked && isNextLevelAccessibleByLevel,
            color: _levelColors[nextLevelName] ?? Colors.grey, // Цвет следующего уровня
          )
        );
      }
    }

    // Если список пуст (например, для нового языка еще нет уроков в БД)
    if (_allLessonsForCurrentLanguage.isEmpty && !_isLoading) {
       adventurePathWidgets.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            child: Column(
              children: [
                Icon(Icons.explore_off_rounded, size: 80, color: Colors.grey[500]),
                SizedBox(height: 20),
                Text(
                  "Уроки для языка '${_getLanguageDisplayName(_currentLearningLanguage)}' скоро появятся!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        )
      );
    }


    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        // Фоновое изображение для "Пути Приключений"
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/adventure_background.png"), // ЗАМЕНИТЕ НА СВОЙ ФОН
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop) // Легкое затемнение фона
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          children: adventurePathWidgets,
        ),
      ),
    );
  }
  
  // Проверяет, доступен ли requiredLevel на основе текущего уровня пользователя userLevel
  bool _isLevelEffectivelyAccessible(String userLevel, String requiredLevel) {
    int userLevelIndex = _levelOrder.indexOf(userLevel);
    int requiredLevelIndex = _levelOrder.indexOf(requiredLevel);

    // Если уровень пользователя не найден в _levelOrder (например, "NotStarted" или кастомный),
    // считаем его ниже Beginner, если это не сам Beginner.
    if (userLevelIndex == -1 && userLevel.toLowerCase() != 'notstarted') {
      // Это может быть кастомный уровень или ошибка. Безопаснее считать его начальным.
      userLevelIndex = 0; // Предполагаем, что это Beginner или что-то перед ним.
    }
    
    // Специальная обработка для "NotStarted"
    if (userLevel.toLowerCase() == 'notstarted') {
        return requiredLevel == 'Beginner'; // Только Beginner доступен, если уровень "NotStarted"
    }

    return userLevelIndex >= requiredLevelIndex;
  }
  
  BottomNavigationBar _buildBottomNavigationBar() {
    // UI для BottomNavigationBar
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Чтобы все метки были видны
      currentIndex: _bottomNavSelectedIndex,
      onTap: (index) {
        if (!mounted) return;
        // Не перезагружать страницу, если мы уже на ней (особенно для LearnPage)
        if (_bottomNavSelectedIndex == index && index == 0) return; 

        setState(() { _bottomNavSelectedIndex = index; });
        // Навигация
        switch (index) {
          case 0: /* Уже на LearnPage */ break; 
          case 1: Navigator.pushReplacementNamed(context, '/games'); break;
          case 2: Navigator.pushReplacementNamed(context, '/notifications'); break; // Или '/chats'
          case 3: Navigator.pushReplacementNamed(context, '/settings'); break;
          case 4: Navigator.pushReplacementNamed(context, '/profile'); break;
        }
      },
      selectedItemColor: Colors.teal[800], // Цвет активного элемента
      unselectedItemColor: Colors.grey[700], // Цвет неактивных элементов
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Путь'), // Иконка для "Пути"
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded), label: 'Играть'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Чаты'), // Если есть чаты
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Настройки'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профиль'),
      ],
    );
  }
}

// ---- ВИДЖЕТ ДЛЯ СЕКЦИИ УРОВНЯ НА КАРТЕ ----
class _AdventureLevelSection extends StatelessWidget {
  final String levelName;
  final List<Lesson> lessons;
  final String userLevel; // Текущий уровень пользователя для этого языка
  final Map<String, int> userLessonProgress; // Прогресс по урокам
  final bool isEffectivelyUnlocked; // Секция в целом разблокирована?
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

  // Статический список уровней для проверки доступности конкретного урока внутри секции
  static const List<String> _levelOrderStatic = ['Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'];


  @override
  Widget build(BuildContext context) {
    // Не рисовать секцию (кроме Beginner), если она заблокирована и в ней нет уроков
    // (чтобы не было пустых заблокированных карточек, кроме самого начала)
    if (lessons.isEmpty && levelName != "Beginner" && !isEffectivelyUnlocked) {
      return SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0, top: 10.0), // Отступы между секциями
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isEffectivelyUnlocked ? 0.92 : 0.75), // Прозрачность для заблокированных
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEffectivelyUnlocked ? levelColor.withOpacity(0.7) : Colors.grey[400]!.withOpacity(0.5), 
          width: 2.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Заголовок уровня
          Row(
            children: [
              CircleAvatar(
                backgroundColor: levelColor.withOpacity(isEffectivelyUnlocked ? 0.15 : 0.05),
                child: Icon(levelIcon, color: isEffectivelyUnlocked ? levelColor : Colors.grey[500], size: 30),
                radius: 30,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  levelName,
                  style: TextStyle(
                    fontSize: 22, // Крупнее
                    fontWeight: FontWeight.bold,
                    color: isEffectivelyUnlocked ? Colors.black.withOpacity(0.85) : Colors.grey[600],
                  ),
                ),
              ),
              if (!isEffectivelyUnlocked)
                Icon(Icons.lock_person_rounded, color: Colors.grey[500], size: 30), // Иконка замка
            ],
          ),
          Divider(height: 25, thickness: 1, color: Colors.grey[300]), // Разделитель

          // Тело секции: уроки или сообщение
          if (lessons.isEmpty && isEffectivelyUnlocked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text("Уроки для этого уровня скоро появятся!", style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic, fontSize: 15)),
            )
          else if (!isEffectivelyUnlocked) // Если секция заблокирована
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
              child: Text("Пройдите предыдущий уровень, чтобы открыть эти уроки.", style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500, fontSize: 15), textAlign: TextAlign.center,),
            )
          else // Если разблокировано и есть уроки
            Wrap( // Используем Wrap для адаптивного размещения узлов уроков
              spacing: 12.0, // Горизонтальный отступ между узлами
              runSpacing: 15.0, // Вертикальный отступ, если узлы переносятся
              alignment: WrapAlignment.spaceAround, // Чтобы узлы распределялись лучше
              children: lessons.map((lesson) {
                final progress = userLessonProgress[lesson.id] ?? 0;
                // Доступность конкретного узла урока: секция должна быть разблокирована
                // И уровень пользователя должен быть не ниже требуемого для этого урока
                // (на случай, если внутри одной секции есть уроки с под-уровнями)
                bool isLessonNodeAccessible = isEffectivelyUnlocked && 
                                               (_levelOrderStatic.indexOf(userLevel) >= _levelOrderStatic.indexOf(lesson.requiredLevel));
                
                return _AdventureLessonNode(
                  lesson: lesson,
                  progress: progress,
                  isAccessible: isLessonNodeAccessible,
                  onTap: () => onLessonTap(lesson),
                  isAdmin: isAdmin,
                  onDelete: () => onDeleteLesson(lesson),
                  baseColor: levelColor, // Передаем базовый цвет уровня
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ---- ВИДЖЕТ ДЛЯ УЗЛА УРОКА НА КАРТЕ ----
class _AdventureLessonNode extends StatelessWidget {
  final Lesson lesson;
  final int progress;
  final bool isAccessible;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback onDelete;
  final Color baseColor; // Базовый цвет, наследуемый от уровня

  const _AdventureLessonNode({
    Key? key,
    required this.lesson,
    required this.progress,
    required this.isAccessible,
    required this.onTap,
    required this.isAdmin,
    required this.onDelete,
    required this.baseColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCompleted = progress >= 100;
    // Цвет узла: зеленый если пройден, базовый цвет уровня если доступен, серый если заблокирован
    Color activeColor = isCompleted ? Colors.green[600]! : baseColor;
    Color nodeColor = isAccessible ? activeColor : Colors.grey[400]!;
    // Иконка узла
    IconData nodeIconData = isAccessible 
        ? (isCompleted ? Icons.check_circle_rounded : Icons.stars_rounded) // Звезда для активного, галочка для пройденного
        : Icons.lock_rounded; // Замок для заблокированного

    // Иконка типа урока (если есть в модели Lesson)
    IconData lessonTypeIcon = Icons.article_outlined; // Иконка по умолчанию
    switch (lesson.lessonType.toLowerCase()) {
      case 'interactive': // Или 'chooseTranslation' как в админке
      case 'choosetranslation':
        lessonTypeIcon = Icons.touch_app_rounded; break;
      case 'audiolesson': lessonTypeIcon = Icons.volume_up_rounded; break;
      case 'videolesson': lessonTypeIcon = Icons.play_circle_fill_rounded; break;
      // Добавьте другие типы
    }


    return Opacity(
      opacity: isAccessible ? 1.0 : 0.65, // Меньшая прозрачность для заблокированных
      child: Column(
        mainAxisSize: MainAxisSize.min, // Чтобы колонка занимала минимум места
        children: [
          InkWell(
            onTap: isAccessible ? onTap : null,
            borderRadius: BorderRadius.circular(35), // Радиус для эффекта нажатия
            child: Container(
              width: 70, // Размер узла
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient( // Градиент для объема
                  colors: isAccessible 
                    ? [nodeColor.withOpacity(0.5), nodeColor] 
                    : [nodeColor.withOpacity(0.3), nodeColor.withOpacity(0.7)],
                  center: Alignment(0.3, -0.3), // Смещение центра для эффекта света
                ),
                border: Border.all(
                  color: isAccessible ? nodeColor.withOpacity(0.9) : Colors.grey[500]!, 
                  width: 3
                ),
                boxShadow: isAccessible ? [ // Тень только для доступных
                  BoxShadow(color: nodeColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 0, offset: Offset(2,2))
                ] : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Основная иконка (статус или тип урока)
                  Icon(isAccessible ? lessonTypeIcon : nodeIconData, color: Colors.white.withOpacity(isAccessible ? 0.9 : 0.6), size: 32),
                  // Иконка статуса поверх (если урок доступен)
                  if (isAccessible)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Icon(
                        isCompleted ? Icons.check_circle_outline_rounded : Icons.star_outline, 
                        color: Colors.white.withOpacity(0.8), 
                        size: 18
                      )
                    ),
                  // Прогресс, если урок начат, но не завершен
                  if (isAccessible && progress > 0 && !isCompleted)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          "$progress%",
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  // Кнопка удаления для админа
                  if (isAdmin && isAccessible)
                    Positioned(
                      top: -2, // Небольшое смещение для лучшего вида
                      right: -2,
                      child: InkWell(
                        onTap: onDelete,
                        child: CircleAvatar(
                          radius: 13, // Размер кнопки удаления
                          backgroundColor: Colors.redAccent.withOpacity(0.85),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 15),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          // Название урока
          SizedBox(
            width: 80, // Ограничиваем ширину текста, чтобы он переносился
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2, // Максимум 2 строки
              overflow: TextOverflow.ellipsis, // Многоточие, если не помещается
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isAccessible ? Colors.black.withOpacity(0.75) : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- ВИДЖЕТ ДЛЯ СОЕДИНИТЕЛЬНОЙ ТРОПИНКИ МЕЖДУ УРОВНЯМИ ----
class _PathConnector extends StatelessWidget {
  final bool isUnlocked; // Разблокирован ли путь к следующему уровню
  final Color color; // Цвет пути (обычно цвет следующего уровня)
  const _PathConnector({Key? key, required this.isUnlocked, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50, // Высота соединителя
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(20, 50), // Ширина и высота области рисования
        painter: _PathPainter(isUnlocked: isUnlocked, pathColor: color),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final bool isUnlocked;
  final Color pathColor;
  _PathPainter({required this.isUnlocked, required this.pathColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isUnlocked ? pathColor.withOpacity(0.8) : Colors.grey[400]!.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 // Толще тропинка
      ..strokeCap = StrokeCap.round; // Скругленные концы

    if (isUnlocked) {
      // Сплошная линия для разблокированного пути
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    } else {
      // Пунктирная линия для заблокированного пути
      double dashHeight = 6;
      double dashSpace = 4;
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(Offset(size.width / 2, startY), Offset(size.width / 2, startY + dashHeight), paint);
        startY += dashHeight + dashSpace;
      }
    }
    
    // Рисуем стрелку вниз, если путь разблокирован и есть место
    if (isUnlocked && size.height > 10) { // Рисуем стрелку только если есть место
      final arrowPaint = Paint()
        ..color = pathColor // Цвет стрелки совпадает с цветом пути
        ..style = PaintingStyle.fill;
      Path path = Path();
      double arrowSize = 6; // Размер стрелки
      // Рисуем треугольник-стрелку
      path.moveTo(size.width / 2 - arrowSize, size.height - (arrowSize * 1.5)); // Смещаем стрелку чуть выше от нижнего края
      path.lineTo(size.width / 2 + arrowSize, size.height - (arrowSize * 1.5));
      path.lineTo(size.width / 2, size.height - (arrowSize * 0.5)); // Вершина стрелки
      path.close();
      canvas.drawPath(path, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => 
    oldDelegate.isUnlocked != isUnlocked || oldDelegate.pathColor != pathColor;
}