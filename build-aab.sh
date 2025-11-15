#!/bin/bash

# Script para generar Android App Bundle (.aab)
# Uso: ./build-aab.sh

set -e

echo "🚀 Iniciando proceso de build para Android App Bundle (.aab)"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Este script debe ejecutarse desde la carpeta apps/mobile"
    exit 1
fi

# Verificar si existe el archivo key.properties
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  Advertencia: No se encontró android/key.properties"
    echo "   El build usará las claves de debug."
    echo "   Para producción, crea el archivo key.properties siguiendo BUILD_AAB_GUIDE.md"
    echo ""
    read -p "¿Continuar con claves de debug? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Verificar que no haya errores de análisis
echo "🔍 Analizando código..."
flutter analyze

# Build del app bundle
echo "🔨 Generando Android App Bundle..."
flutter build appbundle --release

# Verificar que se generó correctamente
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(ls -lh "$AAB_PATH" | awk '{print $5}')
    echo ""
    echo "✅ ¡App Bundle generado exitosamente!"
    echo "📍 Ubicación: $AAB_PATH"
    echo "📊 Tamaño: $AAB_SIZE"
    echo ""
    echo "📤 Puedes subir este archivo a Google Play Console"
else
    echo ""
    echo "❌ Error: No se pudo generar el App Bundle"
    exit 1
fi
