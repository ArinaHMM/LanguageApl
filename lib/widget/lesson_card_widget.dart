// lib/widgets/lesson_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart'; // Убедитесь, что импорт модели Lesson правильный

class LessonCardWidget extends StatelessWidget {
  final Lesson lesson;
  final int progress; // от 0 до 100
  final bool isAccessible;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback onDelete;

  const LessonCardWidget({
    Key? key,
    required this.lesson,
    required this.progress,
    required this.isAccessible,
    required this.onTap,
    required this.isAdmin,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAccessible ? 1.0 : 0.6, // Менее прозрачный для лучшей читаемости
      child: Card(
        elevation: isAccessible ? 3.0 : 1.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias, // Для эффекта при InkWell
        child: InkWell(
          onTap: isAccessible ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Чтобы элементы распределились
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 15, // Чуть меньше для компактности
                          fontWeight: FontWeight.bold,
                          color: isAccessible ? Colors.black87 : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isAccessible)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.lock_outline_rounded, size: 20, color: Colors.grey[500]),
                      ),
                  ],
                ),
                if (lesson.lessonContentPreview.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      lesson.lessonContentPreview,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(), // Занимает доступное пространство, прижимая прогресс-бар вниз
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAccessible) // Показываем прогресс только для доступных
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          "$progress%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: progress == 100 ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                      ),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAccessible
                            ? (progress == 100 ? Colors.green : Colors.blueAccent)
                            : Colors.grey[400]!,
                      ),
                      minHeight: 7, // Чуть толще
                      borderRadius: BorderRadius.circular(4), // Скругление
                    ),
                  ],
                ),
                if (isAdmin)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: Icon(Icons.delete_forever_rounded, color: Colors.red[400], size: 22),
                      padding: EdgeInsets.all(4), // Меньше отступы
                      constraints: BoxConstraints(),
                      tooltip: "Удалить урок",
                      onPressed: onDelete,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}