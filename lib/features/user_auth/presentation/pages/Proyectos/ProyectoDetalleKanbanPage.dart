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
import 'widgets/proyecto_asistente_chat_widget.dart';
import 'widgets/inventario_view.dart';
import 'widgets/repositorio_conocimiento_view.dart';
import 'widgets/informes_view.dart';
import 'widgets/correos_view.dart';
import 'widgets/calendario_proyecto_view.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

      for (String uid in uids.cast<String>()) {
        final userDoc = await _firestore.collection("users").doc(uid).get();
        if (userDoc.exists) {
          final uData = userDoc.data()!;
          temp.add({
            "uid": uid,
            "nombre": _resolverNombreUsuario(uData),
            "email": uData["email"]?.toString() ?? "",
          });
        }
      }

      if (mounted) setState(() => participantes = temp);
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
      'pendiente': filtradas.where((t) => t.estado == 'pendiente').toList(),
      'en_progreso': filtradas.where((t) => t.estado == 'en_progreso').toList(),
      'completada': filtradas.where((t) => t.estado == 'completada').toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0A0E27),
      appBar: _buildAppBar(),
      drawer: _buildProjectInfoDrawer(),
      endDrawer: _buildEndDrawer(),
      body: loading ? _buildLoadingState() : _buildTabView(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final completadas = todasLasTareas.where((t) => t.completado).length;
    final total = todasLasTareas.length;
    final progreso = total > 0 ? completadas / total : 0.0;

    return AppBar(
      backgroundColor: const Color(0xFF0A0E27),
      elevation: 0,
      toolbarHeight: 60,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection("proyectos").doc(widget.proyectoId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text('Proyecto', style: TextStyle(color: Colors.white));
          final proyecto = Proyecto.fromFirestore(snapshot.data!);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proyecto.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Mini barra de progreso
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progreso,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progreso >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completadas/$total',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        // Botón Participantes (visible)
        IconButton(
          icon: const Icon(Icons.group, color: Colors.white70, size: 22),
          tooltip: 'Participantes',
          onPressed: _mostrarGestionParticipantes,
        ),
        // Botón Asistente IA (visible)
        IconButton(
          icon: const Icon(Icons.smart_toy, color: Color(0xFF8B5CF6), size: 22),
          tooltip: 'Asistente IA',
          onPressed: _abrirAsistenteProyecto,
        ),
        // Botón panel lateral: Inventario + Recursos
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.folder_special, color: Color(0xFF10B981), size: 22),
            tooltip: 'Inventario y Recursos',
            onPressed: () {
              Scaffold.of(ctx).openEndDrawer();
            },
          ),
        ),
        // Menú con opciones secundarias
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: (filtroResponsable != null || filtroPrioridad != null)
                ? const Color(0xFF8B5CF6)
                : Colors.white70,
            size: 22,
          ),
          tooltip: 'Más opciones',
          onSelected: (value) {
            if (value == 'asignar_ia') {
              _asignarTareasConIA();
            } else if (value == 'redistribuir') {
              _redistribuirTareasPendientes();
            } else if (value == 'reunion') {
              _navegarAReunion();
            } else if (value == 'info') {
              _scaffoldKey.currentState?.openDrawer();
            } else if (value == 'diagnostico') {
              _mostrarDiagnosticoTareas();
            } else if (value == 'limpiar_filtros') {
              setState(() {
                filtroResponsable = null;
                filtroPrioridad = null;
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'asignar_ia',
              child: Row(
                children: [
                  Icon(Icons.psychology, color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 12),
                  Text('Asignación Automática'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'redistribuir',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('Redistribuir Tareas'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reunion',
              child: Row(
                children: [
                  Icon(Icons.video_call, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('Reunión Presencial'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white54, size: 20),
                  SizedBox(width: 12),
                  Text('Info del Proyecto'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            // Filtros inline
            ..._buildFiltroResponsables(),
            if (nombreResponsables.isNotEmpty) const PopupMenuDivider(),
            ..._buildFiltroPrioridad(),
            if (filtroResponsable != null || filtroPrioridad != null) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'limpiar_filtros',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Limpiar Filtros'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(participantes.length > 1 ? 96 : 96),
        child: Column(
          children: [
            // Avatares de participantes (si hay más de 1)
            if (participantes.length > 1)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Avatares apilados
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: participantes.take(8).map((p) {
                            final nombre = p['nombre'] ?? '?';
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Tooltip(
                                message: nombre,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: _colorDesdeUID(p['uid']!),
                                  child: Text(
                                    nombre[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (participantes.length > 8)
                      Text(
                        '+${participantes.length - 8}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    // Barra de búsqueda compacta
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 160,
                      height: 32,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 16),
                          prefixIconConstraints: const BoxConstraints(minWidth: 32),
                          suffixIcon: searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => searchQuery = '');
                                  },
                                  child: const Icon(Icons.clear, color: Colors.white38, size: 14),
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(minWidth: 28),
                          filled: true,
                          fillColor: const Color(0xFF1A1F3A),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        onChanged: (value) => setState(() => searchQuery = value),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Sin participantes múltiples: barra de búsqueda completa
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                height: 44,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar tareas...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 18),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1A1F3A),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: [
                const Tab(icon: Icon(Icons.view_kanban, size: 18), text: 'Kanban'),
                const Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Timeline'),
                Tab(icon: Icon(esPMI ? Icons.account_tree : Icons.bar_chart, size: 18), text: esPMI ? 'PMI' : 'Stats'),
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
        esPMI
          ? PMITreeView(
              tareas: tareasFiltradas,
              onTareaTapped: _mostrarDetalleTarea,
              onCheckboxChanged: _onCheckboxChanged,
              nombreResponsables: nombreResponsables,
              userId: _auth.currentUser!.uid,
            )
          : PersonalStatsView(tareas: tareasFiltradas),
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

  /// Panel lateral derecho con Inventario y Recursos
  Widget _buildEndDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Drawer(
        backgroundColor: const Color(0xFF0A0E27),
        child: SafeArea(
          child: DefaultTabController(
            length: 5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder_special, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Recursos del Proyecto',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  indicatorColor: const Color(0xFF8B5CF6),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF8B5CF6),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: const [
                    Tab(icon: Icon(Icons.calendar_month, size: 16), text: 'Calendario'),
                    Tab(icon: Icon(Icons.inventory_2, size: 16), text: 'Inventario'),
                    Tab(icon: Icon(Icons.menu_book, size: 16), text: 'Recursos'),
                    Tab(icon: Icon(Icons.folder_copy, size: 16), text: 'Informes'),
                    Tab(icon: Icon(Icons.email, size: 16), text: 'Correos'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      CalendarioProyectoView(proyectoId: widget.proyectoId),
                      InventarioView(proyectoId: widget.proyectoId),
                      RepositorioConocimientoView(proyectoId: widget.proyectoId),
                      InformesView(proyectoId: widget.proyectoId),
                      CorreosView(proyectoId: widget.proyectoId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: "nuevaTareaKanban",
      backgroundColor: const Color(0xFF8B5CF6),
      label: const Text("Nueva tarea", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      icon: const Icon(Icons.add, color: Colors.white, size: 18),
      onPressed: _crearNuevaTarea,
      elevation: 4,
    );
  }

  // ========================================
  //  ACCIONES
  // ========================================

  Future<void> _moverTarea(Tarea tarea, String nuevoEstado) async {
    bool nuevoCompletado = nuevoEstado == 'completada';

    // Crear tarea actualizada
    final tareaActualizada = Tarea(
      titulo: tarea.titulo,
      fecha: tarea.fecha,
      duracion: tarea.duracion,
      prioridad: tarea.prioridad,
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
      fechaLimite: tarea.fechaLimite,
      fechaProgramada: tarea.fechaProgramada,
      fechaCompletada: nuevoCompletado ? (tarea.fechaCompletada ?? DateTime.now()) : null,
      googleCalendarEventId: tarea.googleCalendarEventId,
      estado: nuevoEstado,
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
      final resultado = await _redistribucionService.redistribuirTareas(
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

  /// Abrir asistente conversacional del proyecto
  void _abrirAsistenteProyecto() async {
    try {
      // DIAGNÓSTICO: Verificar tareas antes de abrir el asistente
      print('🔍 [DEBUG] Verificando tareas del proyecto ${widget.proyectoId}');
      final tareasSnapshot = await _firestore
          .collection('proyectos')
          .doc(widget.proyectoId)
          .collection('tareas')
          .get();

      print('🔍 [DEBUG] Tareas encontradas en Firestore: ${tareasSnapshot.docs.length}');
      for (var doc in tareasSnapshot.docs.take(5)) {
        print('🔍 [DEBUG] - Tarea: ${doc.data()['titulo']} (ID: ${doc.id})');
      }
      print('🔍 [DEBUG] todasLasTareas en memoria: ${todasLasTareas.length}');

      // Obtener nombre del proyecto
      final proyectoDoc = await _firestore.collection('proyectos').doc(widget.proyectoId).get();
      final proyectoNombre = proyectoDoc.data()?['nombre'] ?? 'Proyecto';

      if (!mounted) return;

      // Abrir modal con el asistente
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => ProyectoAsistenteChatWidget(
          proyectoId: widget.proyectoId,
          proyectoNombre: proyectoNombre,
          modoPanel: false, // Modo modal
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error abriendo asistente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostrar diagnóstico de tareas
  void _mostrarDiagnosticoTareas() async {
    try {
      // Consultar directamente Firestore
      final tareasSnapshot = await _firestore
          .collection('proyectos')
          .doc(widget.proyectoId)
          .collection('tareas')
          .get();

      final mensaje = StringBuffer();
      mensaje.writeln('📊 DIAGNÓSTICO DE TAREAS\n');
      mensaje.writeln('Proyecto ID: ${widget.proyectoId}\n');
      mensaje.writeln('Tareas en Firestore: ${tareasSnapshot.docs.length}');
      mensaje.writeln('Tareas en memoria: ${todasLasTareas.length}\n');

      if (tareasSnapshot.docs.isEmpty) {
        mensaje.writeln('⚠️ No hay tareas en Firestore para este proyecto.');
        mensaje.writeln('\nVerifica en Firebase Console:');
        mensaje.writeln('proyectos/${widget.proyectoId}/tareas');
      } else {
        mensaje.writeln('\n📋 Primeras 10 tareas en Firestore:');
        for (var doc in tareasSnapshot.docs.take(10)) {
          final data = doc.data();
          mensaje.writeln('- ${data['titulo'] ?? 'Sin título'} (${doc.id})');
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0D1229),
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8),
              Text('Diagnóstico', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              mensaje.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en diagnóstico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navegar a reunión presencial
  void _navegarAReunion() async {
    try {
      // Obtener proyecto completo
      final proyectoDoc = await _firestore.collection('proyectos').doc(widget.proyectoId).get();
      if (!proyectoDoc.exists || !mounted) return;

      final proyecto = Proyecto.fromFirestore(proyectoDoc);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReunionPresencialPage(proyecto: proyecto),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Buscar usuarios por nombre o email (busca en múltiples campos)
  Future<List<Map<String, String>>> _buscarUsuarios(String query) async {
    if (query.trim().length < 2) return [];
    final queryLower = query.trim().toLowerCase();
    final uidsActuales = participantes.map((p) => p['uid']).toSet();

    final resultados = <Map<String, String>>[];
    final idsAgregados = <String>{};

    // Estrategia 1: Firestore range query por full_name (más eficiente)
    try {
      final queryUpper = queryLower.substring(0, queryLower.length - 1) +
          String.fromCharCode(queryLower.codeUnitAt(queryLower.length - 1) + 1);
      final snapshotNombre = await _firestore
          .collection("users")
          .where('full_name', isGreaterThanOrEqualTo: query.trim())
          .where('full_name', isLessThan: queryUpper)
          .limit(10)
          .get();

      for (var doc in snapshotNombre.docs) {
        if (uidsActuales.contains(doc.id) || idsAgregados.contains(doc.id)) continue;
        final data = doc.data();
        final nombre = data['full_name']?.toString() ?? data['email']?.toString() ?? 'Usuario';
        resultados.add({'uid': doc.id, 'nombre': nombre, 'email': data['email']?.toString() ?? ''});
        idsAgregados.add(doc.id);
      }
    } catch (_) {}

    // Estrategia 2: carga local y filtra (fallback amplio)
    final snapshot = await _firestore.collection("users").limit(300).get();
    debugPrint('🔍 Total usuarios en Firestore: ${snapshot.docs.length}, query: "$queryLower"');

    for (var doc in snapshot.docs) {
      if (uidsActuales.contains(doc.id) || idsAgregados.contains(doc.id)) continue;
      final data = doc.data();

      // Buscar en todos los campos posibles
      final fullName = (data['full_name'] ?? '').toString().toLowerCase();
      final displayName = (data['displayName'] ?? '').toString().toLowerCase();
      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final uid = doc.id.toLowerCase();

      final matchesQuery = fullName.contains(queryLower) ||
          displayName.contains(queryLower) ||
          nombre.contains(queryLower) ||
          name.contains(queryLower) ||
          email.contains(queryLower) ||
          uid.contains(queryLower);

      if (matchesQuery) {
        final nombreMostrar = _resolverNombreUsuario(data);
        resultados.add({
          'uid': doc.id,
          'nombre': nombreMostrar,
          'email': data['email']?.toString() ?? '',
        });
        idsAgregados.add(doc.id);
        debugPrint('✅ Usuario encontrado: $nombreMostrar (${data['email']})');
      }
    }

    debugPrint('🔍 Resultados totales: ${resultados.length}');
    return resultados;
  }

  /// Resolver el mejor nombre disponible de un usuario
  String _resolverNombreUsuario(Map<String, dynamic> data) {
    final candidatos = [
      data['full_name']?.toString(),
      data['displayName']?.toString(),
      data['nombre']?.toString(),
      data['name']?.toString(),
      data['email']?.toString(),
    ];
    for (final c in candidatos) {
      if (c != null && c.isNotEmpty && c != 'No name') return c;
    }
    return 'Usuario';
  }

  /// Agregar participante por UID
  Future<void> _agregarParticipantePorUID(String uid) async {
    try {
      await _firestore.collection("proyectos").doc(widget.proyectoId).update({
        "participantes": FieldValue.arrayUnion([uid])
      });

      await _cargarParticipantes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Participante agregado exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al agregar participante: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Eliminar participante del proyecto
  Future<void> _eliminarParticipante(String uid) async {
    try {
      await _firestore.collection("proyectos").doc(widget.proyectoId).update({
        "participantes": FieldValue.arrayRemove([uid])
      });

      await _cargarParticipantes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Participante eliminado"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar participante: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mostrar diálogo de gestión de participantes
  void _mostrarGestionParticipantes() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController searchController = TextEditingController();
        List<Map<String, String>> resultadosBusqueda = [];
        bool buscando = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D1229),
              title: const Row(
                children: [
                  Icon(Icons.group, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 12),
                  Text(
                    'Gestionar Participantes',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buscar por nombre o email
                    Text(
                      'Agregar Participante',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o email...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                        suffixIcon: buscando
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) async {
                        if (value.trim().length < 2) {
                          setDialogState(() => resultadosBusqueda = []);
                          return;
                        }
                        setDialogState(() => buscando = true);
                        final resultados = await _buscarUsuarios(value);
                        setDialogState(() {
                          resultadosBusqueda = resultados;
                          buscando = false;
                        });
                      },
                    ),

                    // Resultados de búsqueda
                    if (resultadosBusqueda.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: resultadosBusqueda.length,
                          itemBuilder: (context, index) {
                            final r = resultadosBusqueda[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                                child: Text(
                                  (r['nombre'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(r['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              subtitle: Text(r['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                              trailing: const Icon(Icons.person_add, color: Color(0xFF10B981), size: 20),
                              onTap: () async {
                                // Agregar sin cerrar el dialog - actualizar en vivo
                                setDialogState(() {
                                  resultadosBusqueda.removeWhere((u) => u['uid'] == r['uid']);
                                });
                                await _agregarParticipantePorUID(r['uid']!);
                                if (mounted) setDialogState(() {
                                  searchController.clear();
                                  resultadosBusqueda = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    if (searchController.text.trim().length >= 2 && resultadosBusqueda.isEmpty && !buscando) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white38, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'No se encontraron usuarios con ese nombre o email. El usuario debe estar registrado en la app.',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    // Lista de participantes actuales
                    Text(
                      'Participantes Actuales (${participantes.length})',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: participantes.isEmpty
                          ? Center(
                              child: Text(
                                'No hay participantes',
                                style: TextStyle(color: Colors.white.withOpacity(0.4)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: participantes.length,
                              itemBuilder: (context, index) {
                                final p = participantes[index];
                                final uid = p["uid"]!;
                                final nombre = p["nombre"] ?? "Usuario";
                                final email = p["email"] ?? "";
                                final esCreador = uid == _auth.currentUser?.uid;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _colorDesdeUID(uid),
                                      child: Text(
                                        nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      nombre,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      email,
                                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                    ),
                                    trailing: esCreador
                                        ? const Chip(
                                            label: Text(
                                              'Tú',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            backgroundColor: Color(0xFF10B981),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              final confirmar = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  backgroundColor: const Color(0xFF0D1229),
                                                  title: const Text(
                                                    '¿Eliminar participante?',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                  content: Text(
                                                    '¿Estás seguro de eliminar a $nombre del proyecto?',
                                                    style: const TextStyle(color: Colors.white70),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red,
                                                      ),
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: const Text('Eliminar'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmar == true && mounted) {
                                                await _eliminarParticipante(uid);
                                                if (mounted) setDialogState(() {});
                                              }
                                            },
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
