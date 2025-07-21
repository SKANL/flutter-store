import 'package:flutter/material.dart';
import 'package:store_manager/components/store_info_cards.dart';
import 'package:store_manager/screens/store_inventory_screen.dart';
import 'package:store_manager/screens/store_add_product_screen.dart';
import 'package:store_manager/screens/store_advanced_reports_screen.dart';
import 'package:store_manager/screens/store_register_sale_screen.dart';
import '../components/bottom_navigation_bar.dart';
import '../components/floating_add_button.dart';
import '../components/barcode_diagnostic_tool.dart';
import '../components/connection_diagnostic_tool.dart';
import '../components/api_config_tool.dart';

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
    },), // Dashboard
    const StoreInventoryScreen(), // Inventory
    const StoreAddProductScreen(), // Add Product
    const StoreAdvancedReportsScreen(), // Sales & Reports
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
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón de configuración API
                FloatingActionButton.small(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ApiConfigTool(),
                      ),
                    );
                  },
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  heroTag: 'api_config',
                  tooltip: 'Configuración API',
                  child: const Icon(Icons.settings, size: 18),
                ),
                const SizedBox(height: 8),
                // Botón de diagnóstico de conexión
                FloatingActionButton.small(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ConnectionDiagnosticTool(),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  heroTag: 'connection_diagnostic',
                  tooltip: 'Diagnóstico de Conexión API',
                  child: const Icon(Icons.wifi_find, size: 18),
                ),
                const SizedBox(height: 8),
                // Botón de diagnóstico de códigos de barras
                FloatingActionButton.small(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BarcodeDiagnosticTool(),
                      ),
                    );
                  },
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  heroTag: 'barcode_diagnostic',
                  tooltip: 'Diagnóstico Códigos de Barras',
                  child: const Icon(Icons.bug_report, size: 18),
                ),
                const SizedBox(height: 8),
                // Botón principal de agregar producto
                FloatingAddButton(
                  onPressed: () async {
                    print('🔄 [NAV] Navegando a agregar producto desde dashboard...');
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const StoreAddProductScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      print('✅ [NAV] Producto guardado desde dashboard, recargando...');
                      // Aquí podrías recargar el inventario si es necesario
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Producto agregado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  tooltip: 'Agregar Producto',
                ),
              ],
            )
          : null,
    );
  }
}
