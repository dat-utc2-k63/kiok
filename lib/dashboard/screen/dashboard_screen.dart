import 'package:flutter/material.dart';
import '../sidebar.dart';
import '../widgets/expense_card.dart';
import '../widgets/income_card.dart';
import '../widgets/transactions_list.dart';
import '../widgets/active_kiosks.dart';
import '../widgets/category_statistics.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  buildTopBar(),

                  const SizedBox(height: 20),

                  // Dashboard content
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              // Stats row
                              Row(
                                children: [
                                  const Expanded(
                                    child: ExpenseCard(),
                                  ),
                                  const SizedBox(width: 20),
                                  const Expanded(
                                    child: IncomeCard(),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              const SizedBox(height: 20),

                              // Transactions
                              const Expanded(
                                child: TransactionsList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Right column
                        Expanded(
                          child: Column(
                            children: [
                              // Active Kiosks
                              const ActiveKiosks(),

                              const SizedBox(height: 20),

                              // Statistics
                              const Expanded(
                                child: CategoryStatistics(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopBar() {
    return Row(
      children: [
        const Text(
          'Tổng Quan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        Row(
          children: [
            const Text(
              'Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}