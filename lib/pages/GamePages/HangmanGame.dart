// lib/pages/GamePages/HangmanGame.dart
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/hang.dart';

class HangmanGamePage extends StatefulWidget {
  final String languageCode;

  const HangmanGamePage({Key? key, required this.languageCode})
      : super(key: key);

  @override
  _HangmanGamePageState createState() => _HangmanGamePageState();
}

class _HangmanGamePageState extends State<HangmanGamePage>
    with TickerProviderStateMixin {
  // TickerProviderStateMixin для нескольких контроллеров
  // --- Цвета и стили ---
  final Color appBarColor =
      const Color.fromARGB(255, 255, 130, 29); // Глубокий фиолетовый
  final Color backgroundColor =
      const Color(0xFFF3E5F5); // Очень светлый лавандовый
  final Color correctLetterColor = Colors.green.shade600;
  final Color incorrectLetterColor = Colors.red.shade600;
  final Color buttonColor = const Color.fromARGB(255, 238, 118, 49); // Средний фиолетовый
  final Color buttonHoverColor = const Color.fromARGB(255, 250, 145, 47);
  final Color disabledButtonColor = Colors.grey.shade400;
  final Color hangmanStructureColor =
      const Color(0xFF6D4C41); // Темно-коричневый
  final Color hangmanBodyColor = const Color(0xFF546E7A); // Сине-серый

  final TextStyle feedbackTextStyle =
      const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  final TextStyle wordDisplayTextStyle = const TextStyle(
      fontSize: 34,
      letterSpacing: 7,
      fontWeight: FontWeight.bold,
      color: Color(0xFF311B92));
  final TextStyle attemptsTextStyle = const TextStyle(
      fontSize: 17, color: Color(0xFF4A148C), fontWeight: FontWeight.w500);
  final TextStyle gameOverMessageStyle = const TextStyle(
      fontSize: 18, color: Color(0xFF4A148C), fontWeight: FontWeight.w500);
  // ---------------------

  String currentWord = "";
  List<String> guessedLetters = [];
  int incorrectGuesses = 0;
  final int maxIncorrectGuesses = 7; // Совпадает с этапами в HangmanPainter

  final Map<String, List<String>> _wordsByLanguage = {
    'english': [
      'FLUTTER',
      'DEVELOPER',
      'WIDGET',
      'MOBILE',
      'ANDROID',
      'PROJECT',
      'KEYBOARD',
      'LANGUAGE',
      'CHALLENGE',
      'PLATFORM'
    ],
    'spanish': [
      'PROGRAMA',
      'VENTANA',
      'JUEGO',
      'AMIGO',
      'FLORES',
      'IDIOMA',
      'PALABRA',
      'APRENDER',
      'DESAFIO',
      'IDIOMAS'
    ],
    'german': [
      'ENTWICKLER',
      'TASTATUR',
      'BILDSCHIRM',
      'APFELSAFT',
      'FREUNDE',
      'SPRACHE',
      'WÖRTERBUCH',
      'HERAUSFORDERUNG',
      'PLATTFORM'
    ],
  };
  List<String> currentLanguageWords = [];

  late AnimationController _wordFeedbackAnimationController;
  late Animation<double> _wordFeedbackScaleAnimation;
  late AnimationController
      _hangmanDrawingController; // Для плавной отрисовки виселицы

  final Map<String, String> _alphabets = {
    'english': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'spanish': 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ',
    'german': 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜẞ',
  };
  String get currentAlphabet =>
      _alphabets[widget.languageCode] ?? _alphabets['english']!;

  @override
  void initState() {
    super.initState();
    currentLanguageWords = List<String>.from(
        _wordsByLanguage[widget.languageCode] ?? _wordsByLanguage['english']!);

    _wordFeedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _wordFeedbackScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _wordFeedbackAnimationController, curve: Curves.elasticOut),
    );

    _hangmanDrawingController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 300), // Длительность анимации для одной части
    );

    _startNewGame();
  }

  @override
  void dispose() {
    _wordFeedbackAnimationController.dispose();
    _hangmanDrawingController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    if (currentLanguageWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Нет слов для языка ${widget.languageCode}'),
            backgroundColor: Colors.redAccent),
      );
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      return;
    }
    final randomIndex = Random().nextInt(currentLanguageWords.length);
    setState(() {
      currentWord = currentLanguageWords[randomIndex].toUpperCase();
      guessedLetters = [];
      incorrectGuesses = 0;
      _hangmanDrawingController.value = 0; // Сброс анимации виселицы на начало
      _wordFeedbackAnimationController.reset();
    });
  }

  String get displayWord {
    if (currentWord.isEmpty) return "";
    return currentWord.split('').map((letter) {
      return guessedLetters.contains(letter) ? letter : '_';
    }).join(' ');
  }

  bool get isGameWon => currentWord.isNotEmpty && !displayWord.contains('_');
  bool get isGameOver => incorrectGuesses >= maxIncorrectGuesses || isGameWon;

  void _guessLetter(String letter) {
    if (isGameOver || guessedLetters.contains(letter.toUpperCase())) return;

    final upperCaseLetter = letter.toUpperCase();
    bool correctGuess = currentWord.contains(upperCaseLetter);

    setState(() {
      guessedLetters.add(upperCaseLetter);
      if (!correctGuess) {
        incorrectGuesses++;
        // Анимируем к следующему состоянию виселицы
        double targetProgress = incorrectGuesses / maxIncorrectGuesses;
        _hangmanDrawingController.animateTo(targetProgress.clamp(0.0, 1.0));
      } else {
        _wordFeedbackAnimationController.forward(from: 0.0);
      }
    });

    if (isGameOver) {
      _showGameEndDialog();
    }
  }

  void _showGameEndDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                  isGameWon
                      ? Icons.celebration_rounded
                      : Icons.sentiment_very_dissatisfied_rounded,
                  color: isGameWon ? correctLetterColor : incorrectLetterColor,
                  size: 30),
              const SizedBox(width: 10),
              Text(isGameWon ? 'Победа!' : 'Игра окончена',
                  style: TextStyle(
                      color:
                          isGameWon ? correctLetterColor : incorrectLetterColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  isGameWon
                      ? 'Отлично! Вы угадали слово:'
                      : 'Увы! Загаданное слово было:',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Center(
                  child: Text(currentWord,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2))),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            TextButton(
              child: Text('В меню игр',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (Navigator.canPop(context)) Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Играть снова', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: appBarColor, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _startNewGame();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHangmanDisplay() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.33,
      constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
      decoration: BoxDecoration(
          // color: Colors.white.withOpacity(0.5),
          // borderRadius: BorderRadius.circular(12),
          ),
      child: CustomPaint(
        // Используем значение контроллера анимации для плавной отрисовки
        painter: HangmanPainter(
          errors: (_hangmanDrawingController.value * maxIncorrectGuesses)
              .round()
              .clamp(0, maxIncorrectGuesses),
          maxErrors: maxIncorrectGuesses,
          lineColor: hangmanStructureColor,
          bodyColor: hangmanBodyColor,
          strokeWidth: 4.5, // Чуть толще линии
        ),
        size: Size.infinite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String langDisplayName =
        _languageOptions[widget.languageCode] ?? widget.languageCode;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardPadding = screenWidth > 500 ? (screenWidth - 500) / 2 : 8.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Виселица: $langDisplayName',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: appBarColor,
        elevation: 2,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildHangmanDisplay(),
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: _wordFeedbackScaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3))
                        ]),
                    child: Text(
                      displayWord,
                      style: wordDisplayTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Ошибок: $incorrectGuesses / $maxIncorrectGuesses',
                    style: attemptsTextStyle),
                const SizedBox(height: 28),
                if (isGameOver)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: Column(
                      children: [
                        Text(
                          isGameWon ? '🎉 ПОБЕДА! 🎉' : 'ПОРАЖЕНИЕ',
                          style: feedbackTextStyle.copyWith(
                              color: isGameWon
                                  ? correctLetterColor
                                  : incorrectLetterColor),
                          textAlign: TextAlign.center,
                        ),
                        if (!isGameWon) const SizedBox(height: 8),
                        if (!isGameWon)
                          Text('Слово было: $currentWord',
                              style: gameOverMessageStyle),
                        const SizedBox(height: 25),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Играть снова'),
                          onPressed: _startNewGame,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 35, vertical: 15),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        )
                      ],
                    ),
                  )
                else
                  Padding(
                    // Отступы для клавиатуры
                    padding: EdgeInsets.symmetric(horizontal: keyboardPadding),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Wrap(
                        spacing: 9.0, // Расстояние между кнопками
                        runSpacing: 9.0,
                        alignment: WrapAlignment.center,
                        children: currentAlphabet.split('').map((letter) {
                          final bool alreadyGuessed =
                              guessedLetters.contains(letter);
                          final bool isCorrectIfGuessed =
                              currentWord.contains(letter);
                          return SizedBox(
                            // Обертка для фиксированного размера кнопок
                            width: 46, height: 46,
                            child: ElevatedButton(
                              onPressed: alreadyGuessed || isGameOver
                                  ? null
                                  : () => _guessLetter(letter),
                              child: Text(letter,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: alreadyGuessed
                                    ? (isCorrectIfGuessed
                                        ? correctLetterColor.withOpacity(0.65)
                                        : incorrectLetterColor
                                            .withOpacity(0.65))
                                    : buttonColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final Map<String, String> _languageOptions = {
    'english': 'Англ.',
    'german': 'Нем.',
    'spanish': 'Исп.',
  };
}
