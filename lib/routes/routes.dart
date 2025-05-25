import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AddLesson/AdminPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AdvancedPage/AdminAdvanced.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AdvancedPage/AdvancedLessonPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AudiosPage/AdminAudioLessonPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AudiosPage/LessonAudioPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/ChatsSupport.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/Game.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/HangmanGame.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/GamePages/ViewGamesPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/LearnPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/LessonPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/AddLesson/LessonPage1.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/NotificationsPages/NotificationPape.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/LoginWithCodePage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/PagesChanged/PhoneAuthPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/ProfilePage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/SettingsPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/SupportNav.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperIntermediateLesson/AdminUpInterPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperIntermediateLesson/UpIntermediarePage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperUpInterPage/AdminUpperUp.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/Video/VideoAdminPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/chatPage/ChatPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/chatPage/SupChat.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/AniPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/AuthPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/EditAdminLessonPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/GptChatPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/LanguageLevelTestPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/NavigationAdminPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/RegistrationPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/UpperLesson/UpperLessonAdminPage.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/SplashScreen.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/WelcomePage.dart';

final routes = {
  // '/auth': (context) => const AuthPage(),
  '/auth': (context) => AuthPage(),
  '/reg': (context) => const RegistrationPage(),
  '/profile': (context) => const ProfilePage(),
  '/chat1': (context) => const ChatsPage1(),

  '/settings': (context) => const SettingsPage(),
  '/learn': (context) => LearnPage(), // Главная страница
  '/lesson': (context) => LessonPage(),
  '/admin': (context) => AddLessonPage(),
  '/lesson1': (context) => LessonPage1(
        lessonLevel: '',
        lessonId: '',
        onProgressUpdated: (int newProgress) {},
      ),
  '/what': (context) => const LanguageLevelTestPage(
        userId: '',
        email: '',
        firstName: '',
        lastName: '',
        birthDate: '',
      ),
  '/audiolesson': (context) => AdminAudioLessonPage(),
  '/audio': (context) => AudioLessonPage(
        lessonId: '',
      ),
  '/welcome': (context) => const WelcomePage(),
  '/ani': (context) => const IntroductionPage(),
  '/game': (context) => MemoryGamePage(),
  '/video': (context) => VideoUploadPage(),
  '/navadmin': (context) => const AdminNavigationPage(),
  '/navsupport': (context) => const SupportNavigationPage(),
  '/splash': (context) => const SplashScreen(),

  '/game2': (context) => HangmanGamePage(),
  '/games': (context) => GamesPage(),
  '/chat': (context) => const ChatsPage(),
  '/prof1': (context) => const ProfilePage1(),

  '/learnadmin': (context) => AdminLearnPage(),
  '/notifications': (context) => NotificationsPage(),
  '/upperlesson': (context) => AddUpperLessonPage(),
  '/upperupinterlesson': (context) => AddUpperUpInterLessonPageState(),
  '/upperinterlesson': (context) => AddUpperInterLessonPageState(),
  '/advancedlesson': (context) => AddAdvancedLessonPage(),

  // '/gpt': (context) => GptChatPage(),
};
