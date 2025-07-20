import 'package:flutter/material.dart';
import 'package:store_manager/core/app_theme.dart';
import 'package:store_manager/core/inventory_state.dart';
import 'package:store_manager/screens/store_dashboard_screen.dart';

void main() {
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
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 [INIT] Inicializando aplicación...'); // Debug log
      
      // Cargar datos en paralelo para mejor rendimiento
      final futures = [
        widget.inventoryState.loadCategorias(),
        widget.inventoryState.loadProveedores(),
        widget.inventoryState.loadProducts(),
      ];
      
      print('⏳ [INIT] Ejecutando cargas en paralelo...'); // Debug log
      await Future.wait(futures);
      
      print('✅ [INIT] Todas las cargas completadas exitosamente'); // Debug log
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('❌ [INIT] Error durante la inicialización: $e'); // Debug log
      if (mounted) {
        setState(() {
          _initError = 'Error al conectar con el servidor: ${e.toString()}';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando datos...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error de Conexión',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _initError = null;
                  });
                  _initializeApp();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return const StoreDashboardScreen();
  }
}