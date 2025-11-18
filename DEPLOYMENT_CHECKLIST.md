# ✅ Checklist de Despliegue - Sistema Híbrido de Skills

Este documento te guía paso a paso para desplegar el sistema completo en producción.

---

## 📋 Pre-requisitos

- [ ] Firebase CLI instalado (`npm install -g firebase-tools`)
- [ ] Autenticado en Firebase (`firebase login`)
- [ ] Proyecto seleccionado (`firebase use pucp-flow`)
- [ ] OpenAI API key configurada en Firebase Secrets

---

## 🚀 Pasos de Despliegue

### **1. Desplegar Índices de Firestore** ⏱️ ~10 minutos

```bash
cd E:\FLOW\pucpflow
firebase deploy --only firestore:indexes
```

**Qué hace:**
- Crea índice en `skill_suggestions` para filtrado por status
- Crea índice en `professional_skills` (collection group) para actualización masiva
- Optimiza las consultas del panel de administración

**Verificar:**
- [ ] Ve a: https://console.firebase.google.com/project/pucp-flow/firestore/indexes
- [ ] Verifica que los 3 índices estén en estado "Enabled" (verde)
- [ ] Espera a que todos cambien de "Building" a "Enabled"

**Índices esperados:**
```
✅ skill_suggestions (Collection)
   - status: Ascending
   - createdAt: Descending

✅ skill_suggestions (Collection)
   - status: Ascending
   - frequency: Descending
   - createdAt: Descending

✅ professional_skills (Collection Group) ⭐ IMPORTANTE
   - suggestionId: Ascending
```

---

### **2. Desplegar Cloud Functions** ⏱️ ~10 minutos

```bash
firebase deploy --only functions
```

**Qué hace:**
- Despliega `extraerCV` - Procesa CVs con OpenAI GPT-4o-mini
- Despliega `guardarSkillsConfirmadas` - Guarda skills estándar + custom
- Despliega `gestionarSugerenciaSkill` - Panel de administración

**Verificar:**
- [ ] El comando termina con "Deploy complete!"
- [ ] Ve a: https://console.firebase.google.com/project/pucp-flow/functions
- [ ] Verifica que las 3 funciones estén activas

**Funciones esperadas:**
```
✅ extraerCV (2nd gen)
✅ guardarSkillsConfirmadas (2nd gen)
✅ gestionarSugerenciaSkill (2nd gen)
```

---

### **3. Configurar Administradores** ⏱️ ~2 minutos

Ve a Firestore Database:
```
https://console.firebase.google.com/project/pucp-flow/firestore/data/~2Fusers
```

**Para cada usuario administrador:**
1. [ ] Encuentra el documento del usuario en la colección `users`
2. [ ] Haz clic en "Add field"
3. [ ] Agrega:
   - **Field name**: `isAdmin`
   - **Type**: `boolean`
   - **Value**: `true`
4. [ ] Guarda

**Ejemplo de documento de usuario:**
```
users/ABC123DEF456
  ├─ email: "admin@example.com"
  ├─ name: "Admin User"
  ├─ isAdmin: true  ← AGREGAR ESTO
  └─ ...otros campos
```

---

### **4. Compilar y Desplegar App Flutter** ⏱️ Varía según plataforma

#### Para Web (Firebase Hosting):
```bash
cd E:\FLOW\pucpflow
flutter build web --release
firebase deploy --only hosting
```

#### Para Android (Google Play):
```bash
flutter build appbundle --release
# Subir manualmente a Google Play Console
```

#### Para iOS (App Store):
```bash
flutter build ipa --release
# Subir manualmente a App Store Connect
```

#### Para Windows (Desktop):
```bash
flutter build windows --release
# El ejecutable estará en: build\windows\runner\Release\
```

**Verificar:**
- [ ] La app se compila sin errores
- [ ] Los imports de las nuevas páginas funcionan
- [ ] No hay errores de dependencias

---

### **5. Probar en Producción** ⏱️ ~15 minutos

#### 5.1 Probar carga de CV con skills custom

- [ ] Inicia sesión en la app en producción
- [ ] Ve a "Cargar CV"
- [ ] Sube un CV que contenga skills no estándar
- [ ] Verifica que aparezcan como "Habilidades Personalizadas" (púrpura)
- [ ] Selecciona todas y guarda
- [ ] Verifica en Firestore que se creó en `skill_suggestions`

**Ruta en Firestore:**
```
skill_suggestions/custom_{nombre}_{userId}
  ├─ suggestedName: "Office Avanzado"
  ├─ status: "pending"
  ├─ frequency: 1
  └─ ...
```

#### 5.2 Probar panel de administración

- [ ] Inicia sesión con usuario admin
- [ ] Abre el menú lateral
- [ ] Verifica que aparece "Admin: Gestionar Skills" con icono púrpura
- [ ] Haz clic y verifica que carga las sugerencias pendientes
- [ ] Estadísticas muestran números correctos

#### 5.3 Probar Aprobar sugerencia

- [ ] Haz clic en "Aprobar" en una sugerencia
- [ ] Verifica que muestra skills similares (si existen)
- [ ] Selecciona sector del dropdown
- [ ] Agrega descripción opcional
- [ ] Confirma
- [ ] Verifica que:
  - [ ] Aparece mensaje de éxito
  - [ ] La sugerencia desaparece de "Pendientes"
  - [ ] Aparece en "Aprobadas"
  - [ ] Se creó nueva skill en colección `skills`
  - [ ] El perfil del usuario se actualizó

**Verificar en Firestore:**
```
skills/{newSkillId}
  ├─ name: "Office Avanzado"
  ├─ sector: "Ofimática"
  ├─ fromSuggestion: true
  └─ ...

users/{userId}/professional_skills/{newSkillId}
  ├─ isStandard: true
  ├─ isCustom: false
  ├─ status: "active"
  └─ ...
```

#### 5.4 Probar Fusionar sugerencia

- [ ] Haz clic en "Fusionar" en una sugerencia
- [ ] Verifica que busca automáticamente skills similares
- [ ] Busca otra skill manualmente
- [ ] Selecciona una skill para fusionar
- [ ] Confirma
- [ ] Verifica que:
  - [ ] La sugerencia se marca como "merged"
  - [ ] El perfil del usuario ahora tiene la skill estándar

#### 5.5 Probar Rechazar sugerencia

- [ ] Haz clic en "Rechazar" en una sugerencia
- [ ] Verifica que muestra toda la información
- [ ] Confirma el rechazo
- [ ] Verifica que se marca como "rejected"

---

### **6. Monitoreo Post-Despliegue** ⏱️ Continuo

#### Ver logs de Cloud Functions:
```bash
firebase functions:log --only gestionarSugerenciaSkill
```

O en la consola:
```
https://console.firebase.google.com/project/pucp-flow/functions/logs
```

**Buscar en logs:**
- ✅ "Aprobando skill: ..."
- ✅ "Nueva skill creada: ..."
- ✅ "Actualizados X perfiles de usuario"
- ❌ Cualquier error o warning

#### Verificar uso de OpenAI:
```
https://platform.openai.com/usage
```

#### Verificar uso de Firebase:
```
https://console.firebase.google.com/project/pucp-flow/usage
```

---

## 🐛 Troubleshooting

### Error: "The query requires an index"

**Causa:** Los índices no están completamente construidos

**Solución:**
1. Verifica en https://console.firebase.google.com/project/pucp-flow/firestore/indexes
2. Si algún índice está en "Building", espera 5-10 minutos más
3. Si falló, haz clic en el enlace del error para crearlo manualmente

---

### Error: "Permission denied" al aprobar

**Causa:** El usuario no tiene `isAdmin: true`

**Solución:**
1. Ve a Firestore Database
2. Navega a `users/{userId}`
3. Agrega campo `isAdmin: true`
4. Hot restart la app

---

### Las sugerencias no aparecen

**Causa:** Posible problema con el filtrado en el cliente

**Solución:**
1. Verifica que existan documentos en `skill_suggestions`
2. Verifica que tengan `status: "pending"`
3. Revisa logs de la app en Chrome DevTools (F12)
4. Verifica permisos de lectura en Firestore Rules

---

### Skills no se actualizan al aprobar

**Causa:** Falta el índice de collection group

**Solución:**
1. Ve a: https://console.firebase.google.com/project/pucp-flow/firestore/indexes
2. Busca el índice de `professional_skills` (Collection Group)
3. Si no existe, créalo manualmente:
   - Collection Group: `professional_skills`
   - Field: `suggestionId` - Ascending
   - Query scope: Collection group

---

## 📊 Métricas de Éxito

Después del despliegue, deberías ver:

- [ ] **Índices**: 3/3 en estado "Enabled"
- [ ] **Functions**: 3/3 desplegadas y activas
- [ ] **Admins**: Al menos 1 usuario con `isAdmin: true`
- [ ] **App**: Compilada y desplegada sin errores
- [ ] **Skills custom**: Funcionando en carga de CV
- [ ] **Panel admin**: Accesible y funcional
- [ ] **Aprobar**: Crea skill estándar correctamente
- [ ] **Fusionar**: Fusiona con skill existente
- [ ] **Rechazar**: Marca como rechazada

---

## 🔄 Rollback (si algo sale mal)

### Revertir Cloud Functions:
```bash
firebase functions:delete gestionarSugerenciaSkill
firebase functions:delete guardarSkillsConfirmadas
firebase functions:delete extraerCV
```

### Revertir índices:
Ve a Firebase Console > Firestore > Indexes y elimina manualmente los índices creados

### Revertir código:
```bash
git log  # Encuentra el commit anterior
git revert <commit-hash>
git push
```

---

## 📝 Notas Finales

- Los índices de Firestore se cobran por uso, pero el costo es mínimo
- OpenAI cobra por tokens usados (~$0.03 por 1000 CVs procesados)
- Las Cloud Functions 2nd Gen tienen 2M invocaciones gratis/mes
- Monitorea los costos en Firebase Console > Usage and billing

---

**Última actualización:** 2025-11-18
**Versión del sistema:** Híbrido Skills v1.0
**Mantenedor:** Sistema PUCP Flow
