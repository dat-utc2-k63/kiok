import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kiot_order/screen/add_data_screen.dart';
import 'package:kiot_order/screen/main_menu_screen.dart'; // Import màn hình thêm dữ liệu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiot Order',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFFFF9C4), // Màu vàng nhẹ
      ),
      home: MainMenuScreen(), // Gọi màn hình thêm dữ liệu
    );
  }
}