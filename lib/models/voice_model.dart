// lib/models/speaking_exercise_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SpeakingExercise {
  final String id;
  final String type;
  final String targetLanguage;
  final String level;
  final String textToSpeak; // Текст, который пользователь должен произнести
  final String? audioUrlExample; // Опционально: URL аудио-примера от носителя
  final String? title;
  final int orderIndex;
  final Timestamp createdAt;
  final bool isPublished;

  SpeakingExercise({
    required this.id,
    this.type = "speaking_pronunciation", // или просто "speaking"
    required this.targetLanguage,
    required this.level,
    required this.textToSpeak,
    this.audioUrlExample,
    this.title,
    required this.orderIndex,
    required this.createdAt,
    this.isPublished = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'targetLanguage': targetLanguage,
      'level': level,
      'textToSpeak': textToSpeak,
      if (audioUrlExample != null && audioUrlExample!.isNotEmpty) 'audioUrlExample': audioUrlExample,
      if (title != null && title!.isNotEmpty) 'title': title,
      'orderIndex': orderIndex,
      'createdAt': createdAt,
      'isPublished': isPublished,
    };
  }

  factory SpeakingExercise.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError("Missing data for SpeakingExercise ${doc.id}");
    return SpeakingExercise(
      id: doc.id,
      type: data['type'] as String? ?? 'speaking_pronunciation',
      targetLanguage: data['targetLanguage'] as String? ?? 'en-US',
      level: data['level'] as String? ?? 'Unknown',
      textToSpeak: data['textToSpeak'] as String? ?? '',
      audioUrlExample: data['audioUrlExample'] as String?,
      title: data['title'] as String?,
      orderIndex: data['orderIndex'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      isPublished: data['isPublished'] as bool? ?? true,
    );
  }
}