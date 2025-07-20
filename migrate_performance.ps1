# Script PowerShell para completar la migración de mejoras de rendimiento
# Ejecutar desde el directorio raíz del proyecto Flutter

Write-Host "🔧 Iniciando migración de mejoras de rendimiento..." -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Buscar todos los print() restantes
Write-Host "📝 Buscando print() restantes..." -ForegroundColor Yellow
$printMatches = Select-String -Path "lib\*.dart" -Pattern "print\(" -Recurse
if ($printMatches.Count -gt 0) {
    Write-Host "⚠️  Encontrados $($printMatches.Count) usos de print() que necesitan migración:" -ForegroundColor Red
    $printMatches | ForEach-Object { 
        Write-Host "   $($_.Filename):$($_.LineNumber) - $($_.Line.Trim())" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "💡 Reemplazar con AppLogger según el tipo:" -ForegroundColor Green
    Write-Host "   - print('debug...') → AppLogger.debug('mensaje', 'TAG')" -ForegroundColor White
    Write-Host "   - print('error...') → AppLogger.error('mensaje', 'TAG', error)" -ForegroundColor White
    Write-Host "   - print('info...') → AppLogger.info('mensaje', 'TAG')" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "✅ No se encontraron print() en lib/" -ForegroundColor Green
}

# 2. Buscar usos problemáticos de BuildContext
Write-Host "📝 Buscando usos potencialmente problemáticos de BuildContext..." -ForegroundColor Yellow
$contextMatches = Select-String -Path "lib\*.dart" -Pattern "context\." -Recurse | Where-Object { $_.Line -match "(await|async)" }
if ($contextMatches.Count -gt 0) {
    Write-Host "⚠️  Encontrados $($contextMatches.Count) posibles problemas de contexto:" -ForegroundColor Red
    $contextMatches | ForEach-Object { 
        Write-Host "   $($_.Filename):$($_.LineNumber) - $($_.Line.Trim())" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "💡 Revisar estos casos y usar SafeContextService cuando sea necesario" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "✅ No se encontraron problemas evidentes de contexto" -ForegroundColor Green
}

# 3. Verificar que los archivos nuevos existan
Write-Host "📝 Verificando archivos de mejora..." -ForegroundColor Yellow
$filesToCheck = @(
    "lib\core\app_logger.dart",
    "lib\services\safe_context_service.dart",
    "lib\services\background_task_service.dart",
    "lib\services\barcode_service.dart"
)

foreach ($file in $filesToCheck) {
    if (Test-Path $file) {
        Write-Host "✅ $file existe" -ForegroundColor Green
    } else {
        Write-Host "❌ $file NO existe - necesario crear" -ForegroundColor Red
    }
}

# 4. Verificar configuración de análisis
Write-Host ""
Write-Host "📝 Verificando configuración de análisis..." -ForegroundColor Yellow
if (Test-Path "analysis_options.yaml") {
    Write-Host "✅ analysis_options.yaml existe" -ForegroundColor Green
    $analysisContent = Get-Content "analysis_options.yaml" -Raw
    if ($analysisContent -match "use_build_context_synchronously") {
        Write-Host "✅ Regla use_build_context_synchronously configurada" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Considerar añadir regla use_build_context_synchronously" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ analysis_options.yaml NO encontrado" -ForegroundColor Red
}

# 5. Sugerencias de testing
Write-Host ""
Write-Host "🧪 TESTING RECOMENDADO:" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host "1. Ejecutar flutter analyze para verificar reglas:" -ForegroundColor White
Write-Host "   flutter analyze" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Ejecutar en dispositivo de bajos recursos:" -ForegroundColor White
Write-Host "   flutter run --profile" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Monitorear rendimiento:" -ForegroundColor White
Write-Host "   flutter run --profile --enable-software-rendering" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Verificar memory leaks:" -ForegroundColor White
Write-Host "   Usar DevTools → Memory tab" -ForegroundColor Gray

# 6. Comandos de limpieza
Write-Host ""
Write-Host "🧹 COMANDOS DE LIMPIEZA:" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host "flutter clean" -ForegroundColor Gray
Write-Host "flutter pub get" -ForegroundColor Gray
Write-Host "flutter pub upgrade" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ Migración completada!" -ForegroundColor Green
Write-Host "📋 Revisar PERFORMANCE_IMPROVEMENTS.md para detalles completos" -ForegroundColor Cyan
Write-Host ""

# Preguntar si ejecutar flutter analyze automáticamente
$response = Read-Host "¿Quieres ejecutar 'flutter analyze' ahora? (s/n)"
if ($response -eq "s" -or $response -eq "S" -or $response -eq "si" -or $response -eq "Si") {
    Write-Host "Ejecutando flutter analyze..." -ForegroundColor Cyan
    flutter analyze
}
