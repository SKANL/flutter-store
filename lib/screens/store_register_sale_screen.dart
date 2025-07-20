import 'package:flutter/material.dart';
import '../core/app_color.dart';

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Aquí podrás registrar nuevas ventas\ny actualizar el inventario',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
