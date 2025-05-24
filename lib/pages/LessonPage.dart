import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonPage extends StatefulWidget {
  @override
  _LessonPageState createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  String? selectedOption;
  String? correctAnswer;
  bool isAnswerCorrect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lessonId = ModalRoute.of(context)!.settings.arguments as String;
    fetchLesson(lessonId);
  }

  Future<void> fetchLesson(String lessonId) async {
    DocumentSnapshot lessonSnapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .doc(lessonId)
        .get();

    if (lessonSnapshot.exists) {
      Map<String, dynamic> lessonData =
          lessonSnapshot.data() as Map<String, dynamic>;

      setState(() {
        questions = List<Map<String, dynamic>>.from(lessonData['questions']);
        correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
      });
    } else {
      print('Урок не найден');
    }
  }

  void handleOptionSelected(String option) {
    setState(() {
      selectedOption = option;
      isAnswerCorrect = (option == correctAnswer);
    });
  }

  void goToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
        correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
        isAnswerCorrect = false; // Сбрасываем состояние
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = questions[currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(title: Text("Урок")),
      body: SingleChildScrollView(
        // Добавлено для скролла
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentQuestion['question'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...currentQuestion['options'].map<Widget>((option) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity, // Занять всю доступную ширину
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blueAccent),
                    ),
                    backgroundColor: selectedOption == option
                        ? (isAnswerCorrect ? Colors.green : Colors.red)
                        : Color.fromARGB(255, 16, 146, 4),
                  ),
                  onPressed: () => handleOptionSelected(option),
                  child: Text(
                    option,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    overflow:
                        TextOverflow.ellipsis, // Добавлено для обрезки текста
                    maxLines: 1, // Ограничение на количество строк
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            if (selectedOption != null && !isAnswerCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Неверно! Попробуйте снова.',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            if (isAnswerCorrect)
              ElevatedButton(
                onPressed: goToNextQuestion,
                child: Text("Далее"),
              ),
          ],
        ),
      ),
    );
  }
}
