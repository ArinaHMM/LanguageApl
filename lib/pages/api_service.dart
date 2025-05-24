import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

// Функция для получения вопросов из API
Future<List<Map<String, dynamic>>> fetchQuestionsFromApi() async {
  final response = await http.get(Uri.parse('https://opentdb.com/api.php?amount=10&category=9&difficulty=easy&type=multiple'));

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    List<dynamic> questionsData = jsonResponse['results'];

    return questionsData.map<Map<String, dynamic>>((item) {
      return {
        'question': item['question'],
        'correctAnswer': item['correct_answer'],
        'options': [
          item['correct_answer'], 
          ...item['incorrect_answers']
        ]..shuffle(), // Перемешиваем варианты ответов
      };
    }).toList();
  } else {
    throw Exception('Не удалось загрузить вопросы: ${response.statusCode}');
  }
}

// Функция для сохранения вопросов в Firestore
Future<void> saveQuestionsToFirestore(List<Map<String, dynamic>> questions, String lessonId) async {
  final collection = FirebaseFirestore.instance.collection('lessons');
  
  await collection.doc(lessonId).update({
    'questions': questions,
  });
}

// Функция для загрузки вопросов и их сохранения
Future<void> fetchAndSaveQuestions(String lessonId) async {
  try {
    final questions = await fetchQuestionsFromApi();
    await saveQuestionsToFirestore(questions, lessonId);
    print('Вопросы успешно сохранены в Firestore');
  } catch (e) {
    print('Ошибка: $e');
  }
}

// Функция для получения всех уроков из Firestore
Future<List<Map<String, dynamic>>> fetchLessonsFromFirestore() async {
  final collection = FirebaseFirestore.instance.collection('lessons');
  final snapshot = await collection.get();

  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
}
