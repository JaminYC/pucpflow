# ✅ Verificación de Google Authentication para Beta

**Fecha:** 2025-12-31
**Proyecto:** FLOW - Vastoria
**Objetivo:** Asegurar que la autenticación con Google funcione correctamente para el lanzamiento en beta

---

## 📋 Checklist de Verificación

### ✅ 1. Código de Autenticación (COMPLETADO)

**Ubicación:** [firebase_auth_services.dart](lib/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart#L106-L184)

**Implementación verificada:**
```dart
Future<UserModel?> signInWithGoogle() async {
  try {
    // ✅ Inicializa Google Sign-In
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // ✅ Maneja cancelación del usuario
    if (googleUser == null) return null;

    // ✅ Obtiene credenciales de Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // ✅ Autentica con Firebase
    UserCredential userCredential = await _auth.signInWithCredential(credential);
    User? user = userCredential.user;

    // ✅ Crea o actualiza usuario en Firestore
    if (user != null) {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // Crea nuevo usuario con datos de Google
        UserModel newUser = UserModel(
          id: user.uid,
          nombre: googleUser.displayName ?? "Usuario",
          correoElectronico: user.email!,
          fotoPerfil: user.photoURL,
          // ... valores por defecto
        );
        await userRef.set(newUser.toMap());
      }
      return await getUserFromFirestore(user.uid);
    }
    return null;
  } catch (e) {
    print("Error en Google Sign-In: $e");
    return null;
  }
}
```

**✅ Puntos fuertes:**
- Maneja correctamente la cancelación del usuario
- Crea usuario en Firestore si no existe
- Captura errores y los registra
- Retorna UserModel completo

**⚠️ RECOMENDACIÓN para beta:**
Cambiar `print()` por `debugPrint()` o un logger más robusto para producción.

---

### ✅ 2. Configuración Web (COMPLETADO)

**Ubicación:** [web/index.html](web/index.html#L17)

**Client ID configurado:**
```html
<meta name="google-signin-client_id"
      content="547054267025-62eputqjlamebrmshg37rfohl9s10q0c.apps.googleusercontent.com">
```

**Firebase Config:**
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyAIxbm_eohVKVyb5wgvIa9YI6RUAFDkDOs",
  authDomain: "pucp-flow.firebaseapp.com",
  projectId: "pucp-flow",
  storageBucket: "pucp-flow.appspot.com",
  messagingSenderId: "547054267025",
  appId: "1:547054267025:web:eaa1dcee42475981d8ed30",
  measurementId: "G-FKF059M50"
};
```

**✅ Verificado:**
- Client ID presente
- Firebase inicializado correctamente
- GoogleAuthProvider configurado

---

### ❓ 3. Configuración Android/iOS (REQUIERE VERIFICACIÓN)

**Android:**
- ✅ Archivo existe: `android/app/google-services.json`
- ⚠️ **VERIFICAR:** ¿Está configurado el SHA-1 fingerprint en Firebase Console?

**iOS (si aplica):**
- ⚠️ **VERIFICAR:** ¿Existe GoogleService-Info.plist?
- ⚠️ **VERIFICAR:** ¿Está configurado el URL Scheme?

---

### 🔴 4. Configuración de OAuth Consent Screen (CRÍTICO PARA BETA)

**Para que usuarios externos puedan autenticarse, DEBES configurar:**

#### **Paso 1: Ir a Google Cloud Console**
1. Ve a: https://console.cloud.google.com/
2. Selecciona tu proyecto: **pucp-flow**
3. Ve a: **APIs & Services** → **OAuth consent screen**

#### **Paso 2: Configurar la pantalla de consentimiento**

**Opciones:**

##### **Opción A: Internal (Solo para testing limitado)**
- ✅ Solo usuarios de tu organización Google Workspace
- ❌ NO funciona para usuarios externos (@gmail.com, etc.)
- ✅ No requiere verificación de Google
- **Uso:** Solo para testing interno con cuentas de tu dominio

##### **Opción B: External - Testing (RECOMENDADO PARA BETA) ✅**
- ✅ Permite hasta 100 usuarios de prueba
- ✅ Funciona con cualquier cuenta de Google
- ✅ No requiere verificación de Google
- ⚠️ Requiere agregar emails de usuarios de prueba manualmente
- **Uso:** Perfecto para beta cerrada

**Configuración requerida:**
```
User type: External
Publishing status: Testing
App name: FLOW - Vastoria
User support email: tu-email@dominio.com
Developer contact information: tu-email@dominio.com

Scopes (mínimo):
- .../auth/userinfo.email
- .../auth/userinfo.profile
- openid

Test users: (agregar emails de tus beta testers)
- usuario1@gmail.com
- usuario2@gmail.com
- ... (hasta 100)
```

##### **Opción C: External - Production (Para lanzamiento público)**
- ✅ Usuarios ilimitados
- ✅ No muestra "app no verificada"
- 🔴 **REQUIERE VERIFICACIÓN DE GOOGLE** (proceso de 4-6 semanas)
- 🔴 Requiere política de privacidad pública
- 🔴 Requiere términos de servicio
- **Uso:** Solo cuando estés listo para producción completa

---

### ✅ 5. Dominios Autorizados en Firebase

**Ir a Firebase Console:**
1. Firebase Console → Authentication → Settings → Authorized domains
2. **Verificar que estén autorizados:**
   - ✅ `localhost` (para desarrollo)
   - ✅ `teamvastoria.com`
   - ✅ `flow.teamvastoria.com`
   - ⚠️ Cualquier otro dominio donde se vaya a desplegar

**Comando para verificar:**
```bash
firebase auth:domains
```

---

### ✅ 6. Manejo de Errores

**Errores comunes y soluciones:**

#### **Error: "popup_closed_by_user"**
```dart
// ✅ Ya está manejado en el código:
if (googleUser == null) return null;
```
**Solución:** Usuario canceló, se retorna null correctamente.

#### **Error: "unauthorized_client"**
**Causa:** OAuth consent screen no configurado o Client ID incorrecto
**Solución:**
1. Verifica OAuth consent screen en Google Cloud Console
2. Verifica que el Client ID coincida en todos lados

#### **Error: "redirect_uri_mismatch"**
**Causa:** Dominio no autorizado
**Solución:** Agregar dominio a Firebase Authorized domains

#### **Error: "access_denied"**
**Causa:** Usuario no está en la lista de test users (si está en modo Testing)
**Solución:** Agregar email del usuario a Test users en OAuth consent screen

---

### ✅ 7. Persistencia de Sesión

**Verificación:**
```dart
// Firebase Auth mantiene la sesión automáticamente
// El estado se preserva entre recargas
FirebaseAuth.instance.authStateChanges()
```

**En el código actual:**
- ✅ Firebase Auth maneja la persistencia automáticamente
- ✅ El token se refresca automáticamente
- ✅ La sesión persiste hasta que el usuario cierre sesión

---

### 🔐 8. Reglas de Seguridad de Firestore

**Ubicación:** Firebase Console → Firestore Database → Rules

**Reglas RECOMENDADAS para beta:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuarios: solo pueden leer/escribir sus propios datos
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Proyectos: propietario y participantes pueden acceder
    match /proyectos/{proyectoId} {
      allow read: if request.auth != null && (
        resource.data.propietario == request.auth.uid ||
        request.auth.uid in resource.data.participantes
      );
      allow create: if request.auth != null &&
        request.resource.data.propietario == request.auth.uid;
      allow update, delete: if request.auth != null &&
        resource.data.propietario == request.auth.uid;
    }

    // Denegar todo lo demás por defecto
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**⚠️ VERIFICAR ACTUALMENTE:**
```bash
# Ver reglas actuales
firebase firestore:rules:get
```

---

### ✅ 9. Testing Manual

**Checklist de pruebas:**

#### **Prueba 1: Login exitoso**
- [ ] Abrir app en navegador
- [ ] Click en "Iniciar sesión con Google"
- [ ] Seleccionar cuenta Google
- [ ] ✅ Debe redirigir a la app autenticado
- [ ] ✅ Debe crear/actualizar usuario en Firestore
- [ ] ✅ Debe mostrar nombre y foto de perfil

#### **Prueba 2: Usuario nuevo**
- [ ] Usar cuenta Google que nunca ha entrado
- [ ] ✅ Debe crear documento en `users/{uid}`
- [ ] ✅ Debe tener todos los campos por defecto

#### **Prueba 3: Usuario existente**
- [ ] Iniciar sesión con cuenta que ya existe
- [ ] ✅ NO debe sobrescribir datos existentes
- [ ] ✅ Debe cargar datos correctamente

#### **Prueba 4: Cancelación**
- [ ] Click en "Iniciar sesión con Google"
- [ ] Cerrar popup sin seleccionar cuenta
- [ ] ✅ No debe crashear la app
- [ ] ✅ Debe permanecer en login

#### **Prueba 5: Persistencia**
- [ ] Iniciar sesión
- [ ] Recargar página (F5)
- [ ] ✅ Debe mantener la sesión activa

#### **Prueba 6: Logout**
- [ ] Cerrar sesión
- [ ] ✅ Debe redirigir a login
- [ ] ✅ No debe poder acceder a rutas protegidas

#### **Prueba 7: Múltiples dispositivos**
- [ ] Iniciar sesión en PC
- [ ] Iniciar sesión en móvil con misma cuenta
- [ ] ✅ Datos deben sincronizarse

---

### 🚀 10. Configuración para BETA LAUNCH

**Pasos para lanzar en beta:**

#### **1. Configurar OAuth Consent Screen (CRÍTICO)**
```
1. Google Cloud Console
2. OAuth consent screen
3. User type: External
4. Publishing status: Testing
5. Agregar emails de beta testers (máx 100)
```

#### **2. Verificar Client ID en todos los archivos**
```bash
# Buscar todas las referencias al Client ID
grep -r "547054267025" .
```

**Debe estar en:**
- ✅ `web/index.html`
- ✅ `android/app/google-services.json` (automático)
- ⚠️ iOS GoogleService-Info.plist (si aplica)

#### **3. Configurar dominios autorizados**
```
Firebase Console → Authentication → Settings → Authorized domains
Agregar:
- teamvastoria.com
- flow.teamvastoria.com
- (cualquier otro dominio de beta)
```

#### **4. Agregar usuarios de prueba**
```
Google Cloud Console → OAuth consent screen → Test users
Agregar emails de todos los beta testers
```

#### **5. Desplegar a producción/beta**
```bash
# Web
firebase deploy --only hosting

# Verificar que funcione en el dominio real
```

---

### ⚠️ PROBLEMAS COMUNES EN BETA

#### **Problema 1: "This app isn't verified"**
**Causa:** App en modo Testing y usuario NO está en Test users
**Solución:**
- Agregar email del usuario a Test users en OAuth consent screen
- O hacer click en "Advanced" → "Go to app (unsafe)" (solo para testing)

#### **Problema 2: "Access blocked: This app's request is invalid"**
**Causa:** Redirect URI no coincide
**Solución:**
- Verificar dominios autorizados en Firebase
- Verificar que el dominio esté en OAuth consent screen

#### **Problema 3: Usuario no puede hacer login desde móvil**
**Causa:** SHA-1 fingerprint no configurado (Android)
**Solución:**
```bash
# Obtener SHA-1
cd android
./gradlew signingReport

# Agregar a Firebase Console → Project Settings → Your apps → Android app
```

---

### 📊 Monitoreo en Beta

**Dashboard de Firebase:**
1. **Authentication → Users**: Ver usuarios registrados
2. **Firestore → Data**: Verificar creación de documentos
3. **Analytics → Events**: Monitorear eventos de login
4. **Crashlytics**: Detectar errores en producción

**Logs útiles:**
```dart
// En firebase_auth_services.dart
// Cambiar print() por:
debugPrint("Google Sign-In: ${user.email} - ${user.uid}");
```

---

### ✅ RESUMEN PARA BETA LAUNCH

**Estado actual:**
- ✅ Código de autenticación: **LISTO**
- ✅ Configuración web: **LISTO**
- ✅ Manejo de errores: **BUENO**
- ⚠️ OAuth Consent Screen: **REQUIERE CONFIGURACIÓN**
- ⚠️ Reglas de Firestore: **VERIFICAR**
- ⚠️ Usuarios de prueba: **AGREGAR**

**Acción INMEDIATA para beta:**

1. **CRÍTICO:**
   ```
   Google Cloud Console → OAuth consent screen
   - User type: External
   - Publishing status: Testing
   - Agregar emails de beta testers
   ```

2. **IMPORTANTE:**
   ```
   Firebase Console → Authentication → Settings
   - Verificar dominios autorizados
   ```

3. **RECOMENDADO:**
   ```
   Firebase Console → Firestore → Rules
   - Revisar y actualizar reglas de seguridad
   ```

4. **TESTING:**
   - Probar con al menos 3 cuentas diferentes
   - Probar en diferentes navegadores
   - Probar en móvil (si aplica)

---

### 📝 Notas Adicionales

**Para escalar a producción (después de beta):**
- Mover OAuth consent screen de "Testing" a "Production"
- Completar proceso de verificación de Google (4-6 semanas)
- Agregar política de privacidad pública
- Agregar términos de servicio
- Configurar logging robusto (Sentry, LogRocket, etc.)
- Implementar analytics detallados

**Contacto de soporte para usuarios beta:**
- Email: [TU_EMAIL_DE_SOPORTE]
- Reportar bugs: [URL_GITHUB_ISSUES o formulario]

---

**✅ CHECKLIST FINAL ANTES DE BETA:**

- [ ] OAuth consent screen configurado en modo Testing
- [ ] Emails de beta testers agregados (hasta 100)
- [ ] Dominios autorizados verificados
- [ ] Reglas de Firestore revisadas
- [ ] Testing manual completado (todas las pruebas)
- [ ] App desplegada en dominio de beta
- [ ] Login desde dominio real probado
- [ ] Documentación de onboarding lista para beta testers
- [ ] Canal de feedback configurado (email, form, Discord, etc.)

---

**Fecha de verificación:** 2025-12-31
**Próxima revisión:** Antes del lanzamiento público
**Responsable:** Equipo Vastoria
