import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';

class StoreRegisterSaleScreen extends StatelessWidget {
  const StoreRegisterSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sell,
              size: 100,
              color: Colors.orange,
            ),
            SizedBox(height: 20),
            Text(
              'Registrar Venta',
              style: AppTextStyles.title,
            ),
            SizedBox(height: 10),
            Text(
              'Aquí podrás registrar nuevas ventas\ny actualizar el inventario',
              textAlign: TextAlign.center,
              style: AppTextStyles.description,
            ),
          ],
        ),
      ),
    );
  }
}
