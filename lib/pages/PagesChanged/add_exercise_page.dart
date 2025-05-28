// lib/admin/pages/AdminAddInteractiveLessonPage.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:toast/toast.dart';

// Модели TaskOption и LessonTask остаются без изменений (как в вашем коде)
class TaskOption {
  String id;
  TextEditingController textController = TextEditingController();
  bool isCorrect = false;
  TextEditingController feedbackController = TextEditingController();

  TaskOption({String? id}) : id = id ?? Uuid().v4();

  Map<String, dynamic> toJson() => {
    'text': textController.text.trim(),
    'isCorrect': isCorrect,
    'feedback': feedbackController.text.trim(),
  };
}

class LessonTask {
  String id;
  TextEditingController promptTextController = TextEditingController();
  File? imageFile;
  String? imageUrlForSaving;
  List<TaskOption> options = [TaskOption(), TaskOption()];

  LessonTask({String? id}) : id = id ?? Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'selectCorrectTranslation',
    'promptText': promptTextController.text.trim(),
    'imagePromptUrl': imageUrlForSaving ?? '',
    'options': options.map((opt) => opt.toJson()).toList(),
  };
}
// Конец моделей

class AdminAddInteractiveLessonPage extends StatefulWidget {
  const AdminAddInteractiveLessonPage({Key? key}) : super(key: key);

  @override
  _AdminAddInteractiveLessonPageState createState() =>
      _AdminAddInteractiveLessonPageState();
}

class _AdminAddInteractiveLessonPageState
    extends State<AdminAddInteractiveLessonPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedTargetLanguage = 'english';
  String _selectedRequiredLevel = 'Beginner';

  final List<String> _supportedLanguages = ['english', 'spanish', 'german'];
  final List<String> _supportedLevels = ['Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'];

  List<LessonTask> _tasks = [LessonTask()];

  bool _isLoading = false;
  final Uuid _uuid = Uuid();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var task in _tasks) {
      task.promptTextController.dispose();
      for (var option in task.options) {
        option.textController.dispose();
        option.feedbackController.dispose();
      }
    }
    super.dispose();
  }

  void _addTask() {
    setState(() {
      _tasks.add(LessonTask());
    });
  }

  void _removeTask(int taskIndex) {
    if (_tasks.length > 1) {
      setState(() {
        _tasks[taskIndex].promptTextController.dispose();
        for (var option in _tasks[taskIndex].options) {
          option.textController.dispose();
          option.feedbackController.dispose();
        }
        _tasks.removeAt(taskIndex);
      });
    } else {
      Toast.show("В уроке должно быть хотя бы одно задание.");
    }
  }

  void _addOptionToTask(int taskIndex) {
    setState(() {
      if (_tasks[taskIndex].options.length < 5) {
         _tasks[taskIndex].options.add(TaskOption());
      } else {
        Toast.show("Максимум 5 вариантов ответа.");
      }
    });
  }

  void _removeOptionFromTask(int taskIndex, int optionIndex) {
    if (_tasks[taskIndex].options.length > 2) {
      setState(() {
        _tasks[taskIndex].options[optionIndex].textController.dispose();
        _tasks[taskIndex].options[optionIndex].feedbackController.dispose();
        _tasks[taskIndex].options.removeAt(optionIndex);
      });
    } else {
      Toast.show("Минимум 2 варианта ответа.");
    }
  }

  Future<void> _pickImageForTask(int taskIndex) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _tasks[taskIndex].imageFile = File(pickedFile.path);
          _tasks[taskIndex].imageUrlForSaving = null;
        });
      }
    } catch (e) {
      Toast.show("Ошибка выбора изображения: $e", duration: Toast.lengthLong);
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile, String lessonId, String taskId) async {
    try {
      String fileExtension = imageFile.path.split('.').last;
      String fileName = 'interactiveLessons/$lessonId/$taskId/${_uuid.v4()}.$fileExtension';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Ошибка загрузки изображения в Storage: $e");
      Toast.show("Ошибка загрузки изображения.", duration: Toast.lengthLong);
      return null;
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) {
      Toast.show("Пожалуйста, заполните все обязательные поля.");
      return;
    }

    for (int i = 0; i < _tasks.length; i++) {
      var task = _tasks[i];
      if (task.promptTextController.text.trim().isEmpty) {
        Toast.show("Текст подсказки для задания ${i + 1} не может быть пустым.");
        return;
      }
      if (task.options.any((opt) => opt.textController.text.trim().isEmpty)) {
           Toast.show("Текст варианта ответа в задании ${i + 1} не может быть пустым.");
           return;
      }
      if (!task.options.any((opt) => opt.isCorrect)) {
        Toast.show("Задание ${i + 1} должно иметь хотя бы один правильный вариант ответа.");
        return;
      }
    }

    if (!mounted) return;
    setState(() { _isLoading = true; });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Toast.show("Ошибка: администратор не авторизован.");
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    String newLessonId = _uuid.v4();

    try {
      for (int i = 0; i < _tasks.length; i++) {
        if (_tasks[i].imageFile != null && _tasks[i].imageUrlForSaving == null) {
          String? uploadedUrl = await _uploadImageToStorage(_tasks[i].imageFile!, newLessonId, _tasks[i].id);
          if (uploadedUrl != null) {
            _tasks[i].imageUrlForSaving = uploadedUrl;
          } else {
            Toast.show("Не удалось загрузить изображение для задания ${i + 1}. Урок не сохранен.", duration: Toast.lengthLong);
            if (mounted) setState(() { _isLoading = false; });
            return;
          }
        }
      }

      final lessonData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'targetLanguage': _selectedTargetLanguage,
        'requiredLevel': _selectedRequiredLevel,
        'lessonType': 'chooseTranslation',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authorId': currentUser.uid,
        'order': await _getNextLessonOrder(),
        'tasks': _tasks.map((task) => task.toJson()).toList(),
      };

      await FirebaseFirestore.instance.collection('interactiveLessons').doc(newLessonId).set(lessonData);

      Toast.show("Урок успешно добавлен!", duration: Toast.lengthLong);
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      if(mounted) {
        setState(() {
          _tasks.forEach((task) {
            task.promptTextController.clear();
            task.imageFile = null;
            task.imageUrlForSaving = null;
            task.options.forEach((option) {
              option.textController.clear();
              option.feedbackController.clear();
              option.isCorrect = false;
            });
             if (task.options.length > 2) {
                task.options.removeRange(2, task.options.length);
            } else if (task.options.length < 2 && task.options.isNotEmpty) {
                task.options.add(TaskOption());
            } else if (task.options.isEmpty){
                 task.options.add(TaskOption());
                 task.options.add(TaskOption());
            }
          });
          if (_tasks.length > 1) {
             _tasks.removeRange(1, _tasks.length);
          } else if (_tasks.isEmpty){
             _tasks.add(LessonTask());
          }
          _isLoading = false;
        });
      }

    } catch (e) {
      print("Ошибка добавления урока: $e");
      Toast.show("Не удалось добавить урок. Попробуйте снова.", duration: Toast.lengthLong);
       if(mounted) setState(() { _isLoading = false; });
    }
  }

  Future<int> _getNextLessonOrder() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('interactiveLessons')
        .where('targetLanguage', isEqualTo: _selectedTargetLanguage)
        .where('requiredLevel', isEqualTo: _selectedRequiredLevel)
        .orderBy('order', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return (querySnapshot.docs.first.data()['order'] as int? ?? 0) + 1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
        appBar: AppBar(
        // --- НАЧАЛО ИЗМЕНЕНИЙ ---
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), // Иконка "Назад"
          tooltip: "Назад",
          onPressed: () {
            // Это стандартное действие для возврата на предыдущую страницу в стеке навигации
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Если вернуться некуда (например, это первая страница после входа в админку),
              // можно предусмотреть переход на главную страницу админки,
              // если она у вас есть и вы знаете ее маршрут.
              // Например: Navigator.pushReplacementNamed(context, '/adminHome');
              // Пока оставим просто pop, если это возможно.
            }
          },
        ),
        // --- КОНЕЦ ИЗМЕНЕНИЙ ---
        title: Text("Добавить урок: Выбор перевода"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // Обертка для всей формы для общей прокрутки
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("1. Информация об уроке", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Название урока", border: OutlineInputBorder(), hintText: "Например: Приветствия на испанском"),
                  validator: (value) => value == null || value.isEmpty ? "Введите название урока" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: "Описание (опционально)", border: OutlineInputBorder(), hintText: "Чему научит этот урок?"),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Используем Wrap для DropdownButtonFormField для лучшей адаптивности
                Wrap(
                  spacing: 12.0, // Горизонтальный отступ между элементами
                  runSpacing: 12.0, // Вертикальный отступ, если элементы переносятся
                  children: [
                    SizedBox( // Ограничиваем минимальную ширину для Dropdown, чтобы они не были слишком узкими
                      width: MediaQuery.of(context).size.width < 400 ? double.infinity : (MediaQuery.of(context).size.width / 2) - 22, // -22 для padding и spacing
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: "Язык урока", border: OutlineInputBorder()),
                        value: _selectedTargetLanguage,
                        items: _supportedLanguages.map((lang) {
                           String displayName = lang;
                           if(lang == 'english') displayName = 'Английский';
                           if(lang == 'spanish') displayName = 'Испанский';
                           if(lang == 'german') displayName = 'Немецкий';
                           return DropdownMenuItem(value: lang, child: Text(displayName));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedTargetLanguage = value!),
                        validator: (value) => value == null ? "Выберите язык" : null,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width < 400 ? double.infinity : (MediaQuery.of(context).size.width / 2) - 22,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: "Требуемый уровень", border: OutlineInputBorder()),
                        value: _selectedRequiredLevel,
                        items: _supportedLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                        onChanged: (value) => setState(() => _selectedRequiredLevel = value!),
                         validator: (value) => value == null ? "Выберите уровень" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(thickness: 1),
                const SizedBox(height: 16),
                Text("2. Задания урока (выберите правильный перевод)", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (_tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text("Нажмите 'Добавить задание', чтобы начать.", style: TextStyle(color: Colors.grey[600]))),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(), // Важно для вложенных списков
                  itemCount: _tasks.length,
                  itemBuilder: (context, taskIndex) {
                    return _buildTaskInput(taskIndex);
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                  label: Text("Добавить задание", style: TextStyle(color: Colors.blueAccent)),
                  onPressed: _addTask,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save_alt_outlined, color: Colors.white),
                    label: Text("Сохранить урок", style: TextStyle(color: Colors.white)),
                    onPressed: _isLoading ? null : _saveLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                if (_isLoading) Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInput(int taskIndex) {
    LessonTask task = _tasks[taskIndex];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Задание ${taskIndex + 1}", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (_tasks.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                    tooltip: "Удалить это задание",
                    onPressed: () => _removeTask(taskIndex),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: task.promptTextController,
              decoration: InputDecoration(
                labelText: "Вопрос / Фраза для перевода",
                hintText: "Например: Как сказать 'Доброе утро'?",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.quiz_outlined)
              ),
              validator: (value) => value == null || value.isEmpty ? "Введите вопрос или фразу" : null,
            ),
            const SizedBox(height: 16),
            Text("Изображение/GIF (опционально):", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.attach_file, size: 20),
                  label: Text(task.imageFile == null && (task.imageUrlForSaving == null || task.imageUrlForSaving!.isEmpty) ? "Выбрать" : "Изменить"),
                  onPressed: () => _pickImageForTask(taskIndex),
                ),
                const SizedBox(width: 12),
                // Используем Flexible, чтобы текст мог переноситься или сокращаться
                if (task.imageFile != null)
                  Flexible(
                    child: Text(
                      "...${task.imageFile!.path.split(Platform.pathSeparator).last}",
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(fontSize: 12, color: Colors.grey[700])
                    )
                  )
                else if (task.imageUrlForSaving != null && task.imageUrlForSaving!.isNotEmpty)
                    Flexible(child: Text("Загружено", style: TextStyle(fontSize: 12, color: Colors.green[700], fontStyle: FontStyle.italic))),
              ],
            ),
            // Предпросмотр изображения
            if (task.imageFile != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                constraints: BoxConstraints(maxHeight: 150), // Ограничиваем высоту предпросмотра
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                child: Image.file(task.imageFile!, width: double.infinity, fit: BoxFit.contain),
              )
            else if (task.imageUrlForSaving != null && task.imageUrlForSaving!.isNotEmpty)
                 Container(
                    margin: const EdgeInsets.only(top: 10),
                    constraints: BoxConstraints(maxHeight: 150),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                    child: Image.network(
                        task.imageUrlForSaving!,
                        width: double.infinity, fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 40, color: Colors.red)),
                        loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: SizedBox(width: 30, height: 30, child:CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null ?
                                       loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                       : null,
                                strokeWidth: 2.0,
                            )));
                        },
                    )
                  ),
            const SizedBox(height: 16),
            Text("Варианты ответа (на изучаемом языке):", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: task.options.length,
              itemBuilder: (context, optionIndex) {
                TaskOption option = task.options[optionIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  // Используем Wrap для вариантов, если они не помещаются в строку на узких экранах
                  child: Wrap( // ИЗМЕНЕНИЕ: Обернули Row в Wrap
                    spacing: 8.0, // Горизонтальный отступ
                    runSpacing: 8.0, // Вертикальный отступ при переносе
                    crossAxisAlignment: WrapCrossAlignment.center, // Выравнивание по центру при переносе
                    children: [
                      SizedBox( // Ограничиваем ширину, чтобы Wrap мог работать
                        width: MediaQuery.of(context).size.width > 500 ? 200 : (MediaQuery.of(context).size.width * 0.35),
                        child: TextFormField(
                          controller: option.textController,
                          decoration: InputDecoration(
                            labelText: "Вариант ${optionIndex + 1}",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)
                          ),
                           validator: (value) => value == null || value.isEmpty ? "Введите текст варианта" : null,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width > 500 ? 200 : (MediaQuery.of(context).size.width * 0.3),
                        child: TextFormField(
                          controller: option.feedbackController,
                          decoration: InputDecoration(
                            labelText: "Фидбек",
                            hintText: "Опционально",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)
                            ),
                        ),
                      ),
                      // Оставляем Checkbox и кнопку удаления как есть, Wrap должен их разместить
                      Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        child: Checkbox(
                          value: option.isCorrect,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                for (var opt in task.options) {
                                  opt.isCorrect = false;
                                }
                                option.isCorrect = true;
                              } else {
                                option.isCorrect = false;
                              }
                            });
                          },
                        ),
                      ),
                      if (task.options.length > 2)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: Colors.red[300]),
                          tooltip: "Удалить вариант",
                          onPressed: () => _removeOptionFromTask(taskIndex, optionIndex),
                        ),
                    ],
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.add, size: 20),
                label: Text("Добавить вариант"),
                onPressed: () => _addOptionToTask(taskIndex),
                style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8))
              ),
            ),
             if (taskIndex < _tasks.length - 1)
                Divider(height: 30, thickness: 0.8, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}