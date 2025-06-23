// lib/admin/pages/admin_add_audio_word_bank_lesson_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/database/storage/audiolessons.dart';
import 'package:uuid/uuid.dart';
import 'package:toast/toast.dart';
import 'package:audioplayers/audioplayers.dart';

// Импортируем новый сервисный класс
// Импортируем TtsService
import 'package:flutter_languageapplicationmycourse_2/models/tts.dart'; // Предполагаем, что TtsService в этом файле

// Модель AudioWordBankTask (остается такой же)
class AudioWordBankTask {
  String id;
  TextEditingController promptTextController = TextEditingController();
  TextEditingController textToSpeakController = TextEditingController();
  String? audioUrlForSaving;
  TextEditingController correctSentenceController = TextEditingController();
  TextEditingController wordBankController = TextEditingController();
  TextEditingController feedbackCorrectController = TextEditingController();
  TextEditingController feedbackIncorrectController = TextEditingController();
  bool isSynthesizing = false;
  // bool previewAudioAvailable = false; 

  AudioWordBankTask({String? id}) : id = id ?? Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'audioWordBankSentence',
    'promptText': promptTextController.text.trim(),
    'textToSpeak': textToSpeakController.text.trim(),
    'audioUrl': audioUrlForSaving ?? '',
    'correctSentence': correctSentenceController.text.trim(),
    'wordBank': wordBankController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    'feedbackCorrect': feedbackCorrectController.text.trim(),
    'feedbackIncorrect': feedbackIncorrectController.text.trim(),
  };

  void dispose() {
    promptTextController.dispose();
    textToSpeakController.dispose();
    correctSentenceController.dispose();
    wordBankController.dispose();
    feedbackCorrectController.dispose();
    feedbackIncorrectController.dispose();
  }
}

class AdminAddAudioWordBankLessonPage extends StatefulWidget {
  const AdminAddAudioWordBankLessonPage({Key? key}) : super(key: key);

  @override
  _AdminAddAudioWordBankLessonPageState createState() =>
      _AdminAddAudioWordBankLessonPageState();
}

class _AdminAddAudioWordBankLessonPageState extends State<AdminAddAudioWordBankLessonPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedTargetLanguage = 'english';
  String _selectedRequiredLevel = 'Beginner';

  final List<String> _supportedLanguages = ['english', 'spanish', 'german'];
  final List<String> _supportedLevels = ['Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'];

  List<AudioWordBankTask> _tasks = [AudioWordBankTask()];

  bool _isLoading = false;
  final Uuid _uuid = Uuid();
  final AudioPlayer _adminAudioPlayer = AudioPlayer();
  int _currentlyPlayingPreviewTaskIndex = -1;
  String? _lastPlayedPreviewUrl;

  // Экземпляр нового сервиса
  final AudioWordBankLessonsService _audioWordBankLessonsService = AudioWordBankLessonsService();

  @override
  void initState() {
    super.initState();
    _adminAudioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      if (!mounted) return;
      if (s == PlayerState.completed || s == PlayerState.stopped || s == PlayerState.paused) {
        setState(() => _currentlyPlayingPreviewTaskIndex = -1);
      }
    });
  }

  @override
  void dispose() {
    // ... (dispose контроллеров как раньше) ...
    _titleController.dispose();
    _descriptionController.dispose();
    for (var task in _tasks) {
      task.dispose();
    }
    _adminAudioPlayer.dispose();
    super.dispose();
  }

  void _addTask() { /* ... (без изменений) ... */ 
     setState(() {
      _tasks.add(AudioWordBankTask());
    });
  }
  void _removeTask(int taskIndex) { /* ... (без изменений) ... */ 
      if (_tasks.length > 1) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text("Удалить задание?"),
            content: Text("Вы уверены, что хотите удалить Задание ${taskIndex + 1}?"),
            actions: <Widget>[
              TextButton(child: Text("Отмена"), onPressed: () => Navigator.of(dialogContext).pop()),
              TextButton(
                child: Text("Удалить", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _tasks[taskIndex].dispose();
                    _tasks.removeAt(taskIndex);
                  });
                },
              ),
            ],
          );
        },
      );
    } else {
      Toast.show("В уроке должно быть хотя бы одно задание.");
    }
  }

  Future<void> _previewSynthesizedAudio(int taskIndex) async { /* ... (без изменений, использует TtsService.synthesizeAndUpload) ... */ 
      if (!mounted) return;
    final task = _tasks[taskIndex];
    if (task.textToSpeakController.text.trim().isEmpty) {
      Toast.show("Введите текст для озвучивания.");
      return;
    }

    if (_adminAudioPlayer.state == PlayerState.playing && _currentlyPlayingPreviewTaskIndex != taskIndex) {
        await _adminAudioPlayer.stop();
        setState(() => _currentlyPlayingPreviewTaskIndex = -1);
    }
    
    setState(() {
      task.isSynthesizing = true;
      _lastPlayedPreviewUrl = null; 
    });

    try {
      String? synthesizedAudioUrl = await TtsService.synthesizeAndUpload(
        task.textToSpeakController.text.trim(),
        _selectedTargetLanguage,
        "previewLessonId", 
        task.id,
      );

      if (mounted) {
        setState(() { task.isSynthesizing = false; });
      }

      if (synthesizedAudioUrl != null) {
        _lastPlayedPreviewUrl = synthesizedAudioUrl;
        await _adminAudioPlayer.play(UrlSource(synthesizedAudioUrl));
        if (mounted) {
          setState(() => _currentlyPlayingPreviewTaskIndex = taskIndex);
        }
      } else {
        Toast.show("Не удалось синтезировать речь для предпрослушивания.");
      }
    } catch (e) {
      if (mounted) {
        setState(() { task.isSynthesizing = false; });
        Toast.show("Ошибка предпрослушивания: $e", duration: Toast.lengthLong);
      }
    }
  }

  Future<void> _saveLesson() async {
    // ... (валидация как раньше) ...
    if (!_formKey.currentState!.validate()) {
      Toast.show("Пожалуйста, заполните все обязательные поля и исправьте ошибки.");
      return;
    }
    for (int i = 0; i < _tasks.length; i++) {
      var task = _tasks[i];
      if (task.textToSpeakController.text.trim().isEmpty) {
        Toast.show("Текст для озвучивания в задании ${i + 1} не может быть пустым.");
        return;
      }
      if (task.correctSentenceController.text.trim().isEmpty) { 
        Toast.show("Правильное предложение для задания ${i + 1} не может быть пустым.");
        return;
      }
      if (task.wordBankController.text.trim().isEmpty) {
        Toast.show("Банк слов для задания ${i + 1} не может быть пустым.");
        return;
      }
       List<String> correctWords = task.correctSentenceController.text
    .trim()
    .toLowerCase()
    .split(RegExp(r'[^\w]+')) // заменили \p{Punct}
    .where((s) => s.isNotEmpty)
    .toList();

       List<String> bankWords = task.wordBankController.text.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
       if (!correctWords.every((word) => bankWords.contains(word))) {
          Toast.show("Не все слова из правильного предложения (${correctWords.join(' ')}) есть в банке слов для задания ${i+1}. Банк: ${bankWords.join(', ')}");
       }
    }


    if (!mounted) return;
    setState(() { _isLoading = true; });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) { /* ... */ 
        Toast.show("Ошибка: администратор не авторизован.");
        if (mounted) setState(() { _isLoading = false; });
        return;
    }

    String newLessonId = _uuid.v4();

    try {
      List<Map<String, dynamic>> tasksJsonList = [];
      for (int i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        if (task.audioUrlForSaving == null || task.audioUrlForSaving!.isEmpty) {
          if (task.textToSpeakController.text.trim().isEmpty) {
              Toast.show("Текст для озвучивания в задании ${i + 1} пуст. Урок не сохранен.", duration: Toast.lengthLong);
              if (mounted) setState(() { _isLoading = false; });
              return;
          }
          Toast.show("Генерация аудио для задания ${i + 1}...", duration: Toast.lengthShort);
          String? generatedAudioUrl = await TtsService.synthesizeAndUpload(
            task.textToSpeakController.text.trim(),
            _selectedTargetLanguage,
            newLessonId,
            task.id,
          );

          if (generatedAudioUrl != null) {
            task.audioUrlForSaving = generatedAudioUrl;
          } else { /* ... (обработка ошибки генерации) ... */ 
              Toast.show("Не удалось синтезировать аудио для задания ${i + 1}. Урок не сохранен.", duration: Toast.lengthLong);
            if (mounted) setState(() { _isLoading = false; });
            return;
          }
        }
        tasksJsonList.add(task.toJson());
      }

      final lessonData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'targetLanguage': _selectedTargetLanguage,
        'requiredLevel': _selectedRequiredLevel,
        'lessonType': 'audioWordBankSentence', // Тип урока
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authorId': currentUser.uid,
        // Используем новый сервис для получения порядка для НОВОЙ КОЛЛЕКЦИИ
        'order': await _audioWordBankLessonsService.getNextOrderForAudioWordBankLesson(
            _selectedTargetLanguage, 
            _selectedRequiredLevel
        ),
        'tasks': tasksJsonList,
      };

      // Используем новый сервис для добавления урока в НОВУЮ КОЛЛЕКЦИЮ
      await _audioWordBankLessonsService.addAudioWordBankLesson(newLessonId, lessonData);

      Toast.show("Урок '${_titleController.text.trim()}' успешно добавлен в 'audioWordBankLessons'!", duration: Toast.lengthLong);
      
      // ... (сброс формы как раньше) ...
      _formKey.currentState?.reset();
      _titleController.clear();
      _descriptionController.clear();
      if(mounted) {
        setState(() {
          for (var task in _tasks) { task.dispose(); }
          _tasks = [AudioWordBankTask()]; 
          _isLoading = false;
        });
      }

    } catch (e) {
      print("Ошибка добавления урока (AudioWordBank TTS to new collection): $e");
      Toast.show("Не удалось добавить урок. Попробуйте снова.", duration: Toast.lengthLong);
       if(mounted) setState(() { _isLoading = false; });
    }
  }

  // Убираем getNextLessonOrder из этого файла, так как он теперь в сервисе
  // Future<int> _getNextLessonOrder(String collectionName) async { ... } 


  @override
  Widget build(BuildContext context) { /* ... (UI как раньше, без изменений в этой части) ... */ 
    ToastContext().init(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        title: Text("Урок: Аудио TTS + Банк Слов", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.orange[400],
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("1. Информация об уроке", theme),
                 TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(labelText: "Название урока", hintText: "Например: Покупки в магазине"),
                  validator: (value) => value == null || value.trim().isEmpty ? "Введите название урока" : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(labelText: "Описание (опционально)", hintText: "Кратко, о чем этот урок"),
                  maxLines: 3,
                  minLines: 1,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _inputDecoration(labelText: "Язык урока"),
                        value: _selectedTargetLanguage,
                        items: _supportedLanguages.map((lang) {
                          String displayName = lang;
                          if (lang == 'english') displayName = 'Английский';
                          if (lang == 'spanish') displayName = 'Испанский';
                          if (lang == 'german') displayName = 'Немецкий';
                          return DropdownMenuItem(value: lang, child: Text(displayName));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedTargetLanguage = value);
                        },
                        validator: (value) => value == null ? "Выберите язык" : null,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _inputDecoration(labelText: "Требуемый уровень"),
                        value: _selectedRequiredLevel,
                        items: _supportedLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                        onChanged: (value) {
                           if (value != null) setState(() => _selectedRequiredLevel = value);
                        },
                        validator: (value) => value == null ? "Выберите уровень" : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Divider(thickness: 1.2, color: theme.dividerColor.withOpacity(0.5)),
                SizedBox(height: 16),
                
                _buildSectionTitle("2. Задания урока", theme),
                if (_tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: Text("Нажмите 'Добавить задание', чтобы начать.", style: TextStyle(color: Colors.grey[600]))),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _tasks.length,
                  itemBuilder: (context, taskIndex) {
                    return _buildTextToSpeechTaskInput(taskIndex, theme); 
                  },
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.secondary),
                    label: Text("Добавить задание", style: TextStyle(color: theme.colorScheme.secondary)),
                    onPressed: _addTask,
                     style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.7)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save_alt_outlined, color: Colors.white),
                    label: Text("Сохранить урок", style: TextStyle(color: Colors.white, fontSize: 18)),
                    onPressed: _isLoading ? null : _saveLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(color: theme.primaryColor),
                    ),
                  ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
   }

  Widget _buildSectionTitle(String title, ThemeData theme) { /* ... (без изменений) ... */ 
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  InputDecoration _inputDecoration({required String labelText, String? hintText, Widget? prefixIcon}) { /* ... (без изменений) ... */
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
   }

  Widget _buildTextToSpeechTaskInput(int taskIndex, ThemeData theme) { /* ... (без изменений) ... */
    AudioWordBankTask task = _tasks[taskIndex];
    bool isCurrentlyPlayingThisPreview = _currentlyPlayingPreviewTaskIndex == taskIndex && _adminAudioPlayer.state == PlayerState.playing;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Задание ${taskIndex + 1}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                if (_tasks.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent[200]),
                    tooltip: "Удалить это задание",
                    onPressed: () => _removeTask(taskIndex),
                  ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: task.promptTextController,
              decoration: _inputDecoration(labelText: "Инструкция к заданию (опционально)", hintText: "Например: Прослушайте и соберите фразу", prefixIcon: Icon(Icons.help_outline_rounded)),
            ),
            SizedBox(height: 12),
            
            Text("Текст для озвучивания (на языке урока):", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            TextFormField(
              controller: task.textToSpeakController,
              decoration: _inputDecoration(labelText: "Текст для синтеза речи", hintText: "Введите текст, который будет озвучен", prefixIcon: Icon(Icons.record_voice_over_rounded)),
              maxLines: 3,
              minLines: 1,
              validator: (v) => v == null || v.trim().isEmpty ? "Введите текст для озвучивания" : null,
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: task.isSynthesizing 
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))
                    : Icon(
                        isCurrentlyPlayingThisPreview ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                        color: isCurrentlyPlayingThisPreview ? Colors.redAccent : theme.colorScheme.primary,
                        size: 22
                      ),
                label: Text(
                  task.isSynthesizing ? "Синтез..." : (isCurrentlyPlayingThisPreview ? "Стоп" : "Прослушать"),
                  style: TextStyle(color: isCurrentlyPlayingThisPreview && !task.isSynthesizing ? Colors.redAccent : theme.colorScheme.primary),
                ),
                onPressed: task.isSynthesizing ? null : () {
                  if (isCurrentlyPlayingThisPreview) {
                    _adminAudioPlayer.stop();
                  } else {
                    _previewSynthesizedAudio(taskIndex);
                  }
                },
                style: OutlinedButton.styleFrom(
                   side: BorderSide(color: isCurrentlyPlayingThisPreview && !task.isSynthesizing ? Colors.redAccent.withOpacity(0.7) : theme.colorScheme.primary.withOpacity(0.7)),
                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                ),
              ),
            ),
            if (task.audioUrlForSaving != null && task.audioUrlForSaving!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("Аудио URL: ${task.audioUrlForSaving!.substring(0,min(Random().nextInt(task.audioUrlForSaving!.length -1 ) +1, task.audioUrlForSaving!.length > 40 ? 40 : task.audioUrlForSaving!.length))}...", style: TextStyle(color: Colors.green[700], fontSize: 10, fontStyle: FontStyle.italic)),
              ),
            SizedBox(height: 16),

            TextFormField(
              controller: task.correctSentenceController,
              decoration: _inputDecoration(labelText: "Правильное предложение", hintText: "Что пользователь должен собрать", prefixIcon: Icon(Icons.check_circle_outline_rounded)),
              validator: (v) => v == null || v.trim().isEmpty ? "Введите правильное предложение" : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: task.wordBankController,
              decoration: _inputDecoration(labelText: "Банк слов (через запятую)", hintText: "Слово1, Слово2, ЛишнееСлово", prefixIcon: Icon(Icons.list_alt_rounded)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Заполните банк слов";
                if (v.split(',').where((s) => s.trim().isNotEmpty).length < 2) return "Минимум 2 слова в банке";
                return null;
              },
            ),
            SizedBox(height: 16),
            Text("Фидбек (опционально):", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            TextFormField(
              controller: task.feedbackCorrectController,
              decoration: _inputDecoration(labelText: "При правильном ответе", prefixIcon: Icon(Icons.thumb_up_alt_outlined)),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: task.feedbackIncorrectController,
              decoration: _inputDecoration(labelText: "При неправильном ответе", prefixIcon: Icon(Icons.thumb_down_alt_outlined)),
            ),
            if (taskIndex < _tasks.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Divider(thickness: 1, color: theme.dividerColor.withOpacity(0.4)),
              ),
          ],
        ),
      ),
    );
  }
}