// lib/models/lesson_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Добавлен импорт для Uuid, если используется в парсинге

// Модель Exercise остается такой же, как вы предоставили, если она вас устраивает
class Exercise {
  final String exerciseId;
  final String type;
  final Map<String, dynamic>? promptData;
  final String? questionText;
  final String? imageUrl;
  final String? gifUrl;
  final String? audioUrl;
  final Map<String, dynamic>? optionsData; // Ожидаемая структура: {'languageCode': List<Map<String, dynamic>>}
                                          // где List<Map<String, dynamic>> это [{'text': '...', 'isCorrect': true, 'feedback': '...'}, ...]
  final Map<String, dynamic>? correctAnswerData; // Ожидаемая структура: {'languageCode': 'текст правильного ответа'}
  final Timestamp createdAt;
  final List<String>? wordBank;
  final Map<String, String>? feedbackCorrect;
  final Map<String, String>? feedbackIncorrect;
  final Map<String, String>? matchPairs;

  Exercise({
    required this.exerciseId,
    required this.type,
    this.promptData,
    this.questionText,
    this.imageUrl,
    this.gifUrl,
    this.audioUrl,
    this.optionsData,
    this.correctAnswerData,
    required this.createdAt,
    this.wordBank,
    this.feedbackCorrect,
    this.feedbackIncorrect,
    this.matchPairs,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    if (map['exerciseId'] == null || map['type'] == null || map['createdAt'] == null) {
      print("ERROR: Exercise.fromMap - Missing critical fields. Data: $map");
      throw FormatException("Exercise data is missing critical fields.");
    }
    return Exercise(
      exerciseId: map['exerciseId'] as String,
      type: map['type'] as String,
      promptData: map['promptData'] != null ? Map<String, dynamic>.from(map['promptData'] as Map) : null,
      questionText: map['questionText'] as String?,
      imageUrl: map['imageUrl'] as String?,
      gifUrl: map['gifUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      optionsData: map['optionsData'] != null ? Map<String, dynamic>.from(map['optionsData'] as Map) : null,
      correctAnswerData: map['correctAnswerData'] != null ? Map<String, dynamic>.from(map['correctAnswerData'] as Map) : null,
      createdAt: map['createdAt'] as Timestamp,
      wordBank: (map['wordBank'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      feedbackCorrect: (map['feedbackCorrect'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key.toString(), value.toString())),
      feedbackIncorrect: (map['feedbackIncorrect'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key.toString(), value.toString())),
      matchPairs: (map['matchPairs'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key.toString(), value.toString())),
    );
  }

  // Ваши getLocalized... методы
  String getLocalizedPrompt(String interfaceLanguageCode, {String defaultPrompt = "Выполните задание:"}) {
    if (promptData == null) return defaultPrompt;
    return promptData![interfaceLanguageCode]?.toString() ?? 
           promptData!['russian']?.toString() ?? 
           promptData!.values.firstWhere((element) => element is String, orElse: () => defaultPrompt)?.toString() ??
           defaultPrompt;
  }

  // Этот метод теперь должен возвращать List<Map<String, dynamic>> для опций, если вы хотите иметь isCorrect и feedback
  // Либо LessonPlayerPage должен будет работать с optionsData напрямую
  List<Map<String, dynamic>> getLocalizedOptionsList(String interfaceLanguageCode) {
    if (optionsData == null) return [];
    dynamic langSpecificOptionsRaw = optionsData![interfaceLanguageCode] ?? optionsData!['russian'];
    
    if (langSpecificOptionsRaw is List) {
      return langSpecificOptionsRaw
          .whereType<Map>() // Убедимся, что это Map
          .map((e) => Map<String, dynamic>.from(e)) // Преобразуем в Map<String, dynamic>
          .toList();
    }
    return [];
  }
  
  // Старый метод, если опции это просто строки (возможно, устарел для интерактивных)
  List<String> getLocalizedOptionTexts(String interfaceLanguageCode) {
    if (optionsData == null) return [];
    dynamic langSpecificOptions = optionsData![interfaceLanguageCode] ?? optionsData!['russian']; 
    
    if (langSpecificOptions is List) {
      // Если это список карт (новая структура)
      if (langSpecificOptions.isNotEmpty && langSpecificOptions.first is Map) {
        return langSpecificOptions
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)['text']?.toString() ?? '')
            .toList();
      }
      // Если это список строк (старая структура)
      return langSpecificOptions.map((e) => e.toString()).toList();
    }
    return [];
  }


  String? getLocalizedCorrectAnswer(String interfaceLanguageCode) {
    if (correctAnswerData == null) return null;
    return correctAnswerData![interfaceLanguageCode]?.toString() ?? 
           correctAnswerData!['russian']?.toString();
  }

  String getLocalizedFeedbackCorrect(String interfaceLanguageCode, {String defaultFeedback = "Отлично!"}) {
    if (feedbackCorrect == null) return defaultFeedback;
    return feedbackCorrect![interfaceLanguageCode] ?? 
           feedbackCorrect!['russian'] ?? 
           defaultFeedback;
  }

  String getLocalizedFeedbackIncorrect(String interfaceLanguageCode, {String? actualCorrectAnswer, String defaultFeedback = "Попробуйте еще раз."}) {
    String feedbackMessage = feedbackIncorrect?[interfaceLanguageCode] ?? 
                             feedbackIncorrect?['russian'] ?? 
                             defaultFeedback;

    if (actualCorrectAnswer != null && actualCorrectAnswer.isNotEmpty) {
      if (feedbackMessage.contains('{correctAnswer}')) {
        feedbackMessage = feedbackMessage.replaceAll('{correctAnswer}', actualCorrectAnswer);
      } else if (feedbackMessage == defaultFeedback || feedbackMessage == (feedbackIncorrect?['russian'] ?? defaultFeedback) ) { 
        feedbackMessage = "Неверно. Правильный ответ: $actualCorrectAnswer";
      }
    }
    return feedbackMessage;
  }
}

class Lesson {
  final String id;
  final String title;
  final String targetLanguage;
  final String requiredLevel;
  final String lessonContentPreview;
  final String collectionName;
  final String lessonType;
  final List<Exercise> exercises;
  final String? iconUrl;
  final int orderIndex;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Lesson({
    required this.id,
    required this.title,
    required this.targetLanguage,
    required this.requiredLevel,
    this.lessonContentPreview = '',
    required this.collectionName,
    required this.lessonType,
    this.exercises = const [],
    this.iconUrl,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String fromCollectionName) {
    final data = doc.data();

    if (data == null) {
      print("ERROR: Lesson.fromFirestore - Lesson data is null for doc ID: ${doc.id} in collection $fromCollectionName");
      throw Exception("Lesson data is null for doc ID: ${doc.id}. Cannot create Lesson object.");
    }

    List<Exercise> parsedExercises = [];
    String determinedLessonType = data['lessonType'] as String? ?? 'unknown';
    final String lessonTargetLanguage = data['targetLanguage'] as String? ?? 'english'; // Язык урока

    if (data['exercises'] != null && data['exercises'] is List) {
      // Парсинг для стандартной структуры 'exercises'
      parsedExercises = (data['exercises'] as List).map((exMap) {
        if (exMap is Map) {
          try {
            return Exercise.fromMap(Map<String, dynamic>.from(exMap));
          } catch (e, s) {
            print("ERROR: Lesson.fromFirestore (exercises) - Failed to parse. Error: $e. Stack: $s. Data: $exMap");
            return null;
          }
        }
        return null;
      }).whereType<Exercise>().toList();
    } else if (fromCollectionName == 'interactiveLessons' && data['tasks'] != null && data['tasks'] is List) {
      // Парсинг для 'tasks' из 'interactiveLessons'
      determinedLessonType = data['lessonType'] as String? ?? 'chooseTranslation'; 

      parsedExercises = (data['tasks'] as List).map((taskData) {
        if (taskData is Map) {
          final taskMap = Map<String, dynamic>.from(taskData);
          try {
            List<Map<String, dynamic>> exerciseOptionsForTargetLang = [];
            String? correctAnswerTextForTargetLang;

            if (taskMap['options'] is List) {
              for (var optionAdminData in (taskMap['options'] as List)) {
                if (optionAdminData is Map) {
                  final optionAdminMap = Map<String, dynamic>.from(optionAdminData);
                  // Сохраняем полную структуру опции
                  exerciseOptionsForTargetLang.add({
                    'text': optionAdminMap['text']?.toString() ?? '',
                    'isCorrect': optionAdminMap['isCorrect'] ?? false,
                    'feedback': optionAdminMap['feedback']?.toString() ?? '',
                  });
                  if (optionAdminMap['isCorrect'] == true) {
                    correctAnswerTextForTargetLang = optionAdminMap['text']?.toString();
                  }
                }
              }
            }
            
            Map<String, dynamic> exerciseMapForParsing = {
              'exerciseId': taskMap['id']?.toString() ?? Uuid().v4(),
              'type': taskMap['type']?.toString() ?? determinedLessonType,
              'promptData': {
                lessonTargetLanguage: taskMap['promptText']?.toString() ?? '',
                'russian': taskMap['promptText']?.toString() ?? '' // Если нужно, добавьте русскую версию
              },
              'questionText': taskMap['promptText']?.toString(),
              'imageUrl': taskMap['imagePromptUrl'] as String?,
              'optionsData': { // Сохраняем структурированные опции
                 lessonTargetLanguage: exerciseOptionsForTargetLang,
              },
              'correctAnswerData': { // Сохраняем текст правильного ответа
                 lessonTargetLanguage: correctAnswerTextForTargetLang,
              },
              'createdAt': data['createdAt'] as Timestamp? ?? Timestamp.now(), // createdAt урока, не таска
            };
            return Exercise.fromMap(exerciseMapForParsing);
          } catch (e, s) {
            print("ERROR: Lesson.fromFirestore (tasks) - Failed to parse. Error: $e. Stack: $s. Data: $taskMap");
            return null;
          }
        }
        return null;
      }).whereType<Exercise>().toList();
    }

    if (determinedLessonType == 'unknown') {
      if (fromCollectionName.toLowerCase().contains('audio')) {
        determinedLessonType = 'audiolesson';
      } else if (fromCollectionName.toLowerCase().contains('video')) {
        determinedLessonType = 'videolesson';
      } else if (fromCollectionName.toLowerCase().contains('addlessons') ||
                 fromCollectionName.toLowerCase().contains('upperlessons') ||
                 fromCollectionName.toLowerCase().contains('advancedlessons')) {
        determinedLessonType = 'standard';
      }
    }

    return Lesson(
      id: doc.id,
      title: data['title'] as String? ?? data['lessonName'] as String? ?? 'Без названия',
      targetLanguage: lessonTargetLanguage,
      requiredLevel: data['requiredLevel'] as String? ?? data['level'] as String? ?? 'Beginner',
      lessonContentPreview: data['description'] as String? ?? data['lessonContentPreview'] as String? ?? '',
      collectionName: fromCollectionName,
      lessonType: determinedLessonType,
      exercises: parsedExercises,
      iconUrl: data['iconUrl'] as String?,
      orderIndex: (data['order'] as int?) ?? (data['orderIndex'] as int? ?? 0),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}