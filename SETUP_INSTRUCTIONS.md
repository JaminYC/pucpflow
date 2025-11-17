# Instrucciones de Configuración - PucpFlow

## Requisitos Previos

- Flutter SDK (3.0 o superior)
- Firebase CLI
- Node.js y npm (para Firebase Functions)
- Git
- Cuenta de Firebase
- API Key de OpenAI (para funciones de IA)

---

## 1. Clonar el Repositorio

```bash
git clone https://github.com/JaminYC/pucpflow.git
cd pucpflow
```

---

## 2. Configuración de Firebase

### 2.1 Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o usa uno existente
3. Habilita los siguientes servicios:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Cloud Functions**
   - **Storage**

### 2.2 Configurar Firebase en Flutter

#### Para Android:

1. En Firebase Console, agrega una app Android
2. Descarga el archivo `google-services.json`
3. Colócalo en: `android/app/google-services.json`

#### Para iOS:

1. En Firebase Console, agrega una app iOS
2. Descarga el archivo `GoogleService-Info.plist`
3. Colócalo en: `ios/Runner/GoogleService-Info.plist`

#### Para Web:

1. En Firebase Console, agrega una app Web
2. Copia la configuración de Firebase
3. Crea el archivo `web/firebase-config.js`:

```javascript
// Firebase Configuration
const firebaseConfig = {
  apiKey: "TU_API_KEY",
  authDomain: "tu-proyecto.firebaseapp.com",
  projectId: "tu-proyecto-id",
  storageBucket: "tu-proyecto.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456",
  measurementId: "G-XXXXXXXXXX"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
```

4. Referencia este archivo en `web/index.html` (ya debería estar configurado)

---

## 3. Configuración de Firebase Functions

### 3.1 Instalar Dependencias

```bash
cd functions
npm install
```

### 3.2 Configurar Variables de Entorno

Las Firebase Functions requieren la API Key de OpenAI. Configúrala usando Firebase CLI:

```bash
# Asegúrate de estar logueado en Firebase
firebase login

# Configurar la API Key de OpenAI
firebase functions:config:set openai.api_key="TU_OPENAI_API_KEY"
```

Para obtener tu API Key de OpenAI:
1. Ve a [OpenAI Platform](https://platform.openai.com/)
2. Inicia sesión o crea una cuenta
3. Ve a **API Keys**
4. Crea una nueva API Key
5. Cópiala (solo se mostrará una vez)

### 3.3 Verificar Configuración

```bash
firebase functions:config:get
```

Deberías ver:
```json
{
  "openai": {
    "api_key": "sk-..."
  }
}
```

### 3.4 Configuración Local (Opcional para Testing)

Para probar las functions localmente, crea el archivo `functions/.runtimeconfig.json`:

```json
{
  "openai": {
    "api_key": "TU_OPENAI_API_KEY"
  }
}
```

**⚠️ IMPORTANTE:** Este archivo NO debe subirse a Git (ya está en `.gitignore`)

### 3.5 Desplegar Firebase Functions

```bash
# Desde la raíz del proyecto
firebase deploy --only functions
```

O para desplegar solo una función específica:
```bash
firebase deploy --only functions:extractSkillsFromCV
firebase deploy --only functions:generatePMIProject
```

---

## 4. Configuración de Flutter

### 4.1 Instalar Dependencias

```bash
# Desde la raíz del proyecto
flutter pub get
```

### 4.2 Verificar Configuración

```bash
flutter doctor
```

Asegúrate de que todos los checks estén en verde (✓)

### 4.3 Ejecutar la Aplicación

#### En Web:
```bash
flutter run -d chrome
```

#### En Android:
```bash
flutter run -d <device-id>
```

#### En iOS:
```bash
flutter run -d <device-id>
```

---

## 5. Configuración de Firestore Database

### 5.1 Reglas de Seguridad

En Firebase Console → Firestore Database → Rules, configura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios pueden leer y escribir solo sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Proyectos: propietario y participantes pueden leer/escribir
    match /proyectos/{proyectoId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.propietario ||
         request.auth.uid in resource.data.participantes);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.propietario;
    }

    // Skills database (solo lectura para usuarios autenticados)
    match /skills/{skillId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Ajustar según necesidades
    }

    // CV Profiles
    match /cv_profiles/{profileId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
  }
}
```

### 5.2 Índices Compuestos (Si es necesario)

Firebase te notificará si necesitas crear índices. Sigue los enlaces que aparezcan en los errores de consola para crearlos automáticamente.

---

## 6. Configuración de Storage

### 6.1 Reglas de Seguridad

En Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/cv/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /proyectos/{proyectoId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 7. Credenciales para Otros Desarrolladores

### 7.1 Compartir Acceso al Proyecto Firebase

1. Ve a Firebase Console → Project Settings → Users and permissions
2. Agrega el email del desarrollador
3. Asigna rol: **Editor** o **Owner** según sea necesario

### 7.2 Compartir API Keys (Seguro)

**NO compartas directamente las API Keys en código o emails.**

#### Opción 1: Variables de Entorno (Recomendado)

Cada desarrollador debe crear su propio archivo `.env` local:

```bash
# .env (en la raíz del proyecto)
OPENAI_API_KEY=sk-...
```

Este archivo está en `.gitignore` y NO se sube a Git.

#### Opción 2: Gestor de Secretos

Usa herramientas como:
- **1Password** (compartir vaults)
- **LastPass**
- **AWS Secrets Manager**
- **Google Secret Manager**

#### Opción 3: Firebase Remote Config

Para configuración que puede cambiar en runtime sin redesplegar.

### 7.3 Configuración para el Nuevo Desarrollador

El nuevo desarrollador debe:

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/JaminYC/pucpflow.git
   cd pucpflow
   ```

2. **Instalar dependencias de Flutter:**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase CLI:**
   ```bash
   firebase login
   firebase use --add
   # Selecciona tu proyecto de Firebase
   ```

4. **Obtener acceso a la API Key de OpenAI:**
   - Solicitar al administrador del proyecto
   - O crear su propia cuenta de OpenAI para desarrollo

5. **Configurar Firebase Functions:**
   ```bash
   cd functions
   npm install

   # Configurar OpenAI API Key
   firebase functions:config:set openai.api_key="LA_API_KEY"
   ```

6. **Ejecutar la app:**
   ```bash
   flutter run -d chrome
   ```

---

## 8. Características Principales del Sistema

### 8.1 Sistema PMI

- Generación automática de proyectos con metodología PMI
- 5 fases: Iniciación, Planificación, Ejecución, Monitoreo, Cierre
- Jerarquía: Fase → Entregable → Paquete de Trabajo → Tarea
- Visualización jerárquica y por recursos

**Uso:**
1. Ir a "Proyectos" → "Crear Proyecto PMI con IA"
2. Ingresar nombre, descripción, fechas
3. La IA genera automáticamente estructura completa

### 8.2 Sistema de Asignación Inteligente

- Matching automático basado en habilidades
- Score de compatibilidad (0-100%)
- Asignación múltiple de responsables
- El creador del proyecto siempre supervisando

**Uso:**
1. Crear proyecto PMI
2. Agregar participantes
3. Hacer clic en botón "Auto-asignar" (naranja flotante)
4. Ver justificación de cada asignación

### 8.3 Sistema de Skills Mapping

- Extracción automática de habilidades desde CV
- Perfiles de usuario con skills y niveles (1-5)
- Integración con asignación inteligente

**Uso:**
1. Ir a perfil de usuario
2. Subir CV (PDF)
3. La IA extrae automáticamente las habilidades
4. Revisar y confirmar skills extraídas

---

## 9. Estructura del Proyecto

```
pucpflow/
├── lib/
│   ├── features/
│   │   ├── pmi/              # Sistema PMI
│   │   ├── skills/           # Sistema de habilidades
│   │   └── user_auth/
│   │       └── presentation/pages/Proyectos/
│   │           ├── asignacion_inteligente_service.dart
│   │           ├── pmi_ia_service.dart
│   │           ├── ProyectoDetallePage.dart
│   │           └── ...
│   ├── core/                 # Widgets y utilidades compartidas
│   └── main.dart
├── functions/
│   ├── index.js             # Cloud Functions
│   └── package.json
├── android/
├── ios/
├── web/
├── *.md                     # Documentación
└── pubspec.yaml
```

---

## 10. Documentación Adicional

- [INTELLIGENT_ASSIGNMENT_COMPLETE.md](INTELLIGENT_ASSIGNMENT_COMPLETE.md) - Sistema de asignación inteligente
- [PMI_SYSTEM_IMPLEMENTATION_SUMMARY.md](PMI_SYSTEM_IMPLEMENTATION_SUMMARY.md) - Sistema PMI
- [SKILLS_MAPPING_SYSTEM.md](SKILLS_MAPPING_SYSTEM.md) - Sistema de habilidades
- [FIREBASE_FUNCTIONS_CONFIG.md](FIREBASE_FUNCTIONS_CONFIG.md) - Configuración de Functions

---

## 11. Troubleshooting

### Error: "FirebaseException: Missing or insufficient permissions"

**Solución:** Verifica las reglas de Firestore y que el usuario esté autenticado.

### Error: "OpenAI API call failed"

**Solución:**
1. Verifica que la API Key esté configurada: `firebase functions:config:get`
2. Verifica que tengas créditos en tu cuenta de OpenAI
3. Revisa los logs: `firebase functions:log`

### Error: "Cloud Functions deployment failed"

**Solución:**
1. Verifica que Firebase CLI esté actualizado: `npm install -g firebase-tools`
2. Verifica que el proyecto esté seleccionado: `firebase use`
3. Verifica que tengas permisos en Firebase Console

### Error: Flutter build failed

**Solución:**
1. `flutter clean`
2. `flutter pub get`
3. `flutter run`

---

## 12. Contacto y Soporte

Para preguntas o problemas:
- **Repositorio:** https://github.com/JaminYC/pucpflow
- **Issues:** https://github.com/JaminYC/pucpflow/issues

---

## 13. Checklist de Configuración

- [ ] Clonar repositorio
- [ ] Instalar Flutter SDK
- [ ] Crear proyecto en Firebase Console
- [ ] Descargar y colocar `google-services.json` (Android)
- [ ] Descargar y colocar `GoogleService-Info.plist` (iOS)
- [ ] Crear `web/firebase-config.js` (Web)
- [ ] Ejecutar `flutter pub get`
- [ ] Configurar Firebase CLI (`firebase login`)
- [ ] Instalar dependencias de Functions (`cd functions && npm install`)
- [ ] Configurar OpenAI API Key (`firebase functions:config:set openai.api_key="..."`)
- [ ] Desplegar Functions (`firebase deploy --only functions`)
- [ ] Configurar reglas de Firestore
- [ ] Configurar reglas de Storage
- [ ] Ejecutar app (`flutter run -d chrome`)
- [ ] Crear usuario de prueba
- [ ] Verificar que todas las features funcionen

---

**Fecha de creación:** 16 de Noviembre, 2025
**Versión:** 1.0
**Última actualización:** Sistema de Asignación Inteligente con propietario siempre incluido
