# Funcionalidad de Registro de Ventas - Store Flutter App

## Archivos Implementados

### 1. Modelos de Datos
- **`lib/models/venta.dart`**: Modelo para las ventas
  - `idVenta`: ID único de la venta
  - `fecha`: Fecha de la venta
  - `total`: Total de la venta
  - `detalles`: Lista de detalles de la venta (opcional)

- **`lib/models/detalle_venta.dart`**: Modelo para los detalles de venta
  - `idDetalle`: ID único del detalle
  - `idVenta`: ID de la venta asociada
  - `idProducto`: ID del producto vendido
  - `cantidad`: Cantidad vendida
  - `precioUnitario`: Precio unitario al momento de la venta
  - `nombreProducto`: Nombre del producto (para referencia)
  - `codigoBarras`: Código de barras del producto (para referencia)

### 2. Servicios API
- **Métodos agregados a `lib/services/api_service.dart`**:
  - `getAllVentas()`: Obtener todas las ventas
  - `getVentaById(id)`: Obtener una venta por ID
  - `createVenta(venta)`: Crear una nueva venta
  - `getDetallesVentaByVentaId(idVenta)`: Obtener detalles de una venta
  - `createDetalleVenta(detalle)`: Crear un nuevo detalle de venta
  - `getProductByBarcode(barcode)`: Buscar producto por código de barras
  - `createVentaCompleta(detalles)`: Crear venta completa con detalles

### 3. Componentes UI
- **`lib/components/sale_item_card.dart`**: Widget para mostrar items del carrito
  - Muestra información del producto
  - Controles para aumentar/disminuir cantidad
  - Botón para eliminar del carrito
  - Muestra subtotal del item

- **Modificaciones a `lib/components/custom_text_field.dart`**:
  - Agregado soporte para `onSubmitted`
  - Agregado soporte para `inputFormatters`

### 4. Pantalla Principal
- **`lib/screens/store_register_sale_screen.dart`**: Pantalla completa de registro de ventas

## Funcionalidades Implementadas

### 🔍 Búsqueda de Productos
1. **Por código de barras**: 
   - Campo numérico para ingresar código
   - Búsqueda automática al presionar Enter o botón
   - Solo acepta números

2. **Por nombre**:
   - Búsqueda en tiempo real
   - Muestra hasta 10 resultados
   - Búsqueda insensible a mayúsculas/minúsculas

### 🛒 Gestión del Carrito
- Agregar productos al carrito
- Verificación de stock disponible
- Modificar cantidades (+ / -)
- Eliminar productos del carrito
- Cálculo automático de subtotales y total
- Limpiar carrito completo

### 💳 Procesamiento de Ventas
- Validación de carrito no vacío
- Creación de venta en la base de datos
- Creación automática de detalles de venta
- Actualización automática de stock (via triggers de BD)
- Confirmación visual del éxito
- Limpieza automática del carrito tras venta exitosa

### 🎯 Características Adicionales
- Manejo de errores con mensajes informativos
- Estados de loading durante operaciones
- Interfaz responsive y user-friendly
- Validación de stock en tiempo real
- Prevención de ventas con stock insuficiente

## Integración con Base de Datos

La implementación está preparada para trabajar con los endpoints de tu API de C#:

- `GET /api/ventas` - Listar ventas
- `POST /api/ventas` - Crear venta
- `GET /api/ventas/{id}` - Obtener venta por ID
- `GET /api/detallesventa` - Listar detalles de venta
- `POST /api/detallesventa` - Crear detalle de venta

Los triggers de la base de datos se encargarán automáticamente de:
- Validar stock suficiente antes de la venta
- Actualizar stock después de la venta
- Calcular totales automáticamente

## Preparación para Escáner de Código de Barras

La implementación actual está preparada para integrar fácilmente un escáner de código de barras:

- El método `_searchProductByBarcode()` acepta cualquier string
- La UI tiene un campo dedicado para códigos de barras
- Solo necesitarás agregar un botón de escáner que llene el campo automáticamente

## Próximos Pasos Sugeridos

1. **Integrar escáner de código de barras**
2. **Agregar impresión de tickets**
3. **Implementar descuentos y promociones**
4. **Agregar métodos de pago múltiples**
5. **Implementar historial de ventas**
6. **Agregar reportes de ventas**

La base está sólida y extensible para futuras mejoras! 🚀
