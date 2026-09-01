import 'package:flutter/material.dart';
import 'dart:async';
import 'mainScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to login page after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => mainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA9CDE3),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/taskheroLogo.png', width: 500, height: 500),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
