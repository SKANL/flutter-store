import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';

class StoreAddProductScreen extends StatelessWidget {
  const StoreAddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_business,
              size: 100,
              color: Colors.purple,
            ),
            SizedBox(height: 20),
            Text(
              'Agregar Producto',
              style: AppTextStyles.title,
            ),
            SizedBox(height: 10),
            Text(
              'Aquí podrás agregar nuevos productos\nIngresos potenciales: \$64.00',
              textAlign: TextAlign.center,
              style: AppTextStyles.description,
            ),
          ],
        ),
      ),
    );
  }
}
