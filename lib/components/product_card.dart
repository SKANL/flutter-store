import 'package:flutter/material.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;
  final bool showActions;
  final bool showDeleteButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
    this.showActions = true,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('product_${product.idProducto}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y status - Optimizado con RepaintBoundary
              RepaintBoundary(
                child: _buildHeaderSection(),
              ),
              
              const SizedBox(height: 12),
              
              // Información de precios - Separado para evitar rebuilds
              RepaintBoundary(
                child: _buildPricesSection(),
              ),
              
              const SizedBox(height: 12),
              
              // Stock y información adicional
              RepaintBoundary(
                child: _buildStockSection(),
              ),
              
              if (showActions) ...[
                const SizedBox(height: 16),
                // Botones de acción - Separados para optimización
                RepaintBoundary(
                  child: _buildActionsSection(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.nombre,
                style: AppTextStyles.title.copyWith(
                  fontSize: 18,
                  color: AppColor.colorTexto,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColor.colorPrimario.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
                child: Text(
                  product.categoryName,
                  style: AppTextStyles.small.copyWith(
                    color: AppColor.colorPrimario,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Status de caducidad optimizado
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildPricesSection() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            'Precio Venta',
            '\$${product.precioVenta.toStringAsFixed(2)}',
            AppColor.colorTexto,
            Icons.attach_money,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Ganancia/u',
            '\$${product.profitPerUnit.toStringAsFixed(2)}',
            product.profitPerUnit > 0 ? Colors.green : Colors.red,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Stock Actual',
                '${product.stockActual}',
                product.isLowStock ? Colors.red : AppColor.colorTexto,
                product.isLowStock ? Icons.warning : Icons.inventory_2,
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Stock Mínimo',
                '${product.stockMinimo}',
                AppColor.colorTexto,
                Icons.low_priority,
              ),
            ),
          ],
        ),
        if (product.codigoDeBarra != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.qr_code,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                product.codigoDeBarra!,
                style: AppTextStyles.small.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
        
        if (product.fechaCaducidad != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.event,
                size: 16,
                color: _getExpiryColor(),
              ),
              const SizedBox(width: 8),
              Text(
                'Caduca: ${_formatDate(product.fechaCaducidad!)}',
                style: AppTextStyles.small.copyWith(
                  color: _getExpiryColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColor.colorPrimario,
            ),
          ),
        if (onViewDetails != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onViewDetails,
            icon: const Icon(Icons.info, size: 18),
            label: const Text('Ver'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ],
        if (onDelete != null && showDeleteButton) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.description.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;
    
    switch (product.status) {
      case ProductStatus.expired:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        text = 'Vencido';
        break;
      case ProductStatus.expiringSoon:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Por vencer';
        break;
      case ProductStatus.notExpiring:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Activo';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getExpiryColor() {
    if (product.fechaCaducidad == null) return Colors.grey;
    
    final now = DateTime.now();
    final daysUntilExpiry = product.fechaCaducidad!.difference(now).inDays;
    
    if (daysUntilExpiry < 0) return Colors.red;
    if (daysUntilExpiry <= 7) return Colors.orange;
    if (daysUntilExpiry <= 30) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
