// import 'package:flutter/material.dart';
// import 'dart:ui';

// import 'package:flutter_languageapplicationmycourse_2/main.dart'; // Required for ImageFilter.blur

// class IntroductionPage extends StatefulWidget {
//   const IntroductionPage({Key? key}) : super(key: key);

//   @override
//   _IntroductionPageState createState() => _IntroductionPageState();
// }

// class _IntroductionPageState extends State<IntroductionPage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _slideAnimation; // Animation for logo bobbing
//   late Animation<double> _scaleAnimation; // Animation for button pulse

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 2500), // Speed of animations
//       vsync: this,
//     )..repeat(reverse: true); // Repeat back and forth

//     // Logo bobbing animation
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0.0, -0.02), // Start slightly up
//       end: const Offset(0.0, 0.02),   // End slightly down
//     ).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );

//     // Button pulsating animation
//     _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose(); // IMPORTANT: Dispose controller
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     // Optional: Reset status bar style if changed by splash screen
//     // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark); // Or .light

//     return Scaffold(
//       body: Stack(
//         children: [
//           // --- Background Image ---
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 // *** MAKE SURE PATH IS CORRECT ***
//                 image: AssetImage('images/background.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

//           // --- Optional: Blur/Overlay for contrast ---
//           // Positioned.fill(
//           //   child: BackdropFilter(
//           //     filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
//           //     child: Container(
//           //       color: Colors.black.withOpacity(0.15),
//           //     ),
//           //   ),
//           // ),

//           // --- Centered Content ---
//           Center(
//             child: SingleChildScrollView( // Allow scrolling on small screens
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // --- LingoQuest Logo with Slide Animation ---
//                   SlideTransition(
//                     position: _slideAnimation,
//                     child: FractionallySizedBox(
//                       widthFactor: screenWidth < 600 ? 0.7 : 0.5, // Responsive width
//                       child: Image.asset(
//                         // *** MAKE SURE PATH IS CORRECT & IMAGE HAS TRANSPARENT BG ***
//                         'images/LingoQuest_logos.png',
//                         fit: BoxFit.contain,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.05), // Responsive spacing

//                   // --- Text Container ---
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 25, vertical: 30),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.orange.shade700.withOpacity(0.80),
//                           Colors.amber.shade600.withOpacity(0.85),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(15),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 12,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: const [
//                         Text(
//                           'Добро пожаловать в LingoQuest!',
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             shadows: [
//                               Shadow(
//                                 blurRadius: 2.0,
//                                 color: Colors.black54,
//                                 offset: Offset(1.0, 1.0),
//                               ),
//                             ],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         SizedBox(height: 15),
//                         Text(
//                           'Здесь вы сможете выучить английский язык, проходить множество уроков и повышать свой уровень владения языком!',
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.white,
//                             height: 1.4, // Line spacing
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.06), // Responsive spacing

//                   // --- Enhanced Button with Scale Animation ---
//                   ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // Navigate to the Welcome Page using named route
//                         Navigator.pushNamed(context, welcomeRoute);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         foregroundColor: Colors.black87, // Text color on button
//                         backgroundColor: Colors.transparent, // Needed for gradient
//                         padding: EdgeInsets.zero, // Remove padding for Ink
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30), // Pill shape
//                         ),
//                         elevation: 8,
//                         shadowColor: Colors.orange.shade900.withOpacity(0.5),
//                       ),
//                       child: Ink( // Container for gradient
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [
//                               Color.fromARGB(255, 255, 156, 7), // Orange
//                               Color.fromARGB(255, 255, 252, 55), // Yellow
//                             ],
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                           ),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 50, vertical: 18),
//                           alignment: Alignment.center,
//                           child: const Text(
//                             'Продолжить',
//                             style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87 // Explicit text color
//                                 ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }