import 'package:flutter/material.dart';
import '../models/kiosk_card.dart';

class ActiveKiosks extends StatelessWidget {
  const ActiveKiosks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Kiosk Đang Hoạt Động',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 15),
          KioskCard(
            id: '**** 1432',
            name: 'Kiosk Căn Tin',
            color: Colors.red,
          ),
          SizedBox(height: 10),
          KioskCard(
            id: '**** 2231',
            name: 'Kiosk Thư Viện',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}