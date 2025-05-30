import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_languageapplicationmycourse_2/providers/user_provider.dart'
    show UserProvider;
import 'package:provider/provider.dart'; // Если используется UserProvider

// ЗАГЛУШКА UserProvider (если у вас нет своего, или для быстрого теста)
// class UserProvider extends ChangeNotifier {
//   UserModel? _currentUser;
//   UserModel? get currentUser => _currentUser;
//   void setUser(UserModel user) {
//     _currentUser = user;
//     notifyListeners();
//   }
// }

// Цветовая палитра для темы
const Color primaryOrange = Color(0xFFF57C00); // Orange 700
const Color lightOrange = Color(0xFFFFB74D); // Orange 300
const Color darkOrange = Color(0xFFE65100); // Orange 900
const Color primaryYellow = Color(0xFFFFCA28); // Amber 400
const Color lightYellow = Color(0xFFFFF9C4); // Yellow 100
const Color veryLightYellow = Color(0xFFFFFDE7); // Yellow 50
const Color accentAmber = Color(0xFFFFAB00); // Amber A700

const Color darkBrownText = Color(0xFF4E342E); // Brown 800
const Color mediumBrownText = Color(0xFF795548); // Brown 500
const Color lightBrownText = Color(0xFFA1887F); // Brown 300

const Color successGreen = Color(0xFF4CAF50); // Green 500
const Color errorRed = Color(0xFFE53935); // Red 600
// Конец цветовой палитры

class LessonPlayerAudioPage extends StatefulWidget {
  final Lesson lesson;
  final Function(String lessonId, int newProgress) onProgressUpdated;

  const LessonPlayerAudioPage({
    Key? key,
    required this.lesson,
    required this.onProgressUpdated,
  }) : super(key: key);

  @override
  _LessonPlayerAudioPageState createState() => _LessonPlayerAudioPageState();
}

class WordInSentence {
  final String text;
  final int originalBankIndex;
  final String uniqueId;

  WordInSentence({required this.text, required this.originalBankIndex})
      : uniqueId = GlobalKey().toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordInSentence &&
          runtimeType == other.runtimeType &&
          uniqueId == other.uniqueId;

  @override
  int get hashCode => uniqueId.hashCode;
}

class _LessonPlayerAudioPageState extends State<LessonPlayerAudioPage>
    with TickerProviderStateMixin {
  int _currentExerciseIndex = 0;
  int _correctAnswersCount = 0;
  Exercise? _currentExercise;

  bool _isAnswerChecked = false;
  bool _isAnswerCorrect = false;
  String _feedbackMessage = "";

  List<String> _shuffledWordBank = [];
  List<WordInSentence> _constructedSentenceWords = [];
  Map<int, bool> _wordBankSelectionState = {};

  late AnimationController _progressController;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _elementsAppearController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _feedbackAudioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
  String _userInterfaceLanguage = 'russian';

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))
      ..addListener(() => setStateIfMounted(() {}));

    _feedbackController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _feedbackAnimation =
        CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut);

    _elementsAppearController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      setStateIfMounted(() {
        _isAudioPlaying = s == PlayerState.playing;
      });
    });

    _loadNextExercise();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final newLanguage =
        userProvider.currentUser?.languageSettings?.interfaceLanguage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (newLanguage != null && newLanguage != _userInterfaceLanguage) {
          setStateIfMounted(() {
            _userInterfaceLanguage = newLanguage;
          });
        } else if (newLanguage != null &&
            _userInterfaceLanguage == 'russian' &&
            _userInterfaceLanguage != newLanguage) {
          setStateIfMounted(() {
            _userInterfaceLanguage = newLanguage;
          });
        }
      }
    });
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _loadNextExercise() {
    print(
        "--- _loadNextExercise START --- (Текущий индекс упражнения: $_currentExerciseIndex)");
    _audioPlayer.stop();

    bool shouldShowSummaryImmediately = false;

    if (widget.lesson.exercises.isEmpty) {
      print(
          "--- _loadNextExercise: ВНИМАНИЕ! Список упражнений (widget.lesson.exercises) ПУСТ. ---");
      setStateIfMounted(() {
        _isAnswerChecked = false;
        _isAnswerCorrect = false;
        _feedbackMessage = "В этом уроке пока нет упражнений.";
        _currentExercise = null;
        _progressController.animateTo(1.0);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              "--- _loadNextExercise (postFrameCallback): Вызов _showLessonSummary, т.к. упражнений НЕТ. ---");
          _showLessonSummary();
        }
      });
      print("--- _loadNextExercise END (упражнений нет) ---");
      return;
    }

    print(
        "--- _loadNextExercise: Количество упражнений в уроке: ${widget.lesson.exercises.length}. ---");

    setStateIfMounted(() {
      print(
          "--- _loadNextExercise (setStateIfMounted) НАЧАЛО: _currentExerciseIndex = $_currentExerciseIndex ---");
      _isAnswerChecked = false;
      _isAnswerCorrect = false;
      _feedbackMessage = "";
      _currentExercise = null;

      if (_elementsAppearController.isAnimating ||
          _elementsAppearController.isCompleted) {
        _elementsAppearController.reset();
      }
      _constructedSentenceWords.clear();
      _wordBankSelectionState.clear();

      if (_currentExerciseIndex < widget.lesson.exercises.length) {
        print(
            "--- _loadNextExercise (setStateIfMounted): Загружаем упражнение с индексом $_currentExerciseIndex. ---");
        _currentExercise = widget.lesson.exercises[_currentExerciseIndex];

        double progressValue = (_currentExerciseIndex + 1).toDouble() /
            widget.lesson.exercises.length;
        _progressController.animateTo(progressValue);
        print(
            "--- _loadNextExercise (setStateIfMounted): Прогресс установлен на $progressValue. ---");

        if (_currentExercise?.type == 'audioWordBankSentence' &&
            _currentExercise?.wordBank != null &&
            _currentExercise!.wordBank!.isNotEmpty) {
          _shuffledWordBank = List<String>.from(_currentExercise!.wordBank!)
            ..shuffle();
          for (int i = 0; i < _shuffledWordBank.length; i++) {
            _wordBankSelectionState[i] = false;
          }
          print(
              "--- _loadNextExercise (setStateIfMounted): Банк слов для audioWordBankSentence подготовлен. ---");
        } else {
          _shuffledWordBank.clear();
          if (_currentExercise?.type == 'audioWordBankSentence') {
            print(
                "--- _loadNextExercise (setStateIfMounted): ВНИМАНИЕ! Тип audioWordBankSentence, но банк слов пуст или null. ---");
          }
        }
        _elementsAppearController.forward();
      } else {
        print(
            "--- _loadNextExercise (setStateIfMounted): ВСЕ упражнения пройдены. _currentExerciseIndex ($_currentExerciseIndex) >= exercises.length (${widget.lesson.exercises.length}). ---");
        if (mounted) {
          shouldShowSummaryImmediately = true;
          print(
              "--- _loadNextExercise (setStateIfMounted): shouldShowSummaryImmediately установлен в true. ---");
        }
      }
      print("--- _loadNextExercise (setStateIfMounted) КОНЕЦ ---");
    });

    if (shouldShowSummaryImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              "--- _loadNextExercise (postFrameCallback): Вызов _showLessonSummary (т.к. shouldShowSummaryImmediately = true). ---");
          _showLessonSummary();
        }
      });
    }
    print("--- _loadNextExercise END ---");
  }

  void _checkAnswer() {
    if (_currentExercise == null || _isAnswerChecked || !mounted) return;

    String userAnswer =
        _constructedSentenceWords.map((w) => w.text).join(" ").trim();
    String correctAnswer = "";
    bool isCorrect = false;

    if (_currentExercise!.type == 'audioWordBankSentence') {
      correctAnswer = _currentExercise!.correctSentence?.trim() ?? "";

      RegExp punctuationAndExtraSpaces =
          RegExp(r"[^\w\s']+|(\s+)", unicode: true);
      String userAnswerNormalized = userAnswer
          .toLowerCase()
          .replaceAllMapped(punctuationAndExtraSpaces,
              (Match match) => match.group(1) != null ? ' ' : '')
          .trim();
      String correctAnswerNormalized = correctAnswer
          .toLowerCase()
          .replaceAllMapped(punctuationAndExtraSpaces,
              (Match match) => match.group(1) != null ? ' ' : '')
          .trim();

      isCorrect = userAnswerNormalized == correctAnswerNormalized;
      if (isCorrect) {
        _feedbackMessage = _currentExercise!.getLocalizedFeedbackCorrect(
            _userInterfaceLanguage,
            defaultFeedback: "Превосходно!");
      } else {
        _feedbackMessage = _currentExercise!.getLocalizedFeedbackIncorrect(
            _userInterfaceLanguage,
            actualCorrectAnswer: _currentExercise!.correctSentence,
            defaultFeedback:
                "Почти! Правильный ответ: \"${_currentExercise!.correctSentence ?? ''}\"");
      }
    } else {
      isCorrect = false;
      _feedbackMessage =
          "Тип упражнения '${_currentExercise!.type}' не поддерживается на этой странице.";
    }

    _isAnswerCorrect = isCorrect;
    setStateIfMounted(() {
      _isAnswerChecked = true;
    });

    if (_isAnswerCorrect) {
      _correctAnswersCount++;
      _playFeedbackSound('correct.mp3');
    } else {
      _playFeedbackSound('incorrect.mp3');
    }
    _feedbackController.forward(from: 0.0);
  }

  void _handleNext() {
    if (!mounted) return;
    if (!_isAnswerChecked && _currentExercise != null) {
      setStateIfMounted(() {
        _isAnswerChecked = true;
        _isAnswerCorrect = false;
        _feedbackMessage = "Задание пропущено.";
      });
      _feedbackController.forward(from: 0.0);
      return;
    }
    if (_currentExerciseIndex < widget.lesson.exercises.length - 1) {
      setStateIfMounted(() {
        _currentExerciseIndex++;
      });
      _loadNextExercise();
    } else {
      _showLessonSummary();
    }
  }

  void _showLessonSummary() {
    if (!mounted) return;
    _progressController.animateTo(1.0);
    final int totalQuestions = widget.lesson.exercises.length;
    final int progressPercentage = totalQuestions > 0
        ? ((_correctAnswersCount / totalQuestions) * 100).round()
        : 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onProgressUpdated(widget.lesson.id, progressPercentage);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: lightYellow,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Center(
                child: Text("Урок завершён!",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkOrange,
                        fontSize: 24))),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.celebration_rounded,
                  color: accentAmber, size: 80),
              SizedBox(height: 20),
              Text("Ваш результат:",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: darkBrownText)),
              SizedBox(height: 10),
              Text("$_correctAnswersCount из $totalQuestions",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange)),
              Text("правильных ответов",
                  style: TextStyle(fontSize: 16, color: mediumBrownText)),
              SizedBox(height: 15),
              Text("Общий прогресс: $progressPercentage%",
                  style: TextStyle(
                      fontSize: 18,
                      color: darkOrange,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 25),
            ]),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white),
                label: Text("Завершить", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: EdgeInsets.symmetric(
                        horizontal: 35, vertical: 14),
                    textStyle: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _playFeedbackSound(String assetName) async {
    try {
      // await _feedbackAudioPlayer.play(AssetSource('audio/$assetName'));
      print("Playing feedback sound: assets/audio/$assetName");
    } catch (e) {
      print("Error playing feedback sound: $e");
    }
  }

  void _onWordFromBankTap(int bankIndex, String word) {
    if (_isAnswerChecked ||
        (_wordBankSelectionState[bankIndex] ?? false) ||
        !mounted) return;
    setStateIfMounted(() {
      _constructedSentenceWords
          .add(WordInSentence(text: word, originalBankIndex: bankIndex));
      _wordBankSelectionState[bankIndex] = true;
    });
  }

  void _onConstructedWordTap(int constructedIndex) {
    if (_isAnswerChecked ||
        !mounted ||
        constructedIndex < 0 ||
        constructedIndex >= _constructedSentenceWords.length) return;
    setStateIfMounted(() {
      WordInSentence removedWord =
          _constructedSentenceWords.removeAt(constructedIndex);
      if (_wordBankSelectionState.containsKey(removedWord.originalBankIndex)) {
        _wordBankSelectionState[removedWord.originalBankIndex] = false;
      }
    });
  }

  void _clearConstructedSentence() {
    if (_isAnswerChecked || !mounted) return;
    setStateIfMounted(() {
      _constructedSentenceWords.clear();
      _wordBankSelectionState.updateAll((key, value) => false);
    });
  }

  Future<void> _playExerciseAudio() async {
    if (_currentExercise?.audioUrl != null &&
        _currentExercise!.audioUrl!.isNotEmpty) {
      try {
        if (_isAudioPlaying) {
          await _audioPlayer.stop();
        }
        await _audioPlayer.play(UrlSource(_currentExercise!.audioUrl!));
      } catch (e) {
        print("Error playing exercise audio: $e");
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Не удалось воспроизвести аудио."),
              backgroundColor: errorRed));
        }
      }
    } else {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Аудиофайл для этого задания отсутствует."),
            backgroundColor: lightOrange));
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _feedbackController.dispose();
    _elementsAppearController.dispose();
    _audioPlayer.dispose();
    _feedbackAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _currentExercise;
    // final theme = Theme.of(context); // Не используется явно, цвета заданы константами

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)), // Увеличен шрифт
        backgroundColor: Color.lerp(
            lightOrange, primaryOrange, _progressController.value),
        elevation: 3, // Немного увеличена тень
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            }),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(7.0), // Увеличена высота
          child: LinearProgressIndicator(
            value: _progressController.value,
            backgroundColor: lightOrange.withOpacity(0.4),
            valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
            minHeight: 7, // Увеличена высота
          ),
        ),
      ),
      body: exercise == null
          ? Center(child: CircularProgressIndicator(color: primaryOrange))
          : Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF3E0), // Orange 50
                  Color(0xFFFFE0B2), // Orange 100
                  Color(0xFFFFD180) // Amber A100 (светлее)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 90.0), // Увеличен верхний отступ
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPromptSection(exercise),
                      SizedBox(height: 24), // Увеличен отступ
                      if (exercise.type == 'audioWordBankSentence')
                        _buildAudioWordBankUI(exercise)
                      else
                        _buildUnsupportedExerciseUI(exercise),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar:
          exercise != null ? _buildBottomBar(exercise) : null,
    );
  }

  Widget _buildPromptSection(Exercise exercise) {
    String promptText = exercise.promptData?[_userInterfaceLanguage]
            ?.toString() ??
        exercise.promptData?['russian']?.toString() ??
        (exercise.type == 'audioWordBankSentence'
            ? "Прослушайте аудио и составьте услышанное предложение из слов ниже."
            : "Выполните задание");

    bool hasAudio = exercise.audioUrl != null && exercise.audioUrl!.isNotEmpty;

    return Card(
      elevation: 5,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Задание ${_currentExerciseIndex + 1} / ${widget.lesson.exercises.length}",
                  style: TextStyle(
                      fontSize: 15, // Увеличен
                      color: mediumBrownText.withOpacity(0.9),
                      fontWeight: FontWeight.w500),
                ),
                if (hasAudio)
                  ElevatedButton.icon(
                    icon: Icon(
                        _isAudioPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 28), // Увеличен
                    label: Text(_isAudioPlaying ? "Пауза" : "Слушать", style: TextStyle(fontSize: 15)),
                    onPressed: _playExerciseAudio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAudioPlaying ? primaryYellow : primaryOrange,
                      foregroundColor: _isAudioPlaying ? darkBrownText : Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                  )
              ],
            ),
            if (promptText.isNotEmpty &&
                promptText !=
                    "Прослушайте аудио и соберите услышанное предложение из слов ниже.") ...[
              SizedBox(height: 18), // Увеличен
              Text(
                promptText,
                style: TextStyle(
                    fontSize: 20, // Увеличен
                    fontWeight: FontWeight.w500,
                    color: darkBrownText.withOpacity(0.95), // Чуть темнее
                    height: 1.5), // Увеличен
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAudioWordBankUI(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16),
        Text("Соберите предложение:",
            style: TextStyle(
                fontSize: 18, // Увеличен
                fontWeight: FontWeight.bold,
                color: darkOrange)),
        SizedBox(height: 12), // Увеличен
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          constraints: BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
              color: veryLightYellow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _isAnswerChecked
                      ? (_isAnswerCorrect
                          ? successGreen
                          : errorRed)
                      : primaryOrange.withOpacity(0.6),
                  width: 2.0),
              boxShadow: [
                BoxShadow(
                    color: primaryOrange.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 4))
              ]),
          child: _constructedSentenceWords.isEmpty
              ? Center(
                  child: Text("Нажимайте на слова из банка ниже",
                      style: TextStyle(color: lightBrownText, fontSize: 16)))
              : Wrap(
                  spacing: 8.0,
                  runSpacing: 10.0, // Увеличен
                  alignment: WrapAlignment.center,
                  children:
                      List.generate(_constructedSentenceWords.length, (index) {
                    final wordInSentence = _constructedSentenceWords[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isAnswerChecked
                            ? null
                            : () => _onConstructedWordTap(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Chip(
                          label: Text(wordInSentence.text,
                              style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w500,
                                  color: darkBrownText)),
                          backgroundColor: lightOrange.withOpacity(0.7), // Ярче
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: primaryOrange.withOpacity(0.5))),
                          deleteIcon: Icon(Icons.close,
                              size: 20, // Увеличен
                              color: darkOrange.withOpacity(0.8)),
                          onDeleted: _isAnswerChecked
                              ? null
                              : () => _onConstructedWordTap(index),
                        ),
                      ),
                    );
                  }),
                ),
        ),
        if (_constructedSentenceWords.isNotEmpty && !_isAnswerChecked)
          Padding(
            padding: const EdgeInsets.only(top: 6.0), // Увеличен
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: Text("Очистить",
                    style: TextStyle(
                        color: errorRed, // Ярче
                        fontWeight: FontWeight.w500,
                        fontSize: 15)), // Увеличен
                onPressed: _clearConstructedSentence,
              ),
            ),
          ),
        SizedBox(height: 28), // Увеличен
        Text("Банк слов:",
            style: TextStyle(
                fontSize: 18, // Увеличен
                fontWeight: FontWeight.bold,
                color: darkOrange)),
        SizedBox(height: 12), // Увеличен
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65), // Немного прозрачнее
            borderRadius: BorderRadius.circular(18),
          ),
          child: Wrap(
            spacing: 10.0,
            runSpacing: 12.0, // Увеличен
            alignment: WrapAlignment.center,
            children: List.generate(_shuffledWordBank.length, (index) {
              bool isUsed = _wordBankSelectionState[index] ?? false;
              final word = _shuffledWordBank[index];

              return AnimatedOpacity(
                duration: Duration(milliseconds: 250),
                opacity: isUsed ? 0.45 : 1.0, // Чуть виднее
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUsed ? lightOrange.withOpacity(0.5) : Colors.white,
                    foregroundColor: isUsed ? mediumBrownText.withOpacity(0.7) : primaryOrange,
                    elevation: isUsed ? 1 : 4,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12), // Увеличена высота
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(
                            color: isUsed
                                ? lightOrange
                                : primaryOrange.withOpacity(0.7),
                            width: 1.5)), // Четче граница
                  ),
                  onPressed: isUsed || _isAnswerChecked
                      ? null
                      : () => _onWordFromBankTap(index, word),
                  child: Text(word,
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500)),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedExerciseUI(Exercise exercise) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.extension_off_outlined,
              size: 80, color: lightOrange), // Увеличена иконка
          SizedBox(height: 20), // Увеличен
          Text(
            "Упс! Этот тип упражнения (${exercise.type}) еще не готов.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                color: mediumBrownText,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 24), // Увеличен
          TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: primaryOrange,
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              onPressed: _handleNext,
              child: Text("Пропустить задание"))
        ],
      ),
    ));
  }

  Widget _buildBottomBar(Exercise exercise) {
    Color feedbackBgColor = _isAnswerCorrect
        ? successGreen.withOpacity(0.15)
        : errorRed.withOpacity(0.15);
    Color feedbackTextColor =
        _isAnswerCorrect ? successGreen : errorRed;
    IconData feedbackIcon = _isAnswerCorrect
        ? Icons.check_circle_rounded // Заменил на filled
        : Icons.cancel_rounded; // Заменил на filled

    bool canCheck = exercise.type == 'audioWordBankSentence'
        ? _constructedSentenceWords.isNotEmpty
        : false;
    
    final bool isButtonEnabled = _isAnswerChecked || canCheck;
    final Color buttonColor = _isAnswerChecked
        ? (_isAnswerCorrect ? successGreen : errorRed)
        : (canCheck ? primaryOrange : lightOrange.withOpacity(0.7));
    final Color buttonTextColor = _isAnswerChecked || canCheck 
        ? Colors.white 
        : mediumBrownText;


    return Material(
      elevation: 10.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 15,
            bottom: 15 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: _isAnswerChecked
              ? feedbackBgColor
              : Colors.white, // Фон для кнопок
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAnswerChecked)
              ScaleTransition(
                scale: _feedbackAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14.0), // Увеличен
                  child: Row(
                    children: [
                      Icon(feedbackIcon, color: feedbackTextColor, size: 28), // Увеличен
                      SizedBox(width: 12), // Увеличен
                      Expanded(
                        child: Text(
                          _feedbackMessage,
                          style: TextStyle(
                              fontSize: 16, // Увеличен
                              fontWeight: FontWeight.w500,
                              color: feedbackTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)), // Полностью скругленная
                elevation: isButtonEnabled ? 5 : 2,
              ),
              onPressed: isButtonEnabled
                  ? (_isAnswerChecked ? _handleNext : _checkAnswer)
                  : null,
              child: Text(
                _isAnswerChecked ? "ДАЛЕЕ" : "ПРОВЕРИТЬ",
              ),
            ),
          ],
        ),
      ),
    );
  }
}