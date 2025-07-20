import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';
import '../core/inventory_state.dart';
import '../models/product.dart';
import '../models/detalle_venta.dart';
import '../services/api_service.dart';
import '../services/camera_permission_service.dart';
import '../components/sale_item_card.dart';
import '../components/custom_text_field.dart';
import '../components/custom_barcode_scanner.dart';

class StoreRegisterSaleScreen extends StatefulWidget {
  const StoreRegisterSaleScreen({super.key});

  @override
  State<StoreRegisterSaleScreen> createState() => _StoreRegisterSaleScreenState();
}

class _StoreRegisterSaleScreenState extends State<StoreRegisterSaleScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<DetalleVenta> _carritoItems = [];
  final Map<int, Product> _productos = {}; // Cache de productos
  
  bool _isLoading = false;
  bool _isProcessingSale = false;
  String? _errorMessage;
  List<Product> _searchResults = [];

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double get _total => _carritoItems.fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> _searchProductByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await ApiService.getProductByBarcode(barcode.trim());
      if (product != null) {
        await _addProductToCart(product);
        _barcodeController.clear();
        
        // Mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto "${product.nombre}" agregado al carrito'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'No se encontró ningún producto con el código: $barcode';
        });
        
        // Limpiar el mensaje de error después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar producto: ${e.toString()}';
      });
      
      // Limpiar el mensaje de error después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProductsByName(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Debounce: solo buscar después de 500ms sin cambios
    final currentQuery = query;
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Si el query cambió durante el delay, no hacer la búsqueda
    if (_searchController.text != currentQuery) return;

    try {
      final products = await ApiService.searchProducts(query.trim());
      
      // Verificar si el query aún es el mismo antes de actualizar
      if (_searchController.text == currentQuery) {
        setState(() {
          _searchResults = products.take(10).toList(); // Limitar resultados
        });
      }
    } catch (e) {
      print('Error al buscar productos: $e');
      if (_searchController.text == currentQuery) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  Future<void> _addProductToCart(Product product) async {
    // Verificar stock disponible
    if (product.stockActual <= 0) {
      setState(() {
        _errorMessage = 'El producto "${product.nombre}" no tiene stock disponible';
      });
      
      // Limpiar el mensaje de error después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
      return;
    }

    // Buscar si el producto ya está en el carrito
    final existingIndex = _carritoItems.indexWhere((item) => item.idProducto == product.idProducto);
    
    if (existingIndex >= 0) {
      // Si ya existe, aumentar cantidad
      final existingItem = _carritoItems[existingIndex];
      final newQuantity = existingItem.cantidad + 1;
      
      if (newQuantity <= product.stockActual) {
        setState(() {
          _carritoItems[existingIndex] = existingItem.copyWith(cantidad: newQuantity);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Stock insuficiente para "${product.nombre}". Stock disponible: ${product.stockActual}';
        });
        
        // Limpiar el mensaje de error después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    } else {
      // Si no existe, agregarlo
      final detalle = DetalleVenta(
        idProducto: product.idProducto!,
        cantidad: 1,
        precioUnitario: product.precioVenta,
        nombreProducto: product.nombre,
        codigoBarras: product.codigoDeBarra,
      );
      
      setState(() {
        _carritoItems.add(detalle);
        _productos[product.idProducto!] = product;
        _searchResults = [];
        _searchController.clear();
        _errorMessage = null;
      });
    }
  }

  void _updateItemQuantity(int index, int newQuantity) {
    final item = _carritoItems[index];
    final product = _productos[item.idProducto];
    
    if (newQuantity <= 0) {
      _removeItemFromCart(index);
      return;
    }

    if (product != null && newQuantity > product.stockActual) {
      setState(() {
        _errorMessage = 'Stock insuficiente. Stock disponible: ${product.stockActual}';
      });
      
      // Limpiar el mensaje de error después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
      return;
    }

    setState(() {
      _carritoItems[index] = item.copyWith(cantidad: newQuantity);
      _errorMessage = null;
    });
  }

  void _removeItemFromCart(int index) {
    setState(() {
      _carritoItems.removeAt(index);
      _errorMessage = null;
    });
  }

  void _clearCart() {
    setState(() {
      _carritoItems.clear();
      _searchResults = [];
      _searchController.clear();
      _barcodeController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _processSale() async {
    if (_carritoItems.isEmpty) {
      setState(() {
        _errorMessage = 'El carrito está vacío. Agrega productos para continuar.';
      });
      return;
    }

    // Protección adicional contra doble-click
    if (_isProcessingSale) {
      print('⚠️ [UI] Intento de doble procesamiento de venta bloqueado');
      return;
    }

    setState(() {
      _isProcessingSale = true;
      _errorMessage = null;
    });

    try {
      print('🚀 [UI] Iniciando proceso de venta desde UI...');
      final venta = await ApiService.createVentaCompleta(_carritoItems);
      print('✅ [UI] Venta procesada desde UI exitosamente');
      
      // Refrescar el inventario después de la venta exitosa
      try {
        final inventoryState = InventoryProvider.of(context);
        if (inventoryState != null) {
          await inventoryState.refreshProducts();
          print('✅ [UI] Inventario actualizado después de la venta');
        }
      } catch (refreshError) {
        print('⚠️ [UI] Error refrescando inventario: $refreshError');
        // No fallar la venta por error de refresco
      }
      
      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Venta registrada exitosamente! Total: \$${venta.total.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Limpiar carrito
      _clearCart();
      
    } catch (e) {
      print('❌ [UI] Error procesando venta: $e');
      setState(() {
        _errorMessage = 'Error al procesar la venta: $e';
      });
    } finally {
      setState(() {
        _isProcessingSale = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.point_of_sale, color: Colors.orange, size: 32),
                    SizedBox(width: 12),
                    Text('Registrar Venta', style: AppTextStyles.title),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Búsqueda por código de barras
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _barcodeController,
                        label: 'Código de barras',
                        prefixIcon: const Icon(Icons.qr_code_scanner),
                        keyboardType: TextInputType.text,
                        onSubmitted: _searchProductByBarcode,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _scanBarcodeForSale,
                          tooltip: 'Escanear código de barras',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading 
                          ? null 
                          : () => _searchProductByBarcode(_barcodeController.text),
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: const Text('Buscar'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Búsqueda por nombre
                CustomTextField(
                  controller: _searchController,
                  label: 'Buscar producto por nombre',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: _searchProductsByName,
                ),

                // Mensaje de error
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Resultados de búsqueda
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              color: Colors.white,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: Text(
                        product.nombre.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(product.nombre),
                    subtitle: Text(
                      'Precio: \$${product.precioVenta.toStringAsFixed(2)} - Stock: ${product.stockActual}',
                    ),
                    trailing: product.stockActual > 0
                        ? IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                            onPressed: () => _addProductToCart(product),
                          )
                        : const Icon(Icons.remove_shopping_cart, color: Colors.grey),
                    onTap: product.stockActual > 0 
                        ? () => _addProductToCart(product)
                        : null,
                  );
                },
              ),
            ),

          // Lista del carrito
          Expanded(
            child: _carritoItems.isEmpty
                ? const Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Carrito vacío',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Escanea o busca productos para agregar',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _carritoItems.length,
                    itemBuilder: (context, index) {
                      final item = _carritoItems[index];
                      final product = _productos[item.idProducto];
                      
                      return SaleItemCard(
                        detalle: item,
                        product: product,
                        onRemove: () => _removeItemFromCart(index),
                        onQuantityChanged: (newQuantity) => _updateItemQuantity(index, newQuantity),
                      );
                    },
                  ),
          ),

          // Footer con total y acciones
          if (_carritoItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${_carritoItems.length} productos',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Total: \$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessingSale ? null : _clearCart,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessingSale ? null : _processSale,
                          icon: _isProcessingSale
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(_isProcessingSale ? 'Procesando...' : 'Procesar Venta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _scanBarcodeForSale() async {
    try {
      // Verificar y solicitar permisos de cámara
      final hasPermission = await CameraPermissionService.requestPermissionWithUI(context);
      if (!hasPermission) {
        return;
      }

      // Abrir el escáner
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => CustomBarcodeScanner(
            onBarcodeScanned: (barcode) {
              Navigator.of(context).pop(barcode);
            },
            title: 'Escanear Producto',
            subtitle: 'Escanea el código de barras del producto a vender',
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        // Actualizar el campo de texto y buscar el producto
        setState(() {
          _barcodeController.text = result;
        });
        
        // Buscar automáticamente el producto
        await _searchProductByBarcode(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir escáner: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
