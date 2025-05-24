import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background.png'), // Path to your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "Есть аккаунт, войти" Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/auth'); // Navigate to AuthPage
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green, // Button text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                      elevation: 5, // Shadow effect
                      padding: const EdgeInsets.symmetric(horizontal: 20), // Horizontal padding
                    ),
                    child: const Text(
                      'Есть аккаунт, войти',
                      style: TextStyle(fontSize: 18), // Button text style
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Spacing between buttons
                // "Нет аккаунта, зарегистрироваться" Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: MediaQuery.of(context).size.height * 0.1,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reg'); // Navigate to Registration Page
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green, // Button text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                      elevation: 5, // Shadow effect
                      padding: const EdgeInsets.symmetric(horizontal: 20), // Horizontal padding
                    ),
                    child: const Text(
                      'Нет аккаунта, зарегистрироваться',
                      style: TextStyle(fontSize: 18), // Button text style
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
