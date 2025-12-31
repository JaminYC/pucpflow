# Análisis: Sistema de Briefing Diario

**Fecha:** 2025-12-31
**Propósito:** Planificar la implementación de un sistema de briefing diario con las tareas del día

---

## 📋 Resumen del Requerimiento

El usuario quiere implementar un **briefing diario** que muestre las tareas del día y lo que hay que tener en cuenta. Este briefing debe ser proactivo y ayudar al usuario a comenzar su jornada con claridad.

---

## 🔍 Estado Actual del Sistema

### Estructura de Datos Existente

#### 1. **Modelo de Tareas** (`tarea_model.dart`)
- ✅ Las tareas ya tienen campos esenciales:
  - `titulo`: Nombre de la tarea
  - `fecha`: Fecha programada (DateTime nullable)
  - `prioridad`: Nivel de prioridad (int)
  - `completado`: Estado de completitud (bool)
  - `duracion`: Duración estimada en minutos
  - `descripcion`: Descripción detallada
  - `responsables`: Lista de responsables
  - `fasePMI`: Fase del proyecto (opcional)
  - `entregable`: Entregable asociado
  - `paqueteTrabajo`: Paquete de trabajo PMI
  - `area`: Área de trabajo
  - `habilidadesRequeridas`: Skills necesarias
  - `tareasPrevias`: Dependencias

#### 2. **Calendario de Eventos** (`calendar_events_page.dart`)
- ✅ Ya integra eventos de:
  - Google Calendar
  - Tareas de Firestore de todos los proyectos
- ✅ Usa `table_calendar` para visualización
- ✅ Filtra eventos por día

#### 3. **Dashboard** (`DashboardPage.dart`)
- ✅ Muestra métricas de bienestar
- ✅ Rastrea completitud de tareas
- ✅ Tiene visualizaciones de progreso

#### 4. **Asistente IA** (`AsistentePage.dart`)
- ✅ Integración con Cloud Functions
- ✅ Soporte de texto y voz (STT/TTS)
- ✅ ElevenLabs para voz sintética
- ✅ Historial de conversación
- ✅ Acceso a Firestore (userId, proyectos)

### Tecnologías Disponibles

1. **Notificaciones Locales**
   - `flutter_local_notifications: ^17.0.0` ✅ Ya instalado
   - `timezone: ^0.9.2` ✅ Ya instalado

2. **IA y Asistente**
   - `cloud_functions: ^5.3.4` ✅ Cloud Functions
   - `speech_to_text: ^7.0.0` ✅ STT
   - `flutter_tts: ^4.2.3` ✅ TTS
   - Wake word detection disponible

3. **Almacenamiento**
   - `cloud_firestore` ✅ Para persistencia
   - `shared_preferences` ✅ Para configuraciones locales

4. **UI/UX**
   - `lottie`, `rive` para animaciones
   - `fl_chart` para gráficas
   - `table_calendar` para calendario

---

## 💡 Propuestas de Implementación

### Opción 1: **Briefing Visual (Página Dedicada)**

#### Descripción
Una página nueva que se muestra al inicio del día con un resumen visual y organizado de las tareas.

#### Características
- **Vista Matutina Automática**: Se abre automáticamente la primera vez que se abre la app cada día
- **Diseño Dashboard-Style**: Similar a DashboardPage pero enfocado en el día actual
- **Secciones:**
  1. Saludo personalizado con la hora del día
  2. Resumen del día (número de tareas, horas estimadas, prioridades)
  3. Tareas organizadas por:
     - Prioridad (Alta → Media → Baja)
     - Proyecto
     - Hora programada
  4. Eventos de Google Calendar del día
  5. Métricas rápidas (tareas completadas ayer, racha actual)
  6. "Quick wins" - tareas cortas que se pueden hacer rápido

#### Ventajas
- ✅ Control total sobre UX/UI
- ✅ No requiere permisos adicionales
- ✅ Fácil de iterar y mejorar
- ✅ Integración natural con la app

#### Desventajas
- ❌ Requiere que el usuario abra la app
- ❌ No es proactivo fuera de la app

---

### Opción 2: **Briefing por Voz con IA (Asistente Proactivo)**

#### Descripción
El asistente ADAN genera un briefing verbal cada mañana usando IA para crear un resumen inteligente.

#### Características
- **Activación Programada**:
  - Notificación a hora configurable (ej: 7:00 AM)
  - O activación por comando de voz ("Adan, mi briefing del día")
- **Generación Inteligente con IA**:
  - Analiza tareas del día
  - Identifica conflictos de horario
  - Sugiere reorganización si hay sobrecarga
  - Destaca dependencias críticas
  - Recuerda compromisos importantes
- **Salida de Audio**:
  - TTS nativo o ElevenLabs
  - Tono motivacional/profesional configurable
- **Interacción**:
  - "¿Quieres que mueva alguna tarea?"
  - "¿Necesitas recordatorios para algo específico?"

#### Ventajas
- ✅ Manos libres (perfecto para rutina matutina)
- ✅ Usa IA para insights inteligentes
- ✅ Muy diferenciador
- ✅ Aprovecha infraestructura existente (AsistentePage)

#### Desventajas
- ❌ Consume tokens de IA diariamente
- ❌ Requiere conectividad
- ❌ Más complejo de implementar

---

### Opción 3: **Notificación Rica con Resumen**

#### Descripción
Notificación push local cada mañana con resumen textual de las tareas del día.

#### Características
- **Notificación Programada**:
  - Hora configurable por usuario
  - Se programa automáticamente cada noche
- **Contenido de la Notificación**:
  - Título: "Buenos días! Tienes 5 tareas hoy"
  - Cuerpo: Lista breve de las 3-4 tareas más prioritarias
  - Acciones: "Ver todas", "Posponer 1h", "Marcar como visto"
- **Al hacer tap**: Abre la vista de briefing completa (Opción 1)

#### Ventajas
- ✅ Proactivo sin abrir la app
- ✅ Bajo consumo de recursos
- ✅ Fácil de implementar
- ✅ No requiere conectividad

#### Desventajas
- ❌ Limitaciones de espacio en notificación
- ❌ Menos interactivo
- ❌ Permisos de notificación necesarios

---

### Opción 4: **Enfoque Híbrido (Recomendado)**

#### Descripción
Combina las mejores partes de las opciones anteriores para una experiencia completa.

#### Flujo de Usuario

**Por la Mañana (7:00 AM - configurable):**
1. ⏰ **Notificación Local** aparece:
   ```
   ☀️ Buenos días! Tienes 5 tareas hoy
   🔥 2 prioritarias | ⏱️ 6.5 horas estimadas
   Tap para ver tu briefing →
   ```

2. 📱 **Al hacer tap**, se abre **BriefingDiarioPage**:
   - Hero animation desde la notificación
   - Diseño atractivo tipo dashboard matutino
   - Secciones organizadas y accionables

3. 🎙️ **Botón de "Escuchar Briefing"**:
   - Llama al asistente IA
   - Genera briefing verbal personalizado
   - Insights y sugerencias inteligentes

**Durante el Día:**
- Accesible desde menú principal
- Widget compacto en HomePage mostrando tareas pendientes
- Actualización en tiempo real

**En la Noche (opcional):**
- Notificación de cierre del día
- "¿Cómo te fue hoy? 3 de 5 tareas completadas"
- Botón para preparar el día siguiente

#### Componentes Necesarios

1. **BriefingDiarioPage** (Nueva)
   - Vista principal del briefing
   - Componentes visuales
   - Integración con calendario

2. **BriefingService** (Nuevo)
   - Lógica de negocio para briefing
   - Obtención de tareas del día
   - Cálculo de métricas
   - Detección de conflictos

3. **BriefingNotificationService** (Nuevo)
   - Programación de notificaciones
   - Generación de contenido de notificación
   - Manejo de acciones

4. **Función Cloud: `generateDailyBriefing`** (Nueva)
   - Recibe: userId, fecha
   - Analiza: tareas, eventos, historial
   - Retorna: briefing estructurado con insights

5. **Widget: BriefingCompactCard** (Nuevo)
   - Tarjeta compacta para HomePage
   - Muestra resumen rápido
   - Link a vista completa

---

## 🏗️ Arquitectura Propuesta (Opción 4)

```
┌─────────────────────────────────────────────────────┐
│           CAPA DE PRESENTACIÓN                       │
├─────────────────────────────────────────────────────┤
│  BriefingDiarioPage                                 │
│  ├── BriefingHeaderCard (Saludo + Resumen)         │
│  ├── TareasDelDiaSection                           │
│  │   ├── TareaPrioritariaCard                      │
│  │   ├── TareaNormalCard                           │
│  │   └── EventosGoogleCard                         │
│  ├── MetricasRapidasSection                        │
│  ├── InsightsIASection (opcional)                  │
│  └── FloatingVoiceBriefingButton                   │
│                                                      │
│  BriefingCompactCard (Widget en HomePage)          │
└─────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────┐
│           CAPA DE LÓGICA DE NEGOCIO                 │
├─────────────────────────────────────────────────────┤
│  BriefingService                                    │
│  ├── getTareasDelDia(userId, fecha)                │
│  ├── getEventosDelDia(userId, fecha)               │
│  ├── calcularMetricasBriefing()                    │
│  ├── detectarConflictosHorarios()                  │
│  └── generarResumenTexto()                         │
│                                                      │
│  BriefingNotificationService                        │
│  ├── scheduleNextDayBriefing()                     │
│  ├── createBriefingNotification()                  │
│  └── handleNotificationTap()                       │
└─────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────┐
│           CAPA DE DATOS                             │
├─────────────────────────────────────────────────────┤
│  Firestore                                          │
│  ├── proyectos/{proyectoId}/tareas/{tareaId}      │
│  └── usuarios/{userId}/configuracion/briefing      │
│                                                      │
│  Google Calendar API                                │
│  └── events.list(timeMin, timeMax)                 │
│                                                      │
│  Cloud Functions                                    │
│  └── generateDailyBriefing(userId, fecha)          │
│      ├── Analiza tareas y eventos                  │
│      ├── Genera insights con IA                    │
│      └── Retorna briefing estructurado             │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Modelo de Datos

### BriefingDiario (Model)

```dart
class BriefingDiario {
  final DateTime fecha;
  final String saludo;
  final BriefingMetrics metrics;
  final List<TareaBriefing> tareasPrioritarias;
  final List<TareaBriefing> tareasNormales;
  final List<CalendarEvent> eventos;
  final List<String> insights; // Generados por IA
  final List<String> conflictos; // Conflictos de horario detectados

  BriefingDiario({...});
}

class BriefingMetrics {
  final int totalTareas;
  final int tareasCompletadasAyer;
  final int horasEstimadas;
  final int tareasPrioritarias;
  final int rachaActual;
  final double cargaDelDia; // 0.0 - 1.0 (basado en horas disponibles)

  BriefingMetrics({...});
}

class TareaBriefing {
  final String tareaId;
  final String proyectoId;
  final String titulo;
  final DateTime? horaInicio;
  final int duracion;
  final int prioridad;
  final String? fasePMI;
  final List<String> tareasPrevias;
  final bool tieneDependenciasPendientes;
  final String motivoPrioridad; // "Deadline cercano", "Bloqueante", etc.

  TareaBriefing({...});
}
```

### Configuración de Usuario

```dart
class BriefingConfig {
  final bool habilitado;
  final TimeOfDay horaBriefing; // Default: 7:00 AM
  final bool incluirEventosGoogle;
  final bool usarVozIA;
  final bool notificacionNocturna; // Resumen del día
  final int diasAnticipacion; // Cuántos días adelante ver (default: 1)

  BriefingConfig({...});
}
```

Almacenado en:
```
usuarios/{userId}/configuracion/briefing
```

---

## 🎨 Diseño de UI (BriefingDiarioPage)

### Secciones Visuales

#### 1. **Header Card**
```
┌──────────────────────────────────────────────┐
│  ☀️  Buenos días, [Nombre]                   │
│                                               │
│  🗓️  Martes, 31 de Diciembre 2025           │
│                                               │
│  ┌─────────┬─────────┬─────────┬──────────┐ │
│  │ 5 tareas│ 2 altas │ 6.5h est│ 🔥 80%   │ │
│  │    📋   │   ⚡     │   ⏱️    │  carga   │ │
│  └─────────┴─────────┴─────────┴──────────┘ │
└──────────────────────────────────────────────┘
```

#### 2. **Tareas Prioritarias**
```
┌──────────────────────────────────────────────┐
│  ⚡ Tareas Prioritarias                      │
│                                               │
│  🔴 [09:00] Reunión con stakeholders         │
│      📁 Proyecto: Sistema CRM                │
│      ⏱️ 90 min | 🏷️ Planificación PMI       │
│      💡 Bloqueante para 2 tareas             │
│                                               │
│  🔴 [14:00] Revisión de código crítico       │
│      📁 Proyecto: API Gateway                │
│      ⏱️ 120 min | 👥 Juan, María             │
│      ⚠️ Deadline mañana                      │
└──────────────────────────────────────────────┘
```

#### 3. **Otras Tareas**
```
┌──────────────────────────────────────────────┐
│  📝 Otras Tareas del Día                     │
│                                               │
│  🟡 [11:00] Documentar API endpoints         │
│      ⏱️ 60 min | 📁 API Gateway              │
│                                               │
│  🟢 Actualizar tests unitarios               │
│      ⏱️ 45 min | 📁 Sistema CRM              │
└──────────────────────────────────────────────┘
```

#### 4. **Insights de IA** (opcional)
```
┌──────────────────────────────────────────────┐
│  💡 Insights y Recomendaciones               │
│                                               │
│  • Hoy tienes una carga alta (80%). Conside- │
│    ra mover tareas no críticas a mañana.     │
│                                               │
│  • La reunión de las 9:00 puede extenderse.  │
│    Deja un buffer de 30 min después.         │
│                                               │
│  • Llevas 5 días completando >80% de tareas. │
│    ¡Excelente racha! 🔥                      │
└──────────────────────────────────────────────┘
```

#### 5. **Botón de Voz**
```
┌──────────────────────────────────────────────┐
│                                               │
│          🎙️ Escuchar Briefing                │
│          (Narrado por ADAN)                   │
│                                               │
└──────────────────────────────────────────────┘
```

---

## 🔧 Consideraciones Técnicas

### 1. **Permisos Requeridos**
- ✅ Notificaciones locales (iOS/Android)
- ✅ Programación de notificaciones en background
- ⚠️ Verificar si ya están solicitados en la app

### 2. **Rendimiento**
- **Caching**: Generar briefing una vez al día y cachear
- **Lazy Loading**: Cargar detalles de tareas solo cuando sea necesario
- **Optimización de Consultas**: Usar queries eficientes en Firestore

### 3. **Costos de IA**
- **Cloud Functions**: ~$0.0001 por invocación
- **OpenAI/Claude API**: ~$0.01 por briefing (depende del modelo)
- **Estimado mensual** (30 usuarios activos): ~$10-20/mes

### 4. **Offline Support**
- Briefing debe funcionar offline si ya fue cargado
- Notificación debe aparecer incluso sin conexión
- Sincronizar cuando vuelva la conectividad

### 5. **Localización**
- Soportar múltiples idiomas (español, inglés)
- Formateo de fechas y horas según locale
- Saludos contextuales según hora del día

---

## 📅 Plan de Implementación Sugerido

### Fase 1: MVP (Semana 1)
1. **BriefingService** básico
   - Obtener tareas del día desde Firestore
   - Calcular métricas simples
   - Generar resumen textual

2. **BriefingDiarioPage** simple
   - Header con saludo y métricas
   - Lista de tareas del día
   - Navegación desde HomePage

3. **Testing**
   - Validar carga de datos
   - Verificar UI en diferentes dispositivos

### Fase 2: Notificaciones (Semana 2)
1. **BriefingNotificationService**
   - Programación de notificación matutina
   - Contenido dinámico basado en tareas
   - Navegación al tap

2. **Configuración de Usuario**
   - Página de settings para briefing
   - Toggle on/off
   - Selección de hora preferida

### Fase 3: IA y Voz (Semana 3)
1. **Cloud Function: generateDailyBriefing**
   - Análisis de tareas con IA
   - Generación de insights
   - Detección de conflictos

2. **Integración de Voz**
   - Botón para escuchar briefing
   - Usar AsistentePage existente
   - Soporte ElevenLabs

### Fase 4: Refinamiento (Semana 4)
1. **Mejoras de UX**
   - Animaciones fluidas
   - Diseño pulido
   - Micro-interacciones

2. **Features Adicionales**
   - Briefing semanal
   - Resumen nocturno
   - Estadísticas de productividad

---

## ⚠️ Riesgos y Mitigaciones

### Riesgo 1: Baja Adopción
- **Mitigación**:
  - Onboarding explicativo la primera vez
  - Demostración con datos de ejemplo
  - Destacar beneficios claros

### Riesgo 2: Notificaciones Molestas
- **Mitigación**:
  - Fácil desactivación desde settings
  - Respetar "No molestar" del sistema
  - Permitir personalización total

### Riesgo 3: Costos de IA Elevados
- **Mitigación**:
  - Briefing básico sin IA por default
  - IA como feature premium/opcional
  - Limitar llamadas a IA (1 por día)

### Riesgo 4: Complejidad de Implementación
- **Mitigación**:
  - Approach incremental (MVP primero)
  - Reutilizar código existente (CalendarEventsPage, AsistentePage)
  - Documentar bien la arquitectura

---

## 🎯 Métricas de Éxito

1. **Engagement**
   - % de usuarios que abren el briefing diario
   - Tiempo promedio en BriefingDiarioPage
   - Tasa de uso del briefing de voz

2. **Productividad**
   - % de tareas completadas vs planificadas
   - Mejora en puntualidad (tareas completadas a tiempo)
   - Reducción de tareas olvidadas

3. **Satisfacción**
   - Rating del feature (in-app survey)
   - NPS relacionado con briefing
   - Retención de usuarios que usan briefing

---

## 📝 Preguntas para el Usuario

Antes de comenzar la implementación, es importante clarificar:

1. **Alcance**:
   - ¿Prefieres empezar con un MVP simple o la solución completa?
   - ¿Es prioritaria la voz con IA o puede ser una fase posterior?

2. **Horario**:
   - ¿A qué hora ideal debería aparecer el briefing?
   - ¿Debería ser configurable por usuario desde el inicio?

3. **Contenido**:
   - ¿Qué información es MÁS importante mostrar?
   - ¿Debería incluir tareas de varios días o solo hoy?

4. **Integración**:
   - ¿Desde dónde debería ser accesible? (HomePage, menú, notificación)
   - ¿Reemplazar alguna vista existente o agregar nueva?

5. **IA**:
   - ¿Cuál es el presupuesto mensual aceptable para llamadas de IA?
   - ¿Los insights de IA son imprescindibles o nice-to-have?

---

## 🚀 Recomendación Final

**Recomiendo implementar la Opción 4 (Híbrido) de forma incremental:**

1. **Sprint 1**: BriefingDiarioPage básica + BriefingService
2. **Sprint 2**: Notificaciones matutinas
3. **Sprint 3**: Integración con IA y voz
4. **Sprint 4**: Pulido y features avanzadas

Esta aproximación permite:
- ✅ Valor rápido para el usuario
- ✅ Validar la utilidad del feature antes de invertir en IA
- ✅ Mantener costos controlados
- ✅ Iterar basado en feedback real

---

## 📚 Referencias de Código Existente

Para la implementación, reutilizar:
- `CalendarEventsPage`: Lógica de obtención de tareas y eventos
- `DashboardPage`: Diseño de cards y métricas
- `AsistentePage`: Integración de voz y IA
- `tarea_model.dart`: Modelo de datos ya definido
- `flutter_local_notifications`: Ya está en pubspec.yaml

---

**¿Estás listo para comenzar con la implementación?**
Espero tu aprobación y clarificación de las preguntas para proceder.
