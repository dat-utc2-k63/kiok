import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stat_card.dart';

class IncomeCard extends StatelessWidget {
  const IncomeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: 'Doanh Thu',
      amount: '9,780,000 ₫',
      subtitle: 'trong tuần này',
      color: Colors.pink,
      chart: buildIncomeChart(),
    );
  }

  Widget buildIncomeChart() {
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
                color: Colors.pink,
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