# Guía Completa de Despliegue - PucpFlow

## Opciones de Despliegue Disponibles

Tu proyecto puede desplegarse en múltiples plataformas:

1. ✅ **Firebase Hosting** (Web) - ⚡ MÁS RÁPIDO Y RECOMENDADO
2. **Google Play Store** (Android)
3. **Apple App Store** (iOS)
4. **Firebase App Distribution** (Beta testing)
5. **Netlify / Vercel** (Alternativas para Web)

---

## 1. 🔥 Firebase Hosting (Web) - RECOMENDADO

### Ventajas:
- ✅ Gratis hasta 10 GB/mes
- ✅ SSL automático (HTTPS)
- ✅ CDN global
- ✅ Despliegue en 2 minutos
- ✅ Ya está configurado en tu proyecto

### Paso a Paso:

#### A. Verificar Configuración Actual

```bash
# Ver proyecto actual
firebase projects:list

# Debería mostrar: pucp-flow (current)
```

#### B. Build de la Aplicación Web

```bash
# Limpiar builds anteriores
flutter clean

# Build para producción
flutter build web --release

# Esto genera los archivos en: build/web/
```

#### C. Desplegar a Firebase Hosting

```bash
# Desplegar todo (hosting + functions)
firebase deploy

# O solo hosting:
firebase deploy --only hosting

# O solo functions:
firebase deploy --only functions
```

#### D. Resultado

Después del deploy verás:

```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/pucp-flow/overview
Hosting URL: https://pucp-flow.web.app
```

**Tu app estará en vivo en:** `https://pucp-flow.web.app`

### Comandos Útiles:

```bash
# Ver la app antes de desplegar
firebase serve

# Rollback al deploy anterior
firebase hosting:rollback

# Ver historial de deploys
firebase hosting:list

# Ver logs
firebase functions:log
```

### Configuración de Dominio Personalizado (Opcional)

Si tienes un dominio (ej: `pucpflow.com`):

1. Firebase Console → Hosting → Add custom domain
2. Sigue los pasos para verificar DNS
3. Firebase configura SSL automáticamente

---

## 2. 📱 Google Play Store (Android)

### Requisitos:
- Cuenta de Google Play Developer ($25 pago único)
- Keystore para firmar la app
- Iconos y screenshots de la app

### Paso a Paso:

#### A. Crear Keystore para Firma

```bash
# En Windows PowerShell o CMD
keytool -genkey -v -keystore c:\Users\User\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Te pedirá:
# - Password del keystore (GUÁRDALO)
# - Nombre, organización, etc.
```

#### B. Configurar Firma en Android

Crea el archivo `android/key.properties`:

```properties
storePassword=TU_PASSWORD_KEYSTORE
keyPassword=TU_PASSWORD_KEY
keyAlias=upload
storeFile=C:/Users/User/upload-keystore.jks
```

**⚠️ IMPORTANTE:** Agrega `key.properties` al `.gitignore`:

```bash
echo "android/key.properties" >> .gitignore
```

#### C. Modificar `android/app/build.gradle`

Busca la sección `buildTypes` y actualiza:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... código existente ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### D. Build del APK/AAB

```bash
# Build APK (para distribución directa)
flutter build apk --release

# Build AAB (para Google Play - RECOMENDADO)
flutter build appbundle --release

# Los archivos se generan en:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

#### E. Subir a Google Play Console

1. Ir a: https://play.google.com/console
2. Crear nueva aplicación
3. Completar información (nombre, descripción, iconos, screenshots)
4. Subir el archivo `.aab` en **Production** o **Internal Testing**
5. Completar cuestionario de privacidad
6. Enviar para revisión

---

## 3. 🍎 Apple App Store (iOS)

### Requisitos:
- Mac con Xcode
- Cuenta de Apple Developer ($99/año)
- Certificados de firma

### Paso a Paso (Requiere Mac):

```bash
# En Mac
cd ios
pod install
cd ..

# Build para App Store
flutter build ios --release

# Abrir en Xcode
open ios/Runner.xcworkspace

# En Xcode:
# 1. Product → Archive
# 2. Distribute App → App Store Connect
# 3. Subir a TestFlight o directamente a App Store
```

---

## 4. 🧪 Firebase App Distribution (Beta Testing)

### Ventajas:
- Distribución rápida a testers
- No requiere Google Play/App Store
- Gratis
- Ideal para beta testing

### Paso a Paso:

#### A. Instalar Firebase CLI Plugin

```bash
npm install -g firebase-tools
```

#### B. Build y Distribución

**Android:**
```bash
# Build APK
flutter build apk --release

# Subir a Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:547054267025:android:TU_APP_ID \
  --release-notes "Versión beta con sistema PMI completo" \
  --groups "testers"
```

**iOS (en Mac):**
```bash
# Build IPA
flutter build ipa --release

# Distribuir
firebase appdistribution:distribute build/ios/ipa/*.ipa \
  --app 1:547054267025:ios:TU_APP_ID \
  --release-notes "Versión beta" \
  --groups "testers"
```

#### C. Invitar Testers

```bash
# Desde Firebase Console:
# App Distribution → Testers & Groups → Invite testers
# Los testers recibirán email con link de descarga
```

---

## 5. 🌐 Netlify / Vercel (Alternativas Web)

### Netlify

```bash
# Instalar Netlify CLI
npm install -g netlify-cli

# Build
flutter build web --release

# Deploy
cd build/web
netlify deploy --prod
```

### Vercel

```bash
# Instalar Vercel CLI
npm install -g vercel

# Build
flutter build web --release

# Deploy
cd build/web
vercel --prod
```

---

## 6. 🚀 Script de Despliegue Completo

Voy a crear un script para automatizar el despliegue:

**Windows (PowerShell):** `deploy.ps1`

```powershell
# Deploy Script para PucpFlow

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('web', 'android', 'functions', 'all')]
    [string]$Target = 'web'
)

Write-Host "🚀 Desplegando PucpFlow - Target: $Target" -ForegroundColor Cyan

# Limpiar
Write-Host "🧹 Limpiando build anterior..." -ForegroundColor Yellow
flutter clean
flutter pub get

if ($Target -eq 'web' -or $Target -eq 'all') {
    Write-Host "🌐 Building Web..." -ForegroundColor Green
    flutter build web --release

    Write-Host "🔥 Desplegando a Firebase Hosting..." -ForegroundColor Green
    firebase deploy --only hosting
}

if ($Target -eq 'functions' -or $Target -eq 'all') {
    Write-Host "⚡ Desplegando Firebase Functions..." -ForegroundColor Green
    firebase deploy --only functions
}

if ($Target -eq 'android' -or $Target -eq 'all') {
    Write-Host "📱 Building Android..." -ForegroundColor Green
    flutter build appbundle --release

    Write-Host "✅ APK generado en: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
}

Write-Host "✨ Deploy completado!" -ForegroundColor Cyan
```

**Uso:**
```powershell
# Desplegar solo web
.\deploy.ps1 -Target web

# Desplegar solo functions
.\deploy.ps1 -Target functions

# Desplegar solo Android
.\deploy.ps1 -Target android

# Desplegar todo
.\deploy.ps1 -Target all
```

**Linux/Mac (Bash):** `deploy.sh`

```bash
#!/bin/bash

# Deploy Script para PucpFlow

TARGET=${1:-web}

echo "🚀 Desplegando PucpFlow - Target: $TARGET"

# Limpiar
echo "🧹 Limpiando build anterior..."
flutter clean
flutter pub get

if [ "$TARGET" == "web" ] || [ "$TARGET" == "all" ]; then
    echo "🌐 Building Web..."
    flutter build web --release

    echo "🔥 Desplegando a Firebase Hosting..."
    firebase deploy --only hosting
fi

if [ "$TARGET" == "functions" ] || [ "$TARGET" == "all" ]; then
    echo "⚡ Desplegando Firebase Functions..."
    firebase deploy --only functions
fi

if [ "$TARGET" == "android" ] || [ "$TARGET" == "all" ]; then
    echo "📱 Building Android..."
    flutter build appbundle --release

    echo "✅ APK generado en: build/app/outputs/bundle/release/app-release.aab"
fi

echo "✨ Deploy completado!"
```

---

## 7. ⚙️ Configuración Antes del Primer Deploy

### Checklist Pre-Deploy:

- [ ] **Verificar OpenAI API Key configurada:**
  ```bash
  firebase functions:config:get
  ```

- [ ] **Verificar reglas de Firestore actualizadas:**
  - Firebase Console → Firestore → Rules

- [ ] **Verificar reglas de Storage:**
  - Firebase Console → Storage → Rules

- [ ] **Actualizar versión en `pubspec.yaml`:**
  ```yaml
  version: 1.0.0+1  # Incrementar antes de cada deploy
  ```

- [ ] **Probar localmente:**
  ```bash
  flutter run -d chrome
  ```

- [ ] **Verificar que no haya errores:**
  ```bash
  flutter analyze
  ```

---

## 8. 🎯 Despliegue Recomendado para Producción

### Opción 1: Solo Web (MÁS RÁPIDO)

```bash
# 1. Build
flutter clean
flutter build web --release

# 2. Deploy
firebase deploy --only hosting

# ✅ Listo! Tu app estará en: https://pucp-flow.web.app
```

**Tiempo estimado:** 2-3 minutos

### Opción 2: Web + Functions

```bash
# 1. Build web
flutter build web --release

# 2. Deploy todo
firebase deploy

# ✅ Hosting + Functions desplegados
```

**Tiempo estimado:** 5-7 minutos

### Opción 3: Web + Android + Functions

```bash
# 1. Build web
flutter build web --release

# 2. Build Android
flutter build appbundle --release

# 3. Deploy Firebase
firebase deploy

# 4. Subir AAB manualmente a Google Play Console
```

**Tiempo estimado:** 10-15 minutos + revisión de Google Play

---

## 9. 📊 Monitoreo Post-Deploy

### Ver Logs de Functions

```bash
# Logs en tiempo real
firebase functions:log --follow

# Logs de las últimas 2 horas
firebase functions:log --limit 100
```

### Ver Estadísticas de Hosting

```bash
# En Firebase Console:
# Hosting → Dashboard → Ver métricas de tráfico
```

### Configurar Alertas

1. Firebase Console → Project Settings → Integrations
2. Configurar Slack/Email para alertas
3. Monitorear errores en Crashlytics (si está habilitado)

---

## 10. 🔄 Workflow de Deploy Continuo (CI/CD)

### GitHub Actions (Opcional)

Crea `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - run: flutter pub get
      - run: flutter build web --release

      - uses: w9jds/firebase-action@master
        with:
          args: deploy --only hosting
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

**Configuración:**
```bash
# Generar token
firebase login:ci

# Agregar el token a GitHub:
# Settings → Secrets → New secret
# Name: FIREBASE_TOKEN
# Value: [el token generado]
```

---

## 11. 🆘 Troubleshooting

### Error: "Firebase project not found"

```bash
firebase use pucp-flow
firebase deploy
```

### Error: "Functions deployment failed"

```bash
# Verificar que la config esté bien
firebase functions:config:get

# Verificar errores en functions/
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Error: "Build web failed"

```bash
flutter clean
flutter pub get
flutter doctor
flutter build web --release
```

### Error: "Permission denied" en Firebase

```bash
# Re-autenticar
firebase logout
firebase login
firebase use pucp-flow
```

---

## 12. 📝 Resumen de Comandos Rápidos

```bash
# Deploy web más rápido (RECOMENDADO)
flutter build web --release && firebase deploy --only hosting

# Deploy completo
flutter build web --release && firebase deploy

# Solo functions
firebase deploy --only functions

# Android APK
flutter build apk --release

# Android AAB (para Play Store)
flutter build appbundle --release

# Ver logs
firebase functions:log

# Rollback hosting
firebase hosting:rollback
```

---

## 13. 💰 Costos Estimados

### Firebase (Free Tier)
- **Hosting:** 10 GB storage, 360 MB/día - GRATIS
- **Functions:** 2M invocaciones/mes - GRATIS
- **Firestore:** 1 GB storage, 50K lecturas/día - GRATIS

**Si excedes:** ~$0.026/GB storage, ~$0.40/millón de invocaciones

### Google Play Store
- **Registro:** $25 (pago único)
- **Mantenimiento:** $0

### Apple App Store
- **Registro:** $99/año

---

## 14. ✅ Checklist Final Pre-Deploy

- [ ] Código pusheado a GitHub
- [ ] Firebase Functions desplegadas
- [ ] OpenAI API Key configurada
- [ ] Reglas de Firestore/Storage actualizadas
- [ ] App probada localmente
- [ ] Versión incrementada en pubspec.yaml
- [ ] Build exitoso: `flutter build web --release`
- [ ] Deploy ejecutado: `firebase deploy`
- [ ] URL verificada: https://pucp-flow.web.app
- [ ] Features principales probadas en producción

---

**Fecha de creación:** 16 de Noviembre, 2025
**Proyecto Firebase:** pucp-flow
**URL de producción:** https://pucp-flow.web.app (después del deploy)
