
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';

class AudioWordBankLessonsService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final String _collectionName = 'newaudiocollection'; // Имя новой коллекции

  Future<void> addAudioWordBankLesson(String lessonId, Map<String, dynamic> lessonData) async {
    try {
      lessonData['lessonType'] = 'audioWordBankSentence'; // Устанавливаем тип урока явно
      lessonData['createdAt'] = lessonData['createdAt'] ?? FieldValue.serverTimestamp();
      lessonData['updatedAt'] = lessonData['updatedAt'] ?? FieldValue.serverTimestamp();

      await _firebaseFirestore.collection(_collectionName).doc(lessonId).set(lessonData);
      print("AudioWordBank Lesson added with ID: $lessonId to collection '$_collectionName'");
    } catch (e) {
      print("Error adding AudioWordBank Lesson to '$_collectionName': $e");
      rethrow; // Перебрасываем ошибку для обработки в UI
    }
  }

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

  Future<List<Lesson>> getAudioWordBankLessons(String targetLanguage) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firebaseFirestore
          .collection(_collectionName)
          .where('targetLanguage', isEqualTo: targetLanguage)
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        try {
          // Используем ту же модель Lesson, убедившись, что fromFirestore может парсить tasks
          return Lesson.fromFirestore(doc, _collectionName);
        } catch (e) {
          print('Error parsing AudioWordBank lesson doc ID: ${doc.id} from "$_collectionName". Error: $e');
          return null;
        }
      }).whereType<Lesson>().toList();
    } catch (e) {
      print("Error fetching AudioWordBank lessons from '$_collectionName': $e");
      return [];
    }
  }

  Future<void> deleteAudioWordBankLesson(String lessonId) async {
    try {
      await _firebaseFirestore.collection(_collectionName).doc(lessonId).delete();
      print("AudioWordBank Lesson deleted with ID: $lessonId from collection '$_collectionName'");
    } catch (e) {
      print("Error deleting AudioWordBank lesson from '$_collectionName': $e");
      rethrow;
    }
  }
}