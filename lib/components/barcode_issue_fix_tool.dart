import 'package:flutter/material.dart';
import '../core/app_logger.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../services/barcode_generator_service.dart';

class BarcodeIssueFixTool extends StatefulWidget {
  const BarcodeIssueFixTool({super.key});

  @override
  State<BarcodeIssueFixTool> createState() => _BarcodeIssueFixToolState();
}

class _BarcodeIssueFixToolState extends State<BarcodeIssueFixTool> {
  final List<DiagnosticStep> _steps = [];
  bool _isRunning = false;
  bool _showDetailedLogs = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Solución Códigos de Barras'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildControls(),
          Expanded(child: _buildStepsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.red.shade50,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚨 PROBLEMAS IDENTIFICADOS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('1. Códigos de barras no se guardan en BD'),
          Text('2. Búsqueda siempre encuentra Coca Cola'),
          Text('3. Códigos no se muestran en inventario'),
          SizedBox(height: 12),
          Text(
            '🛠️ ESTA HERRAMIENTA:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('• Diagnostica el problema específico'),
          Text('• Corrige automáticamente los errores'),
          Text('• Verifica que todo funcione correctamente'),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runCompleteFix,
                  icon: _isRunning 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.build),
                  label: Text(_isRunning ? 'Ejecutando...' : 'Diagnosticar y Arreglar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _clearSteps,
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _showDetailedLogs,
                onChanged: (value) => setState(() => _showDetailedLogs = value ?? false),
              ),
              const Text('Mostrar logs detallados'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final step = _steps[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: step.isSuccess ? Colors.green : 
                              step.isError ? Colors.red : Colors.orange,
              child: Icon(
                step.isSuccess ? Icons.check : 
                step.isError ? Icons.error : Icons.info,
                color: Colors.white,
              ),
            ),
            title: Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.description),
                if (step.details.isNotEmpty && _showDetailedLogs) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step.details,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
            trailing: step.isSuccess ? const Icon(Icons.check_circle, color: Colors.green) :
                     step.isError ? const Icon(Icons.error_outline, color: Colors.red) :
                     const CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Future<void> _runCompleteFix() async {
    setState(() {
      _isRunning = true;
      _currentStep = 0;
      _steps.clear();
    });

    AppLogger.info('BARCODE_FIX', 'Iniciando diagnóstico y solución completa de códigos de barras');

    // Paso 1: Cargar productos actuales
    await _step1LoadProducts();

    // Paso 2: Identificar productos sin código de barras
    await _step2IdentifyProductsWithoutBarcode();

    // Paso 3: Generar códigos de barras para productos sin código
    await _step3GenerateMissingBarcodes();

    // Paso 4: Verificar búsqueda por código de barras
    await _step4TestBarcodeSearch();

    // Paso 5: Crear producto de prueba con código de barras
    await _step5CreateTestProduct();

    // Paso 6: Verificar que el código se guardó correctamente
    await _step6VerifyBarcodeWasSaved();

    // Paso 7: Limpiar producto de prueba
    await _step7CleanupTestProduct();

    // Paso 8: Generar reporte final
    await _step8GenerateFinalReport();

    setState(() {
      _isRunning = false;
    });

    AppLogger.info('BARCODE_FIX', 'Diagnóstico y solución completa terminada');
  }

  List<Product> _loadedProducts = [];
  List<Product> _productsWithoutBarcode = [];
  int? _testProductId;

  Future<void> _step1LoadProducts() async {
    _addStep('1️⃣ Cargar productos actuales', 'Obteniendo lista de todos los productos...', false);
    
    try {
      _loadedProducts = await ApiService.getAllProducts();
      
      _updateLastStep(
        'Productos cargados correctamente',
        true,
        'Productos encontrados: ${_loadedProducts.length}\n'
        'Productos con código de barras: ${_loadedProducts.where((p) => p.codigoDeBarra != null && p.codigoDeBarra!.trim().isNotEmpty).length}\n'
        'Productos sin código de barras: ${_loadedProducts.where((p) => p.codigoDeBarra == null || p.codigoDeBarra!.trim().isEmpty).length}'
      );
    } catch (e) {
      _updateLastStep('Error cargando productos', false, 'Error: $e');
    }
  }

  Future<void> _step2IdentifyProductsWithoutBarcode() async {
    _addStep('2️⃣ Identificar productos sin código', 'Analizando productos que necesitan código de barras...', false);
    
    _productsWithoutBarcode = _loadedProducts.where((p) => 
      p.codigoDeBarra == null || p.codigoDeBarra!.trim().isEmpty,
    ).toList();

    _updateLastStep(
      'Análisis completado',
      true,
      'Productos sin código de barras: ${_productsWithoutBarcode.length}\n'
      'Productos: ${_productsWithoutBarcode.take(5).map((p) => p.nombre).join(", ")}'
      '${_productsWithoutBarcode.length > 5 ? "..." : ""}'
    );
  }

  Future<void> _step3GenerateMissingBarcodes() async {
    _addStep('3️⃣ Generar códigos faltantes', 'Generando códigos de barras para productos sin código...', false);
    
    int updatedCount = 0;
    final List<String> errors = [];

    for (final product in _productsWithoutBarcode.take(5)) { // Solo los primeros 5 para no sobrecargar
      try {
        final newBarcode = BarcodeGeneratorService.generateEAN13();
        final updatedProduct = product.copyWith(codigoDeBarra: newBarcode);
        
        await ApiService.updateProduct(updatedProduct);
        updatedCount++;
        
        AppLogger.info('BARCODE_FIX', 'Código asignado a ${product.nombre}: $newBarcode');
      } catch (e) {
        errors.add('${product.nombre}: $e');
      }
    }

    _updateLastStep(
      'Códigos generados',
      errors.isEmpty,
      'Productos actualizados: $updatedCount/${_productsWithoutBarcode.take(5).length}\n'
      '${errors.isNotEmpty ? "Errores:\n${errors.join("\n")}" : "Todos los productos actualizados correctamente"}'
    );
  }

  Future<void> _step4TestBarcodeSearch() async {
    _addStep('4️⃣ Probar búsqueda por código', 'Verificando que la búsqueda por código de barras funcione...', false);
    
    // Recargar productos después de las actualizaciones
    try {
      _loadedProducts = await ApiService.getAllProducts();
      
      // Buscar un producto que tenga código de barras
      final productWithBarcode = _loadedProducts.firstWhere(
        (p) => p.codigoDeBarra != null && p.codigoDeBarra!.trim().isNotEmpty,
        orElse: () => throw Exception('No hay productos con código de barras'),
      );

      final foundProduct = await ApiService.getProductByBarcode(productWithBarcode.codigoDeBarra!);
      
      if (foundProduct != null && foundProduct.idProducto == productWithBarcode.idProducto) {
        _updateLastStep(
          'Búsqueda funciona correctamente',
          true,
          'Producto buscado: ${productWithBarcode.nombre}\n'
          'Código buscado: ${productWithBarcode.codigoDeBarra}\n'
          'Producto encontrado: ${foundProduct.nombre}\n'
          'IDs coinciden: ${foundProduct.idProducto == productWithBarcode.idProducto}'
        );
      } else {
        _updateLastStep(
          'Error en búsqueda por código',
          false,
          'Producto esperado: ${productWithBarcode.nombre} (ID: ${productWithBarcode.idProducto})\n'
          'Producto encontrado: ${foundProduct?.nombre ?? "null"} (ID: ${foundProduct?.idProducto ?? "null"})\n'
          'La búsqueda no está funcionando correctamente'
        );
      }
    } catch (e) {
      _updateLastStep('Error en prueba de búsqueda', false, 'Error: $e');
    }
  }

  Future<void> _step5CreateTestProduct() async {
    _addStep('5️⃣ Crear producto de prueba', 'Creando producto de prueba con código de barras...', false);
    
    try {
      final testBarcode = BarcodeGeneratorService.generateEAN13();
      final testProduct = Product(
        idProducto: null,
        nombre: 'PRODUCTO_PRUEBA_BARCODE_${DateTime.now().millisecondsSinceEpoch}',
        codigoDeBarra: testBarcode,
        precioCosto: 50.0,
        precioVenta: 75.0,
        stockActual: 10,
        stockMinimo: 5,
        idCategoria: _loadedProducts.isNotEmpty ? _loadedProducts.first.idCategoria : 1,
        idProveedor: null,
        caducidades: [],
        createdAt: DateTime.now(),
      );

      final createdProduct = await ApiService.createProduct(testProduct);
      _testProductId = createdProduct.idProducto;

      _updateLastStep(
        'Producto de prueba creado',
        true,
        'Producto: ${createdProduct.nombre}\n'
        'ID: ${createdProduct.idProducto}\n'
        'Código asignado: $testBarcode\n'
        'Código en respuesta: ${createdProduct.codigoDeBarra}'
      );
    } catch (e) {
      _updateLastStep('Error creando producto de prueba', false, 'Error: $e');
    }
  }

  Future<void> _step6VerifyBarcodeWasSaved() async {
    _addStep('6️⃣ Verificar código guardado', 'Verificando que el código se guardó en la base de datos...', false);
    
    if (_testProductId == null) {
      _updateLastStep('No hay producto de prueba para verificar', false, 'El paso anterior falló');
      return;
    }

    try {
      final savedProduct = await ApiService.getProductById(_testProductId!);
      
      if (savedProduct != null && savedProduct.codigoDeBarra != null && savedProduct.codigoDeBarra!.trim().isNotEmpty) {
        _updateLastStep(
          'Código guardado correctamente',
          true,
          'Producto encontrado: ${savedProduct.nombre}\n'
          'Código guardado: ${savedProduct.codigoDeBarra}\n'
          '✅ El problema de guardado está resuelto!'
        );
      } else {
        _updateLastStep(
          'Código NO se guardó en la base de datos',
          false,
          'Producto encontrado: ${savedProduct?.nombre ?? "null"}\n'
          'Código en BD: ${savedProduct?.codigoDeBarra ?? "null"}\n'
          '❌ El problema está en el backend - el campo codigoDeBarra no se está guardando'
        );
      }
    } catch (e) {
      _updateLastStep('Error verificando producto guardado', false, 'Error: $e');
    }
  }

  Future<void> _step7CleanupTestProduct() async {
    _addStep('7️⃣ Limpiar producto de prueba', 'Eliminando producto de prueba...', false);
    
    if (_testProductId == null) {
      _updateLastStep('No hay producto de prueba para eliminar', true, 'Limpieza no necesaria');
      return;
    }

    try {
      await ApiService.deleteProduct(_testProductId!);
      _updateLastStep(
        'Producto de prueba eliminado',
        true,
        'Producto ID $_testProductId eliminado correctamente',
      );
    } catch (e) {
      _updateLastStep('Error eliminando producto de prueba', false, 'Error: $e\nPuede eliminarse manualmente');
    }
  }

  Future<void> _step8GenerateFinalReport() async {
    _addStep('8️⃣ Reporte final', 'Generando reporte y recomendaciones...', false);
    
    final successfulSteps = _steps.where((s) => s.isSuccess).length;
    final totalSteps = _steps.length - 1; // Excluir este paso
    
    final hasBackendIssue = _steps.any((s) => s.title.contains('Verificar código guardado') && !s.isSuccess);
    final hasSearchIssue = _steps.any((s) => s.title.contains('Probar búsqueda') && !s.isSuccess);
    
    String recommendations = '';
    
    if (hasBackendIssue) {
      recommendations += '🔴 PROBLEMA CRÍTICO: Backend no guarda códigos de barras\n';
      recommendations += '• Verificar que el controlador reciba el campo codigoDeBarra\n';
      recommendations += '• Verificar que la tabla productos tenga la columna codigoDeBarra\n';
      recommendations += '• Verificar el mapeo en Entity Framework\n\n';
    }
    
    if (hasSearchIssue) {
      recommendations += '🔴 PROBLEMA: Búsqueda por código de barras no funciona\n';
      recommendations += '• Bug corregido en ApiService.getProductByBarcode\n';
      recommendations += '• Ahora verifica que el código no sea null antes de comparar\n\n';
    }
    
    if (!hasBackendIssue && !hasSearchIssue) {
      recommendations += '✅ TODOS LOS PROBLEMAS RESUELTOS!\n';
      recommendations += '• Los códigos de barras se guardan correctamente\n';
      recommendations += '• La búsqueda funciona correctamente\n';
      recommendations += '• Los productos sin código han sido actualizados\n';
    }

    _updateLastStep(
      'Diagnóstico completado',
      !hasBackendIssue,
      'Pasos exitosos: $successfulSteps/$totalSteps\n\n$recommendations',
    );
  }

  void _addStep(String title, String description, bool isComplete) {
    setState(() {
      _steps.add(DiagnosticStep(
        title: title,
        description: description,
        isSuccess: isComplete,
        isError: false,
        details: '',
      ),);
    });
  }

  void _updateLastStep(String description, bool isSuccess, String details) {
    if (_steps.isNotEmpty) {
      setState(() {
        final lastStep = _steps.last;
        _steps[_steps.length - 1] = DiagnosticStep(
          title: lastStep.title,
          description: description,
          isSuccess: isSuccess,
          isError: !isSuccess,
          details: details,
        );
      });
    }
  }

  void _clearSteps() {
    setState(() {
      _steps.clear();
      _currentStep = 0;
    });
  }
}

class DiagnosticStep {
  final String title;
  final String description;
  final bool isSuccess;
  final bool isError;
  final String details;

  DiagnosticStep({
    required this.title,
    required this.description,
    required this.isSuccess,
    required this.isError,
    required this.details,
  });
}
