import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';
import '../core/inventory_state.dart';
import '../models/product.dart';
import '../models/categoria.dart';
import '../models/proveedor.dart';
import '../models/producto_caducidad.dart';
import '../services/api_service.dart';
import '../components/custom_text_field.dart';
import 'store_dashboard_screen.dart';

class StoreAddProductScreen extends StatefulWidget {
  final Product? productToEdit;

  const StoreAddProductScreen({
    super.key,
    this.productToEdit,
  });

  @override
  State<StoreAddProductScreen> createState() => _StoreAddProductScreenState();
}

class _StoreAddProductScreenState extends State<StoreAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  
  DateTime? _expiryDate;
  bool _isLoading = false;
  int? _selectedCategoryId;
  int? _selectedProviderId;
  
  // Listas cargadas de la API
  List<Categoria> _categorias = [];
  List<Proveedor> _proveedores = [];  bool get _isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Cargar categorías y proveedores de la API
      final futures = await Future.wait([
        ApiService.getCategorias(),
        ApiService.getProveedores(),
      ]);
      
      setState(() {
        _categorias = futures[0] as List<Categoria>;
        _proveedores = futures[1] as List<Proveedor>;
      });
      
      // Si estamos editando, llenar los campos con los datos existentes
      if (_isEditing) {
        final product = widget.productToEdit!;
        _nameController.text = product.nombre;
        _barcodeController.text = product.codigoDeBarra ?? '';
        _stockController.text = product.stockActual.toString();
        _minStockController.text = product.stockMinimo.toString();
        _costPriceController.text = product.precioCosto.toString();
        _salePriceController.text = product.precioVenta.toString();
        _expiryDate = product.fechaCaducidad;
        _selectedCategoryId = product.idCategoria;
        _selectedProviderId = product.idProveedor;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading, // Prevenir navegación durante loading
      onPopInvokedWithResult: (didPop, result) {
        if (_isLoading) {
          print('🚫 [NAV] Navegación bloqueada durante loading');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Editar Producto' : 'Agregar Producto',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // Desactivar botón de back durante loading
          leading: _isLoading 
              ? Container(
                  margin: const EdgeInsets.all(14),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : null,
        ),
        body: AbsorbPointer(
          absorbing: _isLoading, // Bloquear todas las interacciones durante loading
          child: Column(
            children: [
              // Indicador de progreso si está cargando
              if (_isLoading)
                Column(
                  children: [
                    const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    Container(
                      width: double.infinity,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _isEditing ? 'Actualizando producto...' : 'Guardando producto...',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Formulario
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Información básica
                        _buildSectionTitle('Información Básica'),
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          label: 'Nombre del Producto',
                          controller: _nameController,
                          isRequired: true,
                          hintText: 'Ej. Leche Entera 1L',
                          prefixIcon: const Icon(Icons.shopping_bag),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildCategoryField(),
                        
                        const SizedBox(height: 16),
                        
                        _buildProviderField(),
                        
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          label: 'Código de Barras',
                          controller: _barcodeController,
                          hintText: 'Opcional - Escanea o ingresa manualmente',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.qr_code),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _scanBarcode,
                            tooltip: 'Escanear código de barras',
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Inventario
                        _buildSectionTitle('Inventario'),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Stock Actual',
                                controller: _stockController,
                                isRequired: true,
                                keyboardType: TextInputType.number,
                                hintText: '0',
                                prefixIcon: const Icon(Icons.inventory),
                                validator: _validatePositiveInteger,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                label: 'Stock Mínimo',
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                hintText: '5',
                                prefixIcon: const Icon(Icons.warning),
                                validator: _validatePositiveInteger,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Precios
                        _buildSectionTitle('Precios'),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Precio de Costo',
                                controller: _costPriceController,
                                isRequired: true,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                hintText: '0.00',
                                prefixIcon: const Icon(Icons.money_off),
                                validator: _validatePositiveDouble,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                label: 'Precio de Venta',
                                controller: _salePriceController,
                                isRequired: true,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                hintText: '0.00',
                                prefixIcon: const Icon(Icons.attach_money),
                                validator: _validateSalePrice,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Mostrar ganancia calculada
                        _buildProfitDisplay(),
                        
                        const SizedBox(height: 32),
                        
                        // Fecha de caducidad
                        _buildSectionTitle('Información Adicional'),
                        const SizedBox(height: 16),
                        
                        _buildExpiryDateField(),
                        
                        const SizedBox(height: 32),
                        
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isEditing ? 'Actualizando...' : 'Guardando...',
                                            style: AppTextStyles.button,
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _isEditing ? 'Actualizar' : 'Guardar',
                                        style: AppTextStyles.button,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.title.copyWith(
        fontSize: 18,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Categoría',
            style: AppTextStyles.description.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            hintText: 'Selecciona una categoría',
            prefixIcon: const Icon(Icons.category),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          items: _categorias.map((categoria) {
            return DropdownMenuItem<int>(
              value: categoria.idCategoria,
              child: Text(categoria.nombre),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'La categoría es obligatoria';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProviderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proveedor (Opcional)',
          style: AppTextStyles.description.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedProviderId,
          decoration: InputDecoration(
            hintText: 'Selecciona un proveedor',
            prefixIcon: const Icon(Icons.business),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Sin proveedor'),
            ),
            ..._proveedores.map((proveedor) {
              return DropdownMenuItem<int>(
                value: proveedor.idProveedor,
                child: Text(proveedor.nombre),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedProviderId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildProfitDisplay() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _costPriceController,
      builder: (context, costValue, _) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _salePriceController,
          builder: (context, saleValue, _) {
            final cost = double.tryParse(costValue.text) ?? 0;
            final sale = double.tryParse(saleValue.text) ?? 0;
            final profit = sale - cost;
            final margin = sale > 0 ? (profit / sale * 100) : 0;

            Color color = Colors.grey.shade600;
            if (profit > 0) color = Colors.green;
            if (profit < 0) color = Colors.red;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ganancia por unidad:',
                        style: AppTextStyles.small.copyWith(color: color),
                      ),
                      Text(
                        '\$${profit.toStringAsFixed(2)}',
                        style: AppTextStyles.description.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Margen de ganancia:',
                        style: AppTextStyles.small.copyWith(color: color),
                      ),
                      Text(
                        '${margin.toStringAsFixed(1)}%',
                        style: AppTextStyles.description.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpiryDateField() {
    return InkWell(
      onTap: _selectExpiryDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de Caducidad (Opcional)',
                    style: AppTextStyles.description.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _expiryDate != null
                        ? _formatDate(_expiryDate!)
                        : 'Seleccionar fecha',
                    style: AppTextStyles.small.copyWith(
                      color: _expiryDate != null ? AppColors.text : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (_expiryDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => _expiryDate = null),
                tooltip: 'Quitar fecha',
              ),
          ],
        ),
      ),
    );
  }

  String? _validatePositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    final intValue = int.tryParse(value.trim());
    if (intValue == null || intValue < 0) {
      return 'Debe ser un número entero positivo';
    }
    return null;
  }

  String? _validatePositiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    final doubleValue = double.tryParse(value.trim());
    if (doubleValue == null || doubleValue < 0) {
      return 'Debe ser un número positivo';
    }
    return null;
  }

  String? _validateSalePrice(String? value) {
    final baseValidation = _validatePositiveDouble(value);
    if (baseValidation != null) return baseValidation;

    final salePrice = double.parse(value!.trim());
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;

    if (costPrice > 0 && salePrice < costPrice) {
      return 'El precio de venta debería ser mayor al costo';
    }

    return null;
  }

  void _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  void _scanBarcode() {
    // TODO: Implementar escáner de códigos de barras
    // Por ahora mostramos un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de escáner próximamente disponible'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _saveProduct() async {
    print('🔄 [SAVE] Iniciando validación...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [SAVE] Validación del formulario falló');
      return;
    }

    if (_selectedCategoryId == null) {
      print('❌ [SAVE] Categoría no seleccionada');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar una categoría'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('✅ [SAVE] Validación completada');
    _formKey.currentState!.save();

    // Mostrar loading
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    final bool wasEditing = _isEditing;
    bool operationSuccess = false;

    try {
      print('🔄 [SAVE] Iniciando guardado de producto...');
      
      final product = Product(
        idProducto: wasEditing ? widget.productToEdit!.idProducto : null,
        nombre: _nameController.text.trim(),
        codigoDeBarra: _barcodeController.text.trim().isEmpty 
            ? null 
            : _barcodeController.text.trim(),
        precioCosto: double.parse(_costPriceController.text.trim()),
        precioVenta: double.parse(_salePriceController.text.trim()),
        stockActual: int.parse(_stockController.text.trim()),
        stockMinimo: int.parse(_minStockController.text.trim()),
        idCategoria: _selectedCategoryId!,
        idProveedor: _selectedProviderId,
        caducidades: _expiryDate != null ? [
          ProductoCaducidad(
            idProducto: 0, // Se actualizará en el servicio
            fechaCaducidad: _expiryDate!,
          )
        ] : [],
        createdAt: wasEditing ? widget.productToEdit!.createdAt : DateTime.now(),
      );

      print('📦 [SAVE] Producto creado: ${product.nombre}');

      // Verificar que tenemos acceso al estado
      if (!mounted) {
        print('⚠️ [SAVE] Widget desmontado antes de guardar');
        return;
      }

      final state = InventoryProvider.of(context);
      if (state != null) {
        print('🔧 [SAVE] Estado encontrado, ${wasEditing ? "actualizando" : "agregando"} producto...');
        
        if (wasEditing) {
          await state.updateProduct(product);
          print('✅ [SAVE] Producto actualizado exitosamente');
        } else {
          await state.addProduct(product);
          print('✅ [SAVE] Producto agregado exitosamente');
        }

        operationSuccess = true;
      } else {
        print('❌ [SAVE] Estado de inventario no encontrado');
        throw Exception('Estado de inventario no disponible');
      }
    } catch (e) {
      print('❌ [SAVE] Error durante el guardado: $e');
      operationSuccess = false;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar producto: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      print('� [SAVE] Finalizando proceso de guardado...');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Manejar navegación después de la operación
    if (operationSuccess && mounted) {
      await _handleSuccessfulSaveNew(wasEditing);
    }
  }

  Future<void> _handleSuccessfulSaveNew(bool wasEditing) async {
    print('🎉 [SAVE] Operación exitosa, manejando navegación mejorada...');
    
    // Mostrar mensaje de éxito con un tiempo más corto
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasEditing ? 'Producto actualizado correctamente' : 'Producto guardado correctamente'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    // Esperar a que termine cualquier animación pendiente
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Verificar contexto antes de navegación
    if (!mounted || !context.mounted) {
      print('⚠️ [SAVE] Contexto no válido para navegación');
      return;
    }

    // Usar WidgetsBinding para asegurar que la navegación ocurra en el próximo frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !context.mounted) {
        print('⚠️ [SAVE] Contexto perdido en postFrameCallback');
        return;
      }
      
      print('🔄 [SAVE] Ejecutando navegación en próximo frame...');
      
      try {
        // Esperar un frame adicional para asegurar estabilidad
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted && context.mounted) {
          // Método más robusto: usar pushNamedAndRemoveUntil
          print('🔄 [SAVE] Navegando con pushNamedAndRemoveUntil...');
          
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
          
          print('✅ [SAVE] Navegación completada exitosamente');
        }
      } catch (e) {
        print('❌ [SAVE] Error en navegación principal: $e');
        
        // Método de respaldo con MaterialPageRoute
        try {
          if (mounted && context.mounted) {
            print('🔄 [SAVE] Intentando método de respaldo...');
            
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const StoreDashboardScreen(),
                settings: const RouteSettings(name: '/dashboard'),
              ),
              (route) => false,
            );
            
            print('✅ [SAVE] Método de respaldo exitoso');
          }
        } catch (e2) {
          print('❌ [SAVE] Error en método de respaldo: $e2');
          
          // Último recurso: pop simple con delay adicional
          if (mounted && context.mounted) {
            try {
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.of(context).pop(true);
              print('✅ [SAVE] Pop simple como último recurso');
            } catch (e3) {
              print('❌ [SAVE] Todos los métodos de navegación fallaron: $e3');
            }
          }
        }
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

  Future<void> _handleSuccessfulSave(bool wasEditing) async {
    print('🎉 [SAVE] Operación exitosa, manejando navegación...');
    
    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasEditing ? 'Producto actualizado correctamente' : 'Producto guardado correctamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Dar tiempo para que se muestre el SnackBar
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Intentar diferentes métodos de navegación en orden de preferencia
    if (mounted && context.mounted) {
      print('🔄 [SAVE] Intentando navegación método 1: Navigator.pop()');
      
      try {
        // Método 1: Navigator.pop normal
        Navigator.of(context).pop(true);
        print('✅ [SAVE] Navegación exitosa con pop()');
        return;
      } catch (e1) {
        print('❌ [SAVE] Error en método 1: $e1');
        
        try {
          print('🔄 [SAVE] Intentando navegación método 2: Navigator.maybePop()');
          // Método 2: maybePop
          final didPop = await Navigator.of(context).maybePop(true);
          if (didPop) {
            print('✅ [SAVE] Navegación exitosa con maybePop()');
            return;
          }
        } catch (e2) {
          print('❌ [SAVE] Error en método 2: $e2');
        }

        try {
          print('🔄 [SAVE] Intentando navegación método 3: pushReplacementNamed()');
          // Método 3: Reemplazar con dashboard
          Navigator.of(context).pushReplacementNamed('/dashboard');
          print('✅ [SAVE] Navegación exitosa con pushReplacementNamed()');
          return;
        } catch (e3) {
          print('❌ [SAVE] Error en método 3: $e3');
        }

        try {
          print('� [SAVE] Intentando navegación método 4: pushAndRemoveUntil()');
          // Método 4: Ir al dashboard limpiando el stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const StoreDashboardScreen()),
            (route) => false,
          );
          print('✅ [SAVE] Navegación exitosa con pushAndRemoveUntil()');
          return;
        } catch (e4) {
          print('❌ [SAVE] Error en método 4: $e4');
          print('🚨 [SAVE] Todos los métodos de navegación fallaron');
        }
      }
    } else {
      print('⚠️ [SAVE] Contexto no válido para navegación');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
