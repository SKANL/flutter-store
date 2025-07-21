# 🌐 SOLUCIÓN PROBLEMA DE CONECTIVIDAD API

## 📋 **Diagnóstico del Problema**

Según los logs del Debug Console, el problema principal es de **conectividad con la API backend**:

```
❌ [API] Error en getCategorias: ClientException: Software caused connection abort, uri=http://192.168.1.7:5041/api/categorias
❌ [API] Error en getProveedores: ClientException: Software caused connection abort, uri=http://192.168.1.7:5041/api/proveedores
```

**Error:** `Software caused connection abort` - La aplicación no puede conectarse al servidor backend.

---

## 🔧 **Herramientas de Diagnóstico Implementadas**

### 1. **🌐 Diagnóstico de Conexión** (Botón azul WiFi)
- Verifica conectividad a internet
- Prueba conexión a diferentes IPs del servidor
- Analiza disponibilidad de endpoints
- Proporciona recomendaciones específicas

### 2. **⚙️ Configuración API** (Botón índigo Settings)
- Permite cambiar la IP del servidor dinámicamente
- Lista IPs comunes para pruebas rápidas
- Función de prueba de conexión antes de guardar
- Instrucciones detalladas de configuración

### 3. **🐛 Diagnóstico de Códigos de Barras** (Botón naranja Bug)
- Para depurar problemas de códigos de barras (cuando la API funcione)

---

## 🛠️ **Pasos de Solución**

### **Paso 1: Verificar que el Servidor Backend esté Ejecutándose**

1. **Ir a tu proyecto de C# backend**
2. **Ejecutar el servidor API:**
   ```bash
   dotnet run
   # o
   dotnet watch run
   ```
3. **Verificar que aparezca algo como:**
   ```
   Now listening on: http://localhost:5041
   Application started. Press Ctrl+C to shut down.
   ```

### **Paso 2: Encontrar la IP Correcta**

En tu **PC donde está el servidor**, abre cmd/terminal y ejecuta:

**Windows:**
```cmd
ipconfig
```

**Linux/Mac:**
```bash
ifconfig
# o
ip addr show
```

Busca la **IP de tu red local** (generalmente algo como `192.168.1.X` o `10.0.0.X`).

### **Paso 3: Usar las Herramientas de Diagnóstico**

1. **Abrir la app Flutter**
2. **Ir a Inventario** 
3. **Presionar el botón ⚙️ (Configuración API)**
4. **Probar diferentes IPs:**
   - La IP que encontraste en el Paso 2
   - `192.168.1.1` (router)
   - `10.0.0.1`
   - Si usas **emulador Android**: `10.0.2.2` (para localhost)

5. **Para cada IP:**
   - Introducir la IP
   - Poner puerto `5041`
   - Presionar **"Probar Conexión"**
   - Si funciona, presionar **"Guardar y Aplicar"**

### **Paso 4: Verificar con Diagnóstico de Conexión**

1. **Presionar el botón 🌐 (Diagnóstico de Conexión)**
2. **Ejecutar diagnóstico completo**
3. **Revisar resultados:**
   - ✅ Verde = Funciona
   - ❌ Rojo = Error
   - ⚠️ Naranja = Advertencia

---

## 🚀 **Configuraciones Comunes por Plataforma**

### **📱 Dispositivo Android Físico**
- **IP del servidor:** La IP real de tu PC (ej: `192.168.1.7`)
- **Puerto:** `5041`
- **URL:** `http://192.168.1.7:5041`

### **📱 Emulador Android**
- **IP del servidor:** `10.0.2.2` (mapea a localhost de la PC host)
- **Puerto:** `5041`
- **URL:** `http://10.0.2.2:5041`

### **💻 Desarrollo en PC**
- **IP del servidor:** `localhost` o `127.0.0.1`
- **Puerto:** `5041`
- **URL:** `http://localhost:5041`

---

## 🔥 **Configuración del Backend C# para Android**

Si el problema persiste, verifica que tu **servidor C# permita conexiones externas**:

### **1. En `Program.cs` o `Startup.cs`:**
```csharp
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(5041); // Escucha en todas las IPs, no solo localhost
});

// O también:
app.Urls.Add("http://*:5041");
```

### **2. Configurar CORS:**
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

app.UseCors("AllowAll");
```

### **3. Verificar Firewall de Windows:**
- Permitir el puerto `5041` en Windows Defender Firewall
- O temporalmente deshabilitar el firewall para pruebas

---

## 📊 **Verificación Final**

Una vez configurado correctamente, los logs deberían cambiar de:
```
❌ [API] Error en getCategorias: ClientException: Software caused connection abort
```

A algo como:
```
✅ [API] getCategorias exitoso: 5 categorías obtenidas
✅ [STATE] Categorías cargadas: 5 items
```

---

## 🎯 **Resumen de Acciones**

1. ✅ **Ejecutar servidor backend C#**
2. ✅ **Encontrar IP correcta de la PC**
3. ✅ **Usar herramienta de Configuración API**
4. ✅ **Probar diferentes IPs hasta encontrar la correcta**
5. ✅ **Verificar con Diagnóstico de Conexión**
6. ✅ **Configurar CORS y firewall si es necesario**

**Una vez solucionado el problema de conectividad, el diagnóstico de códigos de barras funcionará correctamente.**
