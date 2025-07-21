import 'package:flutter/material.dart';
import '../models/proveedor.dart';
import '../services/api_service.dart';
import '../components/custom_text_field.dart';

class StoreProvidersManagementScreen extends StatefulWidget {
  const StoreProvidersManagementScreen({super.key});

  @override
  State<StoreProvidersManagementScreen> createState() => _StoreProvidersManagementScreenState();
}

class _StoreProvidersManagementScreenState extends State<StoreProvidersManagementScreen> {
  List<Proveedor> _proveedores = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProveedores();
  }

  Future<void> _loadProveedores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final proveedores = await ApiService.getProveedores();
      setState(() {
        _proveedores = proveedores;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar proveedores: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showProveedorDialog({Proveedor? proveedor}) async {
    final isEditing = proveedor != null;
    final formKey = GlobalKey<FormState>();
    
    final nombreController = TextEditingController(text: proveedor?.nombre ?? '');
    final telefonoController = TextEditingController(text: proveedor?.telefono ?? '');
    final emailController = TextEditingController(text: proveedor?.email ?? '');
    final direccionController = TextEditingController(text: proveedor?.direccion ?? '');
    
    String? diaRecarga = proveedor?.diaRecarga;
    
    final diasSemana = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
    ];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Nombre del Proveedor',
                    controller: nombreController,
                    hintText: 'Ej: Coca Cola',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.trim().length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'Teléfono (10 dígitos)',
                    controller: telefonoController,
                    hintText: 'Ej: 5512345678',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                          return 'Debe ser exactamente 10 dígitos';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'Email',
                    controller: emailController,
                    hintText: 'contacto@proveedor.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Formato de email inválido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'Dirección',
                    controller: direccionController,
                    hintText: 'Calle, colonia, ciudad',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: diaRecarga,
                    decoration: const InputDecoration(
                      labelText: 'Día de Recarga',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Sin día específico'),
                      ),
                      ...diasSemana.map((dia) => DropdownMenuItem<String>(
                        value: dia,
                        child: Text(dia),
                      ),),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        diaRecarga = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _saveProveedor(
        isEditing: isEditing,
        proveedor: proveedor,
        nombre: nombreController.text.trim(),
        telefono: telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        direccion: direccionController.text.trim().isEmpty ? null : direccionController.text.trim(),
        diaRecarga: diaRecarga,
      );
    }
  }

  Future<void> _saveProveedor({
    required bool isEditing,
    Proveedor? proveedor,
    required String nombre,
    String? telefono,
    String? email,
    String? direccion,
    String? diaRecarga,
  }) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final nuevoProveedor = Proveedor(
        idProveedor: isEditing ? proveedor!.idProveedor : null,
        nombre: nombre,
        telefono: telefono,
        email: email,
        direccion: direccion,
        diaRecarga: diaRecarga,
      );

      if (isEditing) {
        await ApiService.updateProveedor(nuevoProveedor);
        _showSnackBar('Proveedor actualizado exitosamente', isError: false);
      } else {
        await ApiService.createProveedor(nuevoProveedor);
        _showSnackBar('Proveedor creado exitosamente', isError: false);
      }

      await _loadProveedores();
    } catch (e) {
      setState(() {
        _error = 'Error al ${isEditing ? 'actualizar' : 'crear'} proveedor: $e';
      });
      _showSnackBar(_error!, isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProveedor(Proveedor proveedor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar el proveedor "${proveedor.nombre}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
          _error = null;
        });

        await ApiService.deleteProveedor(proveedor.idProveedor!);
        _showSnackBar('Proveedor eliminado exitosamente', isError: false);
        await _loadProveedores();
      } catch (e) {
        setState(() {
          _error = 'Error al eliminar proveedor: $e';
        });
        _showSnackBar(_error!, isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proveedores'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadProveedores,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProveedorDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _proveedores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando proveedores...'),
          ],
        ),
      );
    }

    if (_error != null && _proveedores.isEmpty) {
      return Center(
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
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProveedores,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_proveedores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay proveedores registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Toca el botón + para agregar el primer proveedor'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isLoading)
          const LinearProgressIndicator(),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.business, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '${_proveedores.length} proveedor${_proveedores.length != 1 ? 'es' : ''} registrado${_proveedores.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _proveedores.length,
            itemBuilder: (context, index) {
              final proveedor = _proveedores[index];
              return _buildProveedorCard(proveedor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProveedorCard(Proveedor proveedor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proveedor.nombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showProveedorDialog(proveedor: proveedor);
                    } else if (value == 'delete') {
                      _deleteProveedor(proveedor);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (proveedor.telefono != null) ...[
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(proveedor.telefono!),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (proveedor.email != null) ...[
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(proveedor.email!),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (proveedor.direccion != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(proveedor.direccion!)),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (proveedor.diaRecarga != null) ...[
              Row(
                children: [
                  const Icon(Icons.refresh, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Recarga: ${proveedor.diaRecarga}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
