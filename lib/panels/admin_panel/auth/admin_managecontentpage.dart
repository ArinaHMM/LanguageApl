// lib/admin_panel/pages/admin_manage_content_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/models/learning_module_model.dart'; // Убедитесь, что путь правильный
import 'package:go_router/go_router.dart'; // Для навигации к редактированию (в будущем)
import 'package:toast/toast.dart';

// Предположим, что AdminRoutes и AdminRouteNames доступны, если понадобятся для навигации
// import '../routing/app_router.dart';

class AdminManageContentPage extends StatefulWidget {
  const AdminManageContentPage({Key? key}) : super(key: key);

  @override
  State<AdminManageContentPage> createState() => _AdminManageContentPageState();
}

class _AdminManageContentPageState extends State<AdminManageContentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedLanguageFilter;
  String? _selectedLevelFilter;

  // Опции для фильтров (аналогично вашей странице просмотра)
  final Map<String, String> _languageOptions = {
    'english': 'Английский',
    'german': 'Немецкий',
    'spanish': 'Испанский',
  };
  final List<String> _levelOptions = [
    'Beginner', 'Elementary', 'Intermediate', 'Upper Intermediate', 'Advanced'
  ];

  @override
  void initState() {
    super.initState();
    ToastContext().init(context); // Для сообщений
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getModulesStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('learning_modules')
        .orderBy('created_at', descending: true); // Сначала новые

    if (_selectedLanguageFilter != null) {
      query = query.where('target_language', isEqualTo: _selectedLanguageFilter);
    }
    if (_selectedLevelFilter != null) {
      query = query.where('level', isEqualTo: _selectedLevelFilter);
    }
    return query.snapshots();
  }

  Future<void> _deleteModule(String moduleId, String moduleTitle) async {
    bool confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Удалить модуль?'),
          content: Text('Вы уверены, что хотите удалить учебный модуль "$moduleTitle"? Это действие необратимо.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      try {
        await _firestore.collection('learning_modules').doc(moduleId).delete();
        Toast.show('Модуль "$moduleTitle" удален.', duration: Toast.lengthShort, gravity: Toast.bottom);
      } catch (e) {
        Toast.show('Ошибка удаления модуля: $e', duration: Toast.lengthLong, gravity: Toast.bottom);
        print('Error deleting module $moduleId: $e');
      }
    }
  }

  void _navigateToEditModule(LearningModule module) {
    // TODO: Реализовать навигацию на страницу редактирования
    // Например: context.go('/admin/content/edit/${module.id}');
    // Пока просто покажем сообщение
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Переход к редактированию модуля: ${module.titleRu} (в разработке)')),
    );
    print("Navigate to edit module ID: ${module.id}");
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Слегка другой фон для фильтров
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLanguageFilter,
              decoration: InputDecoration(
                labelText: 'Язык',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Все языки'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Все языки')),
                ..._languageOptions.entries.map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedLanguageFilter = value),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLevelFilter,
              decoration: InputDecoration(
                labelText: 'Уровень',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Все уровни'),
              items: [
                 const DropdownMenuItem<String>(value: null, child: Text('Все уровни')),
                ..._levelOptions.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedLevelFilter = value),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Поскольку эта страница встраивается в AdminLayout, у нее не должно быть своего Scaffold и AppBar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Управление учебным контентом",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        _buildFilterBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getModulesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Учебные модули по выбранным фильтрам не найдены.'));
              }

              final modules = snapshot.data!.docs
                  .map((doc) => LearningModule.fromFirestore(doc)) // Убедитесь, что модель принимает DocumentSnapshot<Map<String, dynamic>>
                  .toList();

              // Простой ListView для админки
              return ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: modules.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return ListTile(
                    title: Text(module.titleRu, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Язык: ${_languageOptions[module.targetLanguage] ?? module.targetLanguage}, Уровень: ${module.level}'),
                        Text('Опубликован: ${module.isPublished ? "Да" : "Нет"}', style: TextStyle(color: module.isPublished ? Colors.green : Colors.orange)),
                        if (module.createdAt != null)
                          Text('Создан: ${module.createdAt?.toDate().toLocal().toString().substring(0,16) ?? 'N/A'}'),
                           Text('ID: ${module.id}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_note_rounded, color: Theme.of(context).primaryColor),
                          tooltip: 'Редактировать',
                          onPressed: () => _navigateToEditModule(module),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
                          tooltip: 'Удалить',
                          onPressed: () => _deleteModule(module.id, module.titleRu),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToEditModule(module), // Можно и по тапу на весь элемент
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}