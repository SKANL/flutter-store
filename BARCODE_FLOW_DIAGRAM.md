# 🔄 Diagrama de Flujo - Escaneo de Códigos de Barras

```
┌─────────────────────────────────────────────────────────────────────┐
│                        🏪 PANTALLA PRINCIPAL                        │
│                     (Dashboard/Inventario/Ventas)                   │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  📋 FORMULARIO CON CAMPO CÓDIGO                     │
│                                                                     │
│  ┌───────────────────────────────┐  ┌──────────────────────────────┐ │
│  │       📝 Campo Texto          │  │      📷 Botón Escaneo        │ │
│  │    [Código de Barras]         │  │        [📷 Cámara]           │ │
│  └───────────────────────────────┘  └──────────────┬───────────────┘ │
└─────────────────────────────────────────────────────┼─────────────────┘
                                                      │
                                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    🎯 MODAL DE OPCIONES                             │
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │   📷 Escanear   │  │  🏷️ Generar    │  │   ⌨️ Manual        │  │
│  │     Código      │  │     Código      │  │    Ingresar         │  │
│  └─────────┬───────┘  └─────────┬───────┘  └─────────┬───────────┘  │
└───────────┼─────────────────────┼─────────────────────┼──────────────┘
            │                     │                     │
            ▼                     ▼                     ▼
┌───────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│   📸 ESCÁNER      │  │  🔧 GENERADOR       │  │   📝 DIALOGO        │
│                   │  │                     │  │                     │
│  ┌─────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │
│  │     📹      │  │  │  │ Tipo: EAN-13  │  │  │  │ [Texto Input] │  │
│  │   Cámara    │  │  │  │ ┌───────────┐ │  │  │  │               │  │
│  │   en vivo   │  │  │  │ │ ║║║ ║║║   │ │  │  │  │ [Confirmar]   │  │
│  │             │  │  │  │ │ ║║║ ║║║   │ │  │  │  └───────────────┘  │
│  │ [Marco GUI] │  │  │  │ └───────────┘ │  │  │                     │
│  └─────────────┘  │  │  └───────────────┘  │  └─────────────────────┘
│                   │  │                     │
│  📱 Detecta código│  │  🎲 Genera código   │
└─────────┬─────────┘  └───────────┬─────────┘
          │                        │
          └────────────────────────┼────────────────────────┐
                                   │                        │
                                   ▼                        ▼
                    ┌─────────────────────────────────────────────────────┐
                    │               🔍 PROCESAMIENTO                      │
                    │                                                     │
                    │  1️⃣ Validar formato del código                     │
                    │  2️⃣ Detectar tipo (EAN-13, UPC-A, etc.)           │
                    │  3️⃣ Búsqueda en API por código                     │
                    │  4️⃣ Mostrar resultado al usuario                   │
                    └─────────────────┬───────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────────────────────────┐
                    │                📊 RESULTADO                        │
                    │                                                     │
                    │  ✅ ÉXITO                    ❌ ERROR               │
                    │  • Campo llenado             • Producto no existe   │
                    │  • Producto encontrado       • Código inválido     │
                    │  • Feedback positivo         • Sin stock           │
                    │  • Continuar flujo           • Retry disponible    │
                    └─────────────────────────────────────────────────────┘
```

## 🎯 **Puntos Clave de la Implementación**

### 📦 **Para Inventario (Agregar/Editar Productos)**
```
Usuario → Campo Código → 📷 Botón → Modal Opciones → Resultado → Campo Llenado
```

### 🛒 **Para Ventas (Registro de Ventas)**
```
Usuario → Campo Código → 📷 Botón → Escáner → Auto-buscar → Agregar al Carrito
```

### 🔍 **Para Búsquedas (Filtro de Inventario)**
```
Usuario → Campo Búsqueda → Texto/Código → Filtro en Tiempo Real → Resultados
```

## ⚙️ **Componentes Técnicos**

```
CustomBarcodeScanner
├── 📱 MobileScannerController
├── 🎨 UI Overlay personalizado
├── 🔆 Control de flash
├── 📳 Feedback háptico
└── ⌨️ Input manual fallback

BarcodeGeneratorService
├── 🔢 Algoritmos de validación
├── 🎲 Generación aleatoria
├── ✅ Cálculo de checksums
└── 🏷️ Detección de tipos

CameraPermissionService
├── 📝 Solicitud de permisos
├── 🚫 Manejo de denegaciones
├── ⚙️ Navegación a Settings
└── 🎯 UI explicativa
```

## 🔄 **Estados del Sistema**

```
IDLE → PERMISOS → ESCANEANDO → PROCESANDO → RESULTADO
  │        │          │           │           │
  │        │          │           │           ├─→ ÉXITO → CONTINUAR
  │        │          │           │           └─→ ERROR → RETRY
  │        │          │           │
  │        │          └─→ CANCELAR → IDLE
  │        │
  │        └─→ DENEGADO → MANUAL INPUT
  │
  └─→ GENERAR → MOSTRAR → USAR → CONTINUAR
```
