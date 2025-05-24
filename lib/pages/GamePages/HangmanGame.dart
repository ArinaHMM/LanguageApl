import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class HangmanGamePage extends StatefulWidget {
  @override
  _HangmanGamePageState createState() => _HangmanGamePageState();
}

class _HangmanGamePageState extends State<HangmanGamePage> {
  String selectedWord = '';
  List<String> displayedWord = [];
  List<String> guessedLetters = [];
  int remainingAttempts = 10; // Увеличили количество попыток
  bool isLoading = true;
  bool hasMadeFirstError = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomWordFromFirestore();
  }

  Future<void> _fetchRandomWordFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('hangman').get();
      if (snapshot.docs.isNotEmpty) {
        var randomDoc = snapshot.docs[Random().nextInt(snapshot.docs.length)];
        selectedWord = randomDoc['word'] as String;

        print("Загаданное слово: $selectedWord");

        displayedWord = List.filled(selectedWord.length, '_');
        guessedLetters.clear();
        remainingAttempts = 10; // Сброс количества попыток
        hasMadeFirstError = false; // Сброс флага при новой игре
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Нет слов в коллекции "hangman"'),
        ));
      }
    } catch (e) {
      print("Ошибка при получении данных: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _guessLetter(String letter) {
    if (guessedLetters.contains(letter) || remainingAttempts <= 0) return;

    setState(() {
      guessedLetters.add(letter);

      if (!selectedWord.contains(letter)) {
        remainingAttempts--;
        // Устанавливаем флаг, если это первая ошибка
        if (!hasMadeFirstError) {
          hasMadeFirstError = true;
        }
      } else {
        for (int i = 0; i < selectedWord.length; i++) {
          if (selectedWord[i] == letter) {
            displayedWord[i] = letter;
          }
        }
      }
    });

    print("Угаданные буквы: $guessedLetters");
    print("Текущее состояние слова: ${displayedWord.join(' ')}");
    print("Осталось попыток: $remainingAttempts");

    // Проверка на окончание игры
    if (isGameFinished) {
      if (remainingAttempts <= 0) {
        _showGameOverDialog(); // Показать диалог о проигрыше
      }
    }
  }

  bool get isGameFinished =>
      displayedWord.join() == selectedWord || remainingAttempts <= 0;

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Игра окончена',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30),
          ),
          content: Text(
              textAlign: TextAlign.center,
              'Слово: $selectedWord',
              style: TextStyle(
                color: Color.fromARGB(255, 9, 121, 9),
                fontSize: 30,
              )),
          actions: [
            TextButton(
              style: TextButton.styleFrom(alignment: Alignment.bottomCenter),
              onPressed: () {
                Navigator.of(context).pop();
                _fetchRandomWordFromFirestore(); // Начать новую игру
              },
              child: Text(
                'Новая игра',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        title: Text('Виселица'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: Size(200, 200),
                    painter:
                        HangmanPainter(remainingAttempts, hasMadeFirstError),
                  ),
                  SizedBox(height: 20),
                  Text(
                    displayedWord.join(' '),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text('Попытки: $remainingAttempts'),
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildAlphabetKeyboard(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAlphabetKeyboard() {
    const String alphabet = 'qwertyuiopasdfghjklzxcvbnm';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            alignment: WrapAlignment.center,
            children: _buildAlphabetButtons(alphabet),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlphabetButtons(String alphabet) {
    List<Widget> buttons = [];
    for (String letter in alphabet.split('')) {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            _guessLetter(letter);
          },
          child: Text(
            letter,
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            backgroundColor: guessedLetters.contains(letter)
                ? Color.fromRGBO(137, 182, 128, 1)
                : Color.fromARGB(255, 8, 134, 4),
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
    return buttons;
  }
}

class HangmanPainter extends CustomPainter {
  final int remainingAttempts;
  final bool hasMadeFirstError;

  HangmanPainter(this.remainingAttempts, this.hasMadeFirstError);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // Рисуем основание
    if (hasMadeFirstError) {
      canvas.drawLine(Offset(size.width * 0.2, size.height),
          Offset(size.width * 0.8, size.height), paint);
    }

    // Рисуем перекладину
    if (hasMadeFirstError && remainingAttempts < 10) {
      canvas.drawLine(Offset(size.width * 0.5, size.height),
          Offset(size.width * 0.5, size.height * 0.33), paint);
    }

    // Рисуем вертикальную часть для виселицы
    if (hasMadeFirstError && remainingAttempts < 9) {
      canvas.drawLine(Offset(size.width * 0.5, size.height * 0.33),
          Offset(size.width * 0.7, size.height * 0.33), paint);
    }

    // Рисуем вертикальную часть
    if (hasMadeFirstError && remainingAttempts < 8) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.75),
          Offset(size.width * 0.7, size.height * 0.45), paint);
    }

    // Рисуем части тела в зависимости от оставшихся попыток
    if (remainingAttempts <= 8) {
      canvas.drawCircle(
          Offset(size.width * 0.7, size.height * 0.4), 15, paint); // Голова
    }
    if (remainingAttempts <= 6) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.55),
          Offset(size.width * 0.7, size.height * 0.75), paint); // Тело
    }
    if (remainingAttempts <= 4) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.6),
          Offset(size.width * 0.75, size.height * 0.55), paint); // Правая рука
    }
    if (remainingAttempts <= 2) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.6),
          Offset(size.width * 0.65, size.height * 0.55), paint); // Левая рука
    }
    if (remainingAttempts <= 1) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.75),
          Offset(size.width * 0.75, size.height * 0.8), paint); // Правая нога
    }
    if (remainingAttempts <= 0) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.75),
          Offset(size.width * 0.65, size.height * 0.8), paint); // Левая нога
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
