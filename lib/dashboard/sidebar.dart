import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const SideBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard, color: Colors.blue),
          ),
          const SizedBox(height: 30),
          _buildSidebarItem(Icons.home, 0),
          _buildSidebarItem(Icons.fastfood, 1), // Icon for Canteen
          _buildSidebarItem(Icons.print, 2), // Icon for Document Printing
          _buildSidebarItem(Icons.attach_money, 3), // Icon for Tuition Fee
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, int index) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}