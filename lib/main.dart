import 'package:flutter/material.dart';
import 'screen/main_menu_screen.dart';

void main() {
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