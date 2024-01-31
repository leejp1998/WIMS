import 'package:flutter/material.dart';

import 'home_page.dart';

class AppLoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your icon goes here
            Image.asset(
              'assets/WIMS_ICON.jpg', // Update with your actual icon path
              width: 100, // Adjust the size as needed
              height: 100,
            ),
            const SizedBox(height: 16),
            // "WIMS" text
            const Text(
              'WIMS',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black54, // Text color
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}