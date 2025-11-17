# PucpFlow - Sistema de Gestión de Proyectos con IA

Sistema completo de gestión de proyectos con metodología PMI, asignación inteligente de tareas basada en habilidades, y extracción automática de skills desde CV usando IA.

[![Firebase](https://img.shields.io/badge/Firebase-Hosting-orange)](https://firebase.google.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)](https://flutter.dev/)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-green)](https://openai.com/)

## 🚀 Features Principales

### 1. Sistema PMI Completo
- ✅ Generación automática de proyectos con IA (OpenAI GPT-4)
- ✅ Metodología de 5 fases: Iniciación, Planificación, Ejecución, Monitoreo, Cierre
- ✅ Jerarquía completa: Fase → Entregable → Paquete de Trabajo → Tarea
- ✅ Visualización jerárquica y por recursos
- ✅ 20-30 tareas generadas automáticamente por proyecto

### 2. Asignación Inteligente con IA
- ✅ Matching automático basado en habilidades
- ✅ Algoritmo de scoring: 70% match de skills + 30% nivel
- ✅ Asignación múltiple: TODOS los usuarios con score >= 60%
- ✅ **Propietario del proyecto SIEMPRE asignado** para supervisión
- ✅ Justificación visible (score, skills coincidentes, nivel promedio)
- ✅ Edición de tareas con visualización de compatibilidad

### 3. Skills Mapping desde CV
- ✅ Extracción automática de habilidades desde CV (PDF)
- ✅ Procesamiento con OpenAI GPT-4
- ✅ Perfiles de usuario con skills y niveles (1-5)
- ✅ Integración directa con sistema de asignación

### 4. Firebase Integration
- ✅ Authentication (Email/Password)
- ✅ Firestore Database
- ✅ Cloud Functions (CV extraction + PMI generation)
- ✅ Storage (CV uploads)
- ✅ Hosting (Web deployment)

---

## 📦 Quick Start

### Prerrequisitos
```bash
flutter --version  # 3.0+
node --version     # 16+
firebase --version # Firebase CLI
```

### Instalación

```bash
# 1. Clonar
git clone https://github.com/JaminYC/pucpflow.git
cd pucpflow

# 2. Instalar dependencias
flutter pub get
cd functions && npm install && cd ..

# 3. Configurar Firebase
firebase login
firebase use pucp-flow

# 4. Ejecutar localmente
flutter run -d chrome
```

**📖 Guía completa:** [QUICK_START.md](QUICK_START.md)

---

## 🚀 Despliegue

### Opción 1: Web (Firebase Hosting) - ⚡ RECOMENDADO

```bash
# Build y deploy en un comando
flutter build web --release && firebase deploy --only hosting

# O usar el script automatizado
.\deploy.ps1 -Target web
```

**Resultado:** Tu app estará en vivo en `https://pucp-flow.web.app`

### Opción 2: Android (Google Play Store)

```bash
# Build AAB
flutter build appbundle --release

# O usar el script
.\deploy.ps1 -Target android

# Subir a: https://play.google.com/console
```

### Opción 3: Deploy Completo

```bash
# Web + Functions + Android
.\deploy.ps1 -Target all
```

**📖 Guía completa de deploy:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 🔧 Configuración

### Variables de Entorno Necesarias

#### OpenAI API Key (para Functions)
```bash
firebase functions:config:set openai.api_key="sk-..."
```

#### Firebase Config Files
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `web/firebase-config.js`

**📖 Setup completo:** [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

---

## 📁 Estructura del Proyecto

```
pucpflow/
├── lib/
│   ├── features/
│   │   ├── pmi/                    # 🎯 Sistema PMI
│   │   │   ├── models/
│   │   │   └── services/
│   │   ├── skills/                 # 🧠 Skills mapping
│   │   │   ├── models/
│   │   │   ├── pages/
│   │   │   └── services/
│   │   └── user_auth/
│   │       └── presentation/pages/Proyectos/
│   │           ├── asignacion_inteligente_service.dart   # 🤖 Asignación IA
│   │           ├── pmi_ia_service.dart                   # 🎨 Generación PMI
│   │           ├── ProyectoDetallePage.dart              # 📊 UI Principal
│   │           └── grafo_tareas_pmi_page.dart            # 📈 Visualización
│   ├── core/                       # Widgets compartidos
│   └── main.dart
├── functions/
│   ├── index.js                    # ☁️ Cloud Functions
│   │   ├── extractSkillsFromCV     # Extracción de skills
│   │   └── generatePMIProject      # Generación de proyectos PMI
│   └── package.json
├── deploy.ps1                      # 🚀 Script de deploy (Windows)
├── deploy.sh                       # 🚀 Script de deploy (Linux/Mac)
└── *.md                            # 📚 Documentación
```

---

## 📚 Documentación

### Para Desarrolladores
- **[QUICK_START.md](QUICK_START.md)** - Setup en 5 minutos
- **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** - Configuración completa
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guía de despliegue

### Documentación Técnica
- **[INTELLIGENT_ASSIGNMENT_COMPLETE.md](INTELLIGENT_ASSIGNMENT_COMPLETE.md)** - Sistema de asignación inteligente
- **[PMI_SYSTEM_IMPLEMENTATION_SUMMARY.md](PMI_SYSTEM_IMPLEMENTATION_SUMMARY.md)** - Sistema PMI
- **[SKILLS_MAPPING_SYSTEM.md](SKILLS_MAPPING_SYSTEM.md)** - Mapeo de habilidades
- **[FIREBASE_FUNCTIONS_CONFIG.md](FIREBASE_FUNCTIONS_CONFIG.md)** - Cloud Functions

### Actualizaciones
- **[OWNER_ASSIGNMENT_UPDATE.md](OWNER_ASSIGNMENT_UPDATE.md)** - Propietario siempre asignado
- **[PMI_HIERARCHY_IMPLEMENTATION.md](PMI_HIERARCHY_IMPLEMENTATION.md)** - Jerarquía PMI

---

## 🎯 Uso del Sistema

### 1. Crear Proyecto PMI con IA

```
Dashboard → Proyectos → "Crear Proyecto PMI con IA"
↓
Llenar formulario (nombre, descripción, fechas)
↓
IA genera automáticamente:
  - 5 fases PMI
  - 10-15 entregables
  - 20-30 tareas con habilidades requeridas
```

### 2. Asignación Inteligente

```
Abrir Proyecto → Agregar Participantes
↓
Botón flotante "Auto-asignar" (naranja)
↓
Sistema asigna automáticamente:
  - Propietario a TODAS las tareas (supervisor)
  - Usuarios con score >= 60%
  - Múltiples responsables por tarea
↓
Ver justificación de cada asignación
```

### 3. Mapeo de Habilidades

```
Perfil de Usuario → "Subir CV"
↓
Seleccionar PDF del CV
↓
IA extrae automáticamente habilidades
↓
Revisar y confirmar skills
↓
Skills disponibles para asignación inteligente
```

---

## 🔐 Seguridad

### Credenciales
- **NO** incluir API keys en código
- Usar `firebase functions:config:set` para secrets
- Archivo `.env` en `.gitignore`
- Compartir credenciales vía gestores seguros (1Password, etc.)

### Reglas de Firestore
```javascript
// Usuarios solo pueden acceder a sus datos
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// Proyectos: solo propietario y participantes
match /proyectos/{proyectoId} {
  allow read: if request.auth.uid in resource.data.participantes;
  allow write: if request.auth.uid == resource.data.propietario;
}
```

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📊 Tecnologías Utilizadas

- **Frontend:** Flutter 3.0+, Dart
- **Backend:** Firebase (Firestore, Functions, Storage, Hosting)
- **IA/ML:** OpenAI GPT-4 (generación PMI, extracción skills)
- **State Management:** Provider / StatefulWidget
- **Charts:** fl_chart
- **PDF Processing:** pdf (Dart package)

---

## 📝 Licencia

Este proyecto es privado. Todos los derechos reservados.

---

## 👥 Equipo

- **Desarrollador Principal:** JaminYC
- **IA Assistant:** Claude Code (Anthropic)

---

## 🆘 Soporte

- **Issues:** https://github.com/JaminYC/pucpflow/issues
- **Documentación:** Ver archivos `.md` en el repositorio

---

## 🎉 Versión Actual

**v1.0.0** - Sistema PMI completo con asignación inteligente

### Últimas actualizaciones:
- ✅ Propietario siempre asignado a todas las tareas
- ✅ Asignación múltiple de responsables
- ✅ Justificación visible de asignaciones
- ✅ Edición de tareas PMI
- ✅ Visualización jerárquica mejorada

---

## 📅 Roadmap

### Próximas Features
- [ ] Dashboard de carga de trabajo por usuario
- [ ] Notificaciones a usuarios asignados
- [ ] Historial de cambios de asignación
- [ ] Reasignación de responsables
- [ ] Exportación de proyectos a PDF/Excel
- [ ] Integración con calendario (Google Calendar)
- [ ] Chat integrado por proyecto
- [ ] Reportes de progreso automáticos

---

**Última actualización:** 16 de Noviembre, 2025
**Proyecto Firebase:** pucp-flow
**URL de Producción:** https://pucp-flow.web.app (después del deploy)
