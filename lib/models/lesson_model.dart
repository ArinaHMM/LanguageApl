// lib/models/lesson_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// --- Класс Exercise (оставляем как у вас) ---
class Exercise {
  final String exerciseId;
  final String type;
  final Map<String, dynamic>? promptData;
  final String? questionText;
  final String? imageUrl;
  final String? gifUrl;
  final String? correctSentence;
  final String? audioUrl;
  final Map<String, dynamic>? optionsData;
  final Map<String, dynamic>? correctAnswerData;
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
      throw FormatException("Exercise data is missing critical fields for exerciseId: ${map['exerciseId']}");
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
      correctSentence: map['correctSentence'] as String?,
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

  String getLocalizedPrompt(String interfaceLanguageCode, {String defaultPrompt = "Выполните задание:"}) {
    // ... (ваша реализация)
    if (promptData == null) return defaultPrompt;
    return promptData![interfaceLanguageCode]?.toString() ?? 
           promptData!['russian']?.toString() ?? 
           promptData!.values.firstWhere((element) => element is String, orElse: () => defaultPrompt)?.toString() ??
           defaultPrompt;
  }

  List<Map<String, dynamic>> getLocalizedOptionsList(String interfaceLanguageCode) {
    // ... (ваша реализация)
    if (optionsData == null) return [];
    dynamic langSpecificOptionsRaw = optionsData![interfaceLanguageCode] ?? optionsData!['russian'];
    
    if (langSpecificOptionsRaw is List) {
      return langSpecificOptionsRaw
          .whereType<Map>() 
          .map((e) => Map<String, dynamic>.from(e)) 
          .toList();
    }
    return [];
  }
  
  List<String> getLocalizedOptionTexts(String interfaceLanguageCode) {
    // ... (ваша реализация)
     if (optionsData == null) return [];
    dynamic langSpecificOptions = optionsData![interfaceLanguageCode] ?? optionsData!['russian']; 
    
    if (langSpecificOptions is List) {
      if (langSpecificOptions.isNotEmpty && langSpecificOptions.first is Map) {
        return langSpecificOptions
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)['text']?.toString() ?? '')
            .toList();
      }
      return langSpecificOptions.map((e) => e.toString()).toList();
    }
    return [];
  }

  String? getLocalizedCorrectAnswer(String interfaceLanguageCode) {
    // ... (ваша реализация)
    if (correctAnswerData == null) return null;
    return correctAnswerData![interfaceLanguageCode]?.toString() ?? 
           correctAnswerData!['russian']?.toString();
  }

  String getLocalizedFeedbackCorrect(String interfaceLanguageCode, {String defaultFeedback = "Отлично!"}) {
    // ... (ваша реализация)
    if (feedbackCorrect == null) return defaultFeedback;
    return feedbackCorrect![interfaceLanguageCode] ?? 
           feedbackCorrect!['russian'] ?? 
           defaultFeedback;
  }

  String getLocalizedFeedbackIncorrect(String interfaceLanguageCode, {String? actualCorrectAnswer, String defaultFeedback = "Неверно. Попробуйте еще раз."}) {
    String feedbackMessage;

    // 1. Сначала проверяем, существует ли вообще Map с фидбеком
    if (feedbackIncorrect != null) {
      // 2. Если существует, пытаемся получить локализованную версию или русскую по умолчанию
      feedbackMessage = feedbackIncorrect![interfaceLanguageCode] ?? 
                        feedbackIncorrect!['russian'] ?? 
                        defaultFeedback;
    } else {
      // 3. Если Map'а нет, сразу используем значение по умолчанию
      feedbackMessage = defaultFeedback;
    }

    // 4. Логика подстановки правильного ответа (остается без изменений, но теперь она безопасна)
    if (actualCorrectAnswer != null && actualCorrectAnswer.isNotEmpty) {
      // Если в сообщении есть плейсхолдер {correctAnswer}, заменяем его
      if (feedbackMessage.contains('{correctAnswer}')) {
        return feedbackMessage.replaceAll('{correctAnswer}', actualCorrectAnswer);
      } 
      // Иначе, если мы используем дефолтное сообщение, лучше показать правильный ответ явно
      else {
        return "Неверно. Правильный ответ: $actualCorrectAnswer";
      }
    }
    
    // Возвращаем сообщение, если нет правильного ответа для подстановки
    return feedbackMessage;
  }
}
// --- Конец класса Exercise ---

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

  // Поля для уроков типа "speaking_pronunciation"
  final String? textToSpeak;
  final String? audioUrlExample;

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
    this.textToSpeak,
    this.audioUrlExample,
  });

  factory Lesson.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String fromCollectionName) {
    final data = doc.data();

    if (data == null) {
      print("FATAL ERROR: Lesson.fromFirestore - Lesson data is null for doc ID: ${doc.id} in collection $fromCollectionName. Skipping this lesson.");
      throw Exception("Lesson data is null for doc ID: ${doc.id}. Cannot create Lesson object.");
    }

    List<Exercise> parsedExercises = [];
    final String lessonTargetLanguage = data['targetLanguage'] as String? ?? 'english'; // Язык урока
    String determinedLessonType = data['lessonType'] as String? ?? data['type'] as String? ?? 'unknown'; // Тип урока из данных

    String? lessonTextToSpeak;
    String? lessonAudioUrlExample;

    print("--- Parsing Lesson ID: ${doc.id} from '$fromCollectionName'. Initial lessonType from data: '${data['lessonType']}', type: '${data['type']}' -> determined: '$determinedLessonType'");

    // Логика для voice_lessons (упражнения на говорение)
    if (fromCollectionName == 'voice_lessons') {
      determinedLessonType = 'speaking_pronunciation'; // Явно устанавливаем тип
      lessonTextToSpeak = data['textToSpeak'] as String?;
      lessonAudioUrlExample = data['audioUrlExample'] as String?;
      // Для 'voice_lessons' поле 'exercises' обычно пустое, так как сам документ урока - это упражнение.
      print("--- Parsed as 'speaking_pronunciation' from 'voice_lessons': textToSpeak='${lessonTextToSpeak != null}', audioExample='${lessonAudioUrlExample != null}'");
    }
    // Логика для других коллекций с полем 'tasks' (newaudiocollection, audiolessons)
    else if ((fromCollectionName == 'newaudiocollection' || fromCollectionName == 'audiolessons' || determinedLessonType == 'audioWordBankSentence') &&
             data['tasks'] != null && data['tasks'] is List) {
      if ((data['tasks'] as List).isNotEmpty) {
        parsedExercises = (data['tasks'] as List).map((taskData) {
          if (taskData is Map) {
            final taskMap = Map<String, dynamic>.from(taskData);
            try {
              return Exercise.fromMap({
                'exerciseId': taskMap['id']?.toString() ?? Uuid().v4(),
                'type': taskMap['type']?.toString() ?? 'audioWordBankSentence',
                'promptData': {lessonTargetLanguage: taskMap['promptText']?.toString() ?? ''},
                'audioUrl': taskMap['audioUrl'] as String?,
                'correctSentence': taskMap['correctSentence'] as String?,
                'wordBank': (taskMap['wordBank'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
                'createdAt': data['createdAt'] as Timestamp? ?? Timestamp.now(), // Используем createdAt урока
                 // Добавьте feedbackCorrect и feedbackIncorrect, если они есть в taskMap
                'feedbackCorrect': taskMap['feedbackCorrect'] is Map ? Map<String,String>.from(taskMap['feedbackCorrect']) : null,
                'feedbackIncorrect': taskMap['feedbackIncorrect'] is Map ? Map<String,String>.from(taskMap['feedbackIncorrect']) : null,
              });
            } catch (e,s) { print("ERROR parsing task in '$fromCollectionName': $e\n$s\nTaskData: $taskMap"); return null; }
          }
          return null;
        }).whereType<Exercise>().toList();
        print("--- Parsed ${parsedExercises.length} exercises from 'tasks' in '$fromCollectionName'.");
      } else { print("--- 'tasks' field is empty in '$fromCollectionName' for lesson ${doc.id}.");}
    }
    // Логика для interactiveLessons с полем 'tasks'
    else if (fromCollectionName == 'interactiveLessons' && data['tasks'] != null && data['tasks'] is List) {
       determinedLessonType = data['lessonType'] as String? ?? 'chooseTranslation';
      if ((data['tasks'] as List).isNotEmpty) {
        parsedExercises = (data['tasks'] as List).map((taskData) {
            // ... (Ваша существующая детальная логика парсинга 'tasks' для 'interactiveLessons')
            // Убедитесь, что она возвращает Exercise или null и использует exerciseId, type, createdAt
            // Пример адаптации:
            if (taskData is Map) {
                final taskMap = Map<String, dynamic>.from(taskData);
                try {
                    List<Map<String, dynamic>> exerciseOptions = [];
                    String? correctAnswer;
                    if (taskMap['options'] is List) {
                        for(var opt in taskMap['options']){
                            if(opt is Map){
                                exerciseOptions.add({
                                    'text': opt['text']?.toString() ?? '',
                                    'isCorrect': opt['isCorrect'] ?? false,
                                    'feedback': opt['feedback']?.toString()
                                });
                                if(opt['isCorrect'] == true) correctAnswer = opt['text']?.toString();
                            }
                        }
                    }
                    return Exercise.fromMap({
                        'exerciseId': taskMap['id']?.toString() ?? Uuid().v4(),
                        'type': taskMap['type']?.toString() ?? determinedLessonType, // 'chooseTranslation' или из taskMap
                        'promptData': {lessonTargetLanguage: taskMap['promptText']?.toString() ?? ''},
                        'imageUrl': taskMap['imagePromptUrl'] as String?,
                        'optionsData': {lessonTargetLanguage: exerciseOptions},
                        'correctAnswerData': {lessonTargetLanguage: correctAnswer},
                        'createdAt': data['createdAt'] as Timestamp? ?? Timestamp.now(),
                         // Добавьте feedbackCorrect и feedbackIncorrect, если они есть в taskMap
                        'feedbackCorrect': taskMap['feedbackCorrect'] is Map ? Map<String,String>.from(taskMap['feedbackCorrect']) : null,
                        'feedbackIncorrect': taskMap['feedbackIncorrect'] is Map ? Map<String,String>.from(taskMap['feedbackIncorrect']) : null,
                    });
                } catch (e,s) { print("ERROR parsing task in 'interactiveLessons': $e\n$s\nTaskData: $taskMap"); return null;}
            }
            return null;
        }).whereType<Exercise>().toList();
        print("--- Parsed ${parsedExercises.length} exercises from 'tasks' in 'interactiveLessons'.");
      } else { print("--- 'tasks' field is empty in 'interactiveLessons' for lesson ${doc.id}.");}
    }
    // Стандартная логика для поля 'exercises'
    else if (data['exercises'] != null && data['exercises'] is List) {
      if ((data['exercises'] as List).isNotEmpty) {
        parsedExercises = (data['exercises'] as List).map((exMap) {
          if (exMap is Map) {
            try { return Exercise.fromMap(Map<String, dynamic>.from(exMap)); }
            catch (e,s) { print("ERROR parsing exercise from 'exercises' list: $e\n$s\nExerciseData: $exMap"); return null; }
          }
          return null;
        }).whereType<Exercise>().toList();
        print("--- Parsed ${parsedExercises.length} exercises from 'exercises' field.");
      } else { print("--- 'exercises' field is empty for lesson ${doc.id}.");}
    } else if (fromCollectionName != 'voice_lessons') { // Для voice_lessons отсутствие exercises - это нормально
        print("--- WARNING: No 'tasks' or 'exercises' field found for lesson ${doc.id} in collection '$fromCollectionName'. Exercise list will be empty.");
    }


    // Финальное определение типа урока, если он все еще 'unknown'
    if (determinedLessonType == 'unknown') {
      if (fromCollectionName == 'voice_lessons') { // Этот if теперь избыточен, т.к. тип установлен выше
        determinedLessonType = 'speaking_pronunciation';
      } else if (parsedExercises.isNotEmpty) {
        determinedLessonType = parsedExercises.first.type;
      } else if (fromCollectionName.toLowerCase().contains('audio')) {
        determinedLessonType = 'audiolesson';
      } else if (fromCollectionName.toLowerCase().contains('interactive')) {
        determinedLessonType = 'interactive';
      } else {
        determinedLessonType = 'standard'; // Или 'content_module' для learning_modules
      }
      print("--- Lesson type for ${doc.id} finally determined as '$determinedLessonType'.");
    }

    return Lesson(
      id: doc.id,
      title: data['title'] as String? ?? data['topic_name'] as String? ?? data['lessonName'] as String? ?? 'Без названия',
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
      // Передаем специфичные поля для speaking_pronunciation, если они были определены
      textToSpeak: lessonTextToSpeak,
      audioUrlExample: lessonAudioUrlExample,
    );
  }
}