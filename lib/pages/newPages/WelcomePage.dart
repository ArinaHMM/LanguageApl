import 'package:flutter/material.dart';
import 'dart:math'
    as math; // Для генерации случайных значений, если понадобится

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut, // Эффект "резинки"
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // --- Фоновое изображение с легким градиентом ---
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'images/background.png'), // Убедитесь, что путь верный
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(
                      0.3), // Затемнение для лучшей читаемости текста
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // --- Декоративные элементы (можно добавить больше) ---
          // Пример: плавающие частицы или абстрактные фигуры (простой пример)
          Positioned(
            top: screenHeight * 0.1,
            left: screenWidth * 0.1,
            child: Opacity(
              opacity: 0.5,
              child: Icon(
                Icons.translate, // Иконка, связанная с языком
                size: screenWidth * 0.2,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.15,
            right: screenWidth * 0.05,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Opacity(
                opacity: 0.6,
                child: Icon(
                  Icons.lightbulb_outline, // Иконка идеи или обучения
                  size: screenWidth * 0.15,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ),

          // --- Основной контент ---
          SafeArea(
            // Чтобы контент не залезал под системные элементы
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Заголовок/Логотип (анимированный) ---
                    // --- Заголовок/Логотип (анимированный) ---
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // --- ВАШ ЛОГОТИП ---
                            Image.asset(
                              'images/LingoQuest_logos.png', // <-- УКАЖИТЕ ПРАВИЛЬНЫЙ ПУТЬ К ВАШЕМУ ЛОГОТИПУ
                              width: screenWidth *
                                  0.65, // Подберите подходящую ширину
                              height: screenHeight *
                                  0.30, // Можно задать и высоту, если нужно
                              fit: BoxFit
                                  .contain, // Чтобы логотип поместился без искажений
                              // Можно добавить тень к контейнеру логотипа, если сам логотип плоский
                              // Для этого можно обернуть Image.asset в DecoratedBox или Container с BoxDecoration
                            ),
                            SizedBox(
                                height: screenHeight *
                                    0.02), // Отступ между логотипом и названием
                            Text(
                              'LingoQuest', // Название вашего приложения
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.1,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8.0,
                                    color: Colors.black.withOpacity(0.6),
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Откройте мир языков!', // Ваш слоган
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white.withOpacity(0.85),
                                shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.08),

                    // --- Кнопки (анимированные) ---
                    // "Есть аккаунт, войти" Button
                    _buildAnimatedButton(
                      context: context,
                      text: 'Есть аккаунт, войти',
                      onPressed: () {
                        Navigator.pushNamed(context, '/auth');
                      },
                      delayFactor:
                          0.8, // Небольшая задержка для эффекта "появления"
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    // "Нет аккаунта, зарегистрироваться" Button
                    _buildAnimatedButton(
                      context: context,
                      text: 'Нет аккаунта, зарегистрироваться',
                      onPressed: () {
                        Navigator.pushNamed(context, '/reg');
                      },
                      delayFactor: 1.0, // Чуть позже для эффекта "появления"
                    ),
                    SizedBox(height: screenHeight * 0.05), // Отступ снизу
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required double delayFactor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.4 * delayFactor, // Начало анимации для этой кнопки
            1.0 * delayFactor, // Конец анимации
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.4 * delayFactor,
              1.0 * delayFactor,
              curve: Curves.elasticOut, // Эффект "резинки"
            ),
          ),
        ),
        child: SizedBox(
          width: screenWidth * 0.75, // Немного шире
          height: screenHeight * 0.07, // Немного выше
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color.fromARGB(
                  255, 255, 132, 49), // Текст кнопки - основной цвет
              backgroundColor: Colors.white, // Фон кнопки - белый
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // Более круглые углы
              ),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04, // Адаптивный размер шрифта
                fontWeight: FontWeight.w600, // Немного жирнее
              ),
            ),
          ),
        ),
      ),
    );
  }
}
