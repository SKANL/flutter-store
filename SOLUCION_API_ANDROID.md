# 🚨 CONFIGURACIÓN REQUERIDA PARA TU API C#

## Problema Identificado
Tu API C# está corriendo en localhost:5041, pero solo acepta conexiones locales.
Android necesita conectarse usando la IP de tu PC (192.168.1.7:5041).

## Solución en tu API C#

### Opción 1: Modificar Program.cs (ASP.NET Core 6+)
```csharp
var builder = WebApplication.CreateBuilder(args);

// Configurar URLs para escuchar en todas las interfaces
builder.WebHost.UseUrls("http://0.0.0.0:5041", "http://192.168.1.7:5041");

// Resto de tu configuración...
var app = builder.Build();

// IMPORTANTE: Configurar CORS para permitir conexiones desde Flutter
app.UseCors(policy => policy
    .AllowAnyOrigin()
    .AllowAnyMethod()
    .AllowAnyHeader());
```

### Opción 2: Modificar launchSettings.json
```json
{
  "profiles": {
    "YourApiName": {
      "commandName": "Project",
      "applicationUrl": "http://0.0.0.0:5041;http://192.168.1.7:5041",
      "launchBrowser": true
    }
  }
}
```

### Opción 3: Ejecutar con comando específico
```bash
dotnet run --urls="http://0.0.0.0:5041"
```

## Prueba Rápida
Después de configurar, ve a: http://192.168.1.7:5041/api/categorias
Si funciona en el navegador, funcionará en Flutter.
