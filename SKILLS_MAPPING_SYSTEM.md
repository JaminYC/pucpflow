# 📋 Sistema de Mapeo de Habilidades desde CV

Sistema completo de extracción automática de habilidades profesionales desde CV (PDF) usando IA (OpenAI GPT-4o-mini), integrado con Firebase Cloud Functions y Flutter.

## 🎯 Características

- ✅ **Carga de CV en PDF** - Upload de archivos PDF desde web/móvil
- ✅ **Extracción automática con IA** - OpenAI analiza el CV y extrae habilidades con niveles 1-10
- ✅ **Mapeo inteligente** - Matching automático contra base de datos de 100+ skills predefinidas
- ✅ **Revisión interactiva** - UI para confirmar/editar skills y ajustar niveles
- ✅ **Visualización rica** - Dashboard con estadísticas, gráficos y agrupación por sectores
- ✅ **Tiempo real** - Sincronización con Firestore en tiempo real

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │ UploadCVPage   │→ │ReviewSkillsPage│→ │SkillsProfilePage│   │
│  │ (PDF Upload)   │  │ (Confirm)      │  │ (Dashboard)     │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
│           ↓                   ↓                     ↓          │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              SkillsService (Dart)                        │  │
│  │  - extractCVProfile()                                    │  │
│  │  - saveConfirmedSkills()                                 │  │
│  │  - getUserSkills()                                       │  │
│  └─────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ↓ HTTPS Callable
┌─────────────────────────────────────────────────────────────────┐
│               FIREBASE CLOUD FUNCTIONS                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  extraerCV(cvBase64, userId)                           │    │
│  │  1. Convierte PDF base64 a texto                       │    │
│  │  2. Llama OpenAI GPT-4o-mini para extraer perfil      │    │
│  │  3. Mapea skills extraídas vs BD Firestore             │    │
│  │  4. Retorna { profile, skills: {found, notFound} }     │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  guardarSkillsConfirmadas(userId, confirmedSkills)     │    │
│  │  1. Valida skills contra BD                            │    │
│  │  2. Guarda en users/{uid}/professional_skills          │    │
│  └────────────────────────────────────────────────────────┘    │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                            │
│                                                                  │
│  skills/                                                         │
│    ├─ {skillId}                                                 │
│    │   ├─ name: "Python"                                        │
│    │   ├─ sector: "Programación"                                │
│    │   ├─ description: "..."                                    │
│    │   └─ standardLevel: 6                                      │
│                                                                  │
│  users/{uid}/professional_skills/                               │
│    ├─ {skillId}                                                 │
│    │   ├─ skillId: "abc123"                                     │
│    │   ├─ skillName: "Python"                                   │
│    │   ├─ sector: "Programación"                                │
│    │   ├─ level: 8                                              │
│    │   ├─ notes: ""                                             │
│    │   ├─ acquiredAt: timestamp                                 │
│    │   └─ updatedAt: timestamp                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📂 Estructura de Archivos

```
lib/features/skills/
├── models/
│   ├── skill_model.dart          # SkillModel, UserSkillModel, MappedSkill
│   └── cv_profile_model.dart     # CVProfileModel, ExperienceModel, EducationModel
├── services/
│   └── skills_service.dart       # Servicio para interactuar con Cloud Functions
├── pages/
│   ├── upload_cv_page.dart       # Página de carga de CV
│   ├── review_skills_page.dart   # Página de revisión de skills
│   └── skills_profile_page.dart  # Dashboard de skills del usuario
└── init_skills_db.dart            # Script para inicializar BD con 100+ skills

functions/
└── index.js
    ├── extraerCV()                # Cloud Function para extraer CV
    └── guardarSkillsConfirmadas() # Cloud Function para guardar skills
```

## 🚀 Instalación y Configuración

### 1. Instalar Dependencias

Agrega al `pubspec.yaml` (ya agregado):

```yaml
dependencies:
  file_picker: ^8.1.4
  cloud_functions: ^5.3.4
  cloud_firestore: ^5.6.4
  fl_chart: ^0.70.2
```

Instala:

```bash
flutter pub get
```

### 2. Inicializar Base de Datos de Skills

Crea un botón temporal en tu app (o un script) para ejecutar:

```dart
import 'package:pucpflow/features/skills/init_skills_db.dart';

// En algún lugar de tu app (por ejemplo, en un botón de admin)
await InitSkillsDB().initializeSkills();
```

Esto poblará la colección `skills` con 100+ habilidades predefinidas organizadas por sectores:
- Programación (Python, JavaScript, Java, etc.)
- Frontend (React, Angular, Vue.js, etc.)
- Backend (Django, Node.js, Spring Boot, etc.)
- Mobile (Flutter, React Native, etc.)
- Bases de Datos (MySQL, MongoDB, PostgreSQL, etc.)
- Cloud Computing (AWS, GCP, Azure, etc.)
- DevOps (Docker, Kubernetes, CI/CD, etc.)
- Inteligencia Artificial (ML, Deep Learning, NLP, etc.)
- Data Science (Pandas, NumPy, etc.)
- Diseño (Figma, UI/UX, etc.)
- Y más...

### 3. Desplegar Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions:extraerCV,functions:guardarSkillsConfirmadas
```

### 4. Configurar OpenAI API Key

En Firebase Functions, configura el secret:

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

Ingresa tu API Key de OpenAI cuando se te solicite.

## 📱 Uso

### 1. Cargar CV

```dart
import 'package:pucpflow/features/skills/pages/upload_cv_page.dart';

// Navegar a la página de carga
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const UploadCVPage()),
);
```

**Flujo:**
1. Usuario selecciona archivo PDF
2. Se convierte a base64
3. Se envía a Cloud Function `extraerCV`
4. OpenAI extrae:
   - Nombre, email, teléfono
   - Resumen profesional
   - Skills con niveles estimados (1-10)
   - Experiencia laboral
   - Educación
5. Skills se mapean contra BD
6. Se muestra pantalla de revisión

### 2. Revisar y Confirmar Skills

La página `ReviewSkillsPage` muestra:
- ✅ **Skills encontradas** - Mapeadas exitosamente contra BD
- ⚠️ **Skills no encontradas** - Sugerencias para agregar a BD
- 🎚️ **Sliders de nivel** - Ajustar competencia 1-10
- ✅ **Checkboxes** - Seleccionar cuáles guardar

**Niveles:**
- 1-3: 🟠 Principiante
- 4-6: 🔵 Intermedio
- 7-8: 🟣 Avanzado
- 9-10: 🟢 Experto

### 3. Ver Dashboard de Skills

```dart
import 'package:pucpflow/features/skills/pages/skills_profile_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SkillsProfilePage()),
);
```

**Dashboard incluye:**
- 📊 Estadísticas generales (Total skills, Nivel promedio, Sectores)
- 📈 Gráfico de pastel con distribución por nivel
- 📂 Skills agrupadas por sector (expandibles)
- 🔄 Pull-to-refresh para actualizar

## 🔧 API Reference

### SkillsService

```dart
final skillsService = SkillsService();

// Extraer CV
final result = await skillsService.extractCVProfile(cvBase64);
// Returns: {
//   profile: CVProfileModel,
//   skills: List<MappedSkill>
// }

// Guardar skills confirmadas
final confirmedSkills = [
  {'skillId': 'abc123', 'level': 8, 'notes': ''},
];
await skillsService.saveConfirmedSkills(confirmedSkills);

// Obtener skills del usuario
final skills = await skillsService.getUserSkills();

// Obtener skills agrupadas por sector
final skillsBySector = await skillsService.getUserSkillsBySector();

// Stream en tiempo real
skillsService.watchUserSkills().listen((skills) {
  print('Skills actualizadas: ${skills.length}');
});

// Actualizar nivel de una skill
await skillsService.updateSkillLevel('skillId', 9);

// Eliminar skill
await skillsService.deleteSkill('skillId');

// Buscar skills disponibles
final results = await skillsService.searchSkills('python');

// Estadísticas
final average = await skillsService.getUserAverageSkillLevel();
final distribution = await skillsService.getSkillLevelDistribution();
```

### Modelos

```dart
// SkillModel - Skill en catálogo
class SkillModel {
  final String id;
  final String name;
  final String sector;
  final String? description;
  final int standardLevel;
}

// UserSkillModel - Skill del usuario
class UserSkillModel {
  final String id;
  final String skillId;
  final String skillName;
  final String sector;
  final int level;           // 1-10
  final String notes;
  final DateTime acquiredAt;
  final DateTime? updatedAt;
}

// CVProfileModel - Perfil extraído del CV
class CVProfileModel {
  final String name;
  final String email;
  final String phone;
  final String summary;
  final List<ExperienceModel> experience;
  final List<EducationModel> education;
}

// MappedSkill - Skill mapeada desde CV
class MappedSkill {
  final String aiSkill;      // Nombre extraído por IA
  final String? dbSkillId;   // ID en BD (si se encontró)
  final String? dbSkillName; // Nombre en BD
  final String? sector;
  final int level;
  final bool isFound;        // true si está en BD
}
```

## 🎨 Personalización

### Agregar Nuevas Skills

Puedes agregar skills manualmente a Firestore:

```dart
await FirebaseFirestore.instance.collection('skills').add({
  'name': 'Nueva Skill',
  'sector': 'Sector',
  'description': 'Descripción',
  'standardLevel': 6,
});
```

O modificar `init_skills_db.dart` para incluirlas en el seed.

### Personalizar Prompt de OpenAI

Edita `functions/index.js`, función `extraerCV`, línea 722:

```javascript
const extractionPrompt = `
Eres un asistente experto en análisis de CVs...
[Personaliza aquí]
`;
```

### Cambiar Modelo de OpenAI

Por defecto usa `gpt-4o-mini` (rápido y económico). Para mejor precisión:

```javascript
// functions/index.js, línea 766
model: "gpt-4",  // O "gpt-4-turbo"
```

## 📊 Estructura de Datos en Firestore

### Colección: `skills`

```javascript
{
  "name": "Python",
  "sector": "Programación",
  "description": "Lenguaje de programación versátil",
  "standardLevel": 6
}
```

**Índices requeridos:**
- `name` (ASC)
- `sector` (ASC)

### Subcolección: `users/{uid}/professional_skills`

```javascript
{
  "skillId": "abc123",
  "skillName": "Python",
  "sector": "Programación",
  "level": 8,
  "notes": "5 años de experiencia",
  "acquiredAt": Timestamp,
  "updatedAt": Timestamp
}
```

**Índices requeridos:**
- `level` (DESC)

## 🔐 Seguridad (Firestore Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Skills públicas (solo lectura)
    match /skills/{skillId} {
      allow read: if true;
      allow write: if false; // Solo via Cloud Functions
    }

    // Professional skills del usuario
    match /users/{userId}/professional_skills/{skillId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Solo via Cloud Functions
    }
  }
}
```

## 🧪 Testing

### Test Manual

1. Crea un CV de prueba en PDF con:
   - Nombre: "Test User"
   - Email: test@example.com
   - Skills: Python, JavaScript, React, AWS
   - Experiencia laboral
   - Educación

2. Carga el CV en la app
3. Verifica que se extraigan las skills correctamente
4. Confirma las skills
5. Revisa el dashboard

### Test de Cloud Function

```bash
# Local
cd functions
npm run serve

# Llamar desde app con emulator
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
```

## 🐛 Troubleshooting

### Error: "Skills collection is empty"

**Solución:** Ejecuta el script de inicialización:
```dart
await InitSkillsDB().initializeSkills();
```

### Error: "OpenAI API failed"

**Solución:** Verifica que la API Key esté configurada:
```bash
firebase functions:secrets:access OPENAI_API_KEY
```

### Error: "PDF parsing failed"

**Causas comunes:**
- PDF con imágenes escaneadas (no texto extraíble)
- PDF encriptado
- Archivo corrupto

**Solución:** Usa PDFs con texto extraíble o implementa OCR.

### Skills no se mapean correctamente

**Solución:**
1. Verifica que la skill exista en la BD
2. Ajusta el algoritmo de matching en `extraerCV` (línea 823)
3. Agrega sinónimos o variantes de nombres

## 🚀 Mejoras Futuras

- [ ] **OCR** - Leer PDFs escaneados con Tesseract/Google Vision
- [ ] **Búsqueda Full-Text** - Integrar Algolia para búsqueda avanzada
- [ ] **Recomendaciones** - Sugerir skills basadas en perfil
- [ ] **Certificaciones** - Vincular skills con certificaciones (Coursera, Udemy)
- [ ] **Exportar PDF** - Generar CV profesional desde skills
- [ ] **Comparación** - Comparar skills con ofertas de trabajo
- [ ] **Gamificación** - Badges y niveles por skills adquiridas
- [ ] **Trending Skills** - Mostrar skills más demandadas

## 📝 Licencia

Parte del ecosistema Vastoria Flow.

---

**Desarrollado con ❤️ por el equipo Vastoria**
