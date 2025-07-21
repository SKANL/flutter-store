# 🧪 GUÍA DE PRUEBAS - Solución Códigos de Barras

## 🎯 **CÓMO PROBAR LA SOLUCIÓN**

### **📱 Paso 1: Abrir la Herramienta de Solución**
1. **Abrir la aplicación Flutter**
2. **Ir a la pantalla de "Inventario"** 
3. **En la esquina inferior derecha, ver 5 botones flotantes:**
   - 🔧 **Arreglar Códigos de Barras** (ROJO) ← **ESTE ES EL IMPORTANTE**
   - ⚙️ Configuración API (índigo)
   - 🌐 Diagnóstico Conexión (azul)
   - 🐛 Diagnóstico General (naranja)
   - ➕ Agregar Producto (verde)

4. **Presionar el botón rojo 🔧 "Arreglar Códigos de Barras"**

### **📊 Paso 2: Ejecutar Diagnóstico Completo**
1. **En la pantalla que se abre, presionar "Diagnosticar y Arreglar"**
2. **Esperar que termine todos los pasos (aproximadamente 1-2 minutos)**
3. **Observar cada paso del diagnóstico:**

**Pasos que ejecutará:**
- 1️⃣ **Cargar productos actuales** → Muestra cuántos productos hay
- 2️⃣ **Identificar productos sin código** → Lista productos que necesitan código
- 3️⃣ **Generar códigos faltantes** → Asigna códigos EAN-13 válidos
- 4️⃣ **Probar búsqueda por código** → Verifica que la búsqueda funcione
- 5️⃣ **Crear producto de prueba** → Crea producto temporal con código
- 6️⃣ **Verificar código guardado** → **PASO CLAVE** - verifica si backend guarda
- 7️⃣ **Limpiar producto de prueba** → Elimina datos temporales
- 8️⃣ **Reporte final** → Muestra conclusiones y recomendaciones

### **📋 Paso 3: Interpretar Resultados**

#### **✅ ESCENARIO 1: Todo Funciona (Resultado Ideal)**
**Resultados esperados:**
- ✅ Todos los pasos en verde
- ✅ "Código guardado correctamente"
- ✅ "Búsqueda funciona correctamente"
- ✅ "TODOS LOS PROBLEMAS RESUELTOS!"

**Qué significa:**
- El problema de búsqueda ya está corregido ✅
- El backend está guardando códigos correctamente ✅
- Productos sin código han sido actualizados ✅

#### **❌ ESCENARIO 2: Problema de Backend**
**Resultados que indicarían problema:**
- ❌ "Código NO se guardó en la base de datos"
- ❌ "El problema está en el backend"
- 🔴 "PROBLEMA CRÍTICO: Backend no guarda códigos de barras"

**Qué significa:**
- Flutter envía los datos correctamente ✅
- **Backend C# NO está guardando el campo `codigoDeBarra`** ❌
- Necesitas revisar tu código C# (detalles abajo)

---

## 🔧 **SI HAY PROBLEMA DE BACKEND - QUÉ HACER**

### **📝 Verificaciones en tu API de C#:**

#### **1. Verificar Controlador de Productos**
```csharp
[HttpPost("productos")]
public async Task<IActionResult> CreateProduct([FromBody] ProductCreateDto productDto)
{
    // ⚠️ AGREGAR ESTE LOGGING TEMPORAL PARA DEBUG:
    Console.WriteLine($"🔍 Código recibido: '{productDto.CodigoDeBarra}'");
    Console.WriteLine($"🔍 Tipo del campo: {productDto.CodigoDeBarra?.GetType()}");
    
    var product = new Product
    {
        Nombre = productDto.Nombre,
        CodigoDeBarra = productDto.CodigoDeBarra,  // ← ¿EXISTE ESTA LÍNEA?
        PrecioCosto = productDto.PrecioCosto,
        PrecioVenta = productDto.PrecioVenta,
        // ... otros campos
    };
    
    Console.WriteLine($"🔍 Código antes de guardar: '{product.CodigoDeBarra}'");
    
    _context.Productos.Add(product);
    await _context.SaveChangesAsync();
    
    // ⚠️ VERIFICAR DESPUÉS DE GUARDAR:
    var savedProduct = await _context.Productos
        .FirstOrDefaultAsync(p => p.Id == product.Id);
    Console.WriteLine($"🔍 Código después de guardar: '{savedProduct.CodigoDeBarra}'");
    
    return Ok(savedProduct);
}
```

#### **2. Verificar DTO (Data Transfer Object)**
```csharp
public class ProductCreateDto
{
    public string Nombre { get; set; }
    public string? CodigoDeBarra { get; set; }  // ← ¿EXISTE ESTA PROPIEDAD?
    public decimal PrecioCosto { get; set; }
    public decimal PrecioVenta { get; set; }
    public int StockActual { get; set; }
    public int StockMinimo { get; set; }
    public int IdCategoria { get; set; }
    public int? IdProveedor { get; set; }
}
```

#### **3. Verificar Modelo de Base de Datos**
```csharp
public class Product
{
    public int Id { get; set; }
    public string Nombre { get; set; }
    public string? CodigoDeBarra { get; set; }  // ← ¿EXISTE ESTA PROPIEDAD?
    public decimal PrecioCosto { get; set; }
    public decimal PrecioVenta { get; set; }
    // ... otros campos
}
```

#### **4. Verificar Configuración Entity Framework**
```csharp
// En tu DbContext o configuración Fluent API
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Product>(entity =>
    {
        entity.Property(e => e.CodigoDeBarra)
            .HasMaxLength(20)
            .IsRequired(false);  // Permitir null
    });
}
```

#### **5. Verificar Tabla en Base de Datos**
```sql
-- Verificar que la columna existe:
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'productos' 
AND COLUMN_NAME LIKE '%codigo%';

-- Si no existe, crearla:
ALTER TABLE productos 
ADD codigoDeBarra VARCHAR(20) NULL;
```

---

## ✅ **PRUEBAS DESPUÉS DE CORREGIR BACKEND**

### **1. Volver a Ejecutar la Herramienta**
- Repetir Paso 1 y 2 de arriba
- Ahora debería mostrar todo en verde ✅

### **2. Prueba Manual - Agregar Producto con Código**
1. **Ir a "Inventario" → Botón verde ➕**
2. **Llenar datos del producto**
3. **En "Código de Barras" escribir: `1234567890123`**
4. **Guardar producto**
5. **Recargar aplicación**
6. **Verificar que el código se mantiene**

### **3. Prueba Manual - Búsqueda por Código**
1. **Ir a "Registrar Venta"**
2. **En "Buscar por código" escribir: `1234567890123`**
3. **Presionar buscar**
4. **Verificar que encuentra el producto correcto**
5. **NO debería encontrar Coca Cola si busca otro código**

### **4. Prueba de Escaneo (Si tienes código impreso)**
1. **Ir a "Inventario" → Agregar producto**
2. **Presionar icono de cámara en campo "Código de Barras"**
3. **Escanear código real**
4. **Guardar producto**
5. **Ir a "Registrar Venta" y escanear el mismo código**
6. **Verificar que encuentra el producto correcto**

---

## 🎯 **RESULTADO FINAL ESPERADO**

### **✅ Funcionalidad Correcta:**
1. **En Inventario:**
   - Productos muestran códigos de barras
   - Se pueden generar códigos nuevos automáticamente
   - Se pueden escanear códigos de productos existentes
   - Los códigos se guardan permanentemente

2. **En Registrar Venta:**
   - Búsqueda por código encuentra el producto exacto
   - NO encuentra productos que no tengan ese código
   - Ya NO siempre encuentra Coca Cola
   - Escaneo en tiempo real funciona correctamente

3. **En Base de Datos:**
   - Los códigos se almacenan correctamente
   - Los códigos persisten después de reiniciar
   - No hay pérdida de datos

---

## 📞 **SI NECESITAS AYUDA**

### **Información para Debug:**
1. **Logs de la herramienta de diagnóstico** (checkbox "Mostrar logs detallados")
2. **Logs del servidor C#** (Console.WriteLine agregados arriba)
3. **Estado de la base de datos** (consulta SQL para verificar columna)

### **Archivos Clave Modificados:**
- `lib/services/api_service.dart` → Bug de búsqueda corregido
- `lib/components/barcode_issue_fix_tool.dart` → Nueva herramienta
- `lib/screens/store_dashboard_screen.dart` → Botón rojo agregado

**¡La herramienta roja 🔧 te dirá exactamente qué está mal y cómo solucionarlo!** 🎯
