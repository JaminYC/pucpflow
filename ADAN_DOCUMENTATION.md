# ADAN - Asistente Digital Adaptativo Natural

## Resumen

ADAN es tu asistente personal inteligente tipo Jarvis, integrado en la aplicación PUCP Flow. Conecta con tu base de datos de Firestore para leer tus proyectos, tareas, habilidades y rendimiento, proporcionando respuestas contextualizadas y proactivas.

## Características Principales

### 1. Reconocimiento de Voz (STT)
- Escucha continuamente tu voz
- Captura texto en tiempo real
- Muestra el texto reconocido en un recuadro azul

### 2. Síntesis de Voz (TTS)
- Responde con voz natural
- Soporte para múltiples voces y velocidades
- Configuración personalizable de pitch y volumen

### 3. Inteligencia Artificial Contextual
- Usa GPT-4o-mini de OpenAI
- Accede a tu información personal de Firestore:
  - **Perfil de usuario**: Nombre, email, rol
  - **Proyectos**: Últimos 5 proyectos con progreso
  - **Tareas**: Últimas 10 tareas asignadas
  - **Habilidades**: Top 10 habilidades profesionales
  - **Estadísticas**: Rendimiento y productividad

### 4. Memoria de Conversación
- Recuerda los últimos 10 mensajes
- Mantiene contexto entre preguntas
- Conversaciones coherentes y naturales

## Cómo Usar ADAN

### Opción 1: Por Voz (Modo Automático)
1. Abre la página de ADAN
2. Habla claramente al micrófono
3. Observa el texto aparecer en el recuadro azul
4. **Importante**: Debido a un problema técnico actual, el reconocimiento de voz no finaliza automáticamente
5. **Solución**: Usa el botón azul "Enviar" después de hablar

### Opción 2: Prueba Manual
1. Haz clic en el botón morado "Prueba Manual"
2. Esto enviará la pregunta predefinida: "Hola ADAN, ¿cómo van mis proyectos?"
3. Útil para probar que todo funciona correctamente

### Opción 3: Envío Manual
1. Habla al micrófono
2. Espera a que el texto aparezca en el recuadro azul
3. Haz clic en el botón azul "Enviar"
4. ADAN procesará tu pregunta y responderá

## Indicadores Visuales

### Icono de Usuario (Esquina Superior Derecha)
- **Verde (👤)**: Usuario autenticado correctamente
- **Rojo (🚫)**: No hay usuario autenticado

### Estado del Micrófono
- **"Listening..."**: ADAN está escuchando
- **Texto en recuadro azul**: ADAN capturó tu voz

### Historial de Conversación
- Muestra tus preguntas y respuestas de ADAN
- Se actualiza en tiempo real

## Ejemplos de Uso

### Consultas sobre Proyectos
```
Tú: "¿Cómo van mis proyectos?"
ADAN: "Tienes 3 proyectos activos. El proyecto 'Sistema de Gestión' va al 75% de progreso..."
```

### Análisis de Rendimiento
```
Tú: "¿Cuál es mi rendimiento esta semana?"
ADAN: "Has completado 8 de 12 tareas pendientes. Tu tasa de finalización es del 67%..."
```

### Revisión de Tareas
```
Tú: "¿Qué tareas tengo pendientes?"
ADAN: "Tienes 4 tareas pendientes: 1) Diseño de interfaz (Alta prioridad)..."
```

### Análisis de Habilidades
```
Tú: "¿En qué habilidades soy más fuerte?"
ADAN: "Tus principales habilidades son: Flutter (nivel 8/10), Firebase (nivel 7/10)..."
```

## Arquitectura Técnica

### Frontend (AsistentePage.dart)
```dart
Componentes principales:
- speech_to_text: Reconocimiento de voz
- flutter_tts: Síntesis de voz
- FirebaseAuth: Autenticación de usuario
- Cloud Functions: Comunicación con backend
```

### Backend (functions/index.js)
```javascript
Función: adanChat
- Input: texto, userId, historial
- Procesamiento:
  1. Obtener datos de Firestore (proyectos, tareas, skills)
  2. Construir contexto completo del usuario
  3. Enviar a OpenAI GPT-4o-mini
  4. Retornar respuesta personalizada
- Output: respuesta de IA + estadísticas
```

### Flujo de Datos
```
Usuario habla → STT → Texto
    ↓
Texto + userId + historial → Cloud Function (adanChat)
    ↓
Firestore ← Obtener datos del usuario
    ↓
OpenAI GPT-4o-mini ← Contexto + pregunta
    ↓
Respuesta → TTS → Voz
    ↓
Usuario escucha
```

## Debugging

### Logs de Consola (con emojis)
- 👤 Usuario actual detectado
- 🆔 UserID capturado
- 🎙️ Resultado de reconocimiento de voz
- 📝 Texto procesado
- ✅ Resultado final detectado
- ⏳ Resultado parcial (esperando final)
- 📞 Inicio de llamada a Cloud Function
- 🔥 Llamando a adanChat
- 📦 Payload enviado
- 📥 Respuesta recibida
- 💬 Reply extraído
- 🎯 Procesando texto
- ❌ Error detectado

### Problemas Comunes y Soluciones

#### Problema 1: ADAN no responde
**Síntoma**: Hablas pero no hay respuesta
**Diagnóstico**:
- Verifica icono de usuario (debe ser verde)
- Revisa logs de consola para errores
**Solución**:
- Haz clic en botón "Refresh" (🔄)
- Si persiste, usa botón "Enviar" manualmente

#### Problema 2: finalResult siempre false
**Síntoma**: Texto capturado pero nunca se envía automáticamente
**Causa**: Timeout de reconocimiento de voz no se completa
**Solución temporal**: Usa botón azul "Enviar"
**Solución permanente (pendiente)**: Ajustar timeout o implementar detección de silencio

#### Problema 3: Error de CORS
**Síntoma**: Error en consola sobre CORS policy
**Solución**: Ya resuelto - todas las Cloud Functions tienen `cors: true`

## Configuración Avanzada

### Modificar Voz de ADAN
En AsistentePage.dart:
```dart
// Cambiar voz
await _tts.setVoice({"name": "nombre_de_voz", "locale": "es-ES"});

// Cambiar velocidad (0.0 - 1.0)
await _tts.setSpeechRate(0.5);

// Cambiar pitch (0.5 - 2.0)
await _tts.setPitch(1.0);
```

### Modificar Personalidad de ADAN
En functions/index.js, línea ~680:
```javascript
const systemPrompt = `
Eres ADAN (Asistente Digital Adaptativo Natural)...
TU PERSONALIDAD:
- [Modifica aquí la personalidad]
`;
```

### Ajustar Cantidad de Datos
En functions/index.js:
```javascript
// Más proyectos
.limit(10) // Cambiar de 5 a 10

// Más tareas
.limit(20) // Cambiar de 10 a 20

// Más mensajes de historial
...history.slice(-20) // Cambiar de -10 a -20
```

## Seguridad y Privacidad

- ADAN solo accede a datos del usuario autenticado
- Requiere Firebase Authentication activa
- No almacena conversaciones en base de datos (solo en memoria)
- Usa HTTPS para todas las comunicaciones
- API de OpenAI no entrena modelos con tus datos

## Próximas Mejoras

- [ ] Corregir problema de finalResult en STT
- [ ] Implementar detección automática de silencio
- [ ] Agregar comandos de voz especiales ("ADAN, silencio", "ADAN, repite")
- [ ] Visualización gráfica de estadísticas
- [ ] Integración con calendario y recordatorios
- [ ] Modo manos libres completo

## Soporte

Si encuentras problemas:
1. Revisa los logs de consola (busca emojis 🎙️ 📞 ❌)
2. Verifica que estés autenticado (icono verde 👤)
3. Prueba el botón "Prueba Manual" para verificar conexión
4. Refresca la aplicación con el botón 🔄

## Créditos

- **Modelo de IA**: OpenAI GPT-4o-mini
- **Backend**: Firebase Cloud Functions
- **Base de datos**: Firestore
- **Frontend**: Flutter
- **STT**: speech_to_text package
- **TTS**: flutter_tts package
