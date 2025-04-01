import 'package:flutter/material.dart';
import 'dashboard/screen/CanteenManagementScreen.dart';
import 'dashboard/screen/DocumentPrintingManagementScreen.dart';
import 'dashboard/screen/TuitionFeeManagement.dart';
import 'dashboard/screen/dashboard_screen.dart';
import 'dashboard/sidebar.dart';

void main() {
  runApp(const KioskManagementApp());
}

class KioskManagementApp extends StatefulWidget {
  const KioskManagementApp({Key? key}) : super(key: key);

  @override
  State<KioskManagementApp> createState() => _KioskManagementAppState();
}

class _KioskManagementAppState extends State<KioskManagementApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CanteenManagementScreen(),
    const DocumentPrintingManagementScreen(),
    const TuitionFeeManagement(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiosk Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFFFF9C4), // Màu vàng nhẹ
      ),
      home: Scaffold(
        body: Row(
          children: [
            SideBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}