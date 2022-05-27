import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rbook/views/main_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  startTimeout() {
    return Timer(const Duration(seconds: 2), handleTimeout);
  }

  void handleTimeout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainPage()));
  }

  @override
  void initState() {
    super.initState();
    startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Icon(
          Icons.call,
          size: 150,
        )
      )
    );
  }

}