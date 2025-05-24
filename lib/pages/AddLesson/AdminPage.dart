import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddLessonPage extends StatefulWidget {
  @override
  _AddLessonPageState createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final TextEditingController _lessonNameController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translation1Controller = TextEditingController();
  final TextEditingController _translation2Controller = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();

  List<Map<String, dynamic>> _wordsList = [];
  File? _image; // для хранения выбранного изображения

  // Функция для выбора изображения
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> updateUserProgress(
      String lessonId, int completedTasks, int totalTasks) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Получаем документ пользователя
      final DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

      // Вычисляем процент прогресса
      int progress = (completedTasks / totalTasks * 100).toInt();

      // Обновляем прогресс для конкретного урока
      await userDoc.set({
        'progress': FieldValue.arrayUnion([
          {lessonId: progress}
        ])
      }, SetOptions(merge: true)); // Используем merge для объединения
    }
  }

  // Функция для загрузки изображения в Firebase Storage
  Future<String?> _uploadImage() async {
    if (_image == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
          'images/${_lessonNameController.text}/${DateTime.now().toIso8601String()}.png');

      await imageRef.putFile(_image!);
      return await imageRef.getDownloadURL();
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  void _addWord() {
    if (_wordController.text.isNotEmpty &&
        _translation1Controller.text.isNotEmpty &&
        _correctAnswerController.text.isNotEmpty) {
      setState(() {
        // Проверка на дубликаты
        if (!_wordsList
            .any((wordData) => wordData['word'] == _wordController.text)) {
          _wordsList.add({
            'word': _wordController.text,
            'translations': [
              _translation1Controller.text,
              _translation2Controller.text,
            ],
            'correctAnswer': _correctAnswerController.text,
          });
        }
      });

      // Очистить поля ввода для следующего слова
      _wordController.clear();
      _translation1Controller.clear();
      _translation2Controller.clear();
      _correctAnswerController.clear();
    }
  }

  void _saveLesson() async {
  if (_lessonNameController.text.isNotEmpty && _wordsList.isNotEmpty) {
    // Загрузить изображение и получить URL
    String? imageUrl = await _uploadImage();

    DocumentReference newLessonRef = await FirebaseFirestore.instance
        .collection('addlessons')
        .add({
      'lessonName': _lessonNameController.text,
      'words': _wordsList,
      'imageUrl': imageUrl, // Сохранить URL изображения
      'progress': 0, // Изначально прогресс 0%
      'level': 'Beginner', // Добавляем уровень со значением "Beginner"
    });

    // Обновить прогресс пользователя
    await updateUserProgress(newLessonRef.id, 0, _wordsList.length); // Обновляем прогресс для нового урока

    // Очистить имя урока и список слов после сохранения
    _lessonNameController.clear();
    setState(() {
      _wordsList.clear();
      _image = null; // Сбросить изображение
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Урок сохранён!'),
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить урок'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(
                context, '/navadmin'); // Возврат на предыдущую страницу
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _lessonNameController,
              decoration: InputDecoration(labelText: 'Название урока'),
            ),
            TextField(
              controller: _wordController,
              decoration: InputDecoration(labelText: 'Слово'),
            ),
            TextField(
              controller: _translation1Controller,
              decoration: InputDecoration(labelText: 'Перевод 1'),
            ),
            TextField(
              controller: _translation2Controller,
              decoration: InputDecoration(labelText: 'Перевод 2'),
            ),
            TextField(
              controller: _correctAnswerController,
              decoration: InputDecoration(labelText: 'Правильный ответ'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addWord,
              child: Text('Добавить задание'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Выбрать изображение'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveLesson,
              child: Text('Сохранить урок'),
            ),
            if (_image != null)
              Image.file(_image!,
                  height: 100,
                  width: 100), // Отображение выбранного изображения
            Expanded(
              child: ListView.builder(
                itemCount: _wordsList.length,
                itemBuilder: (context, index) {
                  final wordData = _wordsList[index];
                  return ListTile(
                    title: Text(wordData['word']),
                    subtitle: Text(wordData['translations'].join(', ')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
