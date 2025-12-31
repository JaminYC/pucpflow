import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/department.dart';
import 'models/department_stats.dart';
import 'models/route_model.dart';
import 'models/signal_model.dart';

class FirestoreRepository {
  FirestoreRepository({
    FirebaseFirestore? firestore,
    bool useLocalFallback = true,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _useLocalFallback = useLocalFallback;

  final FirebaseFirestore _firestore;
  final bool _useLocalFallback;

  static const String _demoRoutePrefix = 'demo__';

  static const Map<String, Map<String, Object>> _demoDepartments = {
    'tumbes': {
      'name': 'Tumbes',
      'region': 'costa',
      'tags': ['playa', 'avistamiento'],
    },
    'piura': {
      'name': 'Piura',
      'region': 'costa',
      'tags': ['gastronomia', 'playa'],
    },
    'lambayeque': {
      'name': 'Lambayeque',
      'region': 'costa',
      'tags': ['museos', 'cultura'],
    },
    'cajamarca': {
      'name': 'Cajamarca',
      'region': 'sierra',
      'tags': ['andino', 'historia'],
    },
    'amazonas': {
      'name': 'Amazonas',
      'region': 'selva',
      'tags': ['bosque', 'cataratas'],
    },
    'la_libertad': {
      'name': 'La Libertad',
      'region': 'costa',
      'tags': ['arqueologia', 'costa'],
    },
    'ancash': {
      'name': 'Ancash',
      'region': 'sierra',
      'tags': ['montana', 'lagunas'],
    },
    'san_martin': {
      'name': 'San Martin',
      'region': 'selva',
      'tags': ['selva', 'cascadas'],
    },
    'loreto': {
      'name': 'Loreto',
      'region': 'selva',
      'tags': ['amazonas', 'fauna'],
    },
    'ucayali': {
      'name': 'Ucayali',
      'region': 'selva',
      'tags': ['rio', 'aventura'],
    },
    'lima': {
      'name': 'Lima',
      'region': 'costa',
      'tags': ['urbano', 'costa'],
    },
    'callao': {
      'name': 'Callao',
      'region': 'costa',
      'tags': ['puerto', 'mar'],
    },
    'huanuco': {
      'name': 'Huanuco',
      'region': 'sierra',
      'tags': ['bosques', 'clima'],
    },
    'pasco': {
      'name': 'Pasco',
      'region': 'sierra',
      'tags': ['altiplano', 'lagunas'],
    },
    'junin': {
      'name': 'Junin',
      'region': 'sierra',
      'tags': ['valle', 'tradicion'],
    },
    'ica': {
      'name': 'Ica',
      'region': 'costa',
      'tags': ['desierto', 'pisco'],
    },
    'huancavelica': {
      'name': 'Huancavelica',
      'region': 'sierra',
      'tags': ['andino', 'rutas'],
    },
    'ayacucho': {
      'name': 'Ayacucho',
      'region': 'sierra',
      'tags': ['arte', 'cultura'],
    },
    'apurimac': {
      'name': 'Apurimac',
      'region': 'sierra',
      'tags': ['caminatas', 'canon'],
    },
    'cusco': {
      'name': 'Cusco',
      'region': 'sierra',
      'tags': ['incas', 'montanas'],
    },
    'arequipa': {
      'name': 'Arequipa',
      'region': 'sierra',
      'tags': ['volcan', 'canones'],
    },
    'moquegua': {
      'name': 'Moquegua',
      'region': 'costa',
      'tags': ['valles', 'vino'],
    },
    'tacna': {
      'name': 'Tacna',
      'region': 'costa',
      'tags': ['frontera', 'desierto'],
    },
    'puno': {
      'name': 'Puno',
      'region': 'sierra',
      'tags': ['lago', 'altiplano'],
    },
    'madre_de_dios': {
      'name': 'Madre de Dios',
      'region': 'selva',
      'tags': ['biodiversidad', 'selva'],
    },
  };

  static const List<Map<String, Object>> _demoRouteTemplates = [
    {
      'suffix': 'ruta_1',
      'name': 'Circuito esencial',
      'durationDays': 2,
      'difficulty': 'baja',
    },
    {
      'suffix': 'ruta_2',
      'name': 'Travesia natural',
      'durationDays': 4,
      'difficulty': 'media',
    },
    {
      'suffix': 'ruta_3',
      'name': 'Exploracion extensa',
      'durationDays': 6,
      'difficulty': 'alta',
    },
  ];

  Stream<Department> watchDepartment(String deptId) {
    return _firestore.collection('departments').doc(deptId).snapshots().map(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return Department.fromMap(snapshot.id, snapshot.data()!);
            }
            if (_useLocalFallback) {
              return _demoDepartment(deptId);
            }
            return Department.placeholder(deptId);
          },
        );
  }

  Stream<DepartmentStats> watchStats(String deptId) {
    return _firestore.collection('stats').doc(deptId).snapshots().map(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return DepartmentStats.fromMap(snapshot.data()!);
            }
            if (_useLocalFallback) {
              return _demoStats(deptId);
            }
            return DepartmentStats.placeholder();
          },
        );
  }

  Stream<List<RouteModel>> watchTopRoutes(String deptId, {int limit = 3}) {
    return _firestore
        .collection('routes')
        .where('deptId', isEqualTo: deptId)
        .orderBy('durationDays', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty && _useLocalFallback) {
            final demo = _demoRoutesForDept(deptId);
            return demo.take(limit).toList();
          }
          return snapshot.docs
              .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<RouteModel>> watchRoutes(String deptId) {
    return _firestore
        .collection('routes')
        .where('deptId', isEqualTo: deptId)
        .orderBy('durationDays', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty && _useLocalFallback) {
            return _demoRoutesForDept(deptId);
          }
          return snapshot.docs
              .map((doc) => RouteModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<RouteModel?> watchRoute(String routeId) {
    return _firestore.collection('routes').doc(routeId).snapshots().map(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return RouteModel.fromMap(snapshot.id, snapshot.data()!);
            }
            if (_useLocalFallback) {
              return _demoRouteById(routeId);
            }
            return null;
          },
        );
  }

  Stream<SignalModel> watchSignal(String deptId) {
    return _firestore.collection('signals').doc(deptId).snapshots().map(
          (snapshot) =>
              snapshot.exists && snapshot.data() != null
                  ? SignalModel.fromMap(snapshot.data()!)
                  : SignalModel.placeholder(),
        );
  }

  Department _demoDepartment(String deptId) {
    final data = _demoDepartments[deptId];
    if (data == null) {
      return Department.placeholder(deptId);
    }
    return Department(
      id: deptId,
      name: data['name'] as String,
      region: data['region'] as String,
      tags: List<String>.from(data['tags'] as List),
    );
  }

  DepartmentStats _demoStats(String deptId) {
    final dept = _demoDepartment(deptId);
    final routes = _demoRoutesForDept(deptId);
    final featuredId = routes.isNotEmpty ? routes.first.id : '';
    return DepartmentStats(
      routesCount: routes.length,
      placesCount: 0,
      featuredRouteId: featuredId,
      recommendedSeason: _seasonForRegion(dept.region),
      lastUpdated: Timestamp.now(),
    );
  }

  List<RouteModel> _demoRoutesForDept(String deptId) {
    final dept = _demoDepartment(deptId);
    return _demoRouteTemplates.map((template) {
      final suffix = template['suffix'] as String;
      final routeId = '$_demoRoutePrefix${deptId}__$suffix';
      return _buildDemoRoute(dept, routeId, template);
    }).toList();
  }

  RouteModel? _demoRouteById(String routeId) {
    if (!routeId.startsWith(_demoRoutePrefix)) return null;
    final parts = routeId.split('__');
    if (parts.length != 3) return null;
    final deptId = parts[1];
    final suffix = parts[2];
    final template = _demoRouteTemplates.firstWhere(
      (item) => item['suffix'] == suffix,
      orElse: () => const <String, Object>{},
    );
    if (template.isEmpty) return null;
    final dept = _demoDepartment(deptId);
    return _buildDemoRoute(dept, routeId, template);
  }

  RouteModel _buildDemoRoute(
    Department dept,
    String routeId,
    Map<String, Object> template,
  ) {
    final name = template['name'] as String;
    return RouteModel(
      id: routeId,
      deptId: dept.id,
      name: '${dept.name} - $name',
      durationDays: template['durationDays'] as int,
      difficulty: template['difficulty'] as String,
      summary: 'Ruta demo para ${dept.name}.',
      tags: ['ruta', dept.region],
    );
  }

  String _seasonForRegion(String region) {
    switch (region) {
      case 'selva':
        return 'may-oct';
      case 'sierra':
        return 'may-sept';
      case 'costa':
        return 'dic-mar';
      default:
        return '--';
    }
  }
}
