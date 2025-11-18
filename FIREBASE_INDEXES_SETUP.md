# Configuración de Índices de Firestore

Este documento explica cómo configurar los índices compuestos necesarios para el sistema de Skills.

## ¿Por qué son necesarios los índices?

Firestore requiere índices compuestos cuando realizas consultas que:
1. Ordenan por un campo Y filtran por otro campo
2. Usan múltiples filtros WHERE en diferentes campos

El sistema de skills usa consultas como:
```dart
.where('status', isEqualTo: 'pending')
.orderBy('createdAt', descending: true)
```

Esto requiere un índice compuesto en `status` + `createdAt`.

---

## Método 1: Crear índices automáticamente desde el error (Recomendado)

Cuando ejecutas la app y ves un error como:

```
❌ Error: The query requires an index. You can create it here:
https://console.firebase.google.com/v1/r/project/pucp-flow/firestore/indexes?create_composite=...
```

**Pasos:**
1. Copia el enlace completo del error
2. Pégalo en tu navegador
3. Firebase Console se abrirá con el índice preconfigurado
4. Haz clic en **"Create Index"**
5. Espera 2-5 minutos para que el índice se construya
6. Recarga tu app

---

## Método 2: Crear índices manualmente

### Paso 1: Acceder a Firebase Console

Ve a: https://console.firebase.google.com/project/pucp-flow/firestore/indexes

### Paso 2: Ir a la pestaña "Indexes"

1. En el menú lateral, selecciona **Firestore Database**
2. Haz clic en la pestaña **"Indexes"** (Índices)

### Paso 3: Crear el índice para skill_suggestions

Haz clic en **"Create Index"** y configura:

**Índice 1: Sugerencias por status y fecha**
- **Collection ID**: `skill_suggestions`
- **Fields indexed**:
  1. Campo: `status`, Orden: `Ascending`
  2. Campo: `createdAt`, Orden: `Descending`
- **Query scope**: Collection
- Haz clic en **"Create"**

**Índice 2: Sugerencias pendientes por frecuencia (opcional, para optimizar)**
- **Collection ID**: `skill_suggestions`
- **Fields indexed**:
  1. Campo: `status`, Orden: `Ascending`
  2. Campo: `frequency`, Orden: `Descending`
  3. Campo: `createdAt`, Orden: `Descending`
- **Query scope**: Collection
- Haz clic en **"Create"**

**Índice 3: Professional skills por suggestionId (IMPORTANTE para aprobar/fusionar)**
- **Collection Group ID**: `professional_skills` (marcar "Collection group")
- **Fields indexed**:
  1. Campo: `suggestionId`, Orden: `Ascending`
- **Query scope**: Collection group
- Haz clic en **"Create"**

> ⚠️ **IMPORTANTE**: Este índice es necesario para que las funciones de Aprobar y Fusionar actualicen automáticamente los perfiles de TODOS los usuarios que tienen la skill sugerida. Sin este índice, solo se actualizará el perfil del usuario que sugirió la skill.

### Paso 4: Esperar la construcción

Los índices pueden tardar entre **2 y 10 minutos** en construirse dependiendo del tamaño de tu base de datos.

Verás el estado en la consola:
- 🔵 **Building** (Construyendo)
- ✅ **Enabled** (Habilitado)

---

## Método 3: Usar el archivo firestore.indexes.json (Avanzado)

Puedes definir los índices en un archivo y desplegarlos con Firebase CLI.

### Paso 1: Crear firestore.indexes.json

Crea el archivo en la raíz de tu proyecto:

```json
{
  "indexes": [
    {
      "collectionGroup": "skill_suggestions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "skill_suggestions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "frequency",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### Paso 2: Desplegar con Firebase CLI

```bash
firebase deploy --only firestore:indexes
```

---

## Verificar que los índices estén funcionando

1. Ve a Firebase Console > Firestore > Indexes
2. Verifica que el estado sea **"Enabled"** (verde)
3. Ejecuta tu app y verifica que no haya errores de índices

---

## Solución temporal: Filtrado en cliente

Si no quieres crear índices inmediatamente, el código ya está configurado para filtrar en el cliente:

```dart
// En admin_skills_service.dart
Future<List<SkillSuggestion>> getSuggestionsByStatus(String status) async {
  // Obtiene TODAS las sugerencias
  final snapshot = await _firestore.collection('skill_suggestions').get();

  // Filtra en el cliente (sin necesidad de índice)
  final suggestions = snapshot.docs
    .map((doc) => SkillSuggestion.fromFirestore(doc))
    .where((suggestion) => suggestion.status == status)
    .toList();

  // Ordena en memoria
  suggestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return suggestions;
}
```

**Ventaja**: No requiere índices
**Desventaja**: Lee todos los documentos (costoso con muchos datos)

---

## Mejoras del sistema de administración

Los diálogos de administración ahora incluyen:

### 🟢 Diálogo de Aprobar
- ✅ Búsqueda automática de skills similares
- ✅ Advertencia si hay duplicados potenciales
- ✅ Autocompletado de sectores existentes
- ✅ Vista del contexto del CV

### 🔵 Diálogo de Fusionar
- ✅ Búsqueda automática de skills similares al abrir
- ✅ Búsqueda en tiempo real mientras escribes
- ✅ Vista del sector de cada skill existente
- ✅ Descripción de skills para mejor contexto
- ✅ Muestra frecuencia y contexto de la sugerencia

### 🔴 Diálogo de Rechazar
- ✅ Vista completa de la información de la sugerencia
- ✅ Contexto del CV
- ✅ Email del usuario que sugirió
- ✅ Frecuencia de sugerencia

---

## Contacto

Si tienes problemas configurando los índices, revisa:
- [Documentación oficial de Firestore Indexes](https://firebase.google.com/docs/firestore/query-data/indexing)
- El log de errores en la consola de Firebase

---

**Última actualización**: $(date)
**Proyecto**: PUCP Flow - Sistema de Skills
