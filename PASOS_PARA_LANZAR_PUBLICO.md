# 🚀 PASOS PARA QUE CUALQUIERA PUEDA USAR FLOW

## 🎯 TU OBJETIVO
Quieres que **cualquier persona con cuenta de Google** pueda usar FLOW inmediatamente.

---

## ⚡ SOLUCIÓN RÁPIDA (Lanzar HOY)

### **Paso 1: Publicar en Producción**

1. Ve a: https://console.cloud.google.com/apis/credentials/consent
2. Selecciona proyecto: **pucp-flow**
3. Click en **"PUBLISH APP"**
4. Selecciona: **"Make app public"** o **"In production"**
5. Click **"CONFIRM"**

**✅ Listo! Ahora cualquiera puede usar FLOW**

---

### **Paso 2: Usuarios verán esta pantalla**

Cuando alguien intente iniciar sesión, verá:

```
⚠️ Google hasn't verified this app

This app hasn't been verified by Google yet. Proceed with caution.

[Continue]  [Advanced]
```

**Para acceder, los usuarios deben:**
1. Click en **"Advanced"** (abajo)
2. Click en **"Go to FLOW (unsafe)"**
3. Permitir acceso

---

## 🔐 IMPORTANTE: Verificar con Redirect URIs

Antes de publicar, asegúrate de tener configurados los **Redirect URIs**:

### **1. Ir a Credenciales**
https://console.cloud.google.com/apis/credentials

### **2. Click en tu Web client (OAuth 2.0 Client ID)**

### **3. Agregar estos Authorized redirect URIs:**

```
https://pucp-flow.firebaseapp.com/__/auth/handler
https://pucp-flow.web.app/__/auth/handler
https://flow.teamvastoria.com/__/auth/handler
https://teamvastoria.com/__/auth/handler
http://localhost/__/auth/handler
```

### **4. Agregar estos Authorized JavaScript origins:**

```
https://pucp-flow.firebaseapp.com
https://pucp-flow.web.app
https://flow.teamvastoria.com
https://teamvastoria.com
http://localhost
```

### **5. Click SAVE**

---

## ✅ VERIFICAR QUE FUNCIONE

### **Prueba 1: Con tu cuenta**
1. Cierra sesión de FLOW
2. Ve a https://flow.teamvastoria.com
3. Click "Iniciar sesión con Google"
4. Selecciona tu cuenta
5. ✅ Debe funcionar (aunque veas advertencia)

### **Prueba 2: Con otra cuenta Gmail**
1. Usa navegador incógnito
2. Ve a https://flow.teamvastoria.com
3. Click "Iniciar sesión con Google"
4. Usa cualquier cuenta @gmail.com
5. ✅ Debe funcionar (con advertencia)

---

## 📧 COMUNICAR A USUARIOS

Cuando invites personas, explícales:

---

**Asunto: Invitación a FLOW**

Hola,

Te invito a probar **FLOW**, nuestra plataforma de gestión de proyectos.

**Importante:** Al iniciar sesión verás una advertencia de Google porque la app está en proceso de verificación. Es completamente seguro.

**Para acceder:**
1. Ve a: https://flow.teamvastoria.com
2. Click "Iniciar sesión con Google"
3. Verás: "Google hasn't verified this app"
4. Click **"Advanced"** → **"Go to FLOW (unsafe)"**
5. Permitir acceso

¡Gracias!

---

---

## 🏆 ELIMINAR LA ADVERTENCIA (Recomendado)

Para que NO aparezca la advertencia y sea profesional:

### **Opción A: Verificación Completa de Google** ✅

1. Ve a OAuth consent screen
2. Click **"Submit for Verification"**
3. Completar formulario:
   - Video demo mostrando la app
   - Explicación de por qué necesitas cada scope
   - Link a privacy policy
   - Link a terms of service

**Tiempo:** 4-6 semanas
**Resultado:** Advertencia desaparece completamente

### **Requisitos para verificación:**

📹 **Video Demo (2-3 minutos):**
```
1. Mostrar login con Google
2. Mostrar cómo se usan los datos (nombre, email, foto)
3. Mostrar acceso a Google Calendar (si lo usas)
4. Mostrar dónde se almacenan los datos
5. Mostrar cómo eliminar cuenta/datos
```

📝 **Justificación de Scopes:**
```
Scope: userinfo.email, userinfo.profile
Uso: Autenticación de usuarios y personalización

Scope: calendar.readonly (si lo usas)
Uso: Sincronización de eventos con tareas
```

---

## 🎯 MI RECOMENDACIÓN

### **Para lanzar AHORA (esta semana):**

1. ✅ **Publicar en producción SIN verificar**
   - Usuarios ven advertencia pero pueden acceder
   - Funciona inmediatamente

2. ✅ **Enviar a verificación en paralelo**
   - Proceso toma 4-6 semanas
   - Mientras tanto la app funciona con advertencia

3. ✅ **Cuando se apruebe la verificación**
   - Advertencia desaparece automáticamente
   - Experiencia profesional

### **Timeline sugerido:**

```
Semana 1:
- Publicar en producción ✓
- Empezar a invitar usuarios
- Enviar solicitud de verificación

Semanas 2-6:
- Crecer usuarios (con advertencia)
- Recopilar feedback
- Mejorar app

Semana 7+:
- Verificación aprobada ✓
- Advertencia desaparece
- Marketing agresivo
```

---

## 🚨 ALTERNATIVA: Solo Usuarios PUCP

Si solo quieres que accedan usuarios PUCP:

1. Mantener en **Testing**
2. En Test users agregar: `@pucp.edu.pe`
3. Cualquier usuario con email PUCP puede acceder
4. NO verán advertencia

**Ventaja:** No requiere verificación
**Desventaja:** Solo usuarios PUCP

---

## ✅ CHECKLIST PARA PUBLICAR

- [ ] Redirect URIs configurados
- [ ] JavaScript origins configurados
- [ ] privacy.html desplegado y accesible
- [ ] terms.html desplegado y accesible
- [ ] Publishing status: **In production**
- [ ] Testing manual exitoso
- [ ] Documentación para usuarios lista
- [ ] Plan de verificación iniciado

---

## 📞 SOPORTE

Si los usuarios tienen problemas:

**Error: "redirect_uri_mismatch"**
→ Verificar que el dominio esté en Authorized redirect URIs

**Error: "access_denied"**
→ Verificar que Publishing status sea "In production"

**Error: "unauthorized_client"**
→ Verificar que Client ID coincida en todas partes

---

**Fecha:** 2025-12-31
**Para:** Lanzamiento Público
**Status:** Listo para publicar
