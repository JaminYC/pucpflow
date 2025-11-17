# 🔧 Configuración de Firebase Cloud Functions

## ✅ Cambios Aplicados

Se ha actualizado `lib/features/skills/services/skills_service.dart` con las configuraciones necesarias para que las Cloud Functions funcionen correctamente.

## 📋 Configuraciones Implementadas

### 1. **Región de Cloud Functions**

```dart
late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
  region: 'us-central1', // 👈 Región configurada
);
```

**¿Por qué es importante?**
- Por defecto, Firebase Functions se despliegan en `us-central1` (Iowa, USA)
- Si tus funciones están en otra región, la app no las encontrará

**¿Cómo saber en qué región están mis funciones?**

```bash
# Ver región actual
firebase functions:list

# O revisa Firebase Console
# https://console.firebase.google.com → Functions → Ver ubicación
```

**Regiones comunes:**
- `us-central1` - Iowa, USA (default)
- `us-east1` - Carolina del Sur, USA
- `southamerica-east1` - São Paulo, Brasil
- `europe-west1` - Bélgica
- `asia-east1` - Taiwán

**Si necesitas cambiar la región:**
1. Abre `lib/features/skills/services/skills_service.dart`
2. Cambia `region: 'us-central1'` por tu región

### 2. **Timeout Aumentado**

```dart
// Para extraerCV (usa OpenAI, puede tardar hasta 5 minutos)
final callable = _functions.httpsCallable(
  'extraerCV',
  options: HttpsCallableOptions(
    timeout: const Duration(seconds: 300), // 5 minutos
  ),
);

// Para guardarSkillsConfirmadas (más rápida)
final callable = _functions.httpsCallable(
  'guardarSkillsConfirmadas',
  options: HttpsCallableOptions(
    timeout: const Duration(seconds: 60), // 1 minuto
  ),
);
```

**¿Por qué es importante?**
- Por defecto, las funciones tienen timeout de **60 segundos**
- OpenAI puede tardar 2-5 minutos en procesar un CV completo
- Sin timeout aumentado, la app mostraría error aunque la función esté funcionando

### 3. **Emulador Local (Desarrollo)**

```dart
SkillsService({bool useEmulator = false}) {
  if (useEmulator) {
    _functions.useFunctionsEmulator('localhost', 5001);
    print('🔧 Usando emulador de Cloud Functions en localhost:5001');
  }
}
```

**¿Cómo usar el emulador?**

```dart
// En tu código de desarrollo:
final skillsService = SkillsService(useEmulator: true);
```

**Para iniciar el emulador:**

```bash
# En carpeta functions/
firebase emulators:start --only functions
```

## 🚀 Desplegar Cloud Functions

### Paso 1: Configurar OpenAI API Key

```bash
# Configurar secret (solo una vez)
firebase functions:secrets:set OPENAI_API_KEY
# Pega tu API key cuando te la pida
```

**Verificar que esté configurada:**

```bash
firebase functions:secrets:access OPENAI_API_KEY
```

### Paso 2: Desplegar Funciones

```bash
cd functions
npm install
firebase deploy --only functions
```

**Para desplegar funciones específicas:**

```bash
# Solo extraerCV
firebase deploy --only functions:extraerCV

# Solo guardarSkillsConfirmadas
firebase deploy --only functions:guardarSkillsConfirmadas

# Ambas
firebase deploy --only functions:extraerCV,functions:guardarSkillsConfirmadas
```

### Paso 3: Verificar Despliegue

```bash
# Ver funciones desplegadas
firebase functions:list

# Ver logs en tiempo real
firebase functions:log --only extraerCV
```

## 🐛 Solución de Problemas

### Error: "Failed to connect to Firebase Functions"

**Causa:** La región configurada no coincide con la región de despliegue.

**Solución:**
1. Revisa la región en Firebase Console
2. Actualiza el código:

```dart
late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
  region: 'TU_REGION_AQUI',
);
```

### Error: "Deadline exceeded" o "Timeout"

**Causa:** La función tarda más que el timeout configurado.

**Solución:** Aumenta el timeout en el código:

```dart
options: HttpsCallableOptions(
  timeout: const Duration(seconds: 600), // 10 minutos
),
```

### Error: "Cloud Functions has not been initialized"

**Causa:** Firebase no está inicializado antes de usar Cloud Functions.

**Solución:** Verifica que `Firebase.initializeApp()` esté en `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### Error: "Secret OPENAI_API_KEY not found"

**Causa:** La API key no está configurada en Firebase.

**Solución:**

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

### Error: "CORS error" (solo en Web)

**Causa:** Firebase Functions bloquea peticiones desde web por CORS.

**Solución:** En `functions/index.js`, agrega CORS:

```javascript
const cors = require('cors')({origin: true});

exports.extraerCV = onCall((request) => {
  return cors(request, response, async () => {
    // Tu código aquí
  });
});
```

## 📊 Monitoreo y Logs

### Ver logs de una función específica

```bash
# Últimos 50 logs
firebase functions:log --only extraerCV --lines 50

# Logs en tiempo real
firebase functions:log --only extraerCV --follow
```

### Firebase Console

Accede a: https://console.firebase.google.com
- Ve a **Functions**
- Click en tu función
- Pestaña **Logs** para ver ejecuciones

### Ver costos

```bash
# Ver métricas de uso
firebase functions:metrics:list

# Ver costo estimado en Firebase Console
# https://console.firebase.google.com → Usage and billing
```

## 🔐 Seguridad

### Firestore Rules (IMPORTANTE)

Asegúrate de tener estas reglas en Firestore para que solo las Cloud Functions puedan escribir:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Skills - Solo lectura pública
    match /skills/{skillId} {
      allow read: if true;
      allow write: if false; // Solo Cloud Functions pueden escribir
    }

    // Professional skills del usuario
    match /users/{userId}/professional_skills/{skillId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Solo Cloud Functions pueden escribir
    }
  }
}
```

### Validación de Usuario

Las funciones ya validan que el usuario esté autenticado:

```javascript
// En functions/index.js
if (!context.auth) {
  throw new HttpsError('unauthenticated', 'Usuario no autenticado');
}
```

## 📝 Checklist de Configuración

- [x] Region configurada en `skills_service.dart`
- [x] Timeout aumentado para `extraerCV` (300 segundos)
- [x] Timeout configurado para `guardarSkillsConfirmadas` (60 segundos)
- [x] Constructor para emulador local
- [ ] OpenAI API Key configurada en Firebase (`firebase functions:secrets:set OPENAI_API_KEY`)
- [ ] Funciones desplegadas (`firebase deploy --only functions`)
- [ ] Firestore Rules actualizadas
- [ ] Firebase inicializado en `main.dart`
- [ ] Skills database inicializada (ejecutar `InitSkillsDB().initializeSkills()`)

## 🎯 Próximos Pasos

1. **Desplegar funciones:**
   ```bash
   cd functions
   firebase deploy --only functions:extraerCV,functions:guardarSkillsConfirmadas
   ```

2. **Inicializar base de datos de skills:**
   - Crea un botón temporal en tu app
   - Ejecuta `await InitSkillsDB().initializeSkills()`
   - Esto poblará Firestore con 100+ skills predefinidas

3. **Probar el flujo completo:**
   - Navega a `PerfilUsuarioPage`
   - Tab "Skills" → Botón "Cargar CV"
   - Selecciona un PDF de prueba
   - Verifica que extraiga skills correctamente

## 📚 Recursos

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Regions and Zones](https://firebase.google.com/docs/functions/locations)
- [OpenAI API Docs](https://platform.openai.com/docs)
- [Cloud Functions Pricing](https://firebase.google.com/pricing)

---

**¿Dudas?** Revisa los logs con `firebase functions:log --only extraerCV` para ver qué está pasando.
