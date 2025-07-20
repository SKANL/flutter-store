#!/bin/bash

# Script para completar la migración de mejoras de rendimiento
# Ejecutar desde el directorio raíz del proyecto Flutter

echo "🔧 Iniciando migración de mejoras de rendimiento..."
echo "=================================================="

# 1. Buscar todos los print() restantes
echo "📝 Buscando print() restantes..."
print_count=$(grep -r "print(" lib/ --include="*.dart" | wc -l)
if [ $print_count -gt 0 ]; then
    echo "⚠️  Encontrados $print_count usos de print() que necesitan migración:"
    grep -r "print(" lib/ --include="*.dart" --line-number
    echo ""
    echo "💡 Reemplazar con AppLogger según el tipo:"
    echo "   - print('debug...') → AppLogger.debug('mensaje', 'TAG')"
    echo "   - print('error...') → AppLogger.error('mensaje', 'TAG', error)"
    echo "   - print('info...') → AppLogger.info('mensaje', 'TAG')"
    echo ""
else
    echo "✅ No se encontraron print() en lib/"
fi

# 2. Buscar usos problemáticos de BuildContext
echo "📝 Buscando usos potencialmente problemáticos de BuildContext..."
context_issues=$(grep -r "context\." lib/ --include="*.dart" | grep -E "(await|async)" | wc -l)
if [ $context_issues -gt 0 ]; then
    echo "⚠️  Encontrados $context_issues posibles problemas de contexto:"
    grep -r "context\." lib/ --include="*.dart" --line-number | grep -E "(await|async)"
    echo ""
    echo "💡 Revisar estos casos y usar SafeContextService cuando sea necesario"
    echo ""
else
    echo "✅ No se encontraron problemas evidentes de contexto"
fi

# 3. Verificar que los archivos nuevos existan
echo "📝 Verificando archivos de mejora..."
files_to_check=(
    "lib/core/app_logger.dart"
    "lib/services/safe_context_service.dart"
    "lib/services/background_task_service.dart"
    "lib/services/barcode_service.dart"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
    else
        echo "❌ $file NO existe - necesario crear"
    fi
done

# 4. Verificar configuración de análisis
echo ""
echo "📝 Verificando configuración de análisis..."
if [ -f "analysis_options.yaml" ]; then
    echo "✅ analysis_options.yaml existe"
    if grep -q "use_build_context_synchronously" analysis_options.yaml; then
        echo "✅ Regla use_build_context_synchronously configurada"
    else
        echo "⚠️  Considerar añadir regla use_build_context_synchronously"
    fi
else
    echo "❌ analysis_options.yaml NO encontrado"
fi

# 5. Sugerencias de testing
echo ""
echo "🧪 TESTING RECOMENDADO:"
echo "======================="
echo "1. Ejecutar flutter analyze para verificar reglas:"
echo "   flutter analyze"
echo ""
echo "2. Ejecutar en dispositivo de bajos recursos:"
echo "   flutter run --profile"
echo ""
echo "3. Monitorear rendimiento:"
echo "   flutter run --profile --enable-software-rendering"
echo ""
echo "4. Verificar memory leaks:"
echo "   Usar DevTools → Memory tab"

# 6. Comandos de limpieza
echo ""
echo "🧹 COMANDOS DE LIMPIEZA:"
echo "======================="
echo "flutter clean"
echo "flutter pub get"
echo "flutter pub upgrade"

echo ""
echo "✅ Migración completada!"
echo "📋 Revisar PERFORMANCE_IMPROVEMENTS.md para detalles completos"
echo ""
