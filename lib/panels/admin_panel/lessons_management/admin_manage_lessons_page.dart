// lib/admin_panel/pages/admin_manage_lessons_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Для Timestamp, если используется напрямую
import 'package:toast/toast.dart'; // Если вы хотите использовать Toast
// Замените пути на ваши реальные пути к моделям и сервисам
import '../../../database/collections/lessons_collections.dart';
import '../../../models/lesson_model.dart';
import '../../../models/audiolessons_service.dart'; // Для AudioWordBankLessonsService
import 'dart:math' as math; // Для math.min

// Предположим, у вас есть этот файл или аналогичные константы где-то
// Это нужно для _levelOrder, _levelColors, _levelIcons
// Если нет, скопируйте их из LearnPage или определите здесь
const List<String> _levelOrder = [
  'Beginner',
  'Elementary',
  'Intermediate',
  'Upper Intermediate',
  'Advanced',
  'Прочее' // Добавим "Прочее" как стандартный уровень в конце
];

// Цвета и иконки можно настроить или взять из LearnPage
final Map<String, Color> _levelColors = {
  'Beginner': Colors.green.shade300,
  'Elementary': Colors.blue.shade300,
  'Intermediate': Colors.orange.shade400,
  'Upper Intermediate': Colors.purple.shade300,
  'Advanced': Colors.red.shade400,
  'Прочее': Colors.grey.shade500,
};

final Map<String, IconData> _levelIcons = {
  'Beginner': Icons.emoji_people_rounded,
  'Elementary': Icons.school_rounded,
  'Intermediate': Icons.auto_stories_rounded,
  'Upper Intermediate': Icons.menu_book_rounded,
  'Advanced': Icons.military_tech_rounded,
  'Прочее': Icons.explore_rounded,
};


class AdminManageLessonsPage extends StatefulWidget {
  const AdminManageLessonsPage({Key? key}) : super(key: key);

  @override
  State<AdminManageLessonsPage> createState() => _AdminManageLessonsPageState();
}

class _AdminManageLessonsPageState extends State<AdminManageLessonsPage> {
  final LessonsCollection _lessonsCollection = LessonsCollection();
  final AudioWordBankLessonsService _audioWordBankService = AudioWordBankLessonsService();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedLanguage = 'english'; // Язык по умолчанию
  List<Lesson> _allLessonsForSelectedLanguage = [];
  Map<String, List<Lesson>> _groupedLessons = {};

  // Список языков, для которых есть уроки или которые вы поддерживаете
  // В идеале, это должно приходить с бэкенда или из конфигурации
  final List<String> _supportedLanguages = ['english', 'spanish', 'german']; // Пример

  @override
  void initState() {
    super.initState();
    ToastContext().init(context); // Инициализация ToastContext
    _fetchLessonsForLanguage(_selectedLanguage);
  }

  String _getLanguageDisplayName(String code) {
    switch (code.toLowerCase()) {
      case 'english': return 'Английский';
      case 'spanish': return 'Испанский';
      case 'german': return 'Немецкий';
      default: return code[0].toUpperCase() + code.substring(1);
    }
  }

  Future<void> _fetchLessonsForLanguage(String languageCode) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allLessonsForSelectedLanguage = [];
      _groupedLessons = {};
    });

    List<Lesson> fetchedLessons = [];
    try {
      // Коллекции стандартных уроков (аналогично LearnPage)
      final standardLessonCollections = [
        'interactiveLessons', 'addlessons', 'upperlessons', 'audiolessons',
        'videolessons', 'advancedlessons', 'upperinterlessons', 'upperupinterlessons'
      ];

      for (String collectionName in standardLessonCollections) {
        try {
          List<Lesson> lessonsFromStdCollection = await _lessonsCollection.getLessons(collectionName, languageCode);
          fetchedLessons.addAll(lessonsFromStdCollection);
        } catch (e) {
          print("Error fetching from standard collection '$collectionName' for $languageCode: $e");
        }
      }

      // Уроки из AudioWordBankService
      try {
        List<Lesson> audioWordBankLessons = await _audioWordBankService.getAudioWordBankLessons(languageCode);
        fetchedLessons.addAll(audioWordBankLessons);
      } catch (e) {
        print("Error fetching from AudioWordBankService for $languageCode: $e");
      }

      // Сортировка (необязательно для админки, но может быть полезна)
      fetchedLessons.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      if (mounted) {
        setState(() {
          _allLessonsForSelectedLanguage = fetchedLessons;
          _groupLessonsByLevel();
          _isLoading = false;
        });
      }
    } catch (e, s) {
      print("Error in _fetchLessonsForLanguage for $languageCode: $e\nStack: $s");
      if (mounted) {
        setState(() {
          _errorMessage = "Не удалось загрузить список уроков для выбранного языка.";
          _isLoading = false;
        });
      }
    }
  }

  void _groupLessonsByLevel() {
    Map<String, List<Lesson>> lessonsByLevelMap = {};
    for (var lesson in _allLessonsForSelectedLanguage) {
      String levelKey = _levelOrder.contains(lesson.requiredLevel) ? lesson.requiredLevel : 'Прочее';
      lessonsByLevelMap.putIfAbsent(levelKey, () => []).add(lesson);
    }
    // Сортируем уровни в соответствии с _levelOrder
    _groupedLessons = Map.fromEntries(
      _levelOrder
          .where((level) => lessonsByLevelMap.containsKey(level))
          .map((level) => MapEntry(level, lessonsByLevelMap[level]!))
    );
    // Добавляем "Прочее", если есть и не было добавлено
    if (lessonsByLevelMap.containsKey('Прочее') && !_groupedLessons.containsKey('Прочее')) {
         _groupedLessons['Прочее'] = lessonsByLevelMap['Прочее']!;
    }
  }


  Future<void> _deleteLesson(Lesson lesson) async {
    if (!mounted) return;

    bool confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Удалить урок?"),
        content: Text(
            "Вы уверены, что хотите удалить урок '${lesson.title}' (ID: ${lesson.id}, Коллекция: ${lesson.collectionName})? Это действие необратимо."),
        actions: <Widget>[
          TextButton(
            child: const Text("Отмена"),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Удалить"),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      setState(() => _isLoading = true); // Показываем индикатор на время удаления
      try {
        if (lesson.collectionName == _audioWordBankService.collectionName) {
          await _audioWordBankService.deleteAudioWordBankLesson(lesson.id);
        } else {
          await _lessonsCollection.deleteLessonFromCollection(lesson.collectionName, lesson.id);
        }
        Toast.show("Урок '${lesson.title}' успешно удален.", duration: Toast.lengthLong, gravity: Toast.bottom);
        // Обновляем список уроков для текущего языка
        await _fetchLessonsForLanguage(_selectedLanguage);
      } catch (e) {
        print("Error deleting lesson: $e");
        Toast.show("Ошибка при удалении урока: $e", duration: Toast.lengthLong, gravity: Toast.bottom);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguageSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text("Повторить"),
                                onPressed: () => _fetchLessonsForLanguage(_selectedLanguage),
                            )
                          ],
                        ),
                      )
                    : _groupedLessons.isEmpty
                        ? Center(
                            child: Text(
                              "Для языка '${_getLanguageDisplayName(_selectedLanguage)}' уроков не найдено.",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _buildLessonsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedLanguage,
      decoration: InputDecoration(
        labelText: 'Выберите язык для управления',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _supportedLanguages.map((String languageCode) {
        return DropdownMenuItem<String>(
          value: languageCode,
          child: Text(_getLanguageDisplayName(languageCode)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null && newValue != _selectedLanguage) {
          setState(() {
            _selectedLanguage = newValue;
          });
          _fetchLessonsForLanguage(newValue);
        }
      },
    );
  }

  Widget _buildLessonsList() {
    return ListView.builder(
      itemCount: _groupedLessons.keys.length,
      itemBuilder: (context, index) {
        String level = _groupedLessons.keys.elementAt(index);
        List<Lesson> lessonsInLevel = _groupedLessons[level]!;
        
        Color levelColor = _levelColors[level] ?? Colors.grey;
        IconData levelIcon = _levelIcons[level] ?? Icons.label_important_outline;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            key: PageStorageKey(level), // Для сохранения состояния открытости/закрытости
            initiallyExpanded: level == _levelOrder.first || lessonsInLevel.isNotEmpty, // Раскрываем первый или непустые
            leading: CircleAvatar(
              backgroundColor: levelColor.withOpacity(0.2),
              child: Icon(levelIcon, color: levelColor, size: 24),
            ),
            title: Text(
              level,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: levelColor),
            ),
            subtitle: Text('${lessonsInLevel.length} урок(ов)'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            children: lessonsInLevel.map((lesson) => _buildLessonTile(lesson)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildLessonTile(Lesson lesson) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${lesson.id}"),
            Text("Тип: ${lesson.lessonType}, Коллекция: ${lesson.collectionName}"),
            Text("Индекс: ${lesson.orderIndex}, Язык: ${lesson.targetLanguage}"),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_forever, color: Colors.red.shade700),
          tooltip: 'Удалить урок',
          onPressed: () => _deleteLesson(lesson),
        ),
        // Можно добавить onTap для перехода к редактированию урока, если планируется
        // onTap: () { /* context.go('/admin/edit-lesson/${lesson.id}'); */ },
      ),
    );
  }
}

// Вспомогательные расширения для цвета, если они нужны для _levelColors
// (они уже есть в вашем LearnPage, но если этот файл изолирован)
extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}