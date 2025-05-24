import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/audio_get.dart';

class LessonsCollection {
  final CollectionReference _lessonsRef = FirebaseFirestore.instance.collection('lessons');

  Future<List<Map<String, dynamic>>> getLessons() async {
    QuerySnapshot snapshot = await _lessonsRef.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }
}
Future<void> createLesson(String title, String text) async {
  String audioUrl = await fetchAudio(text); // Получение аудио
  await FirebaseFirestore.instance.collection('lessons').add({
    'title': title,
    'text': text,
    'audioUrl': audioUrl,
  });
}
