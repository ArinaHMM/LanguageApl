import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioLessonPage extends StatefulWidget {
  final String lessonId;

  AudioLessonPage({
    required this.lessonId,
  });

  @override
  _AudioLessonPageState createState() => _AudioLessonPageState();
}

class _AudioLessonPageState extends State<AudioLessonPage> {
  late Future<Map<String, dynamic>> _audioLessonData;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> selectedWords = []; // Для хранения выбранных слов
  String constructedAnswer = ''; // Для хранения составленного ответа

  @override
  void initState() {
    super.initState();
    _audioLessonData = fetchAudioLesson();
  }

  Future<Map<String, dynamic>> fetchAudioLesson() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('audiolessons')
        .doc(widget.lessonId)
        .get();
    return snapshot.data() as Map<String, dynamic>;
  }

  void playAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl)); // Используйте UrlSource для аудио URL
    } catch (e) {
      print("Ошибка при воспроизведении аудио: $e"); // Логируем ошибку
    }
  }

  Future<void> _updateUserProgress() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      // Получение текущего прогресса
      final userSnapshot = await userDoc.get();
      final userData = userSnapshot.data() as Map<String, dynamic>?;

      int currentProgress = userData?['progressaudio']?[widget.lessonId] ?? 0;

      // Обновляем прогресс до 100%
      await userDoc.update({
        'progressaudio.${widget.lessonId}': 100, // Устанавливаем прогресс урока в 100%
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Аудиоурок"),
        backgroundColor: Colors.green[700],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _audioLessonData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          } else {
            final audioLesson = snapshot.data!;
            final audioUrl = audioLesson['audioUrl'] ?? ''; // Получаем URL аудио
            final words = List<String>.from(audioLesson['words'] ?? []); // Получаем слова
            final correctAnswer = audioLesson['correctAnswer'] ?? ''; // Получаем правильный перевод

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Отображение инструкции
                  Text(
                    "Составьте услышанную фразу!", // Изменено на инструкцию
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Кнопка для воспроизведения аудио
                  ElevatedButton(
                    onPressed: () => playAudio(audioUrl),
                    child: Text("Слушать аудио"),
                  ),
                  SizedBox(height: 20),

                  // Отображение слов для выбора
                  Text("Выберите слова для составления предложения:",
                      style: TextStyle(fontSize: 18)),
                  Wrap(
                    spacing: 8.0,
                    children: words.map((word) {
                      return ChoiceChip(
                        label: Text(word),
                        selected: selectedWords.contains(word),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedWords.add(word);
                            } else {
                              selectedWords.remove(word);
                            }
                            // Обновление составленного ответа
                            constructedAnswer = selectedWords.join(' ');
                          });
                        },
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 20),
                  // Отображение составленного ответа
                  Text("Составленный ответ: $constructedAnswer",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),

                  // Отображение кнопки для проверки ответа
                  ElevatedButton(
                    onPressed: () async {
                      // Проверка правильного ответа
                      if (constructedAnswer.trim() == correctAnswer.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Правильный ответ!"),
                          backgroundColor: Colors.green,
                        ));

                        await _updateUserProgress(); // Обновляем прогресс после правильного ответа
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Неправильный ответ. Попробуйте снова."),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                    child: Text("Проверить ответ"),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
