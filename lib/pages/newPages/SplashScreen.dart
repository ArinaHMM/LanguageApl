import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_languageapplicationmycourse_2/main.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/newPages/AniPage.dart'; // Required for SystemUiOverlayStyle

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  final int _splashDurationSeconds = 3; // How long the splash screen stays

  @override
  void initState() {
    super.initState();

    // --- Animation Setup ---
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Duration of logo fade-in
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward(); // Start the animation

    // --- Timer and Navigation ---
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer(
        Duration(seconds: _splashDurationSeconds), _navigateToIntroduction);
  }

 void _navigateToIntroduction() {
  if (mounted) {
    // ---- НОВЫЙ КОД ДЛЯ ПЛАВНОГО ПЕРЕХОДА ----
    Navigator.of(context).pushReplacement( // Используем pushReplacement, чтобы нельзя было вернуться назад
      PageRouteBuilder(
        // Указываем, какой экран должен открыться
        pageBuilder: (context, animation, secondaryAnimation) =>
            const IntroductionPage(), // Убедись, что IntroductionPage импортирован

        // Описываем сам переход (анимацию)
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Используем FadeTransition для эффекта затухания/появления
          return FadeTransition(
            opacity: animation, // Прозрачность будет меняться в соответствии с анимацией
            child: child,       // child - это наш IntroductionPage
          );
        },
        // Длительность анимации перехода (например, 700 миллисекунд)
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
    // ---- КОНЕЦ НОВОГО КОДА ----
  }
}

  @override
  void dispose() {
    _timer?.cancel(); // IMPORTANT: Cancel timer on dispose
    _animationController.dispose(); // IMPORTANT: Dispose controller on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to be transparent for a cleaner splash screen look
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Adjust if background is dark
    ));

    return Scaffold(
      // Simple background color - often preferred for fast perceived load
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            // *** MAKE SURE PATH IS CORRECT & IMAGE HAS TRANSPARENT BG ***
            'images/LingoQuest_logos.png',
            width: MediaQuery.of(context).size.width * 0.65, // Adjust size
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
