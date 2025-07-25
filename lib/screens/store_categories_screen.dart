import 'package:flutter/material.dart';
import '../core/inventory_state.dart';
import '../models/categoria.dart';
import '../services/api_service.dart';

class StoreCategoriesScreen extends StatefulWidget {
  const StoreCategoriesScreen({super.key});

  @override
  State<StoreCategoriesScreen> createState() => _StoreCategoriesScreenState();
}

class _StoreCategoriesScreenState extends State<StoreCategoriesScreen> {
  bool _isLoading = false;
  Categoria? _editingCategoria;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _refreshCategorias(InventoryState state) async {
    setState(() => _isLoading = true);
    await state.loadCategorias();
    setState(() => _isLoading = false);
  }

  void _showCategoriaForm({Categoria? categoria, required InventoryState state}) {
    if (categoria != null) {
      _nameController.text = categoria.nombre;
      _descController.text = categoria.descripcion ?? '';
    } else {
      _nameController.clear();
      _descController.clear();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = _nameController.text.trim();
              if (nombre.isEmpty) return;
              setState(() => _isLoading = true);
              if (categoria == null) {
                await state.createCategoria(Categoria(nombre: nombre, descripcion: _descController.text.trim()));
              } else {
                await state.updateCategoria(categoria.copyWith(nombre: nombre, descripcion: _descController.text.trim()));
              }
              setState(() => _isLoading = false);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategoria(Categoria categoria, InventoryState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Seguro que deseas eliminar "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await state.deleteCategoria(categoria.idCategoria!);
              setState(() => _isLoading = false);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = InventoryProvider.of(context);
    final categorias = state?.categorias ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshCategorias(state!),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (context, i) {
                final cat = categorias[i];
                return ListTile(
                  title: Text(cat.nombre),
                  subtitle: Text(cat.descripcion ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showCategoriaForm(categoria: cat, state: state!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDeleteCategoria(cat, state!),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoriaForm(state: state!),
        child: const Icon(Icons.add),
      ),
    );
  }
}
