import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Página principal del generador de informes
// ─────────────────────────────────────────────────────────────────────────────
class GeneradorInformeWidget extends StatefulWidget {
  final Proyecto proyecto;
  final String? resumenIA;          // Si viene de una reunión
  final String? textoContexto;      // Texto adicional (actas, notas)

  const GeneradorInformeWidget({
    super.key,
    required this.proyecto,
    this.resumenIA,
    this.textoContexto,
  });

  @override
  State<GeneradorInformeWidget> createState() => _GeneradorInformeWidgetState();
}

class _GeneradorInformeWidgetState extends State<GeneradorInformeWidget> {
  final _firestore = FirebaseFirestore.instance;

  bool _cargando = true;
  bool _generandoPDF = false;
  bool _refinandoIA = false;
  bool _generandoTodo = false;

  // Datos del proyecto (cargados de Firestore)
  String _proyectoNombre = '';
  String _proyectoDescripcion = '';
  String _proyectoCategoria = '';
  String? _proyectoImagenUrl;
  List<Map<String, dynamic>> _tareas = [];
  List<Map<String, String>> _participantes = [];
  int _tareasCompletadas = 0;
  int _tareasPendientes = 0;
  int _tareasEnProgreso = 0;
  int _tareasAltaPrioridad = 0;
  int _tareasBajaPrioridad = 0;
  int _tareasMediaPrioridad = 0;

  // Secciones del informe (editables)
  final _ctrlResumen       = TextEditingController();
  final _ctrlConclusiones  = TextEditingController();
  final _ctrlProximosPasos = TextEditingController();

  static const _bg     = Color(0xFF0A0E27);
  static const _card   = Color(0xFF111827);
  static const _purple = Color(0xFF8B5CF6);
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _ctrlResumen.text = widget.resumenIA ?? '';
    // Inicializar datos básicos del modelo recibido (pueden estar vacíos)
    _proyectoNombre      = widget.proyecto.nombre;
    _proyectoDescripcion = widget.proyecto.descripcion;
    _proyectoCategoria   = widget.proyecto.categoria;
    _proyectoImagenUrl   = widget.proyecto.imagenUrl;
    _cargarDatos();
  }

  @override
  void dispose() {
    _ctrlResumen.dispose();
    _ctrlConclusiones.dispose();
    _ctrlProximosPasos.dispose();
    super.dispose();
  }

  // ── Carga de datos del proyecto ───────────────────────────────────────────
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    // Cargar documento del proyecto (para nombre/descripción completos)
    try {
      final proyDoc = await _firestore
          .collection('proyectos')
          .doc(widget.proyecto.id)
          .get();
      if (proyDoc.exists) {
        final d = proyDoc.data()!;
        _proyectoNombre      = d['nombre'] ?? _proyectoNombre;
        _proyectoDescripcion = d['descripcion'] ?? _proyectoDescripcion;
        _proyectoCategoria   = d['categoria'] ?? _proyectoCategoria;
        _proyectoImagenUrl   = d['imagenUrl'] ?? _proyectoImagenUrl;
      }
    } catch (_) {}

    // Tareas desde subcolección
    final tareasSnap = await _firestore
        .collection('proyectos')
        .doc(widget.proyecto.id)
        .collection('tareas')
        .get();

    final tareas = tareasSnap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList();

    // Participantes: leer desde el documento del proyecto (más confiable)
    final participantes = <Map<String, String>>[];
    try {
      final proyDoc2 = await _firestore
          .collection('proyectos')
          .doc(widget.proyecto.id)
          .get();
      final uids = List<String>.from(proyDoc2.data()?['participantes'] ?? []);
      for (final uid in uids) {
        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          if (doc.exists) {
            final d = doc.data()!;
            participantes.add({
              'uid'   : uid,
              'nombre': d['full_name'] ?? d['nombre'] ?? d['displayName'] ?? 'Usuario',
              'email' : d['email'] ?? '',
            });
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback: si no se cargaron, intentar con widget.proyecto.participantes
    if (participantes.isEmpty) {
      for (final uid in widget.proyecto.participantes) {
        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          if (doc.exists) {
            final d = doc.data()!;
            participantes.add({
              'uid'   : uid,
              'nombre': d['full_name'] ?? d['nombre'] ?? d['displayName'] ?? 'Usuario',
              'email' : d['email'] ?? '',
            });
          }
        } catch (_) {}
      }
    }

    final completadas  = tareas.where((t) => t['estado'] == 'completada').length;
    final enProgreso   = tareas.where((t) => t['estado'] == 'en_progreso').length;
    final pendientes   = tareas.where((t) =>
        t['estado'] != 'completada' && t['estado'] != 'en_progreso').length;

    int alta = 0, media = 0, baja = 0;
    for (final t in tareas) {
      final p = t['prioridad'];
      if (p is int) {
        if (p == 3) alta++;
        else if (p == 2) media++;
        else baja++;
      }
    }

    setState(() {
      _tareas                = tareas;
      _participantes         = participantes;
      _tareasCompletadas     = completadas;
      _tareasEnProgreso      = enProgreso;
      _tareasPendientes      = pendientes;
      _tareasAltaPrioridad   = alta;
      _tareasMediaPrioridad  = media;
      _tareasBajaPrioridad   = baja;
      _cargando              = false;
    });
  }

  // ── Construir contexto completo del proyecto para la IA ──────────────────
  String _construirContextoIA() {
    final avance = _tareas.isNotEmpty
        ? (_tareasCompletadas / _tareas.length * 100).round()
        : 0;
    return '''
Proyecto: $_proyectoNombre
Descripci\u00f3n: $_proyectoDescripcion
Estado: ${widget.proyecto.estado}
Categor\u00eda: $_proyectoCategoria
Avance: $avance%
Tareas totales: ${_tareas.length}
Tareas completadas: $_tareasCompletadas
Tareas en progreso: $_tareasEnProgreso
Tareas pendientes: $_tareasPendientes
Prioridad alta: $_tareasAltaPrioridad
Participantes (${_participantes.length}): ${_participantes.map((p) => p['nombre']).join(', ')}
Contexto adicional: ${widget.textoContexto ?? ''}
Resumen previo: ${_ctrlResumen.text}
''';
  }

  // ── Generar TODO con IA de una sola vez ──────────────────────────────────
  Future<void> _generarTodoConIA() async {
    setState(() => _generandoTodo = true);
    try {
      final contexto = _construirContextoIA();
      final callable = FirebaseFunctions.instance.httpsCallable('procesarReunion');

      // Lanzar 3 llamadas en paralelo
      final futures = await Future.wait([
        callable.call({
          'texto': 'Genera un RESUMEN EJECUTIVO profesional y conciso (3-5 párrafos) para el siguiente proyecto:\n$contexto',
          'modoInforme': true,
          'seccion': 'resumen_ejecutivo',
        }),
        callable.call({
          'texto': 'Genera las CONCLUSIONES del informe ejecutivo (puntos clave, logros, desafíos encontrados) para:\n$contexto',
          'modoInforme': true,
          'seccion': 'conclusiones',
        }),
        callable.call({
          'texto': 'Genera los PRÓXIMOS PASOS recomendados (lista de acciones concretas y priorizadas) para:\n$contexto',
          'modoInforme': true,
          'seccion': 'proximos_pasos',
        }),
      ]);

      final resumen     = futures[0].data?['resumen'] as String? ?? futures[0].data?['texto'] as String? ?? '';
      final conclusiones = futures[1].data?['resumen'] as String? ?? futures[1].data?['texto'] as String? ?? '';
      final proximos    = futures[2].data?['resumen'] as String? ?? futures[2].data?['texto'] as String? ?? '';

      setState(() {
        if (resumen.isNotEmpty)     _ctrlResumen.text      = resumen;
        if (conclusiones.isNotEmpty) _ctrlConclusiones.text = conclusiones;
        if (proximos.isNotEmpty)    _ctrlProximosPasos.text = proximos;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe generado con IA'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar con IA: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _generandoTodo = false);
    }
  }

  // ── Refinar sección con IA ────────────────────────────────────────────────
  Future<void> _refinarConIA(String seccion) async {
    setState(() => _refinandoIA = true);
    try {
      final contexto = _construirContextoIA();
      final callable = FirebaseFunctions.instance.httpsCallable('procesarReunion');
      final result = await callable.call({
        'texto': 'Genera la secci\u00f3n "$seccion" de un informe ejecutivo profesional basado en este contexto:\n$contexto',
        'modoInforme': true,
        'seccion': seccion,
      });

      final texto = result.data?['resumen'] as String? ??
          result.data?['texto'] as String? ?? '';

      if (texto.isNotEmpty) {
        setState(() {
          if (seccion == 'conclusiones') {
            _ctrlConclusiones.text = texto;
          } else if (seccion == 'proximos_pasos') {
            _ctrlProximosPasos.text = texto;
          } else {
            _ctrlResumen.text = texto;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al refinar con IA: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _refinandoIA = false);
    }
  }

  // ── Generación del PDF ────────────────────────────────────────────────────
  Future<void> _generarYVerPDF() async {
    setState(() => _generandoPDF = true);
    try {
      final pdfBytes = await _construirPDF();
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(pdfBytes),
        name: 'Informe_${_proyectoNombre.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _generandoPDF = false);
    }
  }

  // ── Construcción interna del PDF ──────────────────────────────────────────
  Future<List<int>> _construirPDF() async {
    final pdf = pw.Document();

    // Cargar fuentes
    pw.Font font;
    pw.Font fontBold;
    try {
      final fontData     = await rootBundle.load('assets/fonts/Montserrat-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Montserrat-Bold.ttf');
      font     = pw.Font.ttf(fontData);
      fontBold = pw.Font.ttf(fontBoldData);
    } catch (_) {
      font     = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // Logo de Vastoria (marca de agua / footer)
    pw.ImageProvider? logoVastoria;
    try {
      final logoBytes = await rootBundle.load('assets/logovastoria.png');
      logoVastoria = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // Logo del proyecto (si tiene imagenUrl)
    pw.ImageProvider? logoProyecto;
    final imgUrl = _proyectoImagenUrl;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imgUrl));
        if (response.statusCode == 200) {
          logoProyecto = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // Paleta de colores PDF
    const pdfPurple = PdfColor.fromInt(0xFF8B5CF6);
    const pdfDark   = PdfColor.fromInt(0xFF1E293B);
    const pdfGreen  = PdfColor.fromInt(0xFF10B981);
    const pdfAmber  = PdfColor.fromInt(0xFFF59E0B);
    const pdfRed    = PdfColor.fromInt(0xFFEF4444);
    const pdfBlue   = PdfColor.fromInt(0xFF3B82F6);

    final fechaHoy    = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final totalTareas = _tareas.length;
    final avance = totalTareas > 0
        ? (_tareasCompletadas / totalTareas * 100).round()
        : 0;

    // ── PÁGINA 1: PORTADA ─────────────────────────────────────────────────
    // Fondo completamente oscuro para que escale con cualquier cantidad de miembros.
    // Se usa pw.MultiPage para que el contenido no quede cortado.
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        return pw.Container(
          color: pdfDark,
          child: pw.Stack(children: [
            // Acento violeta lateral (página completa)
            pw.Positioned(
              top: 0, left: 0, bottom: 0,
              child: pw.Container(width: 6, color: pdfPurple),
            ),

            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(48, 40, 48, 40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Header: fecha arriba derecha ───────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                        pw.Text('INFORME EJECUTIVO',
                            style: pw.TextStyle(font: fontBold, fontSize: 8,
                                color: PdfColors.grey400, letterSpacing: 2)),
                        pw.SizedBox(height: 4),
                        pw.Text(fechaHoy,
                            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey300)),
                      ]),
                    ],
                  ),

                  pw.SizedBox(height: 24),

                  // ── Logo centrado y grande ─────────────────────────────
                  pw.Center(
                    child: logoProyecto != null
                        ? pw.Container(
                            width: 160, height: 160,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Image(logoProyecto, fit: pw.BoxFit.contain),
                          )
                        : pw.Container(
                            width: 160, height: 160,
                            decoration: pw.BoxDecoration(
                              color: pdfPurple,
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                _proyectoNombre.isNotEmpty ? _proyectoNombre[0].toUpperCase() : 'P',
                                style: pw.TextStyle(font: fontBold, fontSize: 72, color: PdfColors.white),
                              ),
                            ),
                          ),
                  ),

                  pw.SizedBox(height: 28),

                  // ── Badge + título ─────────────────────────────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: pdfPurple,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text('VASTORIA FLOW',
                        style: pw.TextStyle(font: fontBold, fontSize: 8,
                            color: PdfColors.white, letterSpacing: 2)),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(_proyectoNombre,
                      style: pw.TextStyle(font: fontBold, fontSize: 26, color: PdfColors.white),
                      maxLines: 2),
                  pw.SizedBox(height: 8),
                  pw.Text(_proyectoDescripcion,
                      style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey300),
                      maxLines: 3),

                  pw.SizedBox(height: 28),
                  pw.Container(height: 1, color: PdfColors.grey700),
                  pw.SizedBox(height: 22),

                  // ── Stats ──────────────────────────────────────────────
                  pw.Row(children: [
                    _statBox(font, fontBold, '$totalTareas', 'Tareas\ntotales', pdfPurple),
                    pw.SizedBox(width: 12),
                    _statBox(font, fontBold, '$_tareasCompletadas', 'Comple-\ntadas', pdfGreen),
                    pw.SizedBox(width: 12),
                    _statBox(font, fontBold, '$avance%', 'Avance\ngeneral', pdfAmber),
                    pw.SizedBox(width: 12),
                    _statBox(font, fontBold, '${_participantes.length}', 'Miem-\nbros', pdfBlue),
                  ]),

                  pw.SizedBox(height: 22),
                  pw.Container(height: 1, color: PdfColors.grey700),
                  pw.SizedBox(height: 16),

                  // ── Equipo — grid 2 columnas ───────────────────────────
                  pw.Text('Equipo del proyecto',
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey500)),
                  pw.SizedBox(height: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: () {
                      pw.Widget memberCell(Map<String, String> p) {
                        final nombre = p['nombre'] ?? '';
                        final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
                        return pw.Row(children: [
                          pw.Container(
                            width: 24, height: 24,
                            decoration: const pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFF8B5CF6),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(inicial,
                                  style: pw.TextStyle(font: fontBold, fontSize: 9,
                                      color: PdfColors.white)),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(nombre,
                              style: pw.TextStyle(font: font, fontSize: 9,
                                  color: PdfColors.grey200)),
                        ]);
                      }

                      final rows = <pw.Widget>[];
                      for (int i = 0; i < _participantes.length; i += 2) {
                        final a = _participantes[i];
                        final b = i + 1 < _participantes.length ? _participantes[i + 1] : null;
                        rows.add(pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(children: [
                            pw.Expanded(child: memberCell(a)),
                            if (b != null) pw.Expanded(child: memberCell(b)),
                          ]),
                        ));
                      }
                      return rows;
                    }(),
                  ),

                  pw.SizedBox(height: 20),
                  pw.Container(height: 1, color: PdfColors.grey700),
                  pw.SizedBox(height: 16),

                  // ── Branding integrado al pie ──────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (logoVastoria != null)
                        pw.Image(logoVastoria, width: 18, height: 18),
                      pw.SizedBox(width: 8),
                      pw.RichText(text: pw.TextSpan(children: [
                        pw.TextSpan(text: 'Generado con ',
                            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
                        pw.TextSpan(text: 'Vastoria Flow',
                            style: pw.TextStyle(font: fontBold, fontSize: 8, color: pdfPurple)),
                        pw.TextSpan(text: '  ·  Gestión inteligente de proyectos',
                            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        );
      },
    ));

    // ── Mapa uid→nombre para resolver responsables en tablas ────────────
    final Map<String, String> uidNombre = {
      for (final p in _participantes) p['uid']!: p['nombre'] ?? 'Usuario',
    };

    // ── Agrupar tareas con fecha por semana ISO ──────────────────────────
    final Map<DateTime, List<Map<String, dynamic>>> porSemanaMap = {};
    final List<Map<String, dynamic>> sinFecha = [];
    DateTime? fechaMin, fechaMax;

    for (final t in _tareas) {
      final dt = _getFechaLimiteTarea(t);
      if (dt != null) {
        final lun = dt.subtract(Duration(days: dt.weekday - 1));
        final lunSolo = DateTime(lun.year, lun.month, lun.day);
        porSemanaMap.putIfAbsent(lunSolo, () => []).add(t);
        if (fechaMin == null || lunSolo.isBefore(fechaMin)) fechaMin = lunSolo;
        if (fechaMax == null || lunSolo.isAfter(fechaMax)) fechaMax = lunSolo;
      } else {
        sinFecha.add(t);
      }
    }
    final semanas = porSemanaMap.keys.toList()..sort();

    // ── PÁGINAS 2+: Contenido completo en MultiPage ──────────────────────
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      header: (ctx) => pw.Column(children: [
        _pageHeader(font, fontBold, _proyectoNombre, 'Informe Ejecutivo', fechaHoy, pdfPurple),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300, height: 1),
        pw.SizedBox(height: 8),
      ]),
      footer: (ctx) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey300, height: 1),
        pw.SizedBox(height: 4),
        _pageFooter(font, ctx.pageNumber, logoVastoria),
      ]),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        // Helper local para nombre de responsable
        String resolverNombre(dynamic uid) {
          if (uid == null) return '--';
          final s = uid.toString();
          final nombre = uidNombre[s];
          if (nombre != null) return nombre.length > 18 ? '${nombre.substring(0, 16)}...' : nombre;
          return s.length > 14 ? '${s.substring(0, 12)}...' : s;
        }

        // ── 1. Resumen Ejecutivo ─────────────────────────────────────────
        widgets.add(_sectionTitle(fontBold, '1. Resumen Ejecutivo', pdfPurple));
        widgets.add(pw.SizedBox(height: 10));
        if (_ctrlResumen.text.isNotEmpty) {
          widgets.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(width: 3, color: pdfPurple),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Text(
                _ctrlResumen.text,
                style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 5),
              ),
            ),
          ]));
        } else {
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: PdfColors.grey100,
            child: pw.Text('Sin resumen ejecutivo. Use "Generar con IA" para auto-completar.',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500)),
          ));
        }
        widgets.add(pw.SizedBox(height: 20));

        // ── 2. Estado del Proyecto ────────────────────────────────────────
        widgets.add(_sectionTitle(fontBold, '2. Estado del Proyecto', pdfPurple));
        widgets.add(pw.SizedBox(height: 12));
        widgets.add(_buildProgressSection(font, fontBold, avance, pdfPurple, pdfGreen, pdfAmber, pdfRed));
        widgets.add(pw.SizedBox(height: 20));

        // ── 3. Distribución de Tareas (gráficos) ─────────────────────────
        if (totalTareas > 0) {
          widgets.add(_sectionTitle(fontBold, '3. Distribuci\u00f3n de Tareas', pdfPurple));
          widgets.add(pw.SizedBox(height: 12));

          // ── Distribución: círculo de progreso (CSS-like) + barras por prioridad
          // Reemplaza CustomPaint (problemático en pdf) con widgets puros.
          // El "donut" se construye como un círculo exterior + círculo blanco interior
          // coloreados con un gradiente apilado de segmentos usando Transform.rotate.
          widgets.add(pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Lado izquierdo: círculo estilizado + leyenda ─────────────
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Círculo con avance general: borde grueso de color
                  // Simulamos el donut con 3 contenedores anidados circulares
                  pw.Stack(children: [
                    // Fondo gris (total)
                    pw.Container(
                      width: 110, height: 110,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    // Segmento completadas (verde) — sector proporcional simulado con
                    // un contenedor circular de color + clip para la fracción visible.
                    // Usamos un rectángulo coloreado girado como sector aproximado.
                    // Para simplicidad: borde grueso circular partido por color.
                    // Construimos un "pie" con 3 capas de Transform.rotate + ClipRect.
                    if (_tareasCompletadas > 0)
                      pw.Transform.rotate(
                        angle: 0,
                        child: pw.Container(
                          width: 110, height: 110,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(
                              color: pdfGreen,
                              width: 18 * (_tareasCompletadas / totalTareas),
                            ),
                          ),
                        ),
                      ),
                    if (_tareasEnProgreso > 0)
                      pw.Container(
                        width: 110, height: 110,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: pdfAmber,
                            width: 18 * (_tareasEnProgreso / totalTareas),
                          ),
                        ),
                      ),
                    // Círculo interior blanco (agujero)
                    pw.Positioned(
                      left: 20, top: 20,
                      child: pw.Container(
                        width: 70, height: 70,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text('$avance%',
                              style: pw.TextStyle(font: fontBold, fontSize: 15,
                                  color: pdfPurple)),
                        ),
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Text('Por estado',
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 6),
                  _chartLegend(font, [
                    _ChartSegment(_tareasCompletadas.toDouble(), pdfGreen,
                        'Completadas: $_tareasCompletadas'),
                    _ChartSegment(_tareasEnProgreso.toDouble(), pdfAmber,
                        'En progreso: $_tareasEnProgreso'),
                    _ChartSegment(_tareasPendientes.toDouble(), pdfRed,
                        'Pendientes: $_tareasPendientes'),
                  ]),
                ],
              ),
              pw.SizedBox(width: 28),
              // ── Lado derecho: barras por prioridad ───────────────────────
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Por prioridad',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 10),
                    _buildBarChart(font, fontBold, [
                      _BarData('Alta',  _tareasAltaPrioridad,  pdfRed),
                      _BarData('Media', _tareasMediaPrioridad, pdfAmber),
                      _BarData('Baja',  _tareasBajaPrioridad,  pdfGreen),
                    ], totalTareas),
                  ],
                ),
              ),
            ],
          ));
          widgets.add(pw.SizedBox(height: 24));
        }

        // ── 4. Registro completo de tareas ───────────────────────────────
        if (_tareas.isNotEmpty) {
          widgets.add(_sectionTitle(fontBold, '4. Registro de Tareas', pdfPurple));
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.TableHelper.fromTextArray(
            headers: ['#', 'Tarea', 'Estado', 'Prioridad', 'Responsable', 'Fecha l\u00edmite'],
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: pdfDark),
            cellStyle: pw.TextStyle(font: font, fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(20),
              2: const pw.FixedColumnWidth(60),
              3: const pw.FixedColumnWidth(44),
              5: const pw.FixedColumnWidth(54),
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            data: _tareas.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final est  = t['estado'] as String? ?? 'pendiente';
              final prio = t['prioridad'];
              final dtFecha = _getFechaLimiteTarea(t);
              final fecha = dtFecha != null ? DateFormat('dd/MM/yy').format(dtFecha) : '--';
              final prioLabel = prio is int
                  ? (prio == 3 ? 'Alta' : prio == 2 ? 'Media' : 'Baja') : '--';
              // Responsable: resuelve nombre desde uidNombre
              final resps = t['responsables'];
              String responsable = '--';
              if (resps is List && resps.isNotEmpty) {
                responsable = resolverNombre(resps.first);
              }
              final titulo = t['titulo'] as String? ?? 'Sin t\u00edtulo';
              return [
                '${i + 1}',
                titulo.length > 38 ? '${titulo.substring(0, 36)}...' : titulo,
                _estadoLabel(est),
                prioLabel,
                responsable,
                fecha,
              ];
            }).toList(),
          ));
          widgets.add(pw.SizedBox(height: 24));
        }

        // ── 5. Cronograma tipo Gantt ─────────────────────────────────────
        if (semanas.isNotEmpty || sinFecha.isNotEmpty) {
          widgets.add(_sectionTitle(fontBold, '5. Cronograma por Semana (Gantt)', pdfPurple));
          widgets.add(pw.SizedBox(height: 14));

          int semIdx = 1;
          for (final semLun in semanas) {
            final tareasSem = porSemanaMap[semLun]!;
            final compSem = tareasSem.where((t) => t['estado'] == 'completada').length;
            final pctSem = (compSem / tareasSem.length * 100).round();
            final semLabel = '${DateFormat('dd/MM').format(semLun)} – ${DateFormat('dd/MM').format(semLun.add(const Duration(days: 6)))}';

            // Encabezado de sprint
            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: pdfDark,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sprint $semIdx  \u2022  $semLabel',
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
                  pw.Text('$compSem/${tareasSem.length} completadas  ($pctSem%)',
                      style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey300)),
                ],
              ),
            ));
            widgets.add(pw.SizedBox(height: 6));

            // Barras Gantt por tarea
            for (final t in tareasSem) {
              final estado = t['estado'] as String? ?? 'pendiente';
              final titulo = t['titulo'] as String? ?? 'Sin t\u00edtulo';
              final tituloCorto = titulo.length > 28 ? '${titulo.substring(0, 26)}...' : titulo;
              final barColor = estado == 'completada'
                  ? pdfGreen : estado == 'en_progreso' ? pdfAmber : pdfRed;

              widgets.add(pw.LayoutBuilder(builder: (ctx2, constraints) {
                final maxW = constraints?.maxWidth ?? 450.0;
                final labelW = 140.0;
                final barAreaW = maxW - labelW - 8;
                // La barra llena la semana; usa pct de avance dentro de esa tarea si existe
                final barW = estado == 'completada'
                    ? barAreaW
                    : estado == 'en_progreso'
                        ? barAreaW * 0.5
                        : barAreaW * 0.05;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(children: [
                    // Etiqueta
                    pw.SizedBox(
                      width: labelW,
                      child: pw.Text(tituloCorto,
                          style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
                    ),
                    pw.SizedBox(width: 8),
                    // Fondo gris (barra completa)
                    pw.Stack(children: [
                      pw.Container(
                        width: barAreaW, height: 12,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.Container(
                        width: barW > 0 ? barW : 3, height: 12,
                        decoration: pw.BoxDecoration(
                          color: barColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ]),
                  ]),
                );
              }));
            }

            widgets.add(pw.SizedBox(height: 14));
            semIdx++;
          }

          // Tareas sin fecha
          if (sinFecha.isNotEmpty) {
            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey500,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Text('Sin fecha asignada — ${sinFecha.length} tarea${sinFecha.length > 1 ? 's' : ''}',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
            ));
            widgets.add(pw.SizedBox(height: 6));
            for (final t in sinFecha) {
              final titulo = t['titulo'] as String? ?? 'Sin t\u00edtulo';
              final tituloCorto = titulo.length > 40 ? '${titulo.substring(0, 38)}...' : titulo;
              final estado = t['estado'] as String? ?? 'pendiente';
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(children: [
                  pw.Container(
                    width: 7, height: 7,
                    decoration: pw.BoxDecoration(
                      color: estado == 'completada' ? pdfGreen : PdfColors.grey400,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(tituloCorto,
                      style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                ]),
              ));
            }
            widgets.add(pw.SizedBox(height: 20));
          }
        }

        // ── 6. Conclusiones ───────────────────────────────────────────────
        if (_ctrlConclusiones.text.isNotEmpty) {
          widgets.add(_sectionTitle(fontBold, '6. Conclusiones', pdfPurple));
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Text(_ctrlConclusiones.text,
              style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 5)));
          widgets.add(pw.SizedBox(height: 24));
        }

        // ── 7. Próximos Pasos ─────────────────────────────────────────────
        if (_ctrlProximosPasos.text.isNotEmpty) {
          widgets.add(_sectionTitle(fontBold, '7. Pr\u00f3ximos Pasos', pdfPurple));
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Text(_ctrlProximosPasos.text,
              style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 5)));
          widgets.add(pw.SizedBox(height: 16));
        }

        return widgets;
      },
    ));

    return pdf.save();
  }

  // ── Helper: parsear fecha desde cualquier formato Firestore ──────────────
  // Maneja: Timestamp, String ISO, Map {_seconds, _nanoseconds}, null
  DateTime? _parseFechaRaw(dynamic valor) {
    if (valor == null) return null;
    if (valor is Timestamp) return valor.toDate();
    if (valor is String && valor.isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    if (valor is Map) {
      final sec = valor['_seconds'] ?? valor['seconds'];
      if (sec != null) {
        return DateTime.fromMillisecondsSinceEpoch((sec as int) * 1000);
      }
    }
    return null;
  }

  // Obtiene la mejor fecha de una tarea raw: fechaLimite → fecha (legacy)
  DateTime? _getFechaLimiteTarea(Map<String, dynamic> t) {
    return _parseFechaRaw(t['fechaLimite']) ?? _parseFechaRaw(t['fecha']);
  }

  // ── Helpers de construcción PDF ───────────────────────────────────────────

  pw.Widget _statBox(pw.Font font, pw.Font fontBold, String valor, String label, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(valor,
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pageHeader(pw.Font font, pw.Font fontBold,
      String proyecto, String titulo, String fecha, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(titulo,
              style: pw.TextStyle(font: fontBold, fontSize: 15, color: color)),
          pw.Text(proyecto,
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
        ]),
        pw.Text(fecha,
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500)),
      ],
    );
  }

  pw.Widget _pageFooter(pw.Font font, int pageNumber, pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(children: [
          if (logo != null) ...[
            pw.Image(logo, width: 12, height: 12),
            pw.SizedBox(width: 4),
          ],
          pw.Text('Generado con Vastoria Flow',
              style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey400)),
        ]),
        pw.Text('P\u00e1g. $pageNumber',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
      ],
    );
  }

  pw.Widget _sectionTitle(pw.Font fontBold, String texto, PdfColor color) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(texto,
          style: pw.TextStyle(font: fontBold, fontSize: 12, color: color)),
      pw.SizedBox(height: 4),
      pw.Container(height: 2, width: 36, color: color),
    ]);
  }

  pw.Widget _buildProgressSection(
      pw.Font font, pw.Font fontBold, int avance,
      PdfColor purple, PdfColor green, PdfColor amber, PdfColor red) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.LayoutBuilder(builder: (ctx, constraints) {
        final totalW = constraints?.maxWidth ?? 400.0;
        final fillW  = avance > 0 ? totalW * avance / 100 : 0.0;
        return pw.Stack(children: [
          pw.Container(
            height: 16,
            width: totalW,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
          ),
          if (avance > 0)
            pw.Container(
              height: 16,
              width: fillW,
              decoration: pw.BoxDecoration(
                color: avance >= 80 ? green : avance >= 50 ? amber : purple,
                borderRadius: pw.BorderRadius.circular(8),
              ),
            ),
        ]);
      }),
      pw.SizedBox(height: 6),
      pw.Text('$avance% completado',
          style: pw.TextStyle(font: fontBold, fontSize: 10,
              color: avance >= 80 ? green : purple)),
      pw.SizedBox(height: 12),
      pw.Row(children: [
        _estadoPill(font, fontBold, '$_tareasCompletadas', 'Completadas', green),
        pw.SizedBox(width: 8),
        _estadoPill(font, fontBold, '$_tareasEnProgreso', 'En progreso', amber),
        pw.SizedBox(width: 8),
        _estadoPill(font, fontBold, '$_tareasPendientes', 'Pendientes', red),
      ]),
    ]);
  }

  pw.Widget _estadoPill(pw.Font font, pw.Font fontBold, String n, String label, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        pw.Text(n, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.white)),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.white)),
      ]),
    );
  }

  pw.Widget _chartLegend(pw.Font font, List<_ChartSegment> segments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: segments.map((s) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(children: [
          pw.Container(width: 10, height: 10,
              decoration: pw.BoxDecoration(
                  color: s.color, borderRadius: pw.BorderRadius.circular(2))),
          pw.SizedBox(width: 5),
          pw.Text('${s.label}: ${s.value.toInt()}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
        ]),
      )).toList(),
    );
  }

  pw.Widget _buildBarChart(pw.Font font, pw.Font fontBold,
      List<_BarData> bars, int total) {
    final maxVal = bars.fold<int>(0, (m, b) => b.value > m ? b.value : m);
    if (maxVal == 0) {
      return pw.Text('Sin datos',
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey500));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: bars.map((bar) {
        final pct = bar.value / maxVal;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(bar.label,
                    style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                pw.Text('${bar.value}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: bar.color)),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.LayoutBuilder(builder: (ctx, constraints) {
              final maxW = constraints?.maxWidth ?? 200.0;
              return pw.Stack(children: [
                pw.Container(
                    height: 12, width: maxW,
                    decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(6))),
                if (pct > 0)
                  pw.Container(
                      height: 12, width: maxW * pct,
                      decoration: pw.BoxDecoration(
                          color: bar.color,
                          borderRadius: pw.BorderRadius.circular(6))),
              ]);
            }),
          ]),
        );
      }).toList(),
    );
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'completada':  return 'Completada';
      case 'en_progreso': return 'En progreso';
      default:            return 'Pendiente';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD UI
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(children: [
          Icon(Icons.description_outlined, color: Color(0xFF8B5CF6), size: 18),
          SizedBox(width: 10),
          Text('Generar Informe',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _purple.withValues(alpha: 0.3)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _generandoPDF
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _cargando ? null : _generarYVerPDF,
                    icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF8B5CF6), size: 18),
                    label: const Text('Ver PDF',
                        style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Resumen del proyecto ──────────────────────────────
                  _buildProjectSummaryCard(),
                  const SizedBox(height: 16),

                  // ── Botón: Generar todo con IA ────────────────────────
                  _buildGenerarTodoButton(),
                  const SizedBox(height: 16),

                  // ── Sección: Resumen ejecutivo ────────────────────────
                  _buildSeccionEditor(
                    titulo: 'Resumen Ejecutivo',
                    icono: Icons.summarize_outlined,
                    ctrl: _ctrlResumen,
                    hint: 'Escribe o pega el resumen ejecutivo del proyecto...',
                    seccionIA: 'resumen_ejecutivo',
                  ),
                  const SizedBox(height: 12),

                  // ── Sección: Conclusiones ─────────────────────────────
                  _buildSeccionEditor(
                    titulo: 'Conclusiones',
                    icono: Icons.lightbulb_outline,
                    ctrl: _ctrlConclusiones,
                    hint: 'Escribe las conclusiones del proyecto o genera con IA...',
                    seccionIA: 'conclusiones',
                  ),
                  const SizedBox(height: 12),

                  // ── Sección: Próximos pasos ───────────────────────────
                  _buildSeccionEditor(
                    titulo: 'Pr\u00f3ximos Pasos',
                    icono: Icons.arrow_forward_outlined,
                    ctrl: _ctrlProximosPasos,
                    hint: 'Describe los pr\u00f3ximos pasos o genera con IA...',
                    seccionIA: 'proximos_pasos',
                  ),
                  const SizedBox(height: 24),

                  // ── Botón principal ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generandoPDF ? null : _generarYVerPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(_generandoPDF ? 'Generando...' : 'Generar y ver PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildGenerarTodoButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (_generandoTodo || _cargando) ? null : _generarTodoConIA,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                if (_generandoTodo)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _generandoTodo
                            ? 'Generando informe con IA...'
                            : 'Generar todo con IA',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-completa resumen, conclusiones y próximos pasos basado en el estado actual del proyecto',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSummaryCard() {
    final avance = _tareas.isNotEmpty
        ? (_tareasCompletadas / _tareas.length * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                image: _proyectoImagenUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_proyectoImagenUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: _proyectoImagenUrl == null
                  ? Center(child: Text(
                      _proyectoNombre.isNotEmpty
                          ? _proyectoNombre[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_proyectoNombre,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(_proyectoCategoria,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withValues(alpha: 0.4)),
              ),
              child: Text('$avance%',
                  style: const TextStyle(
                      color: _green, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _tareas.isNotEmpty ? _tareasCompletadas / _tareas.length : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                avance >= 80 ? _green : avance >= 50 ? _amber : _purple,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Stats chips
          Wrap(spacing: 8, runSpacing: 6, children: [
            _statChip('$_tareasCompletadas', 'completadas', _green),
            _statChip('$_tareasEnProgreso', 'en progreso', _amber),
            _statChip('$_tareasPendientes', 'pendientes', Colors.grey),
            _statChip('$_tareasAltaPrioridad', 'prioridad alta', const Color(0xFFEF4444)),
          ]),
        ],
      ),
    );
  }

  Widget _statChip(String n, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$n $label',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSeccionEditor({
    required String titulo,
    required IconData icono,
    required TextEditingController ctrl,
    required String hint,
    required String seccionIA,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: _purple, size: 18),
            const SizedBox(width: 8),
            Text(titulo,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: (_refinandoIA || _generandoTodo) ? null : () => _refinarConIA(seccionIA),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _purple.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _refinandoIA
                      ? const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Color(0xFF8B5CF6)),
                        )
                      : const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 13),
                  const SizedBox(width: 4),
                  const Text('IA', style: TextStyle(
                      color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Modelos auxiliares para gráficos
// ─────────────────────────────────────────────────────────────────────────────
class _ChartSegment {
  final double value;
  final PdfColor color;
  final String label;
  const _ChartSegment(this.value, this.color, this.label);
}

class _BarData {
  final String label;
  final int value;
  final PdfColor color;
  const _BarData(this.label, this.value, this.color);
}
