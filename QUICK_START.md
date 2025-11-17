# Quick Start - PucpFlow

## Para Desarrolladores Nuevos

### 1. Requisitos Rápidos
```bash
# Verifica que tengas instalado:
flutter --version    # Flutter 3.0+
node --version       # Node.js 16+
npm --version        # npm 8+
firebase --version   # Firebase CLI
```

Si falta algo:
- **Flutter:** https://docs.flutter.dev/get-started/install
- **Node.js:** https://nodejs.org/
- **Firebase CLI:** `npm install -g firebase-tools`

### 2. Setup en 5 Minutos

```bash
# 1. Clonar
git clone https://github.com/JaminYC/pucpflow.git
cd pucpflow

# 2. Instalar dependencias Flutter
flutter pub get

# 3. Firebase CLI
firebase login
firebase use --add
# Selecciona el proyecto: pucpflow (o el ID que te compartan)

# 4. Functions
cd functions
npm install
cd ..

# 5. Ejecutar app
flutter run -d chrome
```

### 3. Credenciales Necesarias

Pídele al administrador del proyecto:

1. **Acceso a Firebase Console:**
   - Email con permisos de Editor/Owner
   - Link: https://console.firebase.google.com/

2. **OpenAI API Key** (para funciones de IA):
   - Configurar con: `firebase functions:config:set openai.api_key="sk-..."`
   - O créate tu propia cuenta en: https://platform.openai.com/

3. **Archivos de configuración Firebase:**
   - Ya están en el repo en `.gitignore`, pero si faltan:
     - `google-services.json` (Android)
     - `GoogleService-Info.plist` (iOS)
     - `web/firebase-config.js` (Web)

### 4. Probar que Todo Funciona

```bash
# Ejecutar app
flutter run -d chrome

# Crear cuenta de prueba
# Email: test@test.com
# Password: test123456

# Probar features:
# ✅ Crear proyecto PMI con IA
# ✅ Subir CV y extraer habilidades
# ✅ Auto-asignar tareas con IA
```

### 5. Estructura Rápida del Código

```
lib/
├── features/
│   ├── pmi/                          # 🎯 Sistema PMI
│   ├── skills/                       # 🧠 Habilidades
│   └── user_auth/presentation/pages/
│       └── Proyectos/
│           ├── asignacion_inteligente_service.dart   # 🤖 Asignación IA
│           ├── pmi_ia_service.dart                   # 🎨 Generación PMI
│           └── ProyectoDetallePage.dart              # 📊 UI Principal

functions/
└── index.js                          # ☁️ Cloud Functions (CV + PMI)
```

### 6. Features Principales

#### 🎯 Crear Proyecto PMI
1. Dashboard → "Proyectos" → "Crear Proyecto PMI con IA"
2. Llenar formulario
3. IA genera 20-30 tareas automáticamente con jerarquía PMI completa

#### 🤖 Asignación Inteligente
1. Abrir proyecto PMI
2. Agregar participantes
3. Botón flotante naranja "Auto-asignar"
4. Ve justificación de cada asignación (scores, skills, etc.)

#### 🧠 Mapeo de Habilidades
1. Perfil de usuario → "Subir CV"
2. IA extrae habilidades automáticamente
3. Revisar y confirmar

### 7. Comandos Útiles

```bash
# Ver logs de Functions
firebase functions:log

# Redesplegar Functions
firebase deploy --only functions

# Limpiar Flutter
flutter clean && flutter pub get

# Ver config de Firebase
firebase functions:config:get

# Hot reload (en desarrollo)
# Presiona 'r' en la terminal donde corre flutter run
```

### 8. Problemas Comunes

**Error: "Missing permissions"**
```bash
# Verifica que estés usando el proyecto correcto
firebase use
```

**Error: "OpenAI API failed"**
```bash
# Verifica la config
firebase functions:config:get

# Si está vacío, configúrala:
firebase functions:config:set openai.api_key="sk-..."
firebase deploy --only functions
```

**Error: Flutter build failed**
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### 9. Documentación Completa

📖 **Instrucciones detalladas:** [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

📚 **Documentación técnica:**
- [Sistema de Asignación Inteligente](INTELLIGENT_ASSIGNMENT_COMPLETE.md)
- [Sistema PMI](PMI_SYSTEM_IMPLEMENTATION_SUMMARY.md)
- [Sistema de Habilidades](SKILLS_MAPPING_SYSTEM.md)
- [Firebase Functions](FIREBASE_FUNCTIONS_CONFIG.md)

### 10. Contacto

- **Repo:** https://github.com/JaminYC/pucpflow
- **Issues:** https://github.com/JaminYC/pucpflow/issues

---

## ✅ Checklist Mínimo

- [ ] Clonar repo
- [ ] `flutter pub get`
- [ ] `firebase login` + `firebase use --add`
- [ ] `cd functions && npm install`
- [ ] Configurar OpenAI API Key
- [ ] `flutter run -d chrome`
- [ ] Crear usuario de prueba
- [ ] Probar crear proyecto PMI

**Tiempo estimado: 10-15 minutos**

---

**Última actualización:** 16 de Noviembre, 2025
