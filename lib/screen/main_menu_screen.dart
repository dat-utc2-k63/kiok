import 'package:flutter/material.dart';
import 'order_food_screen.dart';
import 'print_document_screen.dart';
import 'tuition_payment_screen.dart';
import '../../widgets/menu_button.dart';

class MainMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dịch Vụ Học Đường'),
        backgroundColor: Colors.amber[200],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MenuButton(
              text: 'Đặt Đồ Ăn',
              icon: Icons.restaurant_menu,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderFoodScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            MenuButton(
              text: 'In Tài Liệu',
              icon: Icons.print,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrintDocumentScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            MenuButton(
              text: 'Đóng Học Phí',
              icon: Icons.payment,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TuitionPaymentScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}