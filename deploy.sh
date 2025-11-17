#!/bin/bash

# Deploy Script para PucpFlow
# Uso: ./deploy.sh [web|android|functions|all]

TARGET=${1:-web}

echo ""
echo "🚀 Desplegando PucpFlow - Target: $TARGET"
echo "================================================"
echo ""

# Validar target
if [[ ! "$TARGET" =~ ^(web|android|functions|all)$ ]]; then
    echo "❌ Target inválido: $TARGET"
    echo "Uso: ./deploy.sh [web|android|functions|all]"
    exit 1
fi

# Limpiar
if [ "$TARGET" == "web" ] || [ "$TARGET" == "android" ] || [ "$TARGET" == "all" ]; then
    echo "🧹 Limpiando build anterior..."
    flutter clean
    flutter pub get
    echo "✅ Limpieza completada"
    echo ""
fi

# Deploy Web
if [ "$TARGET" == "web" ] || [ "$TARGET" == "all" ]; then
    echo "🌐 Building Web para producción..."
    flutter build web --release

    if [ $? -eq 0 ]; then
        echo "✅ Build web exitoso"
        echo ""
        echo "🔥 Desplegando a Firebase Hosting..."
        firebase deploy --only hosting

        if [ $? -eq 0 ]; then
            echo "✅ Deploy de hosting exitoso!"
            echo ""
            echo "🌍 Tu aplicación está disponible en:"
            echo "   https://pucp-flow.web.app"
            echo ""
        else
            echo "❌ Error al desplegar hosting"
            exit 1
        fi
    else
        echo "❌ Error al hacer build web"
        exit 1
    fi
fi

# Deploy Functions
if [ "$TARGET" == "functions" ] || [ "$TARGET" == "all" ]; then
    echo "⚡ Desplegando Firebase Functions..."

    # Verificar config de OpenAI
    echo "🔍 Verificando configuración de OpenAI API Key..."
    config=$(firebase functions:config:get 2>&1)
    if [[ $config == *"openai"* ]]; then
        echo "✅ OpenAI API Key configurada"
    else
        echo "⚠️  Advertencia: OpenAI API Key no configurada"
        echo "   Configúrala con: firebase functions:config:set openai.api_key='tu-key'"
    fi
    echo ""

    firebase deploy --only functions

    if [ $? -eq 0 ]; then
        echo "✅ Deploy de functions exitoso!"
        echo ""
    else
        echo "❌ Error al desplegar functions"
        exit 1
    fi
fi

# Build Android
if [ "$TARGET" == "android" ] || [ "$TARGET" == "all" ]; then
    echo "📱 Building Android App Bundle..."
    flutter build appbundle --release

    if [ $? -eq 0 ]; then
        echo "✅ Build Android exitoso!"
        echo ""
        echo "📦 Archivo generado en:"
        echo "   build/app/outputs/bundle/release/app-release.aab"
        echo ""
        echo "📤 Siguiente paso: Subir a Google Play Console"
        echo "   https://play.google.com/console"
        echo ""
    else
        echo "❌ Error al hacer build Android"
        exit 1
    fi
fi

echo "================================================"
echo "✨ Deploy completado exitosamente!"
echo "================================================"
echo ""
