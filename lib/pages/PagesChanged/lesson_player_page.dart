import 'dart:async';
import 'dart:ui'; // Для ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:flutter_languageapplicationmycourse_2/providers/user_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

class LessonPlayerPage extends StatefulWidget {
  final Lesson lesson;
  final Function(String lessonId, int newProgress) onProgressUpdated;

  const LessonPlayerPage({
    Key? key,
    required this.lesson,
    required this.onProgressUpdated,
  }) : super(key: key);

  @override
  _LessonPlayerPageState createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> with TickerProviderStateMixin {
  int _currentExerciseIndex = 0;
  int _correctAnswersCount = 0;
  Exercise? _currentExercise;

  String? _selectedOptionId; // Храним ID или уникальный текст опции
  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  String _feedbackMessage = "";

  late AnimationController _progressController;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScaleAnimation;
  late Animation<double> _feedbackOpacityAnimation;
  late AnimationController _optionsAppearController;
  late List<Animation<Offset>> _optionOffsetAnimations;
  late List<Animation<double>> _optionFadeAnimations;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;
  String _userInterfaceLanguage = 'russian';

  // --- НОВАЯ ЦВЕТОВАЯ ПАЛИТРА ---
  static const Color pageBackgroundStart = Color(0xFFFFE0B2); // Светло-персиковый
  static const Color pageBackgroundEnd = Color(0xFFFFF8E1); // Очень светло-кремовый

  static const Color appBarGradientStart = Color(0xFFF57C00); // Темно-оранжевый
  static const Color appBarGradientEnd = Color(0xFFFFA726);   // Средний оранжевый

  static const Color primaryActionColor = Color(0xFFFF9800); // Яркий оранжевый (для кнопок)
  static const Color primaryActionText = Colors.white;

  static const Color cardBackground = Colors.white;
  static const Color primaryTextColor = Color(0xFF5D4037); // Темно-коричневый
  static const Color secondaryTextColor = Color(0xFF8D6E63); // Средне-коричневый
  static const Color subtleTextColor = Color(0xFFA1887F); // Светло-коричневый

  static const Color correctColor = Color(0xFF66BB6A); // Мягкий зеленый
  static const Color correctColorLight = Color(0xFFE8F5E9);
  static const Color correctFeedbackText = Color(0xFF2E7D32);


  static const Color incorrectColor = Color(0xFFEF5350); // Мягкий красный
  static const Color incorrectColorLight = Color(0xFFFFEBEE);
  static const Color incorrectFeedbackText = Color(0xFFC62828);

  static const Color selectedOptionBorder = Color(0xFFFFB74D); // Светло-оранжевый для выделения
  static const Color selectedOptionBackground = Color(0xFFFFF3E0); // Очень светлый для фона выделения

  static const Color disabledButtonColor = Color(0xFFFBE9E7); // Бледный персиковый
  static const Color disabledButtonText = Color(0xFFBF360C);

  static const Color progressTrackColor = Color(0xFFFFCC80); // Бледный оранжевый
  static const Color progressValueColor = Color(0xFFFFC107); // Яркий желтый
  static const Color ttsIconColor = Color(0xFFE65100); // Глубокий оранжевый


  @override
  void initState() {
    super.initState();
    _currentExercise = widget.lesson.exercises.isNotEmpty ? widget.lesson.exercises[0] : null;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
      if (mounted) setState(() {});
    });

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackScaleAnimation = CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut);
    _feedbackOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Interval(0.0, 0.6, curve: Curves.easeOut))
    );
    
    _optionsAppearController = AnimationController(
      duration: const Duration(milliseconds: 700), // Немного дольше для более плавного появления
      vsync: this,
    );

    _initializeTts();
    _loadNextExercise(); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final UserLanguageSettings? langSettings = userProvider.currentUser?.languageSettings;
    final String? actualNewLanguageString = langSettings?.interfaceLanguage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (actualNewLanguageString != null && actualNewLanguageString != _userInterfaceLanguage) {
          setState(() {
            _userInterfaceLanguage = actualNewLanguageString;
          });
        }
      }
    });
  }

  Future<void> _initializeTts() async {
    try {
      if (widget.lesson.targetLanguage.isNotEmpty) {
          // Попытка установить более специфичный язык, если доступно, например, 'en-US'
          List<dynamic> languages = await _flutterTts.getLanguages;
          String targetLangCode = widget.lesson.targetLanguage.toLowerCase();
          if (targetLangCode == 'english') targetLangCode = 'en';

          String bestMatchLang = languages.firstWhere(
            (lang) => lang.toString().toLowerCase().startsWith(targetLangCode), 
            orElse: () => widget.lesson.targetLanguage // fallback
          );
          await _flutterTts.setLanguage(bestMatchLang);
      }
      // await _flutterTts.setSpeechRate(0.5); // Можно настроить скорость
      // await _flutterTts.setPitch(1.0); // И высоту тона
      _isTtsInitialized = true;
    } catch (e) {
      print("Ошибка инициализации TTS: $e");
      _isTtsInitialized = false;
    }
  }

  Future<void> _speakText(String text) async {
    if (_isTtsInitialized && text.isNotEmpty) {
      await _flutterTts.stop(); // Остановить предыдущее, если есть
      await _flutterTts.speak(text);
    } else if (text.isNotEmpty) {
      print("TTS не инициализирован или текст пуст.");
      // Можно показать пользователю сообщение об ошибке TTS, если это критично
    }
  }

  void _initOptionAnimations(int count) {
    _optionOffsetAnimations = List.generate(count, (index) => 
      Tween<Offset>(begin: Offset(0, 0.6 + index * 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _optionsAppearController, 
          curve: Interval(0.2 + index * 0.1, 0.8 + index * 0.05, curve: Curves.easeOutBack) // Каскадное появление
        )
      )
    );
    _optionFadeAnimations = List.generate(count, (index) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _optionsAppearController,
          curve: Interval(0.1 + index * 0.1, 0.6 + index * 0.05, curve: Curves.easeIn)
        )
      )
    );
  }

 void _loadNextExercise() {
    if (!mounted) return; 
    
    bool shouldShowSummaryImmediately = false;

    setState(() {
      _selectedOptionId = null;
      _isAnswerChecked = false;
      _isAnswerCorrect = false;
      _feedbackMessage = "";
      
      if (_optionsAppearController.isAnimating || _optionsAppearController.isCompleted) {
        _optionsAppearController.reset();
      }
      _feedbackController.reset();


      if (_currentExerciseIndex < widget.lesson.exercises.length) {
        _currentExercise = widget.lesson.exercises[_currentExerciseIndex];
         // Инициализация анимаций для опций текущего упражнения
        List<dynamic> optionsRaw = _currentExercise?.optionsData?[widget.lesson.targetLanguage] ?? 
                                   _currentExercise?.optionsData?['russian'] ?? [];
        _initOptionAnimations(optionsRaw.length);

        _progressController.animateTo((_currentExerciseIndex + 1) / widget.lesson.exercises.length);
        _optionsAppearController.forward();
      } else {
        _currentExercise = null;
        if (mounted) { 
             shouldShowSummaryImmediately = true;
        }
      }
    });

    if (shouldShowSummaryImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { 
          _showLessonSummary();
        }
      });
    }
  }

  void _checkAnswer(String selectedOptionText) {
    if (_currentExercise == null || _isAnswerChecked || !mounted) return;

    String localizedSelectedOptionText = selectedOptionText;
    String? correctOptionTextInTargetLang;
    bool foundCorrect = false;

    // Получаем опции для целевого языка урока, или для русского как fallback
    List<dynamic> optionsForTargetLanguage = _currentExercise!.optionsData?[widget.lesson.targetLanguage] ?? 
                                              _currentExercise!.optionsData?['russian'] ?? [];
    
    // Сначала найдем правильный ответ на целевом языке для фидбека
    for (var optionEntry in optionsForTargetLanguage) {
      if (optionEntry is Map) {
        Map<String, dynamic> optionMap = Map<String, dynamic>.from(optionEntry);
        if (optionMap['isCorrect'] == true) {
            correctOptionTextInTargetLang = optionMap['text']?.toString();
            break; 
        }
      }
    }
    
    // Теперь проверяем выбранный ответ
    for (var optionEntry in optionsForTargetLanguage) {
      if (optionEntry is Map) {
        Map<String, dynamic> optionMap = Map<String, dynamic>.from(optionEntry);
        if (optionMap['text']?.toString() == localizedSelectedOptionText) {
            if (optionMap['isCorrect'] == true) {
                foundCorrect = true;
                _feedbackMessage = optionMap['feedback']?.toString() ?? _currentExercise!.getLocalizedFeedbackCorrect(_userInterfaceLanguage);
            } else {
                 _feedbackMessage = optionMap['feedback']?.toString() ?? _currentExercise!.getLocalizedFeedbackIncorrect(_userInterfaceLanguage, actualCorrectAnswer: correctOptionTextInTargetLang);
            }
            break; // Выбранная опция найдена, выходим из цикла
        }
      }
    }
    
    // Если фидбек не был установлен (например, структура optionsData невалидна)
    if (_feedbackMessage.isEmpty) {
        if (foundCorrect) {
            _feedbackMessage = _currentExercise!.getLocalizedFeedbackCorrect(_userInterfaceLanguage);
        } else {
            _feedbackMessage = _currentExercise!.getLocalizedFeedbackIncorrect(_userInterfaceLanguage, actualCorrectAnswer: correctOptionTextInTargetLang);
        }
    }
    
    _isAnswerCorrect = foundCorrect;

    if (!mounted) return;
    setState(() {
      _isAnswerChecked = true;
      if (_isAnswerCorrect) {
        _correctAnswersCount++;
        _playSound('correct.mp3'); // Используем более общие имена
      } else {
        _playSound('incorrect.mp3');
      }
    });
    _feedbackController.forward(from: 0.0);
  }

 void _handleNext() {
  if (!mounted) return;
  if (!_isAnswerChecked && _currentExercise != null) { // Если пользователь нажал "Далее", не выбрав ответ
    setState(() {
      _selectedOptionId = "SKIPPED_BY_USER"; // специальное значение
      _isAnswerChecked = true;
      _isAnswerCorrect = false; // Считаем пропуск как неверный ответ

      String correctAnswerText = _getCorrectAnswerText(_currentExercise!) ?? "Неизвестно";
      // Формируем сообщение о пропуске здесь, а не в модели
      if (_userInterfaceLanguage == 'russian') {
         _feedbackMessage = "Вы пропустили. Правильный ответ: \"$correctAnswerText\".";
      } else { // Предположим, английский
         _feedbackMessage = "You skipped this. The correct answer was: \"$correctAnswerText\".";
      }
      // Можно также использовать общий метод из Exercise, если он просто возвращает "Неверно",
      // а потом добавлять информацию о правильном ответе, но это менее гибко.
      // _feedbackMessage = _currentExercise!.getLocalizedFeedbackIncorrect(
      //     _userInterfaceLanguage,
      //     actualCorrectAnswer: correctAnswerText
      // );
    });
    _feedbackController.forward(from: 0.0);
    return;
  }
    if (_currentExerciseIndex < widget.lesson.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
      _loadNextExercise();
    } else {
      _showLessonSummary();
    }
  }

 String? _getCorrectAnswerText(Exercise exercise) {
    List<dynamic> options = exercise.optionsData?[widget.lesson.targetLanguage] ??
                             exercise.optionsData?['russian'] ?? [];
    for (var optionEntry in options) {
      if (optionEntry is Map) {
        Map<String, dynamic> optionMap = Map<String, dynamic>.from(optionEntry);
        if (optionMap['isCorrect'] == true) {
          return optionMap['text']?.toString();
        }
      }
    }
    return null;
  }


  void _showLessonSummary() {
    if (!mounted) return;
    _progressController.animateTo(1.0);
    final int totalQuestions = widget.lesson.exercises.length;
    final int progressPercentage = totalQuestions > 0 ? ((_correctAnswersCount / totalQuestions) * 100).round() : 0;
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onProgressUpdated(widget.lesson.id, progressPercentage);
      }
    });

    if (ModalRoute.of(context)?.isCurrent ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BackdropFilter( // Эффект размытия фона
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            titlePadding: const EdgeInsets.only(top: 30),
            title: Center(
              child: Text(
                "Урок Завершен!", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: primaryActionColor),
              )
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.amber[600], size: 80),
                SizedBox(height: 25),
                Text(
                  "Ваш результат:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor),
                ),
                SizedBox(height: 12),
                Text(
                  "$_correctAnswersCount из $totalQuestions",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                SizedBox(height: 8),
                Text(
                  "($progressPercentage% правильно)",
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
                ),
                SizedBox(height: 30),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            actions: [
              ElevatedButton.icon(
                icon: Icon(Icons.school_rounded, color: primaryActionText),
                label: Text("К Урокам", style: TextStyle(color: primaryActionText, fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context); 
                  if (Navigator.canPop(context)) Navigator.pop(context); 
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _playSound(String assetName) async { // assetName 'correct.mp3' or 'incorrect.mp3'
    try {
      // await _audioPlayer.play(AssetSource('sounds/$assetName')); // Убедитесь, что звуки в assets/sounds/
      print("Playing sound: sounds/$assetName");
    } catch (e) {
      print("Error playing sound $assetName: $e");
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _feedbackController.dispose();
    _optionsAppearController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _currentExercise;

    return Scaffold(
      extendBodyBehindAppBar: true, // Для градиента под статус баром
      appBar: AppBar(
        title: Text(
          widget.lesson.title, 
          style: TextStyle(color: primaryActionText, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0, // Убираем стандартную тень, будем делать свою
        backgroundColor: Colors.transparent, // Прозрачный для градиента
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: primaryActionText, size: 28),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appBarGradientStart, appBarGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)
            ),
            boxShadow: [
              BoxShadow(
                color: appBarGradientStart.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0,4)
              )
            ]
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(8.0), // Немного толще
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0), // Отступы для скругления
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _progressController.value,
                  backgroundColor: progressTrackColor.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(progressValueColor),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container( // Градиент для всего фона страницы
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [pageBackgroundStart, pageBackgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
        child: exercise == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryActionColor),
                    SizedBox(height: 20),
                    Text("Загрузка...", style: TextStyle(color: primaryTextColor, fontSize: 18))
                  ],
                ))
            : SafeArea( // Чтобы контент не залезал под AppBar и BottomNavBar (если он есть)
                top: true, // Учитываем AppBar (SafeArea не всегда нужен сверху если appBar не transparent)
                bottom: false, // BottomBar будет сам обрабатывать safe area
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0), // Отступ сверху больше из-за AppBar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPromptSection(exercise),
                      SizedBox(height: 25),
                      _buildOptionsSection(exercise),
                      SizedBox(height: 30), // Запас места до нижнего бара
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: exercise != null ? _buildBottomBar(exercise) : null,
    );
  }

  Widget _buildPromptSection(Exercise exercise) {
    String promptText = exercise.questionText ?? exercise.getLocalizedPrompt(_userInterfaceLanguage);
    bool hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;
    bool isGif = hasImage && (exercise.imageUrl!.toLowerCase().endsWith('.gif'));

    return Card(
      elevation: 6, // Увеличил тень
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Более круглые углы
      margin: const EdgeInsets.only(bottom: 16),
      color: cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Увеличил паддинги
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Вопрос ${_currentExerciseIndex + 1} / ${widget.lesson.exercises.length}",
                  style: TextStyle(fontSize: 15, color: secondaryTextColor, fontWeight: FontWeight.w600),
                ),
                if (_isTtsInitialized && promptText.isNotEmpty && (widget.lesson.targetLanguage.toLowerCase().startsWith('en')))
                  Material( // Обертка для InkWell с эффектом
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _speakText(promptText),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(Icons.volume_up_rounded, color: ttsIconColor, size: 28),
                      ),
                    ),
                  )
              ],
            ),
            SizedBox(height: 15),
            Text(
              promptText,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor, height: 1.4), // Увеличил line height
              textAlign: TextAlign.center,
            ),
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(top: 25.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.33, // Чуть меньше
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), // Более круглые углы
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: isGif
                        ? Image.network(
                            exercise.imageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null, color: primaryActionColor));
                            },
                            errorBuilder: (context, error, stackTrace) => _imageErrorPlaceholder(),
                          )
                        : CachedNetworkImage(
                            imageUrl: exercise.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator(color: primaryActionColor)),
                            errorWidget: (context, url, error) => _imageErrorPlaceholder(),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16)
      ),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.red[300]?.withOpacity(0.7), size: 70),
      ),
    );
  }

  Widget _buildOptionsSection(Exercise exercise) {
    List<dynamic> optionsRaw = exercise.optionsData?[widget.lesson.targetLanguage] ?? 
                               exercise.optionsData?['russian'] ?? [];
    List<Map<String, dynamic>> options = optionsRaw.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();

    if (options.isEmpty) {
      return Center(child: Text("Нет вариантов ответа.", style: TextStyle(color: incorrectColor, fontSize: 16)));
    }
    // Если анимации еще не инициализированы для текущего количества опций
    if (_optionOffsetAnimations.isEmpty || _optionOffsetAnimations.length != options.length) {
      _initOptionAnimations(options.length); // Переинициализируем
       WidgetsBinding.instance.addPostFrameCallback((_) { // Запускаем анимацию после билда
        if(mounted && !_optionsAppearController.isCompleted) _optionsAppearController.forward(from: 0.0);
      });
    }


    return Column(
      children: List.generate(options.length, (index) {
        final optionMap = options[index];
        final optionText = optionMap['text']?.toString() ?? "Ошибка опции";
        bool isSelected = _selectedOptionId == optionText || (_selectedOptionId == "SKIPPED_BY_USER" && optionMap['isCorrect'] == true && _isAnswerChecked);
        bool? isCorrectForThisOption;

        if (_isAnswerChecked) {
          if (optionMap['isCorrect'] == true) {
            isCorrectForThisOption = true; // Всегда показываем правильный как правильный
          } else if (isSelected && optionMap['isCorrect'] == false) {
            isCorrectForThisOption = false; // Если выбран неправильный, показываем его как неправильный
          }
          // Остальные (не выбранные и не правильные) остаются нейтральными
        }

        return FadeTransition(
          opacity: _optionFadeAnimations[index],
          child: SlideTransition(
            position: _optionOffsetAnimations[index],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7.0), // Немного ближе друг к другу
              child: _OptionButton(
                text: optionText,
                isSelected: isSelected,
                isCorrect: isCorrectForThisOption,
                showAsCorrectOnly: _selectedOptionId == "SKIPPED_BY_USER" && optionMap['isCorrect'] == true && _isAnswerChecked, // Для выделения правильного при пропуске
                onTap: _isAnswerChecked ? null : () {
                   if (mounted) {
                    setState(() {
                      _selectedOptionId = optionText;
                    });
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar(Exercise exercise) {
    Color feedbackBackgroundColor = _isAnswerCorrect ? correctColorLight : incorrectColorLight;
    Color feedbackTextColor = _isAnswerCorrect ? correctFeedbackText : incorrectFeedbackText;
    IconData feedbackIcon = _isAnswerCorrect ? Icons.check_circle_rounded : Icons.highlight_off_rounded; // Другая иконка для ошибки

    String buttonText = _isAnswerChecked ? "Далее" : "Проверить";
    Color buttonColor;
    VoidCallback? buttonAction;

    if (_isAnswerChecked) {
      buttonColor = _isAnswerCorrect ? correctColor : incorrectColor;
      buttonAction = _handleNext;
    } else {
      if (_selectedOptionId != null && _selectedOptionId != "SKIPPED_BY_USER") {
        buttonColor = primaryActionColor;
        buttonAction = () => _checkAnswer(_selectedOptionId!);
      } else {
        // Кнопка "Пропустить", если ничего не выбрано (или "Проверить", если не разрешен пропуск)
        // Пока сделаем ее неактивной, если ничего не выбрано
        buttonColor = disabledButtonColor; // Или Colors.grey если нужен другой вид
        buttonAction = _currentExercise != null ? _handleNext : null; // Позволяет пропустить, если exercise есть
        buttonText = "Пропустить";
      }
    }


    return Material( // Обертка для тени и цвета фона
      elevation: 10,
      color: _isAnswerChecked ? feedbackBackgroundColor : cardBackground, // Фон зависит от состояния
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 15,
          bottom: 15 + MediaQuery.of(context).padding.bottom, // Учет SafeArea снизу
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAnswerChecked)
              FadeTransition(
                opacity: _feedbackOpacityAnimation,
                child: ScaleTransition(
                  scale: _feedbackScaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Row(
                      children: [
                        Icon(feedbackIcon, color: feedbackTextColor, size: 30),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: feedbackTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: primaryActionText, // Цвет текста на кнопке
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Более круглые углы
                elevation: buttonAction != null ? 3 : 0, // Тень только для активной кнопки
              ),
              onPressed: buttonAction,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect; // true, false, или null (не проверено)
  final bool showAsCorrectOnly; // Для выделения правильного при пропуске
  final VoidCallback? onTap;

  const _OptionButton({
    Key? key,
    required this.text,
    required this.isSelected,
    this.isCorrect,
    this.showAsCorrectOnly = false,
    this.onTap,
  }) : super(key: key);

  // Цвета извлекаем из темы _LessonPlayerPageState
  static const Color _primaryTextColor = _LessonPlayerPageState.primaryTextColor;
  static const Color _selectedTextColor = _LessonPlayerPageState.primaryTextColor; // Может быть другим
  static const Color _correctTextColor = _LessonPlayerPageState.correctFeedbackText;
  static const Color _incorrectTextColor = _LessonPlayerPageState.incorrectFeedbackText;

  static const Color _defaultBorder = Color(0xFFDCDCDC); // Светло-серый
  static const Color _selectedBorder = _LessonPlayerPageState.selectedOptionBorder;
  static const Color _correctBorder = _LessonPlayerPageState.correctColor;
  static const Color _incorrectBorder = _LessonPlayerPageState.incorrectColor;

  static const Color _defaultBackground = _LessonPlayerPageState.cardBackground;
  static const Color _selectedBackground = _LessonPlayerPageState.selectedOptionBackground;
  static const Color _correctBackground = _LessonPlayerPageState.correctColorLight;
  static const Color _incorrectBackground = _LessonPlayerPageState.incorrectColorLight;


  @override
  Widget build(BuildContext context) {
    Color borderColor = _defaultBorder;
    Color backgroundColor = _defaultBackground;
    Color textColor = _primaryTextColor;
    IconData? trailingIcon;
    Color? iconColor;
    double borderWidth = 1.5;
    FontWeight fontWeight = FontWeight.w500;

    if (showAsCorrectOnly) { // Специальный режим для подсветки правильного ответа при пропуске
        borderColor = _correctBorder;
        backgroundColor = _correctBackground;
        textColor = _correctTextColor;
        trailingIcon = Icons.check_circle_outline_rounded;
        iconColor = _correctTextColor;
        borderWidth = 2.5;
        fontWeight = FontWeight.bold;
    } else if (isCorrect != null) { // Если ответ проверен
      if (isCorrect!) { // Правильный ответ
        borderColor = _correctBorder;
        backgroundColor = _correctBackground;
        textColor = _correctTextColor;
        if (isSelected || onTap == null) { // Если выбран или это просто индикация правильного
             trailingIcon = Icons.check_circle_rounded;
             iconColor = _correctTextColor;
             fontWeight = FontWeight.bold;
        }
        borderWidth = 2.5;
      } else { // Неправильный ответ
        if (isSelected) { // И он был выбран пользователем
          borderColor = _incorrectBorder;
          backgroundColor = _incorrectBackground;
          textColor = _incorrectTextColor;
          trailingIcon = Icons.cancel_rounded;
          iconColor = _incorrectTextColor;
          borderWidth = 2.5;
          fontWeight = FontWeight.bold;
        } else {
          // Не выбранный и не правильный - остается по умолчанию
        }
      }
    } else if (isSelected) { // Если выбран, но еще не проверен
      borderColor = _selectedBorder;
      backgroundColor = _selectedBackground;
      textColor = _selectedTextColor; // Можно использовать primaryTextColor или специальный
      borderWidth = 2.5;
      fontWeight = FontWeight.w600;
    }

    return Material(
      color: Colors.transparent, // Материал для InkWell и тени
      elevation: onTap != null && (isSelected || isCorrect != null) ? 4 : 1, // Тень побольше для активных
      shadowColor: borderColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(16), // Более круглые углы
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _selectedBorder.withOpacity(0.3),
        highlightColor: _selectedBorder.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Увеличил паддинги
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.start, // Текст слева для лучшей читаемости
                  style: TextStyle(fontSize: 18, fontWeight: fontWeight, color: textColor),
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: 12),
                Icon(trailingIcon, color: iconColor, size: 26),
              ]
            ],
          ),
        ),
      ),
    );
  }
}