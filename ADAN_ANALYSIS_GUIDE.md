# Guía de Análisis de Proyectos con ADAN

## ¿Qué puede hacer ADAN ahora?

ADAN (Asistente Digital Adaptativo Natural) ahora cuenta con capacidades avanzadas de análisis de proyectos. Puede leer, analizar y darte recomendaciones inteligentes sobre tus proyectos de gestión.

---

## Información que ADAN puede analizar

### Por Proyecto:
- **Estado** y **Progreso** actual (%)
- **Descripción** y **Metodología** (Scrum/Kanban/General)
- **Total de tareas** y su **tasa de completitud**
- **Tareas pendientes** por prioridad (Alta, Media, Baja)
- **Tareas asignadas a ti** específicamente
- **Sprint activo** (si usa Scrum): nombre, objetivo, días restantes
- **Fecha de creación** del proyecto

### Métricas Globales:
- Promedio de progreso en todos tus proyectos
- Tasa de completitud de tus tareas personales
- Total de tareas en todos los proyectos
- Proyectos en estado crítico (< 30% progreso)
- Comparación entre proyectos (cuál va mejor/peor)

---

## Cómo pedirle a ADAN que lea tus proyectos

### Ejemplos de preguntas que puedes hacer:

#### 1. Ver todos los proyectos
```
"ADAN, léeme mis proyectos"
"Cuéntame sobre mis proyectos"
"¿Qué proyectos tengo?"
"Dame un resumen de mis proyectos"
```

**ADAN responderá con:**
- Cantidad total de proyectos
- Estado y progreso de cada uno
- Tareas pendientes por proyecto
- Cuál necesita más atención

#### 2. Analizar un proyecto específico
```
"¿Cómo va el proyecto X?"
"Cuéntame sobre el proyecto de Marketing"
"¿Qué tal está el proyecto PMI UI?"
```

**ADAN te dirá:**
- Estado actual y progreso porcentual
- Tareas completadas vs pendientes
- Tareas de alta prioridad
- Sprint activo (si aplica)
- Recomendaciones específicas

#### 3. Obtener recomendaciones
```
"¿En qué debería trabajar hoy?"
"¿Qué proyecto necesita más atención?"
"¿Cuál es mi prioridad ahora?"
"¿Qué tareas urgentes tengo?"
```

**ADAN sugerirá:**
- Proyecto más crítico
- Tareas de alta prioridad específicas
- Redistribución de esfuerzo si es necesario
- Enfoque del día basado en plazos

#### 4. Análisis de rendimiento
```
"¿Cómo va mi rendimiento?"
"¿Cuántas tareas tengo pendientes?"
"¿Estoy progresando bien?"
```

**ADAN analizará:**
- Tasa de completitud de tus tareas
- Promedio de progreso en proyectos
- Carga de trabajo actual
- Patrones de productividad

---

## Capacidades de Análisis Automático

ADAN detecta automáticamente:

### Alertas de Riesgo:
- 🔴 Proyectos con < 30% progreso → "El proyecto X está algo atrasado"
- 🔴 Muchas tareas de alta prioridad acumuladas → "Tienes varias tareas urgentes"
- ⚠️ Sprint próximo a terminar → "El sprint actual termina en X días"
- ⚠️ Baja tasa de completitud (< 50%) → "Hay bastantes tareas pendientes, prioricemos"

### Recomendaciones Inteligentes:
- Qué proyecto atacar primero
- Cuáles tareas son más urgentes
- Si estás sobrecargado o subutilizado
- Oportunidades de mejora

---

## Ejemplo de Conversación Real

```
Tú: "ADAN, léeme mis proyectos"

ADAN: "Tienes 3 proyectos activos. El proyecto PMI UI va muy bien,
con 75% de progreso y 8 de 10 tareas completadas. Sin embargo, el
proyecto Marketing está algo atrasado con solo 20% de progreso y tiene
5 tareas de alta prioridad pendientes. Te recomiendo enfocarte hoy en
ese proyecto."

Tú: "¿Qué debo hacer en Marketing?"

ADAN: "El proyecto Marketing tiene 5 tareas urgentes sin atender.
Empezaría por las 2 tareas de alta prioridad: Diseño de Landing Page
y Estrategia de Redes Sociales. Además, el sprint actual termina en
3 días, así que es momento de acelerar."
```

---

## Estructura de Datos que ADAN Lee

### Contexto Completo por Proyecto:
```
━━━ NOMBRE DEL PROYECTO ━━━
  📝 Descripción: [descripción]
  📊 Estado: [estado] | Progreso general: X%
  🎯 Metodología: Scrum/Kanban/general
  📅 Creado: [fecha]

  📋 TAREAS:
    • Total: X tareas
    • Completadas: X (X%)
    • Pendientes: X
    • Asignadas a ti: X tareas (X pendientes)

  🎯 PRIORIDADES PENDIENTES:
    • Alta: X tareas
    • Media: X tareas
    • Baja: X tareas

  🏃 SPRINT ACTUAL: [si aplica]
    • Nombre: [nombre]
    • Objetivo: [objetivo]
    • Días restantes: X
```

---

## Consejos de Uso

1. **Sé Natural**: Habla con ADAN como si fuera un colega. No necesitas comandos específicos.

2. **Sé Específico**: Si quieres info de un proyecto particular, menciona su nombre.

3. **Pide Recomendaciones**: ADAN es proactivo, pídele que te sugiera en qué enfocarte.

4. **Usa para Planificación Diaria**: Pregúntale cada mañana "¿en qué debería trabajar hoy?"

5. **Aprovecha el Análisis**: Pídele que compare proyectos o identifique riesgos.

6. **Conversaciones Continuas**: ADAN recuerda las últimas 10 interacciones, puedes tener conversaciones fluidas.

---

## Formato de Respuestas de ADAN

ADAN responde de manera:
- **Corta y Conversacional**: Máximo 3-4 oraciones (ideal para síntesis de voz)
- **Específica**: Usa números y datos exactos ("tienes 5 tareas", no "varias tareas")
- **Directa**: Da recomendaciones concretas, no genéricas
- **Natural**: Con conectores como "bueno", "entonces", "mira", "además"
- **Sin markdown**: No usa asteriscos ni emojis (para mejor lectura TTS)

---

## Limitaciones Actuales

- Lee hasta 5 proyectos más recientes
- Analiza hasta 10 tareas por proyecto
- Solo proyectos donde eres creador (campo `creadorId`)
- Necesita datos en Firestore con estructura correcta

---

## Próximas Mejoras

- Análisis predictivo de plazos
- Detección de bloqueos en tareas
- Sugerencias de redistribución de equipo
- Análisis de velocidad de sprint
- Comparación temporal (esta semana vs anterior)

---

## Soporte y Feedback

Si ADAN no puede leer tus proyectos, verifica:
1. Que tengas proyectos creados en Firestore
2. Que el campo `creadorId` sea tu `userId`
3. Que estés autenticado en la app

Para reportar problemas o sugerencias, contacta al equipo de desarrollo.
