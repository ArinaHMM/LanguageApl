import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/models/lesson_model.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/audioplayerpage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/lesson_player_page.dart';

Widget buildLessonPage(Lesson lesson, Function(String, int) onProgressUpdated) {
  final String type = lesson.lessonType.toLowerCase();
  final String collection = lesson.collectionName.toLowerCase();

  if (type == 'audiowordbanksentence' || collection == 'newaudiocollection') {
    return LessonPlayerAudioPage(
      lesson: lesson,
      onProgressUpdated: onProgressUpdated,
    );
  }

  if (collection == 'interactivelessons') {
    return LessonPlayerPage(
      lesson: lesson,
      onProgressUpdated: onProgressUpdated,
    );
  }

  // Другие типы можно добавить здесь при необходимости:

  // if (type == 'videolesson') {
  //   return VideoLessonPage(...);
  // }

  return LessonPlayerPage(
    lesson: lesson,
    onProgressUpdated: onProgressUpdated,
  );
}
