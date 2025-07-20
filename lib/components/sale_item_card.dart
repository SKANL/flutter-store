import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/detalle_venta.dart';

class SaleItemCard extends StatelessWidget {
  final DetalleVenta detalle;
  final Product? product;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onQuantityChanged;

  const SaleItemCard({
    super.key,
    required this.detalle,
    this.product,
    this.onRemove,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.nombre ?? detalle.nombreProducto ?? 'Producto #${detalle.idProducto}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: \$${detalle.precioUnitario.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (product?.codigoDeBarra != null)
                    Text(
                      'Código: ${product!.codigoDeBarra}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            
            // Controles de cantidad
            Row(
              children: [
                IconButton(
                  onPressed: detalle.cantidad > 1
                      ? () => onQuantityChanged?.call(detalle.cantidad - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 20,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${detalle.cantidad}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: (product?.stockActual ?? 0) > detalle.cantidad
                      ? () => onQuantityChanged?.call(detalle.cantidad + 1)
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 20,
                ),
              ],
            ),
            
            // Subtotal y botón eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${detalle.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
