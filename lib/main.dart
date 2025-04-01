import 'package:flutter/material.dart';
import 'screen/main_menu_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SchoolServiceApp());
}

class SchoolServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiosk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFFFF9C4), // Màu vàng nhẹ
      ),
      home: MainMenuScreen(),
    );
  }
}