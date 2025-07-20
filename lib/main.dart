import 'package:flutter/material.dart';
import 'package:store_manager/core/app_theme.dart';
import 'package:store_manager/core/inventory_state.dart';
import 'package:store_manager/core/app_logger.dart';
import 'package:store_manager/screens/store_dashboard_screen.dart';

void main() {
  // Configurar el sistema de logging
  AppLogger.setLogLevel(LogLevel.debug);
  AppLogger.info('Iniciando Store Manager App', 'MAIN');
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crear instancia de InventoryState y cargar datos iniciales
    final inventoryState = InventoryState();
    
    return InventoryProvider(
      notifier: inventoryState,
      child: MaterialApp(
        title: 'Store Manager',
        theme: AppTheme.lightTheme,
        home: AppInitializer(inventoryState: inventoryState),
        debugShowCheckedModeBanner: false,
        // Añadir rutas con nombre para navegación de respaldo
        routes: {
          '/dashboard': (context) => const StoreDashboardScreen(),
        },
      ),
    );
  }
}

// Widget para inicializar datos de la app
class AppInitializer extends StatefulWidget {
  final InventoryState inventoryState;
  
  const AppInitializer({
    super.key,
    required this.inventoryState,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Mostrar UI inmediatamente sin bloquear
    AppLogger.debug('Iniciando carga de datos en background', 'INIT');

    // Cargar datos en background sin bloquear el UI
    try {
      // Usar microtask para no bloquear el hilo principal
      await Future.microtask(() async {
        await widget.inventoryState.initializeData();
      });
      
      AppLogger.info('Datos cargados exitosamente', 'INIT');
    } catch (e, stackTrace) {
      AppLogger.error('Error durante la carga en background', 'INIT', e, stackTrace);
      
      if (mounted) {
        // Mostrar snackbar con error pero mantener la UI funcional
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _initializeApp,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Siempre mostrar StoreDashboardScreen directamente
    // Los datos se cargan en background sin bloquear UI
    return const StoreDashboardScreen();
  }
}
