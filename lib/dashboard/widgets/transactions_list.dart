import 'package:flutter/material.dart';
import '../models/transaction_item.dart';

class TransactionsList extends StatelessWidget {
  const TransactionsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giao Dịch Gần Đây',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: const [
                TransactionItem(
                  title: 'Đặt Đồ Ăn',
                  time: 'Jan 23 10:25 AM',
                  id: 'ID: 47671',
                  amount: '+569,500 ₫',
                  color: Colors.blue,
                ),
                TransactionItem(
                  title: 'In Tài Liệu',
                  time: 'Jan 23 10:25 AM',
                  id: 'ID: 76154',
                  amount: '+350,500 ₫',
                  color: Colors.green,
                ),
                TransactionItem(
                  title: 'Đóng Học Phí',
                  time: 'Jan 23 10:25 AM',
                  id: 'ID: 32267',
                  amount: '+3,448,500 ₫',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}