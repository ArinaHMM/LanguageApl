// lib/database/collections/audio_word_bank_lessons_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart'; // Ваша общая модель Lesson

class AudioWordBankLessonsService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final String _collectionName = 'audioWordBankLessons'; // Имя новой коллекции

  /// Добавляет новый урок типа "Аудио + Банк Слов" в коллекцию.
  /// lessonId: Предопределенный ID для урока.
  /// lessonData: Map<String, dynamic> с данными урока, соответствующий структуре вашей модели Lesson,
  ///             но главное, чтобы `lessonType` был 'audioWordBankSentence' и `tasks` были корректными.
  Future<void> addAudioWordBankLesson(String lessonId, Map<String, dynamic> lessonData) async {
    try {
      // Убедимся, что ключевые поля для Firestore установлены, если они не пришли в lessonData
      lessonData['lessonType'] = 'audioWordBankSentence'; // Устанавливаем тип урока явно
      lessonData['createdAt'] = lessonData['createdAt'] ?? FieldValue.serverTimestamp();
      lessonData['updatedAt'] = lessonData['updatedAt'] ?? FieldValue.serverTimestamp();
      // Поле 'order' должно быть установлено в lessonData перед вызовом этого метода,
      // если вы используете getNextOrder из AdminAddAudioWordBankLessonPage.

      await _firebaseFirestore.collection(_collectionName).doc(lessonId).set(lessonData);
      print("AudioWordBank Lesson added with ID: $lessonId to collection '$_collectionName'");
    } catch (e) {
      print("Error adding AudioWordBank Lesson to '$_collectionName': $e");
      rethrow; // Перебрасываем ошибку для обработки в UI
    }
  }

  /// Получает следующий порядковый номер для урока в коллекции 'audioWordBankLessons'
  /// для указанного языка и уровня.
  Future<int> getNextOrderForAudioWordBankLesson(String targetLanguage, String requiredLevel) async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection(_collectionName)
          .where('targetLanguage', isEqualTo: targetLanguage)
          .where('requiredLevel', isEqualTo: requiredLevel)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return (querySnapshot.docs.first.data()['order'] as int? ?? 0) + 1;
      }
      return 1; // Первый урок будет иметь order: 1
    } catch (e) {
      print("Error fetching next order for '$_collectionName': $e");
      return 1; // Возвращаем 1 в случае ошибки, чтобы не блокировать создание урока
    }
  }

  // Если вам понадобится получать уроки из этой коллекции отдельно (хотя LearnPage будет использовать общий LessonsCollection)
  // Future<List<Lesson>> getAudioWordBankLessons(String targetLanguage) async {
  //   try {
  //     QuerySnapshot<Map<String, dynamic>> snapshot = await _firebaseFirestore
  //         .collection(_collectionName)
  //         .where('targetLanguage', isEqualTo: targetLanguage)
  //         .orderBy('order', descending: false)
  //         .get();

  //     return snapshot.docs.map((doc) {
  //       try {
  //         // Используем ту же модель Lesson, убедившись, что fromFirestore может парсить tasks
  //         return Lesson.fromFirestore(doc, _collectionName);
  //       } catch (e) {
  //         print('Error parsing AudioWordBank lesson doc ID: ${doc.id} from "$_collectionName". Error: $e');
  //         return null;
  //       }
  //     }).whereType<Lesson>().toList();
  //   } catch (e) {
  //     print("Error fetching AudioWordBank lessons from '$_collectionName': $e");
  //     return [];
  //   }
  // }

  // Метод для удаления урока (если понадобится удалять только из этой коллекции)
  // Future<void> deleteAudioWordBankLesson(String lessonId) async {
  //   try {
  //     await _firebaseFirestore.collection(_collectionName).doc(lessonId).delete();
  //     print("AudioWordBank Lesson deleted with ID: $lessonId from collection '$_collectionName'");
  //   } catch (e) {
  //     print("Error deleting AudioWordBank lesson from '$_collectionName': $e");
  //     rethrow;
  //   }
  // }
}