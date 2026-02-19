# 🔧 Instrucciones para Configurar OAuth para Beta

## ⚠️ PROBLEMAS DETECTADOS EN TU CONFIGURACIÓN

Basado en tu captura de Google Cloud Console:

### 🔴 Problema 1: "Usa flujos seguros" - FALLA
**Causa:** Redirect URIs no configurados correctamente
**Impacto:** Usuarios no podrán autenticarse

### 🔴 Problema 2: "Verificación de la app de OAuth" - Requerida
**Causa:** App no está en modo Testing
**Impacto:** Solo 100 primeros usuarios podrán acceder

---

## ✅ SOLUCIÓN PASO A PASO

### **1. Configurar Publishing Status en Testing**

1. Ve a: https://console.cloud.google.com/apis/credentials/consent
2. Asegúrate de estar en el proyecto: **pucp-flow**
3. En la pestaña **"OAuth consent screen"** (arriba, al lado de "Credenciales")
4. Busca la sección **"Publishing status"**
5. Si dice "In production" o "Not published", haz click en **"PUBLISH APP"**
6. Selecciona: **"Testing"**
7. Click **"CONFIRM"**

**Resultado esperado:**
```
Publishing status: Testing
User type: External
```

---

### **2. Agregar Usuarios de Prueba**

1. En la misma página de OAuth consent screen
2. Scroll hasta la sección **"Test users"**
3. Click **"+ ADD USERS"**
4. Agrega los emails de tus beta testers (uno por línea):
   ```
   jamin.yauri@pucp.edu.pe
   usuario1@gmail.com
   usuario2@gmail.com
   [... hasta 100 usuarios]
   ```
5. Click **"SAVE"**

**⚠️ IMPORTANTE:** Solo estos usuarios podrán hacer login mientras esté en Testing.

---

### **3. Verificar Redirect URIs (CRÍTICO)**

#### **3.1 Ir a Credenciales**
1. Ve a: https://console.cloud.google.com/apis/credentials
2. Click en tu **Web client** (OAuth 2.0 Client ID)
3. Busca la sección **"Authorized redirect URIs"**

#### **3.2 Agregar estos URIs:**

```
https://pucp-flow.firebaseapp.com/__/auth/handler
https://pucp-flow.web.app/__/auth/handler
https://flow.teamvastoria.com/__/auth/handler
https://teamvastoria.com/__/auth/handler
http://localhost/__/auth/handler
http://localhost:5000/__/auth/handler
http://localhost:8080/__/auth/handler
```

#### **3.3 Authorized JavaScript origins:**

```
https://pucp-flow.firebaseapp.com
https://pucp-flow.web.app
https://flow.teamvastoria.com
https://teamvastoria.com
http://localhost
http://localhost:5000
http://localhost:8080
```

5. Click **"SAVE"**

---

### **4. Crear Páginas de Privacy y Terms**

Veo que tienes configurados estos links:
- Privacy: `https://flow.teamvastoria.com/privacy.html`
- Terms: `https://flow.teamvastoria.com/terms.html`

**⚠️ IMPORTANTE:** Estas páginas DEBEN existir y ser accesibles públicamente.

#### **Crear archivo: web/privacy.html**

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Política de Privacidad - FLOW</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 800px;
      margin: 40px auto;
      padding: 20px;
      line-height: 1.6;
      color: #333;
    }
    h1 { color: #133E87; }
    h2 { color: #5BE4A8; margin-top: 30px; }
    .last-updated { color: #666; font-style: italic; }
  </style>
</head>
<body>
  <h1>Política de Privacidad de FLOW</h1>
  <p class="last-updated">Última actualización: 31 de diciembre de 2025</p>

  <h2>1. Información que Recopilamos</h2>
  <p>Al usar FLOW con tu cuenta de Google, recopilamos:</p>
  <ul>
    <li><strong>Información de perfil:</strong> Nombre, correo electrónico y foto de perfil de tu cuenta de Google</li>
    <li><strong>Información de uso:</strong> Proyectos, tareas y actividades que creas en FLOW</li>
    <li><strong>Datos de Google Calendar:</strong> Eventos de tu calendario (solo si otorgas permiso)</li>
  </ul>

  <h2>2. Cómo Usamos tu Información</h2>
  <p>Usamos tu información para:</p>
  <ul>
    <li>Proporcionar y mejorar los servicios de FLOW</li>
    <li>Personalizar tu experiencia</li>
    <li>Comunicarnos contigo sobre tu cuenta</li>
    <li>Generar análisis y métricas de uso</li>
  </ul>

  <h2>3. Compartir Información</h2>
  <p>NO vendemos ni compartimos tu información personal con terceros, excepto:</p>
  <ul>
    <li>Cuando tú eliges compartir proyectos con otros usuarios de FLOW</li>
    <li>Cuando sea requerido por ley</li>
    <li>Con proveedores de servicios necesarios (Firebase, Google Cloud)</li>
  </ul>

  <h2>4. Seguridad</h2>
  <p>Protegemos tu información usando:</p>
  <ul>
    <li>Encriptación de datos en tránsito (HTTPS)</li>
    <li>Autenticación segura mediante Google Sign-In</li>
    <li>Reglas de seguridad en Firebase Firestore</li>
  </ul>

  <h2>5. Tus Derechos</h2>
  <p>Tienes derecho a:</p>
  <ul>
    <li>Acceder a tu información personal</li>
    <li>Solicitar la eliminación de tu cuenta y datos</li>
    <li>Revocar permisos de Google Calendar en cualquier momento</li>
  </ul>

  <h2>6. Cookies y Tecnologías Similares</h2>
  <p>Usamos cookies para mantener tu sesión activa y mejorar la experiencia del usuario.</p>

  <h2>7. Cambios a esta Política</h2>
  <p>Podemos actualizar esta política ocasionalmente. Te notificaremos de cambios significativos.</p>

  <h2>8. Contacto</h2>
  <p>Para preguntas sobre privacidad, contáctanos en:</p>
  <p><strong>Email:</strong> jamin.yauri@pucp.edu.pe</p>
  <p><strong>Website:</strong> <a href="https://flow.teamvastoria.com">flow.teamvastoria.com</a></p>

  <hr style="margin-top: 40px;">
  <p style="text-align: center; color: #666;">
    © 2025 Vastoria - FLOW. Todos los derechos reservados.
  </p>
</body>
</html>
```

#### **Crear archivo: web/terms.html**

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Términos de Servicio - FLOW</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 800px;
      margin: 40px auto;
      padding: 20px;
      line-height: 1.6;
      color: #333;
    }
    h1 { color: #133E87; }
    h2 { color: #5BE4A8; margin-top: 30px; }
    .last-updated { color: #666; font-style: italic; }
  </style>
</head>
<body>
  <h1>Términos de Servicio de FLOW</h1>
  <p class="last-updated">Última actualización: 31 de diciembre de 2025</p>

  <h2>1. Aceptación de los Términos</h2>
  <p>Al acceder y usar FLOW, aceptas estar sujeto a estos Términos de Servicio y a nuestra Política de Privacidad.</p>

  <h2>2. Descripción del Servicio</h2>
  <p>FLOW es una plataforma de gestión de proyectos y tareas con inteligencia artificial que te ayuda a:</p>
  <ul>
    <li>Organizar proyectos personales y profesionales</li>
    <li>Gestionar tareas y plazos</li>
    <li>Colaborar con equipos</li>
    <li>Integrar con Google Calendar</li>
  </ul>

  <h2>3. Registro y Cuenta</h2>
  <p>Para usar FLOW debes:</p>
  <ul>
    <li>Tener una cuenta de Google válida</li>
    <li>Proporcionar información precisa y actualizada</li>
    <li>Mantener la seguridad de tu cuenta</li>
    <li>Ser mayor de 13 años</li>
  </ul>

  <h2>4. Uso Permitido</h2>
  <p>Puedes usar FLOW para:</p>
  <ul>
    <li>Crear y gestionar proyectos personales o profesionales</li>
    <li>Colaborar con otros usuarios</li>
    <li>Integrar con servicios de Google autorizados</li>
  </ul>

  <h2>5. Uso Prohibido</h2>
  <p>NO puedes:</p>
  <ul>
    <li>Usar FLOW para actividades ilegales</li>
    <li>Compartir contenido ofensivo, discriminatorio o dañino</li>
    <li>Intentar hackear o comprometer la seguridad del servicio</li>
    <li>Usar bots o automatización no autorizada</li>
    <li>Revender o redistribuir el servicio</li>
  </ul>

  <h2>6. Propiedad Intelectual</h2>
  <p>Tú mantienes la propiedad de tu contenido (proyectos, tareas, etc.). FLOW mantiene los derechos sobre la plataforma, código y diseño.</p>

  <h2>7. Privacidad y Datos</h2>
  <p>El manejo de tus datos se rige por nuestra <a href="/privacy.html">Política de Privacidad</a>.</p>

  <h2>8. Disponibilidad del Servicio</h2>
  <p>FLOW se proporciona "tal cual" sin garantías de disponibilidad continua. Podemos:</p>
  <ul>
    <li>Realizar mantenimiento programado</li>
    <li>Modificar o descontinuar funcionalidades</li>
    <li>Suspender el servicio temporalmente</li>
  </ul>

  <h2>9. Limitación de Responsabilidad</h2>
  <p>FLOW no se hace responsable por:</p>
  <ul>
    <li>Pérdida de datos debido a errores técnicos</li>
    <li>Daños indirectos o consecuentes</li>
    <li>Interrupciones del servicio</li>
  </ul>

  <h2>10. Terminación</h2>
  <p>Podemos suspender o terminar tu cuenta si:</p>
  <ul>
    <li>Violas estos términos</li>
    <li>Usas el servicio de manera fraudulenta</li>
    <li>Lo solicitas (eliminación de cuenta)</li>
  </ul>

  <h2>11. Cambios a los Términos</h2>
  <p>Podemos modificar estos términos ocasionalmente. Te notificaremos de cambios significativos.</p>

  <h2>12. Ley Aplicable</h2>
  <p>Estos términos se rigen por las leyes de Perú.</p>

  <h2>13. Contacto</h2>
  <p>Para preguntas o soporte, contáctanos en:</p>
  <p><strong>Email:</strong> jamin.yauri@pucp.edu.pe</p>
  <p><strong>Website:</strong> <a href="https://flow.teamvastoria.com">flow.teamvastoria.com</a></p>

  <hr style="margin-top: 40px;">
  <p style="text-align: center; color: #666;">
    © 2025 Vastoria - FLOW. Todos los derechos reservados.
  </p>
</body>
</html>
```

---

### **5. Desplegar Privacy y Terms**

```bash
# Asegúrate de que los archivos estén en web/
ls web/privacy.html
ls web/terms.html

# Desplegar a Firebase Hosting
firebase deploy --only hosting
```

**Verifica que funcionen:**
- https://flow.teamvastoria.com/privacy.html
- https://flow.teamvastoria.com/terms.html

---

## ✅ CHECKLIST FINAL

Después de completar los pasos anteriores, verifica:

- [ ] **Publishing status: Testing**
- [ ] **Test users agregados** (emails de beta testers)
- [ ] **Redirect URIs configurados** en credenciales OAuth
- [ ] **JavaScript origins configurados**
- [ ] **privacy.html desplegado y accesible**
- [ ] **terms.html desplegado y accesible**
- [ ] **Dominios autorizados**: teamvastoria.com, pucp-flow.firebaseapp.com
- [ ] **Testing manual**: Login con cuenta de prueba funciona

---

## 🧪 TESTING

Después de configurar todo:

1. **Prueba con cuenta de test user:**
   ```
   1. Abre: https://flow.teamvastoria.com
   2. Click "Iniciar sesión con Google"
   3. Selecciona cuenta que agregaste a Test users
   4. ✅ Debe autenticar correctamente
   ```

2. **Prueba con cuenta NO en test users:**
   ```
   1. Abre: https://flow.teamvastoria.com
   2. Click "Iniciar sesión con Google"
   3. Selecciona cuenta que NO está en Test users
   4. ❌ Debe mostrar error "access_denied"
   5. ✅ Esto es CORRECTO para modo Testing
   ```

---

## 📧 COMUNICACIÓN A BETA TESTERS

Cuando invites a beta testers, envía este mensaje:

---

**Asunto:** Invitación a FLOW Beta

Hola,

Te invitamos a probar **FLOW**, nuestra plataforma de gestión de proyectos con IA.

**Para acceder:**
1. Ve a: https://flow.teamvastoria.com
2. Click en "Iniciar sesión con Google"
3. Usa esta cuenta de email: **[SU_EMAIL]**

**Importante:**
- Solo puedes acceder con el email especificado
- Si ves "access_denied", verifica que uses el email correcto
- Reporta bugs a: jamin.yauri@pucp.edu.pe

¡Gracias por ayudarnos a mejorar FLOW!

---

## 🚀 DESPUÉS DE BETA (Para producción)

Cuando estés listo para lanzar públicamente:

1. **Cambiar a Production:**
   - OAuth consent screen → Publishing status → "In production"

2. **Enviar a verificación de Google:**
   - Completar formulario de verificación
   - Esperar 4-6 semanas para aprobación

3. **Requisitos para verificación:**
   - Video demo de la app
   - Explicación detallada de uso de scopes
   - Privacy policy pública y completa
   - Terms of service públicos

---

**Fecha:** 2025-12-31
**Para:** Beta Launch
**Responsable:** Equipo Vastoria
