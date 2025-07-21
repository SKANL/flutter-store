import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class StoreAdvancedReportsScreen extends StatefulWidget {
  const StoreAdvancedReportsScreen({super.key});

  @override
  State<StoreAdvancedReportsScreen> createState() => _StoreAdvancedReportsScreenState();
}

class _StoreAdvancedReportsScreenState extends State<StoreAdvancedReportsScreen> {
  bool _isLoading = false;
  String? _error;
  
  List<Product> _productosStatus = [];
  List<Product> _stockBajo = [];
  List<Product> _expiringProducts = [];
  Map<String, dynamic> _salesData = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        ApiService.getProductosStatus(), // Usa la nueva vista optimizada
        ApiService.getLowStockProducts(), // Usa la nueva vista optimizada
        ApiService.getExpiringProducts(),
        ApiService.getSalesAndProfitSummary(), // Nuevas estadísticas de ventas
      ]);

      setState(() {
        _productosStatus = futures[0] as List<Product>;
        _stockBajo = futures[1] as List<Product>;
        _expiringProducts = futures[2] as List<Product>;
        _salesData = futures[3] as Map<String, dynamic>;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar reportes: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Avanzados'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar reportes',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando reportes avanzados...'),
          ],
        ),
      );
    }

    if (_error != null) {
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
              onPressed: _loadReports,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesAndProfitSection(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildStockBajoSection(),
          const SizedBox(height: 24),
          _buildProductosExpirandoSection(),
          const SizedBox(height: 24),
          _buildEstadisticasGenerales(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalProducts = _productosStatus.length;
    final porCaducar = _productosStatus.where((p) => p.status == ProductStatus.expiringSoon).length;
    final caducados = _productosStatus.where((p) => p.status == ProductStatus.expired).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Productos',
                value: totalProducts.toString(),
                icon: Icons.inventory,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Stock Bajo',
                value: _stockBajo.length.toString(),
                icon: Icons.warning,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Por Caducar',
                value: porCaducar.toString(),
                icon: Icons.schedule,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Caducados',
                value: caducados.toString(),
                icon: Icons.dangerous,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBajoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Productos con Stock Bajo (${_stockBajo.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _stockBajo.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('¡Excelente! No hay productos con stock bajo.'),
                    ],
                  ),
                ),
              )
            : Column(
                children: _stockBajo.map((product) => _buildProductCard(
                  product,
                  subtitle: 'Stock actual: ${product.stockActual} - Mínimo: ${product.stockMinimo}',
                  statusColor: Colors.orange,
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildProductosExpirandoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Productos Por Caducar (${_expiringProducts.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _expiringProducts.isEmpty
            ? const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('¡Perfecto! No hay productos próximos a caducar.'),
                    ],
                  ),
                ),
              )
            : Column(
                children: _expiringProducts.map((product) => _buildProductCard(
                  product,
                  subtitle: _getExpiryText(product),
                  statusColor: Colors.amber,
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildProductCard(Product product, {required String subtitle, required Color statusColor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.inventory_2, color: statusColor),
        ),
        title: Text(
          product.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text(
              'Categoría: ${product.categoryName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${product.precioVenta.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Ganancia: \$${product.profitPerUnit.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasGenerales() {
    final valorTotal = _productosStatus.fold(0.0, (sum, product) => sum + product.totalInventoryValue);
    final gananciaPotencial = _productosStatus.fold(0.0, (sum, product) => sum + product.totalProfit);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.analytics, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Estadísticas Generales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow('Valor Total del Inventario', '\$${valorTotal.toStringAsFixed(2)}', Icons.attach_money),
                const Divider(),
                _buildStatRow('Ganancia Potencial', '\$${gananciaPotencial.toStringAsFixed(2)}', Icons.trending_up),
                const Divider(),
                _buildStatRow('Productos Únicos', '${_productosStatus.length}', Icons.category),
                const Divider(),
                _buildStatRow('Promedio Precio Venta', '\$${_getAveragePrice().toStringAsFixed(2)}', Icons.price_check),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  String _getExpiryText(Product product) {
    if (product.fechaCaducidad != null) {
      final daysLeft = product.fechaCaducidad!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) {
        return 'CADUCADO hace ${-daysLeft} días';
      } else if (daysLeft == 0) {
        return 'CADUCA HOY';
      } else {
        return 'Caduca en $daysLeft días';
      }
    }
    return 'Sin fecha de caducidad';
  }

  double _getAveragePrice() {
    if (_productosStatus.isEmpty) return 0.0;
    final total = _productosStatus.fold(0.0, (sum, product) => sum + product.precioVenta);
    return total / _productosStatus.length;
  }

  Widget _buildSalesAndProfitSection() {
    if (_salesData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💰 Ventas y Beneficios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Cards de estadísticas de ventas
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Ventas Totales',
                value: '${_salesData['totalVentas'] ?? 0}',
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Ventas Hoy',
                value: '${_salesData['ventasHoy'] ?? 0}',
                icon: Icons.today,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Ingresos Totales',
                value: '\$${(_salesData['ingresosTotales'] ?? 0.0).toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Ingresos Hoy',
                value: '\$${(_salesData['ingresosHoy'] ?? 0.0).toStringAsFixed(2)}',
                icon: Icons.today,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Ganancia Potencial',
                value: '\$${(_salesData['gananciasPotenciales'] ?? 0.0).toStringAsFixed(2)}',
                icon: Icons.trending_up,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Promedio x Venta',
                value: '\$${(_salesData['promedioVentaDiaria'] ?? 0.0).toStringAsFixed(2)}',
                icon: Icons.analytics,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Top productos
        if (_salesData['topProductos'] != null && (_salesData['topProductos'] as List).isNotEmpty) ...[
          const Text(
            'Top Productos por Stock',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (_salesData['topProductos'] as List).length,
              itemBuilder: (context, index) {
                final producto = (_salesData['topProductos'] as List)[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    producto['nombre'] ?? 'N/A',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Stock: ${producto['stockActual']} | Ganancia: \$${(producto['gananciaUnitaria'] ?? 0.0).toStringAsFixed(2)}'),
                  trailing: Text(
                    '\$${(producto['precioVenta'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
