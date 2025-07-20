import 'package:flutter/material.dart';
import '../core/app_color.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.text,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add Product',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Sales',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sell),
          label: 'Registrar Venta',
        ),
      ],
    );
  }
}
