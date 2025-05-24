import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpperUpInterLessonPage extends StatefulWidget {
  final String lessonId;
  final String languageLevel; // Уровень языка
  final ValueChanged<int> onProgressUpdated;

  UpperUpInterLessonPage(
      {required this.lessonId,
      required this.languageLevel,
      required this.onProgressUpdated});

  @override
  _UpperUpInterLessonPageState createState() => _UpperUpInterLessonPageState();
}

class _UpperUpInterLessonPageState extends State<UpperUpInterLessonPage> {
  List<dynamic> words = [];
  int currentIndex = 0;
  String? selectedAnswer;
  bool isAnswerSelected = false;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchLessonData();
  }

  Future<void> _fetchLessonData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('upperupinterlessons')
        .doc(widget.lessonId)
        .get();

    if (snapshot.exists) {
      final lessonData = snapshot.data() as Map<String, dynamic>;
      setState(() {
        words = lessonData['words'] ?? [];
        imageUrl = lessonData['imageUrl'];
      });
    }
  }

  void _nextWord() async {
    if (currentIndex < words.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        isAnswerSelected = false;
      });
      await _updateProgress();
    } else {
      await _completeLesson();
      Navigator.pop(context);
    }
  }

  Future<void> _completeLesson() async {
    await FirebaseFirestore.instance
        .collection('upperupinterlessons')
        .doc(widget.lessonId)
        .update({'progress': 100});
    await updateUserProgress(widget.lessonId, 100);
    widget.onProgressUpdated(100);
    await _checkAndUpdateUserLevel();
  }

  Future<void> _updateProgress() async {
    final newProgress = ((currentIndex + 1) / words.length * 100).round();
    await FirebaseFirestore.instance
        .collection('upperupinterlessons')
        .doc(widget.lessonId)
        .update({'progress': newProgress});
    await updateUserProgress(widget.lessonId, newProgress);
    widget.onProgressUpdated(newProgress);
  }

  Future<void> updateUserProgress(String lessonId, int newProgress) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      await userDoc.update({
        'progressupint.$lessonId': newProgress,
      });
    }
  }

  Future<void> _checkAndUpdateUserLevel() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      final userSnapshot = await userDoc.get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final currentLevel = userData['language'] ?? 'Upper Intermediate';
        print('Current User Level: $currentLevel');
        print('User Progress: ${userData['progressupint']}');

        // Check if the user's level is "Elementary" to promote them to "Intermediate"
        if (currentLevel == 'Upper Intermediate') {
          // Fetch all "Elementary" level lessons
          final elementaryLessonsSnapshot = await FirebaseFirestore.instance
              .collection('upperlessons')
              .where('level', isEqualTo: 'Upper Intermediate')
              .get();

          // Check if all lessons in "Elementary" are completed
          bool allLessonsCompleted =
              elementaryLessonsSnapshot.docs.every((doc) {
            final lessonProgress = userData['progressel'][doc.id] ?? 0;
            print('Lesson ${doc.id} progress: $lessonProgress');
            return lessonProgress == 100;
          });

          if (allLessonsCompleted) {
            await userDoc.update({'language': 'Advanced'});
            print('User level updated to Intermediate');
          } else {
            print('Not all lessons completed for Elementary level');
          }
        } else if (currentLevel == 'Upper Intermediate') {
          // Fetch all "Intermediate" level lessons
          final intermediateLessonsSnapshot = await FirebaseFirestore.instance
              .collection('upperlessons')
              .where('level', isEqualTo: 'Advanced')
              .get();

          // Check if all lessons in "Intermediate" are completed
          bool allLessonsCompleted =
              intermediateLessonsSnapshot.docs.every((doc) {
            final lessonProgress = userData['progressel'][doc.id] ?? 0;
            print('Lesson ${doc.id} progress: $lessonProgress');
            return lessonProgress == 100;
          });

          if (allLessonsCompleted) {
            await userDoc.update({'language': 'Advanced'});
            print('User level updated to Upper Intermediate');
          }
        }
      }
    }
  }

  bool _isLevelLower(String currentLevel, String lessonLevel) {
    const levels = [
      'Beginner',
      'Elementary',
      'Intermediate',
      'Upper Intermediate',
      'Advanced'
    ];
    final currentIndex = levels.indexOf(currentLevel);
    final lessonIndex = levels.indexOf(lessonLevel);

    return currentIndex < lessonIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Урок: ${widget.lessonId}')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentWordData = words[currentIndex];
    final String word = currentWordData['word'];
    final List<String> translations =
        List<String>.from(currentWordData['translations']);
    final String correctAnswer = currentWordData['correctAnswer'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Урок: ${widget.lessonId}'),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWordCard(word),
            const SizedBox(height: 20),
            if (imageUrl != null) _buildImageCard(imageUrl!),
            const SizedBox(height: 20),
            Text(
              'Выберите перевод:',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800]),
            ),
            const SizedBox(height: 10),
            ...translations.map((translation) {
              return _buildTranslationOption(translation, correctAnswer);
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(String word) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.greenAccent[700],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          height: 200,
          width: double.infinity,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('Ошибка загрузки изображения'));
          },
        ),
      ),
    );
  }

  Widget _buildTranslationOption(String translation, String correctAnswer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ListTile(
        title: Text(translation, style: TextStyle(color: Colors.green[800])),
        leading: Radio<String>(
          value: translation,
          groupValue: selectedAnswer,
          onChanged: (value) {
            setState(() {
              selectedAnswer = value as String;
              isAnswerSelected = true;
            });
            _showAnswerDialog(value == correctAnswer, correctAnswer);
          },
        ),
      ),
    );
  }

  void _showAnswerDialog(bool isCorrect, String correctAnswer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isCorrect ? Colors.green[100] : Colors.red[100],
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.error,
              color: isCorrect ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(isCorrect ? "Правильно!" : "Неправильно!",
                style: TextStyle(color: Colors.green[800])),
          ],
        ),
        content: Text(
          isCorrect
              ? "Отлично! Вы правильно ответили."
              : "Неправильно. Правильный ответ: $correctAnswer",
          style: TextStyle(color: Colors.green[800]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextWord();
            },
            child: Text("Далее", style: TextStyle(color: Colors.green[800])),
          ),
        ],
      ),
    );
  }
}
