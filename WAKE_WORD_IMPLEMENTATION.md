# Implementación Wake Word "Hey ADAN" ✅

## Resumen
Se ha implementado exitosamente la **Fase 1 del sistema Wake Word "Hey ADAN"** para activar el asistente ADAN mediante comandos de voz.

---

## ✅ Fases Completadas

### FASE 1: Configuración de Dependencias y Permisos
**Archivos modificados:**
- [pubspec.yaml](pubspec.yaml)
  - ✅ Agregado `porcupine_flutter: ^3.0.2`
  - ✅ Agregado `flutter_foreground_task: ^8.5.0`
  - ✅ Agregado `assets/wake_words/` para futuros wake words personalizados

- [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
  - ✅ Agregados permisos: `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`
  - ✅ Agregado servicio de foreground task

### FASE 2: Servicio Wake Word (Singleton)
**Archivo creado:**
- [lib/services/wake_word_service.dart](lib/services/wake_word_service.dart)

**Características implementadas:**
- ✅ Patrón Singleton (como `NotificationService`)
- ✅ Estados: idle, detecting, activated, processing, speaking
- ✅ Streams para notificar cambios de estado
- ✅ Detección de wake words: "hey adan", "oye adan", "hola adan"
- ✅ Reinicio automático de escucha cada 30 segundos
- ✅ Gestión de permisos de micrófono
- ✅ Persistencia de configuración en SharedPreferences

**Métodos públicos:**
```dart
// Inicialización
await WakeWordService().initialize();

// Control de detección
await WakeWordService().startDetection();
await WakeWordService().stopDetection();

// Background service (simplificado por ahora)
await WakeWordService().startBackgroundService();
await WakeWordService().stopBackgroundService();

// Notificaciones de estado
WakeWordService().setADANSpeaking(true/false);
WakeWordService().setProcessing(true/false);

// Streams
WakeWordService().wakeWordDetected.listen((_) {
  // Wake word detectado
});

WakeWordService().stateStream.listen((state) {
  // Cambio de estado
});
```

### FASE 3: Integración con main.dart
**Archivo modificado:**
- [lib/main.dart](lib/main.dart)
  - ✅ Importado `WakeWordService`
  - ✅ Inicializado en startup (solo Android)
  - ✅ Ubicado después de `NotificationService`

**Código agregado:**
```dart
// 🎙️ Inicializar servicio de Wake Word (solo Android por ahora)
if (Platform.isAndroid) {
  await WakeWordService().initialize();
}
```

---

## 📋 Próximos Pasos

### FASE 4: Integración con AsistentePage (PENDIENTE)
Necesitas modificar [lib/features/user_auth/presentation/pages/AsistenteIA/AsistentePage.dart](lib/features/user_auth/presentation/pages/AsistenteIA/AsistentePage.dart):

**1. Agregar variables de instancia:**
```dart
// ===== Wake Word Service =====
final WakeWordService _wakeWordService = WakeWordService();
StreamSubscription<void>? _wakeWordSubscription;
bool _isWakeWordEnabled = false;
```

**2. En `initState()` suscribirse al wake word:**
```dart
// Listener para wake word detection
_wakeWordSubscription = _wakeWordService.wakeWordDetected.listen((_) {
  debugPrint('🎯 Wake word "Hey ADAN" detectado!');
  if (mounted && !_isListening) {
    _startListening(); // Activar escucha de comando
  }
});
```

**3. En `dispose()` cancelar suscripción:**
```dart
_wakeWordSubscription?.cancel();
```

**4. Notificar cuando ADAN habla:**
```dart
// En _speak():
_wakeWordService.setADANSpeaking(true);

// En _handlePlaybackFinished():
_wakeWordService.setADANSpeaking(false);
```

**5. Notificar cuando procesa:**
```dart
// En _replyWithAI():
_wakeWordService.setProcessing(true);
// ... código existente ...
_wakeWordService.setProcessing(false);
```

**6. Agregar UI para controlar wake word:**
```dart
// Después del switch de ElevenLabs, agregar:
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.green.shade200),
  ),
  child: Row(
    children: [
      Icon(_isWakeWordEnabled ? Icons.hearing : Icons.hearing_disabled),
      const SizedBox(width: 12),
      Expanded(
        child: Text('Wake Word "Hey ADAN"'),
      ),
      Switch(
        value: _isWakeWordEnabled,
        onChanged: (value) async {
          if (value) {
            await _wakeWordService.startBackgroundService();
          } else {
            await _wakeWordService.stopBackgroundService();
          }
          setState(() => _isWakeWordEnabled = value);
        },
      ),
    ],
  ),
),
```

---

## 🧪 Cómo Probar

### Opción 1: Prueba Básica (sin UI)
1. Abre la app
2. Ve a la página de ADAN (AsistentePage)
3. En la consola, ejecuta:
```dart
await WakeWordService().startBackgroundService();
```
4. Di "Hey ADAN" o "Oye ADAN"
5. Observa los logs en consola

### Opción 2: Con Integración Completa (Fase 4)
1. Implementa los cambios de la Fase 4
2. Abre AsistentePage
3. Activa el switch de Wake Word
4. Di "Hey ADAN"
5. ADAN debería activarse automáticamente

---

## 🎯 Funcionalidades Actuales

### ✅ Implementado
- Detección de wake words: "hey adan", "oye adan", "hola adan"
- Escucha continua con reinicio automático
- Estados: idle, detecting, activated, processing, speaking
- Persistencia de configuración
- Gestión de permisos

### ⏳ Pendiente (Fases Futuras)
- Integración completa con AsistentePage
- Foreground service real (actualmente simplificado)
- Wake word personalizado con Porcupine (requiere AccessKey)
- Optimizaciones de batería
- Soporte iOS
- Página de configuración de sensibilidad

---

## 📱 Requisitos del Sistema

- **Android**: API 26+ (ya configurado)
- **Permisos**: Micrófono (se solicita automáticamente)
- **Dependencias**:
  - `speech_to_text: ^7.0.0` (ya instalado)
  - `permission_handler: ^11.3.1` (ya instalado)
  - `shared_preferences: ^2.5.1` (ya instalado)

---

## 🔧 Solución de Problemas

### Problema: Wake word no se detecta
**Solución:**
1. Verificar que el servicio esté inicializado: `WakeWordService().isReady`
2. Verificar permisos de micrófono
3. Revisar logs en consola (buscar 🎙️ y 🔍)

### Problema: Múltiples detecciones
**Causa**: El sistema detecta variaciones del wake word
**Solución**: Ajustar la lista de wake words o agregar filtro de tiempo entre detecciones

### Problema: No funciona en background
**Nota**: La versión actual NO funciona en background cuando la app está cerrada. El foreground service se agregará en una fase futura.

---

## 📊 Arquitectura

```
Usuario dice "Hey ADAN"
         ↓
WakeWordService (STT escuchando)
         ↓
Detecta texto con "hey adan"
         ↓
Emite evento en stream wakeWordDetected
         ↓
AsistentePage escucha el stream
         ↓
Activa _startListening()
         ↓
Usuario da comando completo
         ↓
ADAN procesa (como siempre)
```

---

## 🎨 Estados del Servicio

| Estado | Descripción | Cuándo ocurre |
|--------|-------------|---------------|
| `idle` | Detenido | Servicio no activo |
| `detecting` | Escuchando wake word | Esperando "Hey ADAN" |
| `activated` | Wake word detectado | Justo después de detectar |
| `processing` | Procesando comando | ADAN analizando con IA |
| `speaking` | ADAN hablando | Reproduciendo respuesta |

---

## 👨‍💻 Mantenimiento

### Agregar más wake words
Edita [lib/services/wake_word_service.dart](lib/services/wake_word_service.dart):
```dart
final List<String> _wakeWords = [
  'hey adan',
  'oye adan',
  'hola adan',
  'ok adan', // ← Agregar aquí
];
```

### Cambiar tiempo de reinicio
```dart
// Línea ~201
Future.delayed(const Duration(seconds: 30), () { // ← Cambiar aquí
```

### Ajustar sensibilidad
```dart
// Línea ~189
listenOptions: stt.SpeechListenOptions(
  partialResults: true, // ← Cambiar a true para más sensibilidad
  cancelOnError: false,
  listenMode: stt.ListenMode.dictation,
),
```

---

## 📝 Notas Importantes

1. **Consumo de Batería**: La versión actual usa STT continuo, que consume más batería que Porcupine. En producción, migrar a Porcupine.

2. **Privacidad**: Todo el procesamiento es local. El audio solo se envía a Google para STT cuando se detecta voz.

3. **Foreground Service**: La versión actual NO incluye foreground service real. Se agregará cuando todo esté funcionando.

4. **Porcupine**: Para usar Porcupine en lugar de STT:
   - Obtener AccessKey en https://console.picovoice.ai/
   - Crear wake word personalizado "Hey ADAN"
   - Descarg archivo .ppn
   - Actualizar código en `_initPorcupine()`

---

## ✅ Checklist de Implementación

- [x] Agregar dependencias
- [x] Configurar permisos Android
- [x] Crear WakeWordService
- [x] Integrar con main.dart
- [ ] Integrar con AsistentePage
- [ ] Probar detección básica
- [ ] Optimizar batería
- [ ] Agregar foreground service real
- [ ] Migrar a Porcupine (opcional)
- [ ] Soporte iOS (futuro)

---

**Última actualización**: $(date)
**Estado**: ✅ Fases 1-3 completadas, Fase 4 pendiente
