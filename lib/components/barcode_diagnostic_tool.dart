import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class BarcodeDiagnosticTool extends StatefulWidget {
  const BarcodeDiagnosticTool({super.key});

  @override
  State<BarcodeDiagnosticTool> createState() => _BarcodeDiagnosticToolState();
}

class _BarcodeDiagnosticToolState extends State<BarcodeDiagnosticTool> {
  String _diagnosticResults = 'Listo para diagnóstico...';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnóstico Código de Barras'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Herramienta de Diagnóstico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esta herramienta creará un producto de prueba con código de barras '
                      'y verificará si se guarda correctamente en la base de datos.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runDiagnostic,
              icon: _isRunning 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Ejecutando...' : 'Ejecutar Diagnóstico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _diagnosticResults,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _diagnosticResults = 'Iniciando diagnóstico...\n\n';
    });

    try {
      await _addLog('🔍 === DIAGNÓSTICO DE CÓDIGO DE BARRAS ===');
      await _addLog('📅 Fecha: ${DateTime.now()}');
      await _addLog('🌐 API URL: ${ApiConfig.currentBaseUrl}');
      await _addLog('');

      // Paso 1: Crear producto de prueba
      await _addLog('📝 PASO 1: Creando producto de prueba...');
      final testProduct = Product(
        nombre: 'PRODUCTO_TEST_${DateTime.now().millisecondsSinceEpoch}',
        codigoDeBarra: '1234567890123', // Código de prueba
        precioCosto: 10.0,
        precioVenta: 15.0,
        stockActual: 100,
        stockMinimo: 5,
        idCategoria: 1, // Asumir que existe categoría 1
      );

      await _addLog('✅ Producto de prueba creado:');
      await _addLog('   - Nombre: ${testProduct.nombre}');
      await _addLog('   - Código: ${testProduct.codigoDeBarra}');
      await _addLog('');

      // Paso 2: Enviar a la API
      await _addLog('📤 PASO 2: Enviando a la API...');
      Product createdProduct;
      try {
        createdProduct = await ApiService.createProduct(testProduct);
        await _addLog('✅ Producto creado exitosamente');
        await _addLog('   - ID: ${createdProduct.idProducto}');
        await _addLog('   - Nombre: ${createdProduct.nombre}');
        await _addLog('   - Código recibido: "${createdProduct.codigoDeBarra}"');
      } catch (e) {
        await _addLog('❌ Error creando producto: $e');
        return;
      }
      await _addLog('');

      // Paso 3: Verificar obtención
      await _addLog('📥 PASO 3: Obteniendo producto de la API...');
      try {
        if (createdProduct.idProducto != null) {
          final retrievedProduct = await ApiService.getProductById(createdProduct.idProducto!);
          if (retrievedProduct != null) {
            await _addLog('✅ Producto obtenido exitosamente');
            await _addLog('   - ID: ${retrievedProduct.idProducto}');
            await _addLog('   - Nombre: ${retrievedProduct.nombre}');
            await _addLog('   - Código obtenido: "${retrievedProduct.codigoDeBarra}"');
          } else {
            await _addLog('❌ No se pudo obtener el producto');
          }
        }
      } catch (e) {
        await _addLog('❌ Error obteniendo producto: $e');
      }
      await _addLog('');

      // Paso 4: Obtener todos los productos y verificar
      await _addLog('📋 PASO 4: Verificando en lista completa...');
      try {
        final allProducts = await ApiService.getAllProducts();
        final foundProduct = allProducts
            .where((p) => p.idProducto == createdProduct.idProducto)
            .firstOrNull;
        
        if (foundProduct != null) {
          await _addLog('✅ Producto encontrado en lista completa');
          await _addLog('   - Código en lista: "${foundProduct.codigoDeBarra}"');
        } else {
          await _addLog('❌ Producto NO encontrado en lista completa');
        }
      } catch (e) {
        await _addLog('❌ Error obteniendo lista de productos: $e');
      }
      await _addLog('');

      // Paso 5: Análisis de resultados
      await _addLog('📊 PASO 5: Análisis de resultados');
      final originalCode = testProduct.codigoDeBarra;
      final receivedCode = createdProduct.codigoDeBarra;
      
      await _addLog('   - Código enviado: "$originalCode"');
      await _addLog('   - Código recibido: "$receivedCode"');
      
      if (originalCode == receivedCode && receivedCode != null && receivedCode.isNotEmpty) {
        await _addLog('✅ DIAGNÓSTICO: CÓDIGO DE BARRAS FUNCIONA CORRECTAMENTE');
      } else if (receivedCode == null || receivedCode.isEmpty) {
        await _addLog('❌ PROBLEMA: El código de barras NO se está guardando');
        await _addLog('   🔧 POSIBLE CAUSA: Backend no procesa el campo codigoDeBarra');
        await _addLog('   🔧 SOLUCIÓN: Verificar endpoint y base de datos en el backend');
      } else {
        await _addLog('⚠️ PROBLEMA: El código se está modificando');
        await _addLog('   🔧 POSIBLE CAUSA: Backend está transformando el valor');
      }
      await _addLog('');

      // Paso 6: Limpieza
      await _addLog('🧹 PASO 6: Limpiando producto de prueba...');
      try {
        if (createdProduct.idProducto != null) {
          await ApiService.deleteProduct(createdProduct.idProducto!);
          await _addLog('✅ Producto de prueba eliminado');
        }
      } catch (e) {
        await _addLog('⚠️ No se pudo eliminar el producto de prueba: $e');
      }

      await _addLog('');
      await _addLog('🎯 === DIAGNÓSTICO COMPLETADO ===');

    } catch (e) {
      await _addLog('❌ Error general en diagnóstico: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _addLog(String message) async {
    setState(() {
      _diagnosticResults += '$message\n';
    });
    
    // Pequeña pausa para permitir la actualización de la UI
    await Future.delayed(const Duration(milliseconds: 10));
  }
}
