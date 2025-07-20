import 'package:flutter/material.dart';
import 'package:store_manager/components/store_info_cards.dart';
import 'package:store_manager/screens/store_inventory_screen.dart';
import 'package:store_manager/screens/store_add_product_screen.dart';
import 'package:store_manager/screens/store_sales_profit_screen.dart';
import 'package:store_manager/screens/store_register_sale_screen.dart';
import '../components/bottom_navigation_bar.dart';
import '../components/floating_add_button.dart';

class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    StoreInfoCards(onTabChange: (int index) {
      setState(() {
        _currentIndex = index;
      });
    }), // Dashboard
    const StoreInventoryScreen(), // Inventory
    const StoreAddProductScreen(), // Add Product
    const StoreSalesProfitScreen(), // Sales
    const StoreRegisterSaleScreen(), // Registrar Venta
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 1 // Solo mostrar en inventario
          ? FloatingAddButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StoreAddProductScreen(),
                  ),
                );
              },
              tooltip: 'Agregar Producto',
            )
          : null,
    );
  }
}
