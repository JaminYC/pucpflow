# Crear Índice de Firestore para ADAN

## Problema
ADAN necesita un índice compuesto en Firestore para buscar proyectos por `participantes` y `fechaCreacion`.

## Solución - Crear el índice manualmente

### Opción 1: Desde la consola de Firebase (Recomendado)

1. Ve a: https://console.firebase.google.com/project/pucp-flow/firestore/indexes

2. Click en **"Crear índice"** o **"Add Index"**

3. Configura el índice con estos valores:

   - **Collection ID**: `proyectos`
   - **Query scope**: `Collection`

   **Campos (Fields)**:
   - Campo 1:
     - **Field path**: `participantes`
     - **Query scope**: `Array-contains` o `CONTAINS`

   - Campo 2:
     - **Field path**: `fechaCreacion`
     - **Query scope**: `Descending` o `DESC`

4. Click en **"Crear"** o **"Create"**

5. Espera 5-10 minutos para que el índice se construya

### Opción 2: Usando el enlace directo de error

1. Cuando ADAN intente buscar proyectos, recibirás un error con un enlace directo para crear el índice

2. El error dirá algo como:
   ```
   The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/pucp-flow/firestore/indexes?create_composite=...
   ```

3. Haz click en ese enlace y confirma la creación del índice

### Opción 3: Comando de Firebase CLI

Ejecuta desde la raíz del proyecto:

```bash
firebase deploy
```

Esto desplegará automáticamente los índices definidos en `firestore.indexes.json`

## Verificar que el índice existe

```bash
firebase firestore:indexes
```

Deberías ver algo como:

```json
{
  "collectionGroup": "proyectos",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "participantes",
      "arrayConfig": "CONTAINS"
    },
    {
      "fieldPath": "fechaCreacion",
      "order": "DESCENDING"
    }
  ]
}
```

## Probar ADAN después de crear el índice

1. Espera 5-10 minutos después de crear el índice
2. Abre la app y ve al Asistente ADAN
3. Pregunta: "ADAN, léeme mis proyectos"
4. Debería responder con información de tus proyectos

## Estado Actual

- ✅ Función `adanChat` actualizada para buscar por `participantes`
- ✅ Archivo `firestore.indexes.json` creado
- ⏳ **Falta crear el índice en Firebase Console** (sigue los pasos arriba)

## Nota Importante

Si no creas el índice, ADAN seguirá diciendo "no tienes proyectos activos" aunque sí los tengas, porque Firestore requiere índices compuestos para queries con `array-contains` + `orderBy`.
