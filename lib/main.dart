import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_languageapplicationmycourse_2/Themes/theme.dart';
import 'package:flutter_languageapplicationmycourse_2/database/auth/service.dart';
import 'package:flutter_languageapplicationmycourse_2/routes/routes.dart';

import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDg6WHmxqIAYKI_asV9lboLhxPEZD2WfnM',
        appId: '1:343134865969:android:6a3d07a714fcb87c0de310',
        messagingSenderId: '343134865969',
        projectId: 'languageapl',
        storageBucket: 'languageapl.appspot.com',
      ),
    );
    runApp(const ThemeAppMenu());
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

class ThemeAppMenu extends StatelessWidget {
  const ThemeAppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider.value(
        initialData: null,
        value: AuthService().currentUser,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LingoQuest',
          initialRoute: '/splash',
          theme: AppThemes.lightTheme, // Наша светлая тема
          darkTheme: AppThemes.darkTheme, // Наша темная тема
          themeMode: ThemeMode.system,
          routes: routes,
        ));
  }
}
