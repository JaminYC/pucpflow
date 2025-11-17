# Deploy Script para PucpFlow
# Uso: .\deploy.ps1 -Target web|android|functions|all

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('web', 'android', 'functions', 'all')]
    [string]$Target = 'web'
)

Write-Host ""
Write-Host "🚀 Desplegando PucpFlow - Target: $Target" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Limpiar
if ($Target -eq 'web' -or $Target -eq 'android' -or $Target -eq 'all') {
    Write-Host "🧹 Limpiando build anterior..." -ForegroundColor Yellow
    flutter clean
    flutter pub get
    Write-Host "✅ Limpieza completada" -ForegroundColor Green
    Write-Host ""
}

# Deploy Web
if ($Target -eq 'web' -or $Target -eq 'all') {
    Write-Host "🌐 Building Web para producción..." -ForegroundColor Green
    flutter build web --release

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build web exitoso" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔥 Desplegando a Firebase Hosting..." -ForegroundColor Green
        firebase deploy --only hosting

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deploy de hosting exitoso!" -ForegroundColor Green
            Write-Host ""
            Write-Host "🌍 Tu aplicación está disponible en:" -ForegroundColor Cyan
            Write-Host "   https://pucp-flow.web.app" -ForegroundColor Yellow
            Write-Host ""
        } else {
            Write-Host "❌ Error al desplegar hosting" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ Error al hacer build web" -ForegroundColor Red
        exit 1
    }
}

# Deploy Functions
if ($Target -eq 'functions' -or $Target -eq 'all') {
    Write-Host "⚡ Desplegando Firebase Functions..." -ForegroundColor Green

    # Verificar config de OpenAI
    Write-Host "🔍 Verificando configuración de OpenAI API Key..." -ForegroundColor Yellow
    $config = firebase functions:config:get 2>&1
    if ($config -like "*openai*") {
        Write-Host "✅ OpenAI API Key configurada" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Advertencia: OpenAI API Key no configurada" -ForegroundColor Yellow
        Write-Host "   Configúrala con: firebase functions:config:set openai.api_key='tu-key'" -ForegroundColor Yellow
    }
    Write-Host ""

    firebase deploy --only functions

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deploy de functions exitoso!" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "❌ Error al desplegar functions" -ForegroundColor Red
        exit 1
    }
}

# Build Android
if ($Target -eq 'android' -or $Target -eq 'all') {
    Write-Host "📱 Building Android App Bundle..." -ForegroundColor Green
    flutter build appbundle --release

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build Android exitoso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📦 Archivo generado en:" -ForegroundColor Cyan
        Write-Host "   build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📤 Siguiente paso: Subir a Google Play Console" -ForegroundColor Cyan
        Write-Host "   https://play.google.com/console" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "❌ Error al hacer build Android" -ForegroundColor Red
        exit 1
    }
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✨ Deploy completado exitosamente!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
