// lib/admin_panel/pages/admin_add_speaking_exercise_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_languageapplicationmycourse_2/models/voice_model.dart';
import 'package:uuid/uuid.dart';

class AdminAddSpeakingExercisePage extends StatefulWidget {
  const AdminAddSpeakingExercisePage({Key? key}) : super(key: key);

  @override
  _AdminAddSpeakingExercisePageState createState() =>
      _AdminAddSpeakingExercisePageState();
}

class _AdminAddSpeakingExercisePageState
    extends State<AdminAddSpeakingExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  // Контроллеры
  final _titleController = TextEditingController();
  final _textToSpeakController = TextEditingController();
  final _orderIndexController = TextEditingController(text: '0');
  final _audioUrlExampleController = TextEditingController(); // Для прямой вставки URL эталонного аудио

  // Переменные состояния
  String _selectedTargetLanguage = 'en-US'; // Используйте коды BCP-47 для Google API
  String _selectedLevel = 'Beginner';
  bool _isPublished = true;
  bool _isLoading = false; // Общий флаг загрузки для формы
  bool _isUploadingAudio = false; // Флаг для загрузки именно аудио-примера

  File? _pickedAudioExampleFile; // Файл для АУДИО-ПРИМЕРА
  String? _pickedAudioExampleFileName;

  final Map<String, String> _targetLanguageOptions = {
    'english': 'Английский',
    'german': 'Немецкий',
    'spanish': 'Испанский',
    // Добавьте другие языки
  };

  final List<String> _levelOptions = [
    'Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _textToSpeakController.dispose();
    _orderIndexController.dispose();
    _audioUrlExampleController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioExample() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedAudioExampleFile = File(result.files.single.path!);
          _pickedAudioExampleFileName = result.files.single.name;
          _audioUrlExampleController.clear(); // Очищаем поле URL, если выбран файл
        });
      } else {
        print('Аудиофайл примера не выбран');
      }
    } catch (e) {
      print("Ошибка выбора аудиофайла примера: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора аудио: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _uploadAudioExampleToStorage(File audioFile, String fileName) async {
    if (_isUploadingAudio) return null;
    setState(() => _isUploadingAudio = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Загрузка аудио-примера..."), duration: Duration(seconds: 10)), // Дольше, т.к. может быть большой файл
    );

    try {
      String uniqueFileName = 'example_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference ref = _storage.ref().child('speaking_exercise_examples/$uniqueFileName');
      UploadTask uploadTask = ref.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Аудио-пример успешно загружен!"), backgroundColor: Colors.green),
        );
      }
      return downloadUrl;
    } catch (e) {
      print("Ошибка загрузки аудио-примера в Storage: $e");
      if(mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки аудио-примера: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }


  Future<void> _submitExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_textToSpeakController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите текст для произношения.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true); // Включаем основной индикатор загрузки

    String? finalAudioExampleUrl = _audioUrlExampleController.text.trim();
    if (finalAudioExampleUrl.isEmpty) finalAudioExampleUrl = null; // Если пусто, то null

    if (_pickedAudioExampleFile != null && _pickedAudioExampleFileName != null) {
      // Если выбран файл для примера, загружаем его
      finalAudioExampleUrl = await _uploadAudioExampleToStorage(_pickedAudioExampleFile!, _pickedAudioExampleFileName!);
      if (finalAudioExampleUrl == null) {
        // Ошибка загрузки аудио-примера, прерываем
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    String exerciseId = _uuid.v4();
    int orderIndex = int.tryParse(_orderIndexController.text) ?? 0;

    final newExercise = SpeakingExercise(
      id: exerciseId,
      targetLanguage: _selectedTargetLanguage,
      level: _selectedLevel,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      textToSpeak: _textToSpeakController.text.trim(),
      audioUrlExample: finalAudioExampleUrl, // Передаем URL загруженного или введенного аудио
      orderIndex: orderIndex,
      createdAt: Timestamp.now(),
      isPublished: _isPublished,
    );

    try {
      await _firestore
          .collection('voice_lessons') // Используем 'voice_lessons'
          .doc(exerciseId)
          .set(newExercise.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Упражнение на говорение успешно добавлено!'), backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      print("Ошибка добавления упражнения в Firestore: $e");
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления упражнения: $e'), backgroundColor: Colors.red),
        );
       }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _textToSpeakController.clear();
    _orderIndexController.text = '0';
    _audioUrlExampleController.clear();
    setState(() {
      _selectedTargetLanguage = _targetLanguageOptions.isNotEmpty ? _targetLanguageOptions.keys.first : 'en-US';
      _selectedLevel = _levelOptions.isNotEmpty ? _levelOptions.first : 'Beginner';
      _isPublished = true;
      _pickedAudioExampleFile = null;
      _pickedAudioExampleFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Добавить упражнение на говорение",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _selectedTargetLanguage,
                decoration: const InputDecoration(labelText: 'Целевой язык*', border: OutlineInputBorder()),
                items: _targetLanguageOptions.entries.map((entry) {
                  return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedTargetLanguage = value);
                },
                validator: (value) => value == null || value.isEmpty ? 'Выберите язык' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: const InputDecoration(labelText: 'Уровень*', border: OutlineInputBorder()),
                items: _levelOptions.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedLevel = value);
                },
                validator: (value) => value == null || value.isEmpty ? 'Выберите уровень' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название упражнения (опционально)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _textToSpeakController,
                decoration: const InputDecoration(labelText: 'Текст для произношения пользователем*', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty ? 'Введите текст, который должен произнести пользователь' : null,
              ),
              const SizedBox(height: 16),

              Text("Аудио-пример эталонного произношения (опционально):", style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text("Пользователь сможет прослушать этот пример перед своей записью.", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _audioUrlExampleController,
                decoration: const InputDecoration(labelText: 'URL аудио-примера (если есть)', border: OutlineInputBorder()),
                keyboardType: TextInputType.url,
                enabled: _pickedAudioExampleFile == null,
              ),
              const SizedBox(height: 8),
              Center(child: Text("ИЛИ", style: TextStyle(color: Colors.grey.shade600))),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_isUploadingAudio ? Icons.hourglass_top_rounded : Icons.audiotrack_outlined),
                    label: Text(_isUploadingAudio ? 'Загрузка...' : 'Выбрать аудио-пример'),
                    onPressed: _isUploadingAudio ? null : _pickAudioExample,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade100, foregroundColor: Colors.blueGrey.shade900),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickedAudioExampleFileName ?? 'Файл не выбран',
                      style: TextStyle(color: _pickedAudioExampleFileName != null ? Colors.green.shade700 : Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_pickedAudioExampleFile != null && !_isUploadingAudio)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.red.shade700),
                      tooltip: "Удалить выбранный файл",
                      onPressed: (){ setState(() { _pickedAudioExampleFile = null; _pickedAudioExampleFileName = null; });},
                    )
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _orderIndexController,
                decoration: const InputDecoration(labelText: 'Порядковый номер*', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Укажите номер';
                  if (int.tryParse(value) == null) return 'Введите число';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Опубликовать сразу:'),
                  Switch(
                    value: _isPublished,
                    onChanged: (value) => setState(() => _isPublished = value),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text('Сохранить упражнение'),
                        onPressed: _submitExercise,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}