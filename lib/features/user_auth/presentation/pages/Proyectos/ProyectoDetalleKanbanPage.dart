import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/tarea_model.dart';
import 'package:pucpflow/features/user_auth/TareaFormWidget.dart';
import 'package:pucpflow/features/user_auth/tarea_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/asignacion_inteligente_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/redistribucion_tareas_service.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/ReunionPresencialPage.dart';

// Importar widgets personalizados
import 'widgets/kanban_draggable_column.dart';
import 'widgets/pmi_tree_view.dart';
import 'widgets/timeline_calendar_view.dart';
import 'widgets/personal_stats_view.dart';

/// Dashboard mejorado con Kanban drag&drop, Timeline y Vista PMI
class ProyectoDetalleKanbanPage extends StatefulWidget {
  final String proyectoId;

  const ProyectoDetalleKanbanPage({super.key, required this.proyectoId});

  @override
  State<ProyectoDetalleKanbanPage> createState() => _ProyectoDetalleKanbanPageState();
}

class _ProyectoDetalleKanbanPageState extends State<ProyectoDetalleKanbanPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TareaService _tareaService = TareaService();
  final AsignacionInteligenteService _asignacionService = AsignacionInteligenteService();
  final RedistribucionTareasService _redistribucionService = RedistribucionTareasService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  List<Tarea> todasLasTareas = [];
  Map<String, String> nombreResponsables = {};
  Map<String, List<String>> areas = {};
  List<Map<String, String>> participantes = [];
  bool loading = true;
  String searchQuery = '';
  String? filtroResponsable;
  String? filtroPrioridad;
  bool esPMI = false; // Detecta si el proyecto es PMI

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => loading = true);
    todasLasTareas = await _tareaService.obtenerTareasDelProyecto(widget.proyectoId);
    await _cargarNombresResponsables();
    await _cargarAreas();
    await _cargarParticipantes();
    await _detectarProyectoPMI();
    setState(() => loading = false);
  }

  Future<void> _detectarProyectoPMI() async {
    // Leer el campo esPMI directamente del proyecto en Firestore
    final doc = await _firestore.collection("proyectos").doc(widget.proyectoId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        esPMI = data["esPMI"] ?? false;
      });
    }
  }

  Future<void> _cargarNombresResponsables() async {
    final uids = todasLasTareas.expand((t) => t.responsables).toSet();
    for (String uid in uids) {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        nombreResponsables[uid] = doc.data()!["full_name"] ?? "Usuario";
      }
    }
  }

  Future<void> _cargarAreas() async {
    final doc = await _firestore.collection("proyectos").doc(widget.proyectoId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data.containsKey('areas') && data['areas'] is Map) {
        final areasOriginales = data['areas'] as Map;

        print("\n🔍 DEBUG _cargarAreas:");
        print("  📦 Áreas desde Firestore: ${areasOriginales.keys.toList()}");

        // Crear un mapa temporal para manejar duplicados después de normalizar
        Map<String, List<String>> areasTemp = {};

        areasOriginales.forEach((key, value) {
          String areaNormalizada = _normalizarArea(key.toString());
          List<String> tareasArea = (value as List).map((e) => e.toString()).toList();

          print("  🔧 Procesando área:");
          print("     Original: '$key'");
          print("     Normalizada: '$areaNormalizada'");
          print("     Ya existe en temp: ${areasTemp.containsKey(areaNormalizada)}");

          // Si el área ya existe, combinar las tareas
          if (areasTemp.containsKey(areaNormalizada)) {
            print("     ⚠️ DUPLICADO DETECTADO - Fusionando tareas");
            areasTemp[areaNormalizada]!.addAll(tareasArea);
          } else {
            areasTemp[areaNormalizada] = tareasArea;
          }
        });

        print("  ✅ Áreas finales después de normalizar: ${areasTemp.keys.toList()}");
        print("  📊 Total áreas: ${areasTemp.length}\n");

        areas = areasTemp;
      }
    }
  }

  // Normalizar nombres de áreas (eliminar saltos de línea y espacios extra)
  String _normalizarArea(String area) {
    return area.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _cargarParticipantes() async {
    final doc = await _firestore.collection("proyectos").doc(widget.proyectoId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> uids = data["participantes"] ?? [];
      final List<Map<String, String>> temp = [];

      for (String uid in uids) {
        final userDoc = await _firestore.collection("users").doc(uid).get();
        if (userDoc.exists) {
          temp.add({
            "uid": uid,
            "nombre": userDoc["full_name"] ?? "Usuario",
            "email": userDoc["email"] ?? "",
          });
        }
      }

      participantes = temp;
    }
  }

  List<Tarea> get tareasFiltradas {
    var tareas = todasLasTareas;

    if (searchQuery.isNotEmpty) {
      tareas = tareas.where((t) {
        final titulo = t.titulo.toLowerCase();
        final descripcion = (t.descripcion ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        return titulo.contains(query) || descripcion.contains(query);
      }).toList();
    }

    if (filtroResponsable != null) {
      tareas = tareas.where((t) => t.responsables.contains(filtroResponsable)).toList();
    }

    if (filtroPrioridad != null) {
      final prioridadMap = {'Baja': 1, 'Media': 2, 'Alta': 3};
      tareas = tareas.where((t) => t.prioridad == prioridadMap[filtroPrioridad]).toList();
    }

    return tareas;
  }

  Map<String, List<Tarea>> get tareasKanban {
    final filtradas = tareasFiltradas;
    return {
      'pendiente': filtradas.where((t) => !t.completado && t.prioridad < 3).toList(),
      'en_progreso': filtradas.where((t) => !t.completado && t.prioridad >= 3).toList(),
      'completada': filtradas.where((t) => t.completado).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: _buildAppBar(),
      drawer: _buildProjectInfoDrawer(),
      body: loading ? _buildLoadingState() : _buildTabView(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0E27),
      elevation: 0,
      title: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection("proyectos").doc(widget.proyectoId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Proyecto');
          final proyecto = Proyecto.fromFirestore(snapshot.data!);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proyecto.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${todasLasTareas.where((t) => t.completado).length}/${todasLasTareas.length} completadas',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.psychology, color: Color(0xFF8B5CF6)),
          tooltip: 'Asignación automática IA',
          onPressed: _asignarTareasConIA,
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.filter_list,
            color: (filtroResponsable != null || filtroPrioridad != null)
                ? const Color(0xFF8B5CF6)
                : Colors.white,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Text('Filtrar por:', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const PopupMenuDivider(),
            ..._buildFiltroResponsables(),
            const PopupMenuDivider(),
            ..._buildFiltroPrioridad(),
            if (filtroResponsable != null || filtroPrioridad != null) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('Limpiar filtros'),
                onTap: () => setState(() {
                  filtroResponsable = null;
                  filtroPrioridad = null;
                }),
              ),
            ],
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar tareas...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1A1F3A).withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF8B5CF6),
              indicatorWeight: 3,
              labelColor: const Color(0xFF8B5CF6),
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              tabs: [
                const Tab(
                  icon: Icon(Icons.view_kanban, size: 20),
                  text: 'Kanban',
                ),
                Tab(
                  icon: const Icon(Icons.calendar_month, size: 20),
                  text: 'Timeline',
                ),
                if (esPMI)
                  const Tab(
                    icon: Icon(Icons.account_tree, size: 20),
                    text: 'Vista PMI',
                  )
                else
                  const Tab(
                    icon: Icon(Icons.bar_chart, size: 20),
                    text: 'Stats',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildFiltroResponsables() {
    final responsables = nombreResponsables.entries.toList();
    if (responsables.isEmpty) return [];

    return [
      const PopupMenuItem(
        enabled: false,
        child: Text('Responsable:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
      ...responsables.map((entry) {
        final seleccionado = filtroResponsable == entry.key;
        return CheckedPopupMenuItem(
          value: entry.key,
          checked: seleccionado,
          onTap: () => setState(() {
            filtroResponsable = seleccionado ? null : entry.key;
          }),
          child: Text(entry.value),
        );
      }),
    ];
  }

  List<PopupMenuEntry<String>> _buildFiltroPrioridad() {
    const prioridades = ['Baja', 'Media', 'Alta'];
    return [
      const PopupMenuItem(
        enabled: false,
        child: Text('Prioridad:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
      ...prioridades.map((prioridad) {
        final seleccionado = filtroPrioridad == prioridad;
        return CheckedPopupMenuItem(
          value: prioridad,
          checked: seleccionado,
          onTap: () => setState(() {
            filtroPrioridad = seleccionado ? null : prioridad;
          }),
          child: Text(prioridad),
        );
      }),
    ];
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Kanban con Drag & Drop
        _buildKanbanView(),

        // Tab 2: Timeline/Calendario
        TimelineCalendarView(
          tareas: tareasFiltradas,
          onTareaTapped: _mostrarDetalleTarea,
          onCheckboxChanged: _onCheckboxChanged,
          nombreResponsables: nombreResponsables,
          userId: _auth.currentUser!.uid,
        ),

        // Tab 3: Vista PMI o Stats Personales
        if (esPMI)
          PMITreeView(
            tareas: tareasFiltradas,
            onTareaTapped: _mostrarDetalleTarea,
            onCheckboxChanged: _onCheckboxChanged,
            nombreResponsables: nombreResponsables,
            userId: _auth.currentUser!.uid,
          )
        else
          PersonalStatsView(tareas: tareasFiltradas),
      ],
    );
  }

  Widget _buildKanbanView() {
    final kanban = tareasKanban;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detectar si es móvil (ancho < 600px) o tablet/desktop
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Vista móvil: Scroll horizontal con columnas de ancho fijo
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.85, // 85% del ancho de pantalla por columna
                  child: KanbanDraggableColumn(
                    titulo: 'Pendiente',
                    tareas: kanban['pendiente']!,
                    color: const Color(0xFFF59E0B),
                    icono: Icons.pending_outlined,
                    estadoObjetivo: 'pendiente',
                    onTareaMoved: _moverTarea,
                    onTareaTapped: _mostrarDetalleTarea,
                    onCheckboxChanged: _onCheckboxChanged,
                    nombreResponsables: nombreResponsables,
                    userId: _auth.currentUser!.uid,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: constraints.maxWidth * 0.85,
                  child: KanbanDraggableColumn(
                    titulo: 'En Progreso',
                    tareas: kanban['en_progreso']!,
                    color: const Color(0xFF3B82F6),
                    icono: Icons.play_circle_outline,
                    estadoObjetivo: 'en_progreso',
                    onTareaMoved: _moverTarea,
                    onTareaTapped: _mostrarDetalleTarea,
                    onCheckboxChanged: _onCheckboxChanged,
                    nombreResponsables: nombreResponsables,
                    userId: _auth.currentUser!.uid,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: constraints.maxWidth * 0.85,
                  child: KanbanDraggableColumn(
                    titulo: 'Completada',
                    tareas: kanban['completada']!,
                    color: const Color(0xFF10B981),
                    icono: Icons.check_circle_outline,
                    estadoObjetivo: 'completada',
                    onTareaMoved: _moverTarea,
                    onTareaTapped: _mostrarDetalleTarea,
                    onCheckboxChanged: _onCheckboxChanged,
                    nombreResponsables: nombreResponsables,
                    userId: _auth.currentUser!.uid,
                  ),
                ),
                const SizedBox(width: 8), // Padding final
              ],
            ),
          );
        } else {
          // Vista desktop/tablet: Row normal con Expanded
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: KanbanDraggableColumn(
                  titulo: 'Pendiente',
                  tareas: kanban['pendiente']!,
                  color: const Color(0xFFF59E0B),
                  icono: Icons.pending_outlined,
                  estadoObjetivo: 'pendiente',
                  onTareaMoved: _moverTarea,
                  onTareaTapped: _mostrarDetalleTarea,
                  onCheckboxChanged: _onCheckboxChanged,
                  nombreResponsables: nombreResponsables,
                  userId: _auth.currentUser!.uid,
                ),
              ),
              Expanded(
                child: KanbanDraggableColumn(
                  titulo: 'En Progreso',
                  tareas: kanban['en_progreso']!,
                  color: const Color(0xFF3B82F6),
                  icono: Icons.play_circle_outline,
                  estadoObjetivo: 'en_progreso',
                  onTareaMoved: _moverTarea,
                  onTareaTapped: _mostrarDetalleTarea,
                  onCheckboxChanged: _onCheckboxChanged,
                  nombreResponsables: nombreResponsables,
                  userId: _auth.currentUser!.uid,
                ),
              ),
              Expanded(
                child: KanbanDraggableColumn(
                  titulo: 'Completada',
                  tareas: kanban['completada']!,
                  color: const Color(0xFF10B981),
                  icono: Icons.check_circle_outline,
                  estadoObjetivo: 'completada',
                  onTareaMoved: _moverTarea,
                  onTareaTapped: _mostrarDetalleTarea,
                  onCheckboxChanged: _onCheckboxChanged,
                  nombreResponsables: nombreResponsables,
                  userId: _auth.currentUser!.uid,
                ),
              ),
            ],
          );
        }
      },
    );
  }


  Widget _buildProjectInfoDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0E27),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection("proyectos").doc(widget.proyectoId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final proyecto = Proyecto.fromFirestore(snapshot.data!);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Info del Proyecto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDrawerInfoCard(
                    Icons.folder_outlined,
                    'Nombre',
                    proyecto.nombre,
                  ),
                  const SizedBox(height: 12),
                  _buildDrawerInfoCard(
                    Icons.calendar_today,
                    'Inicio',
                    proyecto.fechaInicio != null
                        ? DateFormat('dd/MM/yyyy').format(proyecto.fechaInicio!)
                        : 'No definida',
                  ),
                  const SizedBox(height: 12),
                  _buildDrawerInfoCard(
                    Icons.event,
                    'Fin',
                    proyecto.fechaFin != null
                        ? DateFormat('dd/MM/yyyy').format(proyecto.fechaFin!)
                        : 'No definida',
                  ),
                  const SizedBox(height: 24),
                  _buildDrawerParticipantes(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerParticipantes() {
    if (participantes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...participantes.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _colorDesdeUID(p['uid']!),
                    child: Text(
                      p['nombre']![0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['nombre']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          p['email']!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón principal: Nueva tarea
        FloatingActionButton.extended(
          heroTag: "nuevaTareaKanban",
          backgroundColor: const Color(0xFF8B5CF6),
          label: const Text("Nueva tarea", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          onPressed: _crearNuevaTarea,
          elevation: 4,
        ),
        const SizedBox(height: 12),
        // Menú de opciones (tres puntos)
        FloatingActionButton(
          heroTag: "menuBtnKanban",
          backgroundColor: Colors.white,
          onPressed: _mostrarMenuOpciones,
          elevation: 4,
          child: const Icon(Icons.more_vert, color: Colors.black87),
        ),
      ],
    );
  }

  void _mostrarMenuOpciones() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Opciones de Proyecto",
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.blue),
              ),
              title: const Text("Redistribuir Tareas", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Reorganizar tareas pendientes", style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _redistribuirTareasPendientes();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.orange),
              ),
              title: const Text("Auto-asignar Tareas", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Asignar automáticamente", style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _asignarTareasConIA();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mic, color: Colors.black87),
              ),
              title: const Text("Iniciar Reunión", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Reunión presencial con IA", style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _abrirReunion();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ========================================
  //  ACCIONES
  // ========================================

  Future<void> _moverTarea(Tarea tarea, String nuevoEstado) async {
    // Actualizar prioridad según la columna
    int nuevaPrioridad = tarea.prioridad;
    bool nuevoCompletado = tarea.completado;

    switch (nuevoEstado) {
      case 'pendiente':
        nuevaPrioridad = tarea.prioridad < 3 ? tarea.prioridad : 2;
        nuevoCompletado = false;
        break;
      case 'en_progreso':
        nuevaPrioridad = 3; // Alta prioridad
        nuevoCompletado = false;
        break;
      case 'completada':
        nuevoCompletado = true;
        break;
    }

    // Crear tarea actualizada
    final tareaActualizada = Tarea(
      titulo: tarea.titulo,
      fecha: tarea.fecha,
      duracion: tarea.duracion,
      prioridad: nuevaPrioridad,
      completado: nuevoCompletado,
      colorId: tarea.colorId,
      responsables: tarea.responsables,
      tipoTarea: tarea.tipoTarea,
      requisitos: tarea.requisitos,
      dificultad: tarea.dificultad,
      descripcion: tarea.descripcion,
      tareasPrevias: tarea.tareasPrevias,
      area: tarea.area,
      habilidadesRequeridas: tarea.habilidadesRequeridas,
      fasePMI: tarea.fasePMI,
      entregable: tarea.entregable,
      paqueteTrabajo: tarea.paqueteTrabajo,
    );

    await _tareaService.actualizarTareaEnProyecto(
      widget.proyectoId,
      tarea,
      tareaActualizada,
    );

    _cargarDatos();
  }

  Future<void> _onCheckboxChanged(Tarea tarea, bool completado, String userId) async {
    await _tareaService.marcarTareaComoCompletada(tarea, completado, userId);
    _cargarDatos();
  }

  // ========================================
  //  REDISTRIBUCIÓN INTELIGENTE DE TAREAS
  // ========================================
  Future<void> _redistribuirTareasPendientes() async {
    final tareasPendientes = todasLasTareas.where((t) => !t.completado).toList();

    if (tareasPendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ No hay tareas pendientes para redistribuir'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Obtener el proyecto actual
    final proyectoDoc = await _firestore.collection('proyectos').doc(widget.proyectoId).get();
    if (!proyectoDoc.exists) return;

    final proyecto = Proyecto.fromFirestore(proyectoDoc);

    // Mostrar diálogo de confirmación con vista previa
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialogoConfirmacionRedistribucion(
        proyecto: proyecto,
        tareasPendientes: tareasPendientes,
      ),
    );

    if (confirmar != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
    );

    try {
      // Ejecutar redistribución
      final resultado = _redistribucionService.redistribuirTareas(
        proyecto: proyecto,
        tareas: todasLasTareas,
      );

      // Guardar tareas actualizadas en Firestore
      final tareasJson = resultado.tareasActualizadas.map((t) => t.toJson()).toList();
      await _firestore.collection('proyectos').doc(widget.proyectoId).update({
        'tareas': tareasJson,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      // Recargar tareas
      await _cargarDatos();

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      // Mostrar resultado
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildDialogoResultadoRedistribucion(resultado),
        );
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en redistribución: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDialogoConfirmacionRedistribucion({
    required Proyecto proyecto,
    required List<Tarea> tareasPendientes,
  }) {
    final fechaInicio = DateTime.now();
    final fechaFin = proyecto.fechaFin ?? fechaInicio.add(const Duration(days: 30));
    final dias = fechaFin.difference(fechaInicio).inDays + 1;

    final totalMinutos = tareasPendientes.fold<int>(0, (sum, t) => sum + t.duracion);
    final totalHoras = (totalMinutos / 60).toStringAsFixed(1);

    final distribucionDificultad = <String, int>{};
    for (var t in tareasPendientes) {
      final dif = t.dificultad ?? 'media';
      distribucionDificultad[dif] = (distribucionDificultad[dif] ?? 0) + 1;
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F3A),
      title: const Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Redistribuir Tareas',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tareasPendientes.length} tareas pendientes serán redistribuidas',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rango', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('📅 ${DateFormat('dd/MM/yy').format(fechaInicio)} → ${DateFormat('dd/MM/yy').format(fechaFin)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('⏱️ $dias días disponibles',
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                if (distribucionDificultad['alta'] != null)
                  Chip(
                    label: Text('Alta: ${distribucionDificultad['alta']}', style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red.shade700,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                if (distribucionDificultad['media'] != null)
                  Chip(
                    label: Text('Media: ${distribucionDificultad['media']}', style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.orange.shade700,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                if (distribucionDificultad['baja'] != null)
                  Chip(
                    label: Text('Baja: ${distribucionDificultad['baja']}', style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green.shade700,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Redistribuir'),
        ),
      ],
    );
  }

  Widget _buildDialogoResultadoRedistribucion(ResultadoRedistribucion resultado) {
    final stats = resultado.estadisticas;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1F3A),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('¡Completado!', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✓ ${resultado.tareasRedistribuidas} tareas redistribuidas',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildStatRowCompact('Completadas', '${resultado.tareasCompletadas}', Colors.green),
                  _buildStatRowCompact('Redistribuidas', '${resultado.tareasRedistribuidas}', Colors.blue),
                  _buildStatRowCompact('Total hrs', '${stats['duracionTotalHoras']}', Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildStatRowCompact(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  // ========================================
  //  ABRIR REUNIÓN
  // ========================================
  Future<void> _abrirReunion() async {
    // Obtener el proyecto actual
    final proyectoDoc = await _firestore.collection('proyectos').doc(widget.proyectoId).get();
    if (!proyectoDoc.exists || !mounted) return;

    final proyecto = Proyecto.fromFirestore(proyectoDoc);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReunionPresencialPage(proyecto: proyecto),
      ),
    );
  }

  Future<void> _crearNuevaTarea() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
          child: TareaFormWidget(
            tareaInicial: null,
            areas: areas,
            participantes: participantes,
            onSubmit: (nuevaTarea) async {
              await _tareaService.agregarTareaAProyecto(widget.proyectoId, nuevaTarea);
              if (mounted) {
                Navigator.pop(context);
                _cargarDatos();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleTarea(Tarea tarea) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
          child: TareaFormWidget(
            tareaInicial: tarea,
            areas: areas,
            participantes: participantes,
            onSubmit: (tareaEditada) async {
              await _tareaService.actualizarTareaEnProyecto(
                widget.proyectoId,
                tarea,
                tareaEditada,
              );
              if (mounted) {
                Navigator.pop(context);
                _cargarDatos();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _asignarTareasConIA() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text('Asignación Inteligente', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'La IA asignará automáticamente las tareas pendientes. ¿Continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Asignar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
      ),
    );

    try {
      final resultado = await _asignacionService.asignarTodasAutomaticamente(
        proyectoId: widget.proyectoId,
        tareas: todasLasTareas,
        participantesIds: participantes.map((p) => p['uid']!).toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        _cargarDatos();

        final asignadas = resultado['asignadas'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$asignadas tareas asignadas'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Color _colorDesdeUID(String uid) {
    final int hash = uid.hashCode;
    final double hue = 40 + (hash % 280);
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.7).toColor();
  }
}
