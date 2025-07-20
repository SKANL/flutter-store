import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';

class StoreSalesProfitScreen extends StatelessWidget {
  const StoreSalesProfitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 100,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'Ganancias y Ventas',
              style: AppTextStyles.title,
            ),
            SizedBox(height: 10),
            Text(
              'Aquí podrás ver tus ganancias y estadísticas de ventas',
              textAlign: TextAlign.center,
              style: AppTextStyles.description,
            ),
          ],
        ),
      ),
    );
  }
}
