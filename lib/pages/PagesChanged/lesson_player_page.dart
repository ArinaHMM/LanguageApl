import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- ДОБАВЛЕН ЭТОТ ИМПОРТ
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart'; // Для получения interfaceLanguage
import 'package:audioplayers/audioplayers.dart'; // Для воспроизведения аудио (если понадобится для фидбека)
import 'package:provider/provider.dart'; // Для доступа к данным пользователя, если используется Provider

// Пример простого UserProvider, если вы не используете более сложный state management
// Если у вас есть свой UserProvider, используйте его.
class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
  // Вам нужно будет где-то инициализировать UserProvider с актуальными данными пользователя
}


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

  // Состояние для текущего упражнения
  String? _selectedOptionId; // ID выбранного варианта (если у вариантов есть ID) или сам текст
  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  String _feedbackMessage = "";

  // Анимации
  late AnimationController _progressController;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _optionsAppearController;

  // Для аудио и TTS
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;
  String _userInterfaceLanguage = 'russian'; // Язык интерфейса пользователя

  @override
  void initState() {
    super.initState();
    _currentExercise = widget.lesson.exercises.isNotEmpty ? widget.lesson.exercises[0] : null;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      setState(() {}); // Перерисовываем индикатор прогресса
    });

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnimation = CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut);
    
    _optionsAppearController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _initializeTts();
    // Получаем язык интерфейса пользователя (пример, если используете Provider)
    // final userProvider = Provider.of<UserProvider>(context, listen: false);
    // if (userProvider.currentUser?.languageSettings?.interfaceLanguage != null) {
    //   _userInterfaceLanguage = userProvider.currentUser!.languageSettings!.interfaceLanguage;
    // }
    // Если не Provider, вам нужно передать interfaceLanguage или получить его другим способом

    _loadNextExercise();
  }

  Future<void> _initializeTts() async {
    try {
      // Установка языка для TTS - используем язык урока
      await _flutterTts.setLanguage(widget.lesson.targetLanguage);
      // Другие настройки TTS, если нужны (скорость, высота тона)
      // await _flutterTts.setSpeechRate(0.5);
      // await _flutterTts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (e) {
      print("Ошибка инициализации TTS: $e");
    }
  }

  Future<void> _speakText(String text) async {
    if (_isTtsInitialized && text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  void _loadNextExercise() {
    setState(() {
      _selectedOptionId = null;
      _isAnswerChecked = false;
      _isAnswerCorrect = false;
      _feedbackMessage = "";
      _optionsAppearController.reset(); // Сброс анимации для новых вариантов

      if (_currentExerciseIndex < widget.lesson.exercises.length) {
        _currentExercise = widget.lesson.exercises[_currentExerciseIndex];
        _progressController.animateTo((_currentExerciseIndex + 1) / widget.lesson.exercises.length);
        _optionsAppearController.forward(); // Запуск анимации появления вариантов
      } else {
        // Урок завершен
        _currentExercise = null;
        _showLessonSummary();
      }
    });
  }

  void _checkAnswer(String selectedOptionText) {
    if (_currentExercise == null || _isAnswerChecked) return;

    final correctAnswerText = _currentExercise!.getLocalizedCorrectAnswer(widget.lesson.targetLanguage);
    // В вашей модели Exercise нет ID у опций, поэтому сравниваем по тексту.
    // Если бы были ID, было бы надежнее.
    // В модели LessonTask из админки у TaskOption есть isCorrect. Мы будем полагаться на это поле.
    // Но, в Exercise.fromMap нужно будет правильно смапить `isCorrect` из `TaskOption`.
    // Сейчас `Exercise.getLocalizedCorrectAnswer` вернет текст правильного ответа.

    // Адаптация под структуру TaskOption из админки, где isCorrect уже есть
    // Предположим, что Exercise.optionsData теперь хранит список Map<String,dynamic> с 'text' и 'isCorrect'
    String localizedSelectedOptionText = selectedOptionText; // Если опции уже на targetLanguage
    String? correctOptionTextInTargetLang;
    bool foundCorrect = false;

    // Ищем правильный вариант в опциях текущего упражнения (Exercise)
    // Это требует, чтобы модель Exercise.optionsData содержала информацию о isCorrect
    // или чтобы getLocalizedCorrectAnswer возвращал точный текст правильного варианта
    // ВАЖНО: Для этого модель Exercise и ее парсер fromMap должны быть доработаны
    // чтобы optionsData содержал не просто List<String>, а List<Map<String, dynamic>>
    // где каждый Map это {'text': '...', 'isCorrect': true/false, 'feedback': '...'}
    // Либо, если lesson.exercises содержит напрямую объекты TaskOption из админки
    // (после правильного маппинга в Lesson.fromFirestore), то можно использовать их.

    // Давайте упростим: будем считать, что _currentExercise.optionsData содержит Map<String, List<Map<String,dynamic>>>
    // где ключ - язык, значение - список опций, каждая опция - Map с 'text' и 'isCorrect'
    List<dynamic> optionsForTargetLanguage = _currentExercise!.optionsData?[widget.lesson.targetLanguage] ?? 
                                              _currentExercise!.optionsData?['russian'] ?? [];
    
    for (var optionEntry in optionsForTargetLanguage) {
      if (optionEntry is Map) {
        Map<String, dynamic> optionMap = Map<String, dynamic>.from(optionEntry);
        if (optionMap['isCorrect'] == true) {
            correctOptionTextInTargetLang = optionMap['text']?.toString();
        }
        if (optionMap['text']?.toString() == localizedSelectedOptionText && optionMap['isCorrect'] == true) {
            foundCorrect = true;
            _feedbackMessage = optionMap['feedback']?.toString() ?? _currentExercise!.getLocalizedFeedbackCorrect(_userInterfaceLanguage);
            break;
        } else if (optionMap['text']?.toString() == localizedSelectedOptionText && optionMap['isCorrect'] == false) {
            _feedbackMessage = optionMap['feedback']?.toString() ?? _currentExercise!.getLocalizedFeedbackIncorrect(_userInterfaceLanguage, actualCorrectAnswer: correctOptionTextInTargetLang);
            break;
        }
      }
    }
    
    _isAnswerCorrect = foundCorrect;


    setState(() {
      _isAnswerChecked = true;
      if (_isAnswerCorrect) {
        _correctAnswersCount++;
        _playSound('correct_answer.mp3'); // Замените на ваш аудиофайл
      } else {
        _playSound('wrong_answer.mp3'); // Замените на ваш аудиофайл
      }
    });
    _feedbackController.forward(from: 0.0);
  }

  void _handleNext() {
    if (!_isAnswerChecked && _currentExercise != null) {
        // Если ответ не был выбран, но пользователь нажал "Далее" (например, в режиме пропуска)
        // Засчитываем как неправильный или просто переходим дальше без фидбека
        setState(() {
            _isAnswerChecked = true; // Помечаем, что проверено (или пропущено)
            _isAnswerCorrect = false; // Считаем пропуск ошибкой
            _feedbackMessage = "Вы пропустили это задание."; // Или другой фидбек
        });
        _feedbackController.forward(from:0.0); // Показать фидбек
        return; // Ждем нажатия "Далее" еще раз после фидбека
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

  void _showLessonSummary() {
    _progressController.animateTo(1.0); // Заполняем прогресс-бар до конца
    final int totalQuestions = widget.lesson.exercises.length;
    final int progressPercentage = totalQuestions > 0 ? ((_correctAnswersCount / totalQuestions) * 100).round() : 0;

    widget.onProgressUpdated(widget.lesson.id, progressPercentage);

    showDialog(
      context: context,
      barrierDismissible: false, // Пользователь должен нажать кнопку
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text("Урок пройден!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber[600], size: 70),
            SizedBox(height: 20),
            Text(
              "Ваш результат:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Text(
              "$_correctAnswersCount из $totalQuestions правильных ответов",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Прогресс: $progressPercentage%",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 25),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            label: Text("К списку уроков"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                textStyle: TextStyle(fontSize: 16)
            ),
            onPressed: () {
              Navigator.pop(context); // Закрыть диалог
              Navigator.pop(context); // Вернуться на LearnPage
            },
          ),
        ],
      ),
    );
  }

  Future<void> _playSound(String assetPath) async {
    // Убедитесь, что у вас есть папка assets/audio и файлы в ней
    // и они прописаны в pubspec.yaml
    try {
      // await _audioPlayer.play(AssetSource(assetPath)); // Для пакета audioplayers >=1.0.0
      // Для старых версий:
      // final AssetSource source = AssetSource(assetPath);
      // await _audioPlayer.play(source);
      // В новой версии audioplayers, если файл в assets/audio/correct_answer.mp3
      // то AssetSource('audio/correct_answer.mp3')
      // Пока заглушка, так как настройка аудио требует файла и pubspec.yaml
      print("Playing sound: $assetPath");
    } catch (e) {
      print("Error playing sound: $e");
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
    final exercise = _currentExercise; // Текущее упражнение

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Color.lerp(Colors.teal[700], Colors.indigo[700], _progressController.value), // Динамический цвет AppBar
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Просто выход из урока
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: _progressController.value,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent[400]!),
          ),
        ),
      ),
      body: exercise == null
          ? Center(child: Text("Загрузка упражнения...")) // Или "Урок завершен" перед диалогом
          : SingleChildScrollView( // Позволяет прокручивать, если контент не помещается
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Блок вопроса ---
                  _buildPromptSection(exercise),
                  SizedBox(height: 20),

                  // --- Блок вариантов ответа ---
                  _buildOptionsSection(exercise),
                  SizedBox(height: 30),
                ],
              ),
            ),
      // --- Нижняя панель с кнопкой "Проверить" / "Далее" и фидбеком ---
      bottomNavigationBar: _buildBottomBar(exercise),
    );
  }

 // lib/pages/PagesChanged/lesson_player_page.dart

// ... (импорты и остальная часть класса без изменений) ...

  Widget _buildPromptSection(Exercise exercise) {
    String promptText = exercise.questionText ?? exercise.getLocalizedPrompt(_userInterfaceLanguage);
    bool hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;
    bool isGif = hasImage && (exercise.imageUrl!.toLowerCase().endsWith('.gif'));

    return Card(
      elevation: 4, // Немного увеличим тень для выделения
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Более скругленные углы
      margin: const EdgeInsets.only(bottom: 16), // Отступ снизу
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем дочерние элементы по ширине
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Задание ${_currentExerciseIndex + 1} из ${widget.lesson.exercises.length}",
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey[600], fontWeight: FontWeight.w500),
                ),
                if (_isTtsInitialized && promptText.isNotEmpty && (widget.lesson.targetLanguage == 'english' || widget.lesson.targetLanguage == 'en-US'))
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: Theme.of(context).colorScheme.secondary), // Используем цвет из темы
                    onPressed: () => _speakText(promptText),
                    tooltip: "Озвучить",
                  )
              ],
            ),
            SizedBox(height: 12),
            Text(
              promptText,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.85)), // Чуть темнее текст
              textAlign: TextAlign.center,
            ),
            // --- Блок для изображения/GIF ---
            if (hasImage)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                  constraints: BoxConstraints(
                    // Ограничиваем максимальную высоту, чтобы не занимало весь экран
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ]
                  ),
                  child: ClipRRect( // Обрезаем по скругленным углам
                    borderRadius: BorderRadius.circular(12.0),
                    child: isGif
                        ? Image.network( // Используем Image.network для GIF
                            exercise.imageUrl!,
                            fit: BoxFit.contain, // Сохраняем пропорции, вписывая в контейнер
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 50, height: 50, // Размер индикатора
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined, color: Colors.red[300], size: 60),
                                ),
                              );
                            },
                          )
                        : CachedNetworkImage( // CachedNetworkImage для статических изображений
                            imageUrl: exercise.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200], // Фон для плейсхолдера
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).primaryColor)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Center(child: Icon(Icons.hide_image_outlined, color: Colors.grey[400], size: 60)),
                            ),
                            // maxHeightDiskCache не всегда применим для fit: BoxFit.contain,
                            // но можно оставить, если ваши изображения одного размера.
                            // Лучше управлять размером через constraints контейнера.
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// ... (остальной код _LessonPlayerPageState без изменений) ...
  Widget _buildOptionsSection(Exercise exercise) {
    // Отображение вариантов ответа
    // List<String> options = exercise.getLocalizedOptions(widget.lesson.targetLanguage);
    // Адаптация под структуру, где optionsData - это Map<String, List<Map<String, dynamic>>>
    List<dynamic> optionsRaw = exercise.optionsData?[widget.lesson.targetLanguage] ?? 
                               exercise.optionsData?['russian'] ?? [];
    List<Map<String, dynamic>> options = optionsRaw.whereType<Map>().map((e) => Map<String,dynamic>.from(e)).toList();


    if (options.isEmpty) {
      return Center(child: Text("Нет вариантов ответа для этого упражнения.", style: TextStyle(color: Colors.red)));
    }

    return Column(
      children: List.generate(options.length, (index) {
        final optionMap = options[index];
        final optionText = optionMap['text']?.toString() ?? "Ошибка опции";
        bool isSelected = _selectedOptionId == optionText; // Сравнение по тексту
        bool? isCorrectForThisOption;
        if (_isAnswerChecked) {
            // Определяем, был ли этот вариант правильным или неправильным, ЕСЛИ он был выбран
            if (isSelected) {
                 isCorrectForThisOption = _isAnswerCorrect;
            } else {
                // Если этот вариант не был выбран, но он ПРАВИЛЬНЫЙ, подсвечиваем его зеленым
                if (optionMap['isCorrect'] == true) {
                    isCorrectForThisOption = true; // Подсветить правильный, даже если не выбран
                }
            }
        }


        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.5 + index * 0.2), // Начинают снизу и с задержкой
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _optionsAppearController, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: _optionsAppearController,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _OptionButton(
                text: optionText,
                isSelected: isSelected,
                isCorrect: isCorrectForThisOption, // null если не проверено, true/false если проверено
                onTap: _isAnswerChecked ? null : () { // Блокируем тап после проверки
                  setState(() {
                    _selectedOptionId = optionText;
                  });
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar(Exercise? exercise) {
    Color feedbackColor = _isAnswerCorrect ? Colors.green[600]! : Colors.red[600]!;
    IconData feedbackIcon = _isAnswerCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: _isAnswerChecked ? 12 : (12 + MediaQuery.of(context).padding.bottom), // Учитываем safe area, если фидбека нет
      ),
      decoration: BoxDecoration(
        color: _isAnswerChecked ? feedbackColor.withOpacity(0.12) : Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.8)),
         boxShadow: _isAnswerChecked ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, -2))
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isAnswerChecked)
            ScaleTransition(
              scale: _feedbackAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(feedbackIcon, color: feedbackColor, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: feedbackColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAnswerChecked
                  ? (_isAnswerCorrect ? Colors.green[600] : Colors.red[500]) // Кнопка меняет цвет в зависимости от правильности
                  : (_selectedOptionId != null ? Colors.blue[600] : Colors.grey[500]), // Синяя, если выбран вариант, серая если нет
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (exercise == null || (_selectedOptionId == null && !_isAnswerChecked))
                ? null // Блокируем, если нет упражнения или не выбран вариант (и ответ еще не проверялся)
                : _isAnswerChecked ? _handleNext : () => _checkAnswer(_selectedOptionId!),
            child: Text(
              _isAnswerChecked ? "Далее" : "Проверить",
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (!_isAnswerChecked && MediaQuery.of(context).padding.bottom > 0)
             SizedBox(height: MediaQuery.of(context).padding.bottom), // Добавляем отступ для safe area только если фидбека нет
        ],
      ),
    );
  }
}

// --- Вспомогательный виджет для кнопки варианта ответа ---
class _OptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect; // null, если не проверено, true/false если проверено
  final VoidCallback? onTap;

  const _OptionButton({
    Key? key,
    required this.text,
    required this.isSelected,
    this.isCorrect,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey[300]!;
    Color backgroundColor = Colors.white;
    Color textColor = Colors.black87;
    IconData? trailingIcon;
    Color? iconColor;

    if (isSelected) {
      borderColor = Theme.of(context).primaryColor;
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
    }

    if (isCorrect != null) { // Если ответ проверен
      if (isCorrect!) { // Правильный ответ
        borderColor = Colors.green[600]!;
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        if (isSelected) trailingIcon = Icons.check_circle_rounded; // Галочка, если выбран И правильный
        iconColor = Colors.green[700];
      } else { // Неправильный ответ
        if (isSelected) { // Только если этот вариант был выбран и он неправильный
            borderColor = Colors.red[600]!;
            backgroundColor = Colors.red[50]!;
            textColor = Colors.red[800]!;
            trailingIcon = Icons.cancel_rounded;
            iconColor = Colors.red[700];
        }
      }
    }


    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isSelected || isCorrect != null ? 2 : 1.5),
             boxShadow: isSelected || isCorrect != null ? [
                BoxShadow(color: borderColor.withOpacity(0.2), blurRadius: 5, spreadRadius: 1)
            ] : []
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: 10),
                Icon(trailingIcon, color: iconColor, size: 24),
              ]
            ],
          ),
        ),
      ),
    );
  }
}