import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/inventory_state.dart';
import 'card_widget.dart';

class StoreInfoCards extends StatelessWidget {
  final Function(int)? onTabChange;

  const StoreInfoCards({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return InventoryBuilder(
      builder: (context, inventory) {        
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Fila 1: Ganancia Total y Valor del Inventario
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CardWidget(
                  title: 'Ganancia Total',
                  value: inventory.isLoading && inventory.products.isEmpty
                    ? 'Cargando...' 
                    : '\$0.00', // TODO: Implementar cálculo de ganancias
                  color: AppColors.backgroundComponent,
                  textColor: Colors.green,
                  onTap: () {
                    // Cambiar al tab de Sales (índice 3)
                    if (onTabChange != null) {
                      onTabChange!(3);
                    }
                  },
                  isLoading: inventory.isLoading && inventory.products.isEmpty,
                ),
                CardWidget(
                  title: 'Valor del Inventario',
                  value: inventory.isLoading && inventory.products.isEmpty
                    ? 'Cargando...'
                    : '\$${inventory.totalInventoryValue.toStringAsFixed(2)}',
                  color: AppColors.backgroundComponent,
                  textColor: Colors.blue,
                  onTap: () {
                    // Cambiar al tab de Inventory (índice 1)
                    if (onTabChange != null) {
                      onTabChange!(1);
                    }
                  },
                  isLoading: inventory.isLoading && inventory.products.isEmpty,
                ),
              ],
            ),
            // Fila 2: Ingresos Potenciales y Productos con Bajo Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CardWidget(
                  title: 'Ingresos Potenciales',
                  value: inventory.isLoading && inventory.products.isEmpty
                    ? 'Cargando...'
                    : '\$${inventory.totalInventoryValue.toStringAsFixed(2)}', // TODO: Calcular ingresos potenciales
                  color: AppColors.backgroundComponent,
                  textColor: Colors.purple,
                  onTap: () {
                    // Cambiar al tab de Add Product (índice 2)
                    if (onTabChange != null) {
                      onTabChange!(2);
                    }
                  },
                  isLoading: inventory.isLoading && inventory.products.isEmpty,
                ),
                CardWidget(
                  title: 'Productos con Bajo Stock',
                  value: inventory.isLoading && inventory.products.isEmpty
                    ? 'Cargando...'
                    : '${inventory.lowStockProducts.length}',
                  color: AppColors.backgroundComponent,
                  textColor: Colors.orange,
                  onTap: () {
                    // Cambiar al tab de Registrar Venta (índice 4)
                    if (onTabChange != null) {
                      onTabChange!(4);
                    }
                  },
                  isLoading: inventory.isLoading && inventory.products.isEmpty,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
