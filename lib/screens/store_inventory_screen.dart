import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';

class StoreInventoryScreen extends StatelessWidget {
  const StoreInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Inventario',
              style: AppTextStyles.title,
            ),
            SizedBox(height: 10),
            Text(
              'Aquí podrás gestionar tu inventario\nValor total: \$72.00',
              textAlign: TextAlign.center,
              style: AppTextStyles.description,
            ),
          ],
        ),
      ),
    );
  }
}
