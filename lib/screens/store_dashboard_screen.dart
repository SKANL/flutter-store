import 'package:flutter/material.dart';
import 'package:store_manager/components/store_info_cards.dart';
import 'package:store_manager/screens/store_inventory_screen.dart';
import 'package:store_manager/screens/store_add_product_screen.dart';
import 'package:store_manager/screens/store_advanced_reports_screen.dart';
import 'package:store_manager/screens/store_register_sale_screen.dart';
import '../components/bottom_navigation_bar.dart';
import '../components/floating_add_button.dart';

// --- IMPORTS CONDICIONALES SEGÚN EL SWITCH ---
// Para activar/desactivar automáticamente, se recomienda usar un build_runner o script, pero aquí se muestra el patrón manual:
// Si el switch está activado, descomenta estas líneas:
// #if SHOW_CONFIG_API_IMPORTS
import '../components/barcode_diagnostic_tool.dart';
import '../components/connection_diagnostic_tool.dart';
import '../components/api_config_tool.dart';
import '../components/barcode_issue_fix_tool.dart';
// #endif

// Para alternar, busca y reemplaza '#if SHOW_CONFIG_API_IMPORTS' por '' y '#endif' por '' para activar,
// o comenta las líneas para desactivar. Puedes automatizar esto con un script simple.

class StoreDashboardScreen extends StatefulWidget {
  final bool showConfigApiSwitch;
  final ValueChanged<bool>? onConfigApiSwitchChanged;
  const StoreDashboardScreen({super.key, this.showConfigApiSwitch = false, this.onConfigApiSwitchChanged});

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
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (_currentIndex == 0 && widget.onConfigApiSwitchChanged != null)
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  const Text('Mostrar Config. API', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: widget.showConfigApiSwitch,
                    onChanged: widget.onConfigApiSwitchChanged,
                  ),
                ],
              ),
            ),
          // Botones de herramientas de diagnóstico, solo si el switch está activado y en el dashboard
          if (_currentIndex == 0 && widget.showConfigApiSwitch)
            Positioned(
              bottom: 32,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'barcode_diagnostic',
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Diagnóstico Códigos de Barras'),
                    backgroundColor: Colors.orange,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BarcodeDiagnosticTool(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'connection_diagnostic',
                    icon: const Icon(Icons.wifi),
                    label: const Text('Diagnóstico de Conexión'),
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ConnectionDiagnosticTool(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'api_config',
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurar API'),
                    backgroundColor: Colors.indigo,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ApiConfigTool(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'barcode_issue_fix',
                    icon: const Icon(Icons.build_circle),
                    label: const Text('Arreglar Códigos de Barras'),
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BarcodeIssueFixTool(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingAddButton(
              onPressed: () async {
                print('🔄 [NAV] Navegando a agregar producto desde dashboard...');
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const StoreAddProductScreen(),
                  ),
                );
                if (result == true && mounted) {
                  print('✅ [NAV] Producto guardado desde dashboard, recargando...');
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
            )
          : null,
    );
  }
}
