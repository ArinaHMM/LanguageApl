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
   final String? correctSentence;
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
    this.correctSentence,
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
      correctSentence: map['correctSentence'] as String?, // <<--- И ПАРСИТСЯ ЗДЕСЬ
      wordBank: (map['wordBank'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      createdAt: map['createdAt'] as Timestamp,
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

 // В твоем файле models/lesson_model.dart

// ... (начало класса Lesson и Exercise остаются как у тебя) ...

factory Lesson.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String fromCollectionName) {
    final data = doc.data();

    if (data == null) {
      print("ERROR: Lesson.fromFirestore - Lesson data is null for doc ID: ${doc.id} in collection $fromCollectionName");
      // Можно выбросить исключение или вернуть "пустой" урок, но лучше сообщить об ошибке.
      // Для простоты пока оставим как у тебя, но это место для улучшения обработки ошибок.
      throw Exception("Lesson data is null for doc ID: ${doc.id}. Cannot create Lesson object.");
    }

    List<Exercise> parsedExercises = [];
    String determinedLessonType = data['lessonType'] as String? ?? 'unknown';
    final String lessonTargetLanguage = data['targetLanguage'] as String? ?? 'english'; 

    print("--- Lesson.fromFirestore: Парсинг урока ID: ${doc.id} из коллекции '$fromCollectionName'. Тип урока из данных: ${data['lessonType']}");

    // --- НАЧАЛО КЛЮЧЕВЫХ ИЗМЕНЕНИЙ ---
    if (fromCollectionName == 'newaudiocollection' || 
        fromCollectionName == 'audiolessons' || // Добавь другие коллекции, где упражнения в 'tasks'
        data['lessonType'] == 'audioWordBankSentence' // Можно и по типу урока, если он уникален для этой структуры
        // Добавь другие условия, если нужно, например, для _audioWordBankService.collectionName
       ) {
      print("--- Lesson.fromFirestore (ID: ${doc.id}): Обнаружена коллекция '$fromCollectionName' или тип '${data['lessonType']}', упражнения ищутся в 'tasks'.");
      if (data['tasks'] != null && data['tasks'] is List) {
        if ((data['tasks'] as List).isNotEmpty) {
            parsedExercises = (data['tasks'] as List).map((taskData) {
            if (taskData is Map) {
                final taskMap = Map<String, dynamic>.from(taskData);
                try {
                // Эта логика маппинга полей должна быть адаптирована под структуру 'tasks'
                // в 'newaudiocollection', как на твоем скриншоте.
                // Убедись, что Exercise.fromMap может принять эти поля.
                // Важно, чтобы Exercise.fromMap правильно парсила 'wordBank', 'correctSentence' и т.д.
                // из taskMap.
                Map<String, dynamic> exerciseMapForParsing = {
                    'exerciseId': taskMap['id']?.toString() ?? Uuid().v4(), // ID из таска или новый
                    'type': taskMap['type']?.toString() ?? 'audioWordBankSentence', // Тип из таска
                    'promptData': { // Пример для promptText
                        // Если promptText это Map: Map<String, dynamic>.from(taskMap['promptText'])
                        // Если promptText это String:
                        lessonTargetLanguage: taskMap['promptText']?.toString() ?? '',
                        'russian': taskMap['promptText']?.toString() ?? '' // Для примера
                    },
                    'questionText': taskMap['promptText']?.toString(), // Если promptText используется как вопрос
                    'audioUrl': taskMap['audioUrl'] as String?,
                    'correctSentence': taskMap['correctSentence'] as String?, // <<--- ВАЖНО ДЛЯ AUDIOWORDBANK
                    'wordBank': (taskMap['wordBank'] as List<dynamic>?)?.map((e) => e.toString()).toList(), // <<--- ВАЖНО
                    'feedbackCorrect': { // Пример, если feedback у тебя Map
                        lessonTargetLanguage: taskMap['feedbackCorrect']?.toString(),
                        'russian': taskMap['feedbackCorrect']?.toString(),
                    },
                    'feedbackIncorrect': {
                        lessonTargetLanguage: taskMap['feedbackIncorrect']?.toString(),
                        'russian': taskMap['feedbackIncorrect']?.toString(),
                    },
                    'createdAt': data['createdAt'] as Timestamp? ?? Timestamp.now(), // createdAt урока
                    // Добавь другие поля из 'tasks', которые нужны для Exercise
                };
                return Exercise.fromMap(exerciseMapForParsing);
                } catch (e, s) {
                print("ERROR: Lesson.fromFirestore ('tasks' for $fromCollectionName) - Failed to parse. Error: $e. Stack: $s. Data: $taskMap");
                return null;
                }
            }
            return null;
            }).whereType<Exercise>().toList();
            print("--- Lesson.fromFirestore (ID: ${doc.id}, from 'tasks'): Успешно загружено ${parsedExercises.length} упражнений.");
        } else {
             print("--- Lesson.fromFirestore (ID: ${doc.id}): Поле 'tasks' для коллекции '$fromCollectionName' найдено, но список пуст.");
        }
      } else {
        print("--- Lesson.fromFirestore (ID: ${doc.id}): ВНИМАНИЕ! Для коллекции '$fromCollectionName' поле 'tasks' отсутствует или не является списком.");
      }
    } 
    // Иначе, если это 'interactiveLessons' и есть 'tasks' (твоя существующая логика)
    else if (fromCollectionName == 'interactiveLessons' && data['tasks'] != null && data['tasks'] is List) {
      print("--- Lesson.fromFirestore (ID: ${doc.id}): Обнаружена коллекция 'interactiveLessons' с полем 'tasks'. Используется специфичный парсинг.");
      determinedLessonType = data['lessonType'] as String? ?? 'chooseTranslation'; 
      parsedExercises = (data['tasks'] as List).map((taskData) {
        // ... твоя существующая логика парсинга 'tasks' для 'interactiveLessons' ...
        // Убедись, что она корректна и возвращает Exercise или null
        if (taskData is Map) {
          final taskMap = Map<String, dynamic>.from(taskData);
          try {
            // ... (твоя логика создания exerciseMapForParsing для interactiveLessons)
            List<Map<String, dynamic>> exerciseOptionsForTargetLang = [];
            String? correctAnswerTextForTargetLang;

            if (taskMap['options'] is List) {
              for (var optionAdminData in (taskMap['options'] as List)) {
                if (optionAdminData is Map) {
                  final optionAdminMap = Map<String, dynamic>.from(optionAdminData);
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
                'russian': taskMap['promptText']?.toString() ?? '' 
              },
              'questionText': taskMap['promptText']?.toString(),
              'imageUrl': taskMap['imagePromptUrl'] as String?,
              'optionsData': { 
                 lessonTargetLanguage: exerciseOptionsForTargetLang,
              },
              'correctAnswerData': { 
                 lessonTargetLanguage: correctAnswerTextForTargetLang,
              },
              'createdAt': data['createdAt'] as Timestamp? ?? Timestamp.now(), 
            };
            return Exercise.fromMap(exerciseMapForParsing);
          } catch (e, s) {
            print("ERROR: Lesson.fromFirestore ('tasks' for interactiveLessons) - Failed to parse. Error: $e. Stack: $s. Data: $taskMap");
            return null;
          }
        }
        return null;
      }).whereType<Exercise>().toList();
      print("--- Lesson.fromFirestore (ID: ${doc.id}, from 'tasks' in interactiveLessons): Успешно загружено ${parsedExercises.length} упражнений.");
    } 
    // Иначе, пробуем стандартное поле 'exercises' (твоя существующая логика)
    else if (data['exercises'] != null && data['exercises'] is List) {
      print("--- Lesson.fromFirestore (ID: ${doc.id}): Упражнения ищутся в стандартном поле 'exercises'.");
      if ((data['exercises'] as List).isNotEmpty) {
        parsedExercises = (data['exercises'] as List).map((exMap) {
            if (exMap is Map) {
            try {
                return Exercise.fromMap(Map<String, dynamic>.from(exMap));
            } catch (e, s) {
                print("ERROR: Lesson.fromFirestore (standard 'exercises') - Failed to parse. Error: $e. Stack: $s. Data: $exMap");
                return null;
            }
            }
            return null;
        }).whereType<Exercise>().toList();
        print("--- Lesson.fromFirestore (ID: ${doc.id}, from 'exercises'): Успешно загружено ${parsedExercises.length} упражнений.");
      } else {
        print("--- Lesson.fromFirestore (ID: ${doc.id}): Поле 'exercises' найдено, но список пуст.");
      }
    } else {
        print("--- Lesson.fromFirestore (ID: ${doc.id}): ВНИМАНИЕ! Упражнения не найдены ни в 'tasks' (для специфичных коллекций), ни в 'exercises'. Список упражнений будет пуст.");
    }
    // --- КОНЕЦ КЛЮЧЕВЫХ ИЗМЕНЕНИЙ ---


    // Определение типа урока, если он не был явно указан и не определен выше
    if (determinedLessonType == 'unknown' && parsedExercises.isNotEmpty) {
      // Можно попытаться определить тип урока по типу первого упражнения, если это имеет смысл
      determinedLessonType = parsedExercises.first.type; 
      print("--- Lesson.fromFirestore (ID: ${doc.id}): Тип урока определен по первому упражнению как '$determinedLessonType'.");
    } else if (determinedLessonType == 'unknown') {
        // Общая логика определения типа, если упражнений нет или тип не ясен
        if (fromCollectionName.toLowerCase().contains('audio')) {
            determinedLessonType = 'audiolesson'; // Более общий тип для аудио
        } else if (fromCollectionName.toLowerCase().contains('video')) {
            determinedLessonType = 'videolesson';
        } else if (fromCollectionName.toLowerCase().contains('interactive')) {
            determinedLessonType = 'interactive'; // Общий интерактивный
        } else {
            determinedLessonType = 'standard'; // Совсем по умолчанию
        }
        print("--- Lesson.fromFirestore (ID: ${doc.id}): Тип урока '$determinedLessonType' определен по имени коллекции или по умолчанию.");
    }


    return Lesson(
      id: doc.id,
      title: data['title'] as String? ?? data['lessonName'] as String? ?? 'Без названия',
      targetLanguage: lessonTargetLanguage,
      requiredLevel: data['requiredLevel'] as String? ?? data['level'] as String? ?? 'Beginner',
      lessonContentPreview: data['description'] as String? ?? data['lessonContentPreview'] as String? ?? '',
      collectionName: fromCollectionName,
      lessonType: determinedLessonType, // Используем определенный тип урока
      exercises: parsedExercises,
      iconUrl: data['iconUrl'] as String?,
      orderIndex: (data['order'] as int?) ?? (data['orderIndex'] as int? ?? 0),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

// ... (остальной код модели Exercise, если он ниже) ...