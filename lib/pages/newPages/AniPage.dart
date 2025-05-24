import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter.blur

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({Key? key}) : super(key: key);

  @override
  _IntroductionPageState createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Removed: late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation; // New animation for sliding/bobbing
  late Animation<double> _scaleAnimation; // Kept for the button

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // Duration controls speed of one cycle (up and down)
      duration: const Duration(
          milliseconds: 2500), // Slightly longer duration for smoother bob
      vsync: this,
    )..repeat(reverse: true); // Repeats the animation back and forth

    // --- New Slide Animation for the Logo ---
    _slideAnimation = Tween<Offset>(
      // Defines the start and end points of the vertical movement
      // Offset(dx, dy): dx is horizontal, dy is vertical
      // Negative dy is up, positive dy is down.
      // These values are relative multipliers of the widget's size,
      // but for SlideTransition, think of them as screen percentage if not constrained.
      // Let's use small values for a subtle bob.
      begin: const Offset(0.0, -0.02), // Start slightly above center
      end: const Offset(0.0, 0.02), // End slightly below center
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth acceleration and deceleration
      ),
    );

    // Scale animation for the button (gentle pulse) - unchanged
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // --- Background Image ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background.png'), // Standard path
                fit: BoxFit.cover,
              ),
            ),
          ),

          // --- Optional: Subtle Blur/Overlay ---
          // Positioned.fill(
          //   child: BackdropFilter(
          //     filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          //     child: Container(
          //       color: Colors.black.withOpacity(0.15),
          //     ),
          //   ),
          // ),

          // --- Centered Content ---
          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- LingoQuest Logo with Slide Animation ---
                  SlideTransition(
                    // Use SlideTransition instead of FadeTransition
                    position: _slideAnimation, // Apply the bobbing animation
                    child: FractionallySizedBox(
                      widthFactor: screenWidth < 600 ? 0.7 : 0.5,
                      child: Image.asset(
                        // *** Ensure transparent background PNG and correct path ***
                        'images/LingoQuest_logos.png', // Standard path
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // Responsive spacing

                  // --- Text Container --- (Unchanged)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade700.withOpacity(0.80),
                          Colors.amber.shade600.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Добро пожаловать в LingoQuest!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Colors.black54,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Здесь вы сможете выучить английский язык, проходить множество уроков и повышать свой уровень владения языком!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06), // Responsive spacing

                  // --- Enhanced Button with Scale Animation --- (Unchanged)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/welcome');
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87, // Text color
                        backgroundColor: Colors.transparent, // For gradient
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: Colors.orange.shade900.withOpacity(0.5),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 255, 156, 7), // Orange
                              Color.fromARGB(255, 255, 252, 55), // Yellow
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 18),
                          alignment: Alignment.center,
                          child: const Text(
                            'Продолжить',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
