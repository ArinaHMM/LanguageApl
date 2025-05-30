import 'package:cloud_firestore/cloud_firestore.dart';
// Убедитесь, что модель Lesson импортирована правильно
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart'; 

class AudioWordBankLessonsService {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  // Имя вашей целевой коллекции для уроков "Аудио + Банк Слов"
  final String _collectionName = 'newaudiocollection'; // ИЛИ 'audioWordBankLessons', если вы так назвали

  // --- ДОБАВЛЕН ПУБЛИЧНЫЙ ГЕТТЕР ---
  String get collectionName => _collectionName;
  
  // --- КОНЕЦ ДОБАВЛЕНИЯ ---

  /// Добавляет новый урок типа "Аудио + Банк Слов" в Firestore.
  Future<void> addAudioWordBankLesson(String lessonId, Map<String, dynamic> lessonData) async {
    try {
      lessonData['lessonType'] = lessonData['lessonType'] ?? 'audioWordBankSentence';
      lessonData['createdAt'] = lessonData['createdAt'] ?? FieldValue.serverTimestamp();
      lessonData['updatedAt'] = lessonData['updatedAt'] ?? FieldValue.serverTimestamp();

      await _firebaseFirestore.collection(_collectionName).doc(lessonId).set(lessonData);
      print("Lesson added with ID: $lessonId to collection '$_collectionName'");
    } catch (e) {
      print("Error adding lesson to '$_collectionName': $e");
      rethrow; 
    }
  }

  /// Получает следующий порядковый номер (order) для нового урока
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
        final data = querySnapshot.docs.first.data();
        final currentOrder = data['order']; 
        if (currentOrder is int) {
          return currentOrder + 1;
        } else if (currentOrder is double) { 
          return currentOrder.toInt() + 1;
        }
        print("Warning: 'order' field in '$_collectionName' is not an int or is missing for doc ${querySnapshot.docs.first.id}. Defaulting to 1 for next.");
        return 1; 
      }
      return 1; 
    } catch (e) {
      print("Error fetching next order for '$_collectionName': $e");
      return 1; 
    }
  }

  /// Получает список уроков типа Lesson из коллекции
  Future<List<Lesson>> getAudioWordBankLessons(String targetLanguage) async {
    try {
      print('Fetching lessons from Firestore collection: "$_collectionName" for language: "$targetLanguage"');
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firebaseFirestore
          .collection(_collectionName) 
          .where('targetLanguage', isEqualTo: targetLanguage)
          .orderBy('order', descending: false) 
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('No lessons found in "$_collectionName" for language "$targetLanguage".');
      } else {
        print('Found ${snapshot.docs.length} lessons in "$_collectionName" for language "$targetLanguage".');
      }

      return snapshot.docs.map((doc) {
        try {
          return Lesson.fromFirestore(doc, _collectionName); 
        } catch (e, s) {
          print('Error parsing lesson doc ID: ${doc.id} from "$_collectionName". Error: $e');
          print('Stacktrace: $s');
          print('Problematic lesson data: ${doc.data()}');
          return null; 
        }
      }).whereType<Lesson>().toList();
    } catch (e, s) {
      print("Error fetching lessons from '$_collectionName' (language: $targetLanguage): $e");
      print("Stacktrace: $s");
      return []; 
    }
  }
  
  /// Удаляет урок из коллекции по ID.
  Future<void> deleteAudioWordBankLesson(String lessonId) async {
      try {
          await _firebaseFirestore.collection(_collectionName).doc(lessonId).delete();
          print("Lesson deleted with ID: $lessonId from collection '$_collectionName'");
      } catch (e) {
          print("Error deleting lesson from '$_collectionName' with ID $lessonId: $e");
          rethrow; 
      }
  }
}