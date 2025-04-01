import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category_item.dart';

class CategoryStatistics extends StatelessWidget {
  const CategoryStatistics({Key? key}) : super(key: key);

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
        children: [
          const Text(
            'Thống Kê Theo Danh Mục',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: _buildPieChart(),
          ),
          const SizedBox(height: 20),
          const CategoryItem(
            title: 'Đồ Ăn',
            percentage: '50%',
            color: Colors.blue,
          ),
          const CategoryItem(
            title: 'In Tài Liệu',
            percentage: '35%',
            color: Colors.pink,
          ),
          const CategoryItem(
            title: 'Học Phí',
            percentage: '15%',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: 50,
            color: Colors.blue,
            radius: 50,
            title: '50%',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            value: 35,
            color: Colors.pink,
            radius: 50,
            title: '35%',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            value: 15,
            color: Colors.amber,
            radius: 50,
            title: '15%',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
