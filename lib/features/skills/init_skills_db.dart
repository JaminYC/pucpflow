import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para inicializar la base de datos de skills en Firestore
/// Ejecutar una sola vez para poblar la colección 'skills' con skills comunes
class InitSkillsDB {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicializa la base de datos con skills predefinidas
  Future<void> initializeSkills() async {
    print('🚀 Iniciando población de base de datos de skills...');

    final skills = _getSkillsList();
    int count = 0;

    for (var skill in skills) {
      try {
        // Verificar si ya existe
        final existing = await _firestore
            .collection('skills')
            .where('name', isEqualTo: skill['name'])
            .get();

        if (existing.docs.isEmpty) {
          await _firestore.collection('skills').add(skill);
          count++;
          print('✅ Skill agregada: ${skill['name']} (${skill['sector']})');
        }
      } catch (e) {
        print('❌ Error agregando skill ${skill['name']}: $e');
      }
    }

    print('✅ Proceso completado: $count nuevas skills agregadas');
  }

  /// Lista de skills predefinidas organizadas por sector
  List<Map<String, dynamic>> _getSkillsList() {
    return [
      // ========== PROGRAMACIÓN ==========
      {'name': 'Python', 'sector': 'Programación', 'description': 'Lenguaje de programación versátil', 'standardLevel': 6},
      {'name': 'JavaScript', 'sector': 'Programación', 'description': 'Lenguaje para desarrollo web', 'standardLevel': 6},
      {'name': 'TypeScript', 'sector': 'Programación', 'description': 'JavaScript con tipado estático', 'standardLevel': 6},
      {'name': 'Java', 'sector': 'Programación', 'description': 'Lenguaje orientado a objetos', 'standardLevel': 6},
      {'name': 'C#', 'sector': 'Programación', 'description': 'Lenguaje de Microsoft .NET', 'standardLevel': 6},
      {'name': 'C++', 'sector': 'Programación', 'description': 'Lenguaje de programación de sistemas', 'standardLevel': 7},
      {'name': 'Go', 'sector': 'Programación', 'description': 'Lenguaje de Google para sistemas', 'standardLevel': 6},
      {'name': 'Rust', 'sector': 'Programación', 'description': 'Lenguaje de sistemas seguro', 'standardLevel': 7},
      {'name': 'PHP', 'sector': 'Programación', 'description': 'Lenguaje para desarrollo web', 'standardLevel': 5},
      {'name': 'Ruby', 'sector': 'Programación', 'description': 'Lenguaje dinámico orientado a objetos', 'standardLevel': 6},
      {'name': 'Kotlin', 'sector': 'Programación', 'description': 'Lenguaje moderno para JVM y Android', 'standardLevel': 6},
      {'name': 'Swift', 'sector': 'Programación', 'description': 'Lenguaje de Apple para iOS', 'standardLevel': 6},
      {'name': 'Dart', 'sector': 'Programación', 'description': 'Lenguaje para Flutter', 'standardLevel': 6},

      // ========== FRAMEWORKS WEB ==========
      {'name': 'React', 'sector': 'Frontend', 'description': 'Librería de UI de Facebook', 'standardLevel': 6},
      {'name': 'Angular', 'sector': 'Frontend', 'description': 'Framework de Google', 'standardLevel': 6},
      {'name': 'Vue.js', 'sector': 'Frontend', 'description': 'Framework progresivo de JavaScript', 'standardLevel': 6},
      {'name': 'Next.js', 'sector': 'Frontend', 'description': 'Framework de React con SSR', 'standardLevel': 6},
      {'name': 'Svelte', 'sector': 'Frontend', 'description': 'Compilador de UI reactivo', 'standardLevel': 6},
      {'name': 'Django', 'sector': 'Backend', 'description': 'Framework web de Python', 'standardLevel': 6},
      {'name': 'Flask', 'sector': 'Backend', 'description': 'Microframework de Python', 'standardLevel': 5},
      {'name': 'FastAPI', 'sector': 'Backend', 'description': 'Framework moderno de Python', 'standardLevel': 6},
      {'name': 'Node.js', 'sector': 'Backend', 'description': 'Runtime de JavaScript', 'standardLevel': 6},
      {'name': 'Express.js', 'sector': 'Backend', 'description': 'Framework web de Node.js', 'standardLevel': 5},
      {'name': 'NestJS', 'sector': 'Backend', 'description': 'Framework de Node.js con TypeScript', 'standardLevel': 6},
      {'name': 'Spring Boot', 'sector': 'Backend', 'description': 'Framework de Java', 'standardLevel': 6},
      {'name': 'Laravel', 'sector': 'Backend', 'description': 'Framework de PHP', 'standardLevel': 6},
      {'name': 'Ruby on Rails', 'sector': 'Backend', 'description': 'Framework de Ruby', 'standardLevel': 6},
      {'name': 'ASP.NET Core', 'sector': 'Backend', 'description': 'Framework de Microsoft', 'standardLevel': 6},

      // ========== MOBILE ==========
      {'name': 'Flutter', 'sector': 'Mobile', 'description': 'Framework multiplataforma de Google', 'standardLevel': 6},
      {'name': 'React Native', 'sector': 'Mobile', 'description': 'Framework móvil de Facebook', 'standardLevel': 6},
      {'name': 'Android Development', 'sector': 'Mobile', 'description': 'Desarrollo nativo Android', 'standardLevel': 6},
      {'name': 'iOS Development', 'sector': 'Mobile', 'description': 'Desarrollo nativo iOS', 'standardLevel': 6},
      {'name': 'SwiftUI', 'sector': 'Mobile', 'description': 'UI framework de Apple', 'standardLevel': 6},
      {'name': 'Jetpack Compose', 'sector': 'Mobile', 'description': 'UI toolkit de Android', 'standardLevel': 6},

      // ========== BASES DE DATOS ==========
      {'name': 'MySQL', 'sector': 'Bases de Datos', 'description': 'Base de datos relacional', 'standardLevel': 5},
      {'name': 'PostgreSQL', 'sector': 'Bases de Datos', 'description': 'Base de datos relacional avanzada', 'standardLevel': 6},
      {'name': 'MongoDB', 'sector': 'Bases de Datos', 'description': 'Base de datos NoSQL documental', 'standardLevel': 5},
      {'name': 'Redis', 'sector': 'Bases de Datos', 'description': 'Almacenamiento en memoria', 'standardLevel': 5},
      {'name': 'Firestore', 'sector': 'Bases de Datos', 'description': 'Base de datos de Firebase', 'standardLevel': 5},
      {'name': 'DynamoDB', 'sector': 'Bases de Datos', 'description': 'Base de datos NoSQL de AWS', 'standardLevel': 6},
      {'name': 'Cassandra', 'sector': 'Bases de Datos', 'description': 'Base de datos distribuida', 'standardLevel': 7},
      {'name': 'Elasticsearch', 'sector': 'Bases de Datos', 'description': 'Motor de búsqueda y análisis', 'standardLevel': 6},
      {'name': 'SQL', 'sector': 'Bases de Datos', 'description': 'Lenguaje de consultas', 'standardLevel': 5},

      // ========== CLOUD ==========
      {'name': 'AWS', 'sector': 'Cloud Computing', 'description': 'Amazon Web Services', 'standardLevel': 6},
      {'name': 'Google Cloud Platform', 'sector': 'Cloud Computing', 'description': 'Plataforma de Google', 'standardLevel': 6},
      {'name': 'Microsoft Azure', 'sector': 'Cloud Computing', 'description': 'Plataforma de Microsoft', 'standardLevel': 6},
      {'name': 'Firebase', 'sector': 'Cloud Computing', 'description': 'Plataforma de desarrollo de Google', 'standardLevel': 5},
      {'name': 'Docker', 'sector': 'DevOps', 'description': 'Contenedores de aplicaciones', 'standardLevel': 6},
      {'name': 'Kubernetes', 'sector': 'DevOps', 'description': 'Orquestación de contenedores', 'standardLevel': 7},
      {'name': 'Terraform', 'sector': 'DevOps', 'description': 'Infraestructura como código', 'standardLevel': 6},
      {'name': 'CI/CD', 'sector': 'DevOps', 'description': 'Integración y despliegue continuo', 'standardLevel': 6},
      {'name': 'GitHub Actions', 'sector': 'DevOps', 'description': 'Automatización de GitHub', 'standardLevel': 5},
      {'name': 'Jenkins', 'sector': 'DevOps', 'description': 'Servidor de automatización', 'standardLevel': 6},

      // ========== DATA SCIENCE & AI ==========
      {'name': 'Machine Learning', 'sector': 'Inteligencia Artificial', 'description': 'Aprendizaje automático', 'standardLevel': 7},
      {'name': 'Deep Learning', 'sector': 'Inteligencia Artificial', 'description': 'Redes neuronales profundas', 'standardLevel': 8},
      {'name': 'TensorFlow', 'sector': 'Inteligencia Artificial', 'description': 'Framework de ML de Google', 'standardLevel': 7},
      {'name': 'PyTorch', 'sector': 'Inteligencia Artificial', 'description': 'Framework de ML de Facebook', 'standardLevel': 7},
      {'name': 'NLP', 'sector': 'Inteligencia Artificial', 'description': 'Procesamiento de lenguaje natural', 'standardLevel': 7},
      {'name': 'Computer Vision', 'sector': 'Inteligencia Artificial', 'description': 'Visión por computadora', 'standardLevel': 7},
      {'name': 'Pandas', 'sector': 'Data Science', 'description': 'Análisis de datos en Python', 'standardLevel': 6},
      {'name': 'NumPy', 'sector': 'Data Science', 'description': 'Computación numérica', 'standardLevel': 6},
      {'name': 'Scikit-learn', 'sector': 'Data Science', 'description': 'Librería de ML', 'standardLevel': 6},
      {'name': 'Data Analysis', 'sector': 'Data Science', 'description': 'Análisis de datos', 'standardLevel': 6},

      // ========== DISEÑO ==========
      {'name': 'UI/UX Design', 'sector': 'Diseño', 'description': 'Diseño de interfaces', 'standardLevel': 6},
      {'name': 'Figma', 'sector': 'Diseño', 'description': 'Herramienta de diseño colaborativo', 'standardLevel': 5},
      {'name': 'Adobe XD', 'sector': 'Diseño', 'description': 'Herramienta de diseño de Adobe', 'standardLevel': 5},
      {'name': 'Sketch', 'sector': 'Diseño', 'description': 'Herramienta de diseño para Mac', 'standardLevel': 5},
      {'name': 'Photoshop', 'sector': 'Diseño', 'description': 'Edición de imágenes', 'standardLevel': 5},
      {'name': 'Illustrator', 'sector': 'Diseño', 'description': 'Diseño vectorial', 'standardLevel': 5},

      // ========== CAD / CAM / DISEÑO MECÁNICO ==========
      {'name': 'SolidWorks', 'sector': 'CAD/CAM', 'description': 'Software de diseño mecánico 3D', 'standardLevel': 6},
      {'name': 'AutoCAD', 'sector': 'CAD/CAM', 'description': 'Software de diseño asistido por computadora', 'standardLevel': 6},
      {'name': 'Inventor', 'sector': 'CAD/CAM', 'description': 'Software de modelado 3D de Autodesk', 'standardLevel': 6},
      {'name': 'CATIA', 'sector': 'CAD/CAM', 'description': 'Software CAD/CAM/CAE de Dassault Systèmes', 'standardLevel': 7},
      {'name': 'Fusion 360', 'sector': 'CAD/CAM', 'description': 'Plataforma CAD/CAM en la nube', 'standardLevel': 6},
      {'name': 'Creo', 'sector': 'CAD/CAM', 'description': 'Software de diseño paramétrico 3D', 'standardLevel': 7},
      {'name': 'Revit', 'sector': 'CAD/CAM', 'description': 'Software BIM para arquitectura e ingeniería', 'standardLevel': 6},
      {'name': 'NX', 'sector': 'CAD/CAM', 'description': 'Software CAD/CAM/CAE de Siemens', 'standardLevel': 7},
      {'name': 'Rhino', 'sector': 'CAD/CAM', 'description': 'Software de modelado 3D NURBS', 'standardLevel': 6},
      {'name': 'SketchUp', 'sector': 'CAD/CAM', 'description': 'Software de modelado 3D', 'standardLevel': 5},
      {'name': 'Mastercam', 'sector': 'CAD/CAM', 'description': 'Software CAM para manufactura', 'standardLevel': 6},
      {'name': 'SolidCAM', 'sector': 'CAD/CAM', 'description': 'Software CAM integrado', 'standardLevel': 6},

      // ========== SIMULACIÓN Y ANÁLISIS ==========
      {'name': 'ANSYS', 'sector': 'Simulación', 'description': 'Software de análisis por elementos finitos', 'standardLevel': 7},
      {'name': 'MATLAB', 'sector': 'Simulación', 'description': 'Entorno de computación numérica', 'standardLevel': 6},
      {'name': 'Simulink', 'sector': 'Simulación', 'description': 'Simulación de sistemas dinámicos', 'standardLevel': 6},
      {'name': 'COMSOL', 'sector': 'Simulación', 'description': 'Software de simulación multifísica', 'standardLevel': 7},
      {'name': 'Abaqus', 'sector': 'Simulación', 'description': 'Software FEA de Dassault Systèmes', 'standardLevel': 7},
      {'name': 'SolidWorks Simulation', 'sector': 'Simulación', 'description': 'Análisis FEA integrado en SolidWorks', 'standardLevel': 6},
      {'name': 'ETABS', 'sector': 'Simulación', 'description': 'Software de análisis estructural', 'standardLevel': 6},
      {'name': 'SAP2000', 'sector': 'Simulación', 'description': 'Software de análisis estructural', 'standardLevel': 6},
      {'name': 'LabVIEW', 'sector': 'Simulación', 'description': 'Plataforma de ingeniería de sistemas', 'standardLevel': 6},
      {'name': 'CFD', 'sector': 'Simulación', 'description': 'Dinámica de fluidos computacional', 'standardLevel': 7},

      // ========== MANUFACTURA Y PRODUCCIÓN ==========
      {'name': 'CNC Programming', 'sector': 'Manufactura', 'description': 'Programación de máquinas CNC', 'standardLevel': 6},
      {'name': 'Lean Manufacturing', 'sector': 'Manufactura', 'description': 'Metodología de manufactura esbelta', 'standardLevel': 6},
      {'name': 'Six Sigma', 'sector': 'Manufactura', 'description': 'Metodología de mejora de procesos', 'standardLevel': 6},
      {'name': '5S', 'sector': 'Manufactura', 'description': 'Metodología de organización', 'standardLevel': 5},
      {'name': 'Kaizen', 'sector': 'Manufactura', 'description': 'Mejora continua', 'standardLevel': 5},
      {'name': 'GD&T', 'sector': 'Manufactura', 'description': 'Dimensionamiento y tolerancias geométricas', 'standardLevel': 6},
      {'name': 'Quality Control', 'sector': 'Manufactura', 'description': 'Control de calidad', 'standardLevel': 5},
      {'name': 'ISO 9001', 'sector': 'Manufactura', 'description': 'Sistema de gestión de calidad', 'standardLevel': 5},
      {'name': 'FMEA', 'sector': 'Manufactura', 'description': 'Análisis de modos de falla y efectos', 'standardLevel': 6},
      {'name': 'SPC', 'sector': 'Manufactura', 'description': 'Control estadístico de procesos', 'standardLevel': 6},
      {'name': '3D Printing', 'sector': 'Manufactura', 'description': 'Impresión 3D / Manufactura aditiva', 'standardLevel': 5},
      {'name': 'Injection Molding', 'sector': 'Manufactura', 'description': 'Moldeo por inyección', 'standardLevel': 6},

      // ========== ELECTRICIDAD Y ELECTRÓNICA ==========
      {'name': 'PLC Programming', 'sector': 'Automatización', 'description': 'Programación de controladores lógicos', 'standardLevel': 6},
      {'name': 'SCADA', 'sector': 'Automatización', 'description': 'Sistemas de supervisión y control', 'standardLevel': 6},
      {'name': 'Arduino', 'sector': 'Electrónica', 'description': 'Plataforma de hardware libre', 'standardLevel': 5},
      {'name': 'Raspberry Pi', 'sector': 'Electrónica', 'description': 'Computadora de placa reducida', 'standardLevel': 5},
      {'name': 'Eagle PCB', 'sector': 'Electrónica', 'description': 'Diseño de circuitos impresos', 'standardLevel': 6},
      {'name': 'KiCad', 'sector': 'Electrónica', 'description': 'Software de diseño de PCB', 'standardLevel': 6},
      {'name': 'Altium Designer', 'sector': 'Electrónica', 'description': 'Software profesional de diseño de PCB', 'standardLevel': 7},
      {'name': 'Proteus', 'sector': 'Electrónica', 'description': 'Software de simulación electrónica', 'standardLevel': 6},
      {'name': 'LTSpice', 'sector': 'Electrónica', 'description': 'Simulador de circuitos', 'standardLevel': 5},

      // ========== INGENIERÍA CIVIL ==========
      {'name': 'Civil 3D', 'sector': 'Ingeniería Civil', 'description': 'Software para ingeniería civil', 'standardLevel': 6},
      {'name': 'Primavera P6', 'sector': 'Gestión de Proyectos', 'description': 'Software de gestión de proyectos', 'standardLevel': 6},
      {'name': 'MS Project', 'sector': 'Gestión de Proyectos', 'description': 'Gestión de proyectos de Microsoft', 'standardLevel': 5},
      {'name': 'BIM', 'sector': 'Ingeniería Civil', 'description': 'Modelado de información de construcción', 'standardLevel': 6},
      {'name': 'Navisworks', 'sector': 'Ingeniería Civil', 'description': 'Revisión de modelos BIM', 'standardLevel': 6},
      {'name': 'Tekla', 'sector': 'Ingeniería Civil', 'description': 'Software BIM para estructuras', 'standardLevel': 6},

      // ========== INGENIERÍA QUÍMICA Y PROCESOS ==========
      {'name': 'Aspen Plus', 'sector': 'Ingeniería Química', 'description': 'Simulación de procesos químicos', 'standardLevel': 7},
      {'name': 'ChemCAD', 'sector': 'Ingeniería Química', 'description': 'Simulación de procesos', 'standardLevel': 7},
      {'name': 'HYSYS', 'sector': 'Ingeniería Química', 'description': 'Simulación de procesos químicos', 'standardLevel': 7},
      {'name': 'Process Control', 'sector': 'Ingeniería Química', 'description': 'Control de procesos industriales', 'standardLevel': 6},

      // ========== ENERGÍA Y SOSTENIBILIDAD ==========
      {'name': 'PVsyst', 'sector': 'Energía Renovable', 'description': 'Diseño de sistemas fotovoltaicos', 'standardLevel': 6},
      {'name': 'Homer', 'sector': 'Energía Renovable', 'description': 'Optimización de sistemas híbridos', 'standardLevel': 6},
      {'name': 'LEED', 'sector': 'Sostenibilidad', 'description': 'Certificación de edificios sustentables', 'standardLevel': 5},

      // ========== OTROS ==========
      {'name': 'Git', 'sector': 'Control de Versiones', 'description': 'Sistema de control de versiones', 'standardLevel': 5},
      {'name': 'GraphQL', 'sector': 'API', 'description': 'Lenguaje de consultas para APIs', 'standardLevel': 6},
      {'name': 'REST API', 'sector': 'API', 'description': 'Arquitectura de servicios web', 'standardLevel': 5},
      {'name': 'Microservices', 'sector': 'Arquitectura', 'description': 'Arquitectura de microservicios', 'standardLevel': 7},
      {'name': 'Agile', 'sector': 'Metodologías', 'description': 'Metodología ágil', 'standardLevel': 5},
      {'name': 'Scrum', 'sector': 'Metodologías', 'description': 'Marco de trabajo ágil', 'standardLevel': 5},
      {'name': 'Testing', 'sector': 'Calidad', 'description': 'Pruebas de software', 'standardLevel': 5},
      {'name': 'Test-Driven Development', 'sector': 'Calidad', 'description': 'Desarrollo guiado por pruebas', 'standardLevel': 6},
      {'name': 'Cybersecurity', 'sector': 'Seguridad', 'description': 'Ciberseguridad', 'standardLevel': 7},
      {'name': 'Blockchain', 'sector': 'Tecnologías Emergentes', 'description': 'Tecnología de cadena de bloques', 'standardLevel': 7},
      {'name': 'Excel', 'sector': 'Productividad', 'description': 'Hoja de cálculo de Microsoft', 'standardLevel': 5},
      {'name': 'Power BI', 'sector': 'Análisis de Datos', 'description': 'Herramienta de visualización de datos', 'standardLevel': 5},
      {'name': 'Tableau', 'sector': 'Análisis de Datos', 'description': 'Plataforma de análisis visual', 'standardLevel': 6},

      // ========== COMPETENCIAS BLANDAS ==========
      {'name': 'Comunicación efectiva', 'sector': 'Soft Skills', 'description': 'Comunicar ideas de forma clara y empática', 'standardLevel': 7, 'nature': 'soft'},
      {'name': 'Pensamiento crítico', 'sector': 'Soft Skills', 'description': 'Analizar escenarios complejos antes de decidir', 'standardLevel': 7, 'nature': 'soft'},
      {'name': 'Colaboración multidisciplinaria', 'sector': 'Soft Skills', 'description': 'Facilitar el trabajo entre perfiles diversos', 'standardLevel': 6, 'nature': 'soft'},
      {'name': 'Gestión del cambio', 'sector': 'Soft Skills', 'description': 'Guiar equipos durante transformaciones', 'standardLevel': 6, 'nature': 'soft'},
      {'name': 'Negociación estratégica', 'sector': 'Soft Skills', 'description': 'Encontrar acuerdos que beneficien a todas las partes', 'standardLevel': 7, 'nature': 'soft'},
      {'name': 'Empatía aplicada', 'sector': 'Soft Skills', 'description': 'Comprender necesidades emocionales del equipo', 'standardLevel': 6, 'nature': 'soft'},
      {'name': 'Gestión de conflictos', 'sector': 'Soft Skills', 'description': 'Resolver desacuerdos de manera constructiva', 'standardLevel': 6, 'nature': 'soft'},

      // ========== LIDERAZGO & FACILITACIÓN ==========
      {'name': 'Liderazgo situacional', 'sector': 'Liderazgo', 'description': 'Adaptar el estilo de liderazgo según el contexto', 'standardLevel': 7, 'nature': 'leadership'},
      {'name': 'Mentoría de equipos', 'sector': 'Liderazgo', 'description': 'Desarrollar talento guiando a otros', 'standardLevel': 6, 'nature': 'leadership'},
      {'name': 'Facilitación de workshops', 'sector': 'Liderazgo', 'description': 'Diseñar y conducir sesiones colaborativas', 'standardLevel': 6, 'nature': 'leadership'},
      {'name': 'Storytelling ejecutivo', 'sector': 'Liderazgo', 'description': 'Presentar estrategias con narrativas convincentes', 'standardLevel': 6, 'nature': 'leadership'},

      // ========== NEGOCIO & ESTRATEGIA ==========
      {'name': 'Modelado de negocio', 'sector': 'Negocio y Estrategia', 'description': 'Diseño de propuestas de valor sostenibles', 'standardLevel': 6, 'nature': 'business'},
      {'name': 'Análisis financiero básico', 'sector': 'Negocio y Estrategia', 'description': 'Interpretar estados financieros esenciales', 'standardLevel': 5, 'nature': 'business'},
      {'name': 'Gestión de stakeholders', 'sector': 'Negocio y Estrategia', 'description': 'Mapear y priorizar interesados clave', 'standardLevel': 7, 'nature': 'business'},
      {'name': 'Customer Centricity', 'sector': 'Negocio y Estrategia', 'description': 'Diseñar decisiones en torno al usuario', 'standardLevel': 6, 'nature': 'business'},
      {'name': 'Design Thinking', 'sector': 'Negocio y Estrategia', 'description': 'Aplicar proceso de descubrimiento y prototipado', 'standardLevel': 6, 'nature': 'creative'},

      // ========== CREATIVIDAD & INNOVACIÓN ==========
      {'name': 'Ideación creativa', 'sector': 'Innovación', 'description': 'Generar hipótesis y conceptos originales', 'standardLevel': 6, 'nature': 'creative'},
      {'name': 'Prototipado rápido', 'sector': 'Innovación', 'description': 'Convertir ideas en pruebas tangibles', 'standardLevel': 6, 'nature': 'creative'},
      {'name': 'Mapas de experiencia', 'sector': 'Innovación', 'description': 'Visualizar journeys y oportunidades', 'standardLevel': 6, 'nature': 'creative'},
      {'name': 'Narrativas para pitching', 'sector': 'Innovación', 'description': 'Construir pitches breves y memorables', 'standardLevel': 6, 'nature': 'creative'},
    ];
  }
}
