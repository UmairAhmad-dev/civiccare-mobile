import 'package:flutter/material.dart';
import 'login_screen.dart'; // Ensure this file exists in the same folder

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CivicCare AI',
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}