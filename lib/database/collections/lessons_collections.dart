import 'package:cloud_firestore/cloud_firestore.dart';
// Убедитесь, что НОВАЯ модель Lesson импортирована из папки /models/
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart'; 
// import 'package:flutter_languageapplicationmycourse_2/pages/audio_get.dart'; // Раскомментируйте, если fetchAudio используется

class LessonsCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // --- СТАРЫЕ МЕТОДЫ (РАССМОТРИТЕ УДАЛЕНИЕ ИЛИ АДАПТАЦИЮ, ЕСЛИ НЕ НУЖНЫ) ---

  // Этот метод возвращает "сырые" данные из коллекции 'lessons'.
  // Если коллекция 'lessons' больше не используется или ее структура изменилась,
  // этот метод может быть не нужен.
  Future<List<Map<String, dynamic>>> getRawLessonsFromDefaultCollection() async {
    try {
      QuerySnapshot snapshot = await _firebaseFirestore.collection('lessons').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
    } catch (e) {
      print("Error in LessonsCollection.getRawLessonsFromDefaultCollection: $e");
      return [];
    }
  }

  // Этот метод создает урок в коллекции 'lessons'.
  // Если вы переходите на создание уроков только через админку (которая пишет в interactiveLessons и др.),
  // или если структура урока изменилась (например, 'text' и 'audioUrl' теперь часть 'exercises'),
  // этот метод нужно адаптировать или удалить.
  Future<void> createLessonInDefaultCollection(
      String title, 
      String text, // Это содержимое урока или вопрос для упражнения?
      String targetLanguage, 
      String requiredLevel,
      // String? audioUrlFromFetch, // Если fetchAudio используется
      ) async {
    // String audioUrl = audioUrlFromFetch ?? ''; // Если используется fetchAudio
    try {
      // Определите, какой lessonType должен быть у уроков, создаваемых этим методом
      String lessonTypeForDefault = 'standard'; // Например

      // Если 'text' и 'audioUrl' - это просто поля урока, а не упражнения:
      await _firebaseFirestore.collection('lessons').add({
        'title': title,
        // 'textContent': text, // Возможно, лучше назвать поле так
        // 'audioUrl': audioUrl, 
        'targetLanguage': targetLanguage,
        'requiredLevel': requiredLevel,
        'lessonType': lessonTypeForDefault, // Укажите тип урока
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'order': 0, // Или другая логика для order
        'exercises': [], // Пустой список упражнений, если это простой урок
      });
    } catch (e) {
      print("Error in LessonsCollection.createLessonInDefaultCollection: $e");
      rethrow;
    }
  }


  // --- МЕТОДЫ, НУЖНЫЕ ДЛЯ НОВОЙ LearnPage (использующие LessonModel) ---

  /// Обобщенная функция для получения уроков из указанной коллекции
  /// по имени этой коллекции и целевому языку.
  Future<List<Lesson>> getLessons(String collectionName, String targetLanguage) async {
    try {
      print('Fetching lessons from Firestore collection: "$collectionName" for language: "$targetLanguage"');
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firebaseFirestore
          .collection(collectionName)
          .where('targetLanguage', isEqualTo: targetLanguage)
          // Раскомментируйте и адаптируйте orderBy, если у вас есть поле для сортировки (например, 'order' или 'orderIndex')
          // Убедитесь, что для этого запроса существует или будет создан соответствующий составной индекс в Firestore,
          // если вы используете orderBy с where.
          // .orderBy('order', descending: false) // или 'orderIndex'
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('No lessons found in "$collectionName" for language "$targetLanguage".');
      } else {
        print('Found ${snapshot.docs.length} lessons in "$collectionName" for language "$targetLanguage".');
      }

      return snapshot.docs
          .map((doc) {
            try {
              // Передаем имя коллекции в fromFirestore, чтобы модель знала, откуда она пришла
              return Lesson.fromFirestore(doc, collectionName);
            } catch (e, s) {
              print('Error parsing lesson doc ID: ${doc.id} from collection "$collectionName". Error: $e');
              print('Stacktrace: $s');
              print('Problematic lesson data: ${doc.data()}');
              return null; 
            }
          })
          .whereType<Lesson>() // Отфильтровываем null (неудачно распарсенные)
          .toList();
          
    } catch (e, s) {
      print("Error in LessonsCollection.getLessons (for collection: $collectionName, language: $targetLanguage): $e");
      print("Stacktrace: $s");
      // В случае ошибки возвращаем пустой список, чтобы UI не падал.
      // В LearnPage можно будет обработать пустой список и показать сообщение.
      return []; 
    }
  }
  
  /// Метод для удаления урока из указанной коллекции по ID урока.
  Future<void> deleteLessonFromCollection(String collectionName, String lessonId) async {
      try {
          await _firebaseFirestore.collection(collectionName).doc(lessonId).delete();
          print('Lesson deleted from "$collectionName", ID: "$lessonId"');
      } catch (e) {
          print("Error in LessonsCollection.deleteLessonFromCollection for $collectionName, ID $lessonId: $e");
          rethrow; // Перебрасываем ошибку, чтобы ее можно было обработать в UI (например, показать SnackBar)
      }
  }
}