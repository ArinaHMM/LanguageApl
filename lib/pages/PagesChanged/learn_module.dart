import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart'; // Usually in main.dart
import 'package:uuid/uuid.dart';

// Модель LearningItem больше не нужна для этой страницы

class AdminAddContentPage extends StatefulWidget {
  const AdminAddContentPage({Key? key}) : super(key: key);

  @override
  _AdminAddContentPageState createState() => _AdminAddContentPageState();
}

class _AdminAddContentPageState extends State<AdminAddContentPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  // Контроллеры для полей
  final _topicNameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _textContentController = TextEditingController();
  final _translationNotesController =
      TextEditingController(); // Для опционального перевода или заметок

  String _selectedTargetLanguage = 'english';
  String _selectedLevel = 'Beginner';
  bool _isPublished = true;
  bool _isLoading = false;

  final Map<String, String> _targetLanguageDisplayNames = {
    'english': 'Английский',
    'german': 'Немецкий',
    'spanish': 'Испанский',
    // Добавьте другие языки по необходимости
  };

  final List<String> _levels = [
    'Beginner',
    'Elementary',
    'Intermediate',
    'Upper Intermediate',
    'Advanced'
  ];

  @override
  void initState() {
    super.initState();
    // Безопасная инициализация выбранных значений
    if (_targetLanguageDisplayNames.isNotEmpty) {
      _selectedTargetLanguage = _targetLanguageDisplayNames.keys.first;
    }
    if (_levels.isNotEmpty) {
      _selectedLevel =
          _levels.contains('Beginner') ? 'Beginner' : _levels.first;
    }
  }

  @override
  void dispose() {
    _topicNameController.dispose();
    _imageUrlController.dispose();
    _textContentController.dispose();
    _translationNotesController.dispose();
    super.dispose();
  }

  void _resetFormFields() {
    _formKey.currentState?.reset();
    _topicNameController.clear();
    _imageUrlController.clear();
    _textContentController.clear();
    _translationNotesController.clear();

    if (_targetLanguageDisplayNames.isNotEmpty) {
      _selectedTargetLanguage = _targetLanguageDisplayNames.keys.first;
    }
    if (_levels.isNotEmpty) {
      _selectedLevel =
          _levels.contains('Beginner') ? 'Beginner' : _levels.first;
    }
    _isPublished = true;
    setState(() {}); // Обновить UI для отражения сброшенных Dropdown и Switch
  }

  Future<void> _submitContent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String contentId = _uuid.v4();
        // Используем новую коллекцию 'learning_content' или измените на 'learning_modules', если хотите перезаписать старую структуру
        await _firestore.collection('learning_modules').doc(contentId).set({
          'content_id': contentId,
          'topic_name': _topicNameController.text,
          'target_language': _selectedTargetLanguage,
          'level': _selectedLevel,
          'image_url': _imageUrlController.text.isNotEmpty
              ? _imageUrlController.text
              : null,
          'text_content': _textContentController.text.isNotEmpty
              ? _textContentController.text
              : null,
          'translation_notes': _translationNotesController.text.isNotEmpty
              ? _translationNotesController.text
              : null,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'is_published': _isPublished,
          'author_id': 'admin_fixed_id', // TODO: Заменить на реальный ID автора
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Контент успешно добавлен!'),
              backgroundColor: Colors.green),
        );
        _resetFormFields();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка добавления контента: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Пожалуйста, заполните все обязательные поля.'),
            backgroundColor: Colors.orange),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600, color: Colors.teal.shade700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить учебный контент'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Основные параметры'),
                const SizedBox(height: 12),

                // Выбор языка и уровня в одной строке для компактности
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTargetLanguage,
                        decoration: InputDecoration(
                          labelText: 'Целевой язык*',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _targetLanguageDisplayNames.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTargetLanguage = value);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Выберите язык' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Уровень*',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _levels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Выберите уровень' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _topicNameController,
                  decoration: InputDecoration(
                    labelText: 'Название темы*',
                    hintText: 'Например: Приветствия и знакомства',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Название темы обязательно'
                      : null,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Опубликовать сразу:',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade700)),
                    Switch(
                      value: _isPublished,
                      onChanged: (value) =>
                          setState(() => _isPublished = value),
                      activeColor: Colors.teal,
                    ),
                  ],
                ),

                _buildSectionTitle('Материалы темы'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'URL фото/изображения (опционально)',
                    hintText: 'https://example.com/image.png',
                    prefixIcon:
                        Icon(Icons.image_outlined, color: Colors.teal.shade300),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _textContentController,
                  decoration: InputDecoration(
                    labelText: 'Основной текст материала (опционально)',
                    hintText:
                        'Введите здесь основной учебный текст, диалог, правила...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true, // Для лучшего вида с multiline
                  ),
                  maxLines: 5,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _translationNotesController,
                  decoration: InputDecoration(
                    labelText: 'Перевод или заметки (опционально)',
                    hintText:
                        'Здесь можно добавить перевод основного текста или важные заметки...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  minLines: 2,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 30),

                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt_outlined, size: 20),
                          label: const Text('Сохранить контент',
                              style: TextStyle(fontSize: 16)),
                          onPressed: _submitContent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                        ),
                ),
                const SizedBox(height: 20), // Дополнительный отступ снизу
              ],
            ),
          ),
        ),
      ),
    );
  }
}
