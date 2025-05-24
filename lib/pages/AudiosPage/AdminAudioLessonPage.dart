import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminAudioLessonPage extends StatefulWidget {
  @override
  _AdminAudioLessonPageState createState() => _AdminAudioLessonPageState();
}

class _AdminAudioLessonPageState extends State<AdminAudioLessonPage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _phraseController = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();
  final TextEditingController _wordsController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isLoading = false;
  File? _selectedImage; // Переменная для выбранного изображения

  // Уровни языка
  String? selectedLanguageLevel;
  final List<String> languageLevels = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Upper Intermediate',
    'Advanced',
  ];

  List<Map<String, dynamic>> temporaryLessons = [];

  Future<Uint8List> fetchAudio(String text) async {
    final apiKey = '19212c1d69204a9eae33604b96f671e7'; // Ваш API ключ
    final url =
        'https://api.voicerss.org/?key=$apiKey&hl=en-us&src=$text&f=16khz_16bit_mono';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Не удалось получить аудио: ${response.reasonPhrase}');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _addTemporaryLesson() {
    if (_phraseController.text.isNotEmpty &&
        _correctAnswerController.text.isNotEmpty &&
        _wordsController.text.isNotEmpty &&
        selectedLanguageLevel != null) {
      final lesson = {
        'topic': _topicController.text, // Сохраняем тему
        'phrase': _phraseController.text,
        'correctAnswer': _correctAnswerController.text,
        'words': _wordsController.text.split(','),
        'languageLevel': selectedLanguageLevel,
        'progress': 0,
      };

      if (_selectedImage != null) {
        // Загрузка изображения в Firebase Storage
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef =
            storageRef.child('images/${_selectedImage!.path.split('/').last}');

        imageRef.putFile(_selectedImage!).then((taskSnapshot) async {
          final imageUrl = await imageRef.getDownloadURL();
          lesson['imageUrl'] = imageUrl; // Добавляем URL изображения в урок
          setState(() {
            temporaryLessons.add(lesson);
            _selectedImage = null; // Сбрасываем выбранное изображение
          });
        });
      } else {
        setState(() {
          temporaryLessons.add(lesson);
        });
      }

      // Очистка полей после добавления, кроме темы
      _phraseController.clear();
      _correctAnswerController.clear();
      _wordsController.clear();
      setState(() {
        selectedLanguageLevel = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Задание добавлено!'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Пожалуйста, заполните все поля!'),
      ));
    }
  }

  void _saveAllLessons() async {
    if (temporaryLessons.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        for (var lesson in temporaryLessons) {
          final audioData = await fetchAudio(lesson['phrase']);
          final storageRef = FirebaseStorage.instance.ref();
          final audioRef = storageRef.child('audio/${lesson['phrase']}.mp3');

          await audioRef.putData(audioData);
          final audioUrl = await audioRef.getDownloadURL();
          lesson['audioUrl'] = audioUrl;

          await FirebaseFirestore.instance
              .collection('audiolessons')
              .add(lesson);
        }

        setState(() {
          temporaryLessons.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Все уроки успешно добавлены!'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
        ));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Нет добавленных заданий для сохранения!'),
      ));
    }
  }

  Future<void> _playAudio(String phrase) async {
    setState(() {
      isLoading = true;
    });

    try {
      final audioData = await fetchAudio(phrase);
      await _audioPlayer.setSource(BytesSource(audioData));
      await _audioPlayer.resume();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка воспроизведения: ${e.toString()}'),
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Добавить аудиоурок"),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
                context, '/navadmin'); // Возврат на предыдущую страницу
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _topicController,
              decoration: InputDecoration(labelText: 'Тема урока'),
            ),
            TextField(
              controller: _phraseController,
              decoration: InputDecoration(labelText: 'Фраза на английском'),
            ),
            TextField(
              controller: _correctAnswerController,
              decoration: InputDecoration(labelText: 'Правильный перевод'),
            ),
            TextField(
              controller: _wordsController,
              decoration: InputDecoration(labelText: 'Слова (через запятую)'),
            ),
            SizedBox(height: 10),
            // Выбор уровня языка
            DropdownButton<String>(
              value: selectedLanguageLevel,
              hint: Text('Выберите уровень языка'),
              items: languageLevels.map((String level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedLanguageLevel = newValue;
                });
              },
            ),
            SizedBox(height: 10),
            // Кнопка для выбора изображения
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Выбрать изображение'),
            ),
            // Отображение выбранного изображения
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTemporaryLesson,
              child: Text('Добавить задание'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveAllLessons,
              child: Text('Сохранить уроки'),
            ),
            SizedBox(height: 10),
            // Кнопка для прослушивания фразы
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      // Воспроизвести аудио при нажатии
                      _playAudio(_phraseController.text);
                    },
              child:
                  Text(isLoading ? 'Воспроизведение...' : 'Прослушать фразу'),
            ),
          ],
        ),
      ),
    );
  }
}
