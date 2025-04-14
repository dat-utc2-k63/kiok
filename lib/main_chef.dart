import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'chef/chef_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ChefApp());
}

class ChefApp extends StatelessWidget {
  const ChefApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chef App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChefScreen(),
    );
  }
}