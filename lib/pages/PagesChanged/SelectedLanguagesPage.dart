  // lib/pages/SelectLanguagePage.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toast/toast.dart';

// Модель для опции языка, чтобы сделать код чище
class LanguageOption {
  final String code; // 'english', 'spanish', 'german'
  final String name; // 'Английский', 'Испанский', 'Немецкий'
  final String flagEmoji; // Эмодзи флага для простоты (можно заменить на IconData или Image asset)
  final Color color;

  LanguageOption({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.color,
  });
}

class SelectLanguagePage extends StatefulWidget {
  const SelectLanguagePage({Key? key}) : super(key: key);

  @override
  _SelectLanguagePageState createState() => _SelectLanguagePageState();
}

class _SelectLanguagePageState extends State<SelectLanguagePage> {
  // Список языков, которые пользователь может выбрать для изучения
  // Русский язык не включен, так как это язык интерфейса
  final List<LanguageOption> _languagesToLearn = [
    LanguageOption(code: 'english', name: 'Английский', flagEmoji: '🇬🇧', color: Colors.indigo[400]!),
    LanguageOption(code: 'spanish', name: 'Испанский', flagEmoji: '🇪🇸', color: Colors.orange[600]!),
    LanguageOption(code: 'german', name: 'Немецкий', flagEmoji: '🇩🇪', color: Colors.red[400]!),
    // Добавьте другие языки при необходимости
    // LanguageOption(code: 'french', name: 'Французский', flagEmoji: '🇫🇷', color: Colors.purple[400]!),
  ];

  String? _selectedLanguageCode;
  bool _isLoading = false;

  Future<void> _saveLanguageSelection() async {
    if (_selectedLanguageCode == null) {
      Toast.show("Пожалуйста, выберите язык для изучения.");
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Toast.show("Ошибка: пользователь не авторизован. Попробуйте войти снова.");
      // Перенаправить на вход, если пользователь каким-то образом попал сюда без авторизации
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Подготовка данных для languageSettings
      Map<String, dynamic> learningProgressPayload = {};
      for (var langOpt in _languagesToLearn) {
        learningProgressPayload[langOpt.code] = {
          'level': langOpt.code == _selectedLanguageCode ? 'Beginner' : 'Beginner', // Устанавливаем Beginner для выбранного
          'xp': 0,
          'lessonsCompleted': {}, // Пустой прогресс по урокам
        };
      }

      Map<String, dynamic> languageSettings = {
        'currentLearningLanguage': _selectedLanguageCode,
        'interfaceLanguage': 'russian', // Язык интерфейса приложения по умолчанию
        'learningProgress': learningProgressPayload,
      };

      // Сохраняем languageSettings в документе пользователя
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'languageSettings': languageSettings}, SetOptions(merge: true));

      Toast.show("Язык '${_languagesToLearn.firstWhere((lang) => lang.code == _selectedLanguageCode).name}' выбран!", duration: Toast.lengthLong);
      
      // Перенаправляем на главную страницу с уроками (или куда вы планируете после этого)
      Navigator.pushNamedAndRemoveUntil(context, '/learn', (route) => false);

    } catch (e) {
      print("Ошибка сохранения выбора языка: $e");
      Toast.show("Не удалось сохранить выбор языка. Пожалуйста, попробуйте снова.");
    } finally {
      // Проверяем, смонтирован ли виджет, перед вызовом setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context); // Инициализация Toast для этой страницы
    return Scaffold(
      appBar: AppBar(
        title: const Text("Выберите язык"),
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false, // Пользователь не должен возвращаться на регистрацию
        elevation: 0, // Убрать тень, если нужно
      ),
      body: Container(
        decoration: BoxDecoration( // Можно добавить градиентный фон
          gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.green[400]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Кнопка будет внизу
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    const Text(
                      "Какой язык вы хотите учить?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Вы всегда сможете добавить другие языки позже.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _languagesToLearn.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lang = _languagesToLearn[index];
                      final isSelected = _selectedLanguageCode == lang.code;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguageCode = lang.code;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: isSelected ? lang.color.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : Border.all(color: Colors.transparent, width: 0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(lang.flagEmoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  lang.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.white, size: 28),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedLanguageCode == null ? Colors.grey[400] : Colors.amber[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    elevation: _selectedLanguageCode == null ? 0 : 5,
                  ),
                  onPressed: _selectedLanguageCode == null || _isLoading ? null : _saveLanguageSelection,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text("Начать обучение!", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}