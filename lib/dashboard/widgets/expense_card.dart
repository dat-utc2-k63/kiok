import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stat_card.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: 'Chi Phí',
      amount: '5,340,000 ₫',
      subtitle: 'trong tuần này',
      color: Colors.blue,
      chart: buildExpenseChart(),
    );
  }

  Widget buildExpenseChart() {
    final data = [
      5.0, 6.0, 8.0, 5.5, 7.0, 9.0, 4.0
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: 10,
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Colors.blue,
                width: 15,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      ),
    );
  }
}