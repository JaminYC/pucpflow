import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CorreosView extends StatefulWidget {
  final String proyectoId;

  const CorreosView({super.key, required this.proyectoId});

  @override
  State<CorreosView> createState() => _CorreosViewState();
}

class _CorreosViewState extends State<CorreosView> {
  final _asuntoCtrl = TextEditingController();
  final _cuerpoCtrl = TextEditingController();
  List<Map<String, String>> _participantes = [];
  List<String> _destinatariosSeleccionados = [];
  bool _generandoIA = false;
  bool _cargando = true;
  List<Map<String, dynamic>> _historialCorreos = [];
  bool _mostrandoFormulario = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _asuntoCtrl.dispose();
    _cuerpoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([_cargarParticipantes(), _cargarHistorial()]);
  }

  Future<void> _cargarParticipantes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.proyectoId)
          .get();
      if (!doc.exists) return;
      final uids = List<String>.from(doc.data()?['participantes'] ?? []);
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final temp = <Map<String, String>>[];

      for (final uid in uids) {
        if (uid == currentUid) continue;
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final email = data['email']?.toString() ?? '';
          if (email.isNotEmpty) {
            temp.add({'uid': uid, 'nombre': _resolverNombre(data), 'email': email});
          }
        }
      }

      if (mounted) {
        setState(() {
          _participantes = temp;
          _destinatariosSeleccionados = temp.map((p) => p['uid']!).toList();
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarHistorial() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.proyectoId)
          .collection('correos_enviados')
          .orderBy('fechaEnvio', descending: true)
          .limit(20)
          .get();
      if (mounted) {
        setState(() {
          _historialCorreos = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        });
      }
    } catch (_) {}
  }

  String _resolverNombre(Map<String, dynamic> data) {
    for (final key in ['full_name', 'displayName', 'nombre', 'name', 'email']) {
      final v = data[key]?.toString();
      if (v != null && v.isNotEmpty && v != 'No name') return v;
    }
    return 'Usuario';
  }

  /// Abre Gmail en nueva pestaña con el mensaje pre-llenado
  Future<void> _abrirClienteCorreo() async {
    final asunto = _asuntoCtrl.text.trim();
    final cuerpo = _cuerpoCtrl.text.trim();

    if (asunto.isEmpty || cuerpo.isEmpty) {
      _snack('Completa el asunto y el mensaje', Colors.orange);
      return;
    }

    final destinatarios = _participantes
        .where((p) => _destinatariosSeleccionados.contains(p['uid']))
        .toList();

    if (destinatarios.isEmpty) {
      _snack('Selecciona al menos un destinatario', Colors.orange);
      return;
    }

    // Obtener nombre del proyecto
    final proyectoDoc = await FirebaseFirestore.instance
        .collection('proyectos')
        .doc(widget.proyectoId)
        .get();
    final nombreProyecto = proyectoDoc.data()?['nombre'] ?? 'Proyecto';

    final emails = destinatarios.map((p) => p['email']!).join(',');
    final asuntoFinal = '[${nombreProyecto}] $asunto';

    // ✅ Usar Gmail web compose URL (abre Gmail directamente en nueva pestaña sin diálogo del navegador)
    final gmailUrl = Uri(
      scheme: 'https',
      host: 'mail.google.com',
      path: '/mail/',
      queryParameters: {
        'view': 'cm',
        'to': emails,
        'su': asuntoFinal,
        'body': cuerpo,
      },
    );

    await launchUrl(gmailUrl, mode: LaunchMode.externalApplication);

    // Guardar en historial
    final currentUser = FirebaseAuth.instance.currentUser;
    String nombreRemitente = currentUser?.displayName ?? 'Yo';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get();
      nombreRemitente = _resolverNombre(userDoc.data() ?? {});
    } catch (_) {}

    await FirebaseFirestore.instance
        .collection('proyectos')
        .doc(widget.proyectoId)
        .collection('correos_enviados')
        .add({
      'asunto': asunto,
      'cuerpo': cuerpo,
      'destinatarios': destinatarios.map((p) => p['email']).toList(),
      'destinatariosNombres': destinatarios.map((p) => p['nombre']).toList(),
      'enviadoPor': currentUser?.uid,
      'nombreRemitente': nombreRemitente,
      'fechaEnvio': FieldValue.serverTimestamp(),
      'totalDestinatarios': destinatarios.length,
    });

    if (mounted) {
      setState(() => _mostrandoFormulario = false);
      await _cargarHistorial();
      _snack('Gmail abierto con ${destinatarios.length} destinatario(s)', const Color(0xFF10B981));
    }
  }

  Future<void> _generarBorradorIA() async {
    final asunto = _asuntoCtrl.text.trim();
    if (asunto.isEmpty) {
      _snack('Escribe primero el asunto', Colors.orange);
      return;
    }

    setState(() => _generandoIA = true);
    try {
      final proyectoDoc = await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.proyectoId)
          .get();
      final nombreProyecto = proyectoDoc.data()?['nombre'] ?? 'el proyecto';
      final vision = proyectoDoc.data()?['vision'] ?? '';

      final callable = FirebaseFunctions.instance.httpsCallable('redactarCorreoIA');
      final result = await callable.call({
        'asunto': asunto,
        'nombreProyecto': nombreProyecto,
        'vision': vision,
        'destinatarios': _participantes
            .where((p) => _destinatariosSeleccionados.contains(p['uid']))
            .map((p) => p['nombre'])
            .toList(),
      });

      final borrador = result.data['cuerpo'] as String? ?? '';
      if (mounted && borrador.isNotEmpty) {
        _cuerpoCtrl.text = borrador;
        _snack('Borrador generado', const Color(0xFF8B5CF6));
      }
    } catch (e) {
      if (mounted) _snack('Error al generar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _generandoIA = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    // Usar rootScaffoldMessenger para evitar el error "SnackBar presented off screen"
    // que ocurre cuando el widget está dentro de un Drawer/endDrawer
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle formulario / historial
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              Expanded(child: _buildToggleBtn('Redactar', Icons.edit_note, _mostrandoFormulario,
                  () => setState(() => _mostrandoFormulario = true))),
              const SizedBox(width: 8),
              Expanded(child: _buildToggleBtn(
                  'Enviados (${_historialCorreos.length})', Icons.history, !_mostrandoFormulario,
                  () => setState(() => _mostrandoFormulario = false))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _mostrandoFormulario ? _buildFormulario() : _buildHistorial(),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, IconData icon, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF8B5CF6).withOpacity(0.2) : const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activo ? const Color(0xFF8B5CF6) : Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: activo ? const Color(0xFF8B5CF6) : Colors.white38),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              color: activo ? const Color(0xFF8B5CF6) : Colors.white38,
              fontSize: 11,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info sobre cómo funciona
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF8B5CF6), size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al presionar "Abrir Gmail", se abrirá Gmail en una nueva pestaña con el mensaje pre-llenado. Se registra en el historial del proyecto.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Destinatarios
          const Text('Para:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (_participantes.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text('No hay otros participantes con email', style: TextStyle(color: Colors.orange, fontSize: 12)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    dense: true,
                    value: _destinatariosSeleccionados.length == _participantes.length,
                    tristate: _destinatariosSeleccionados.isNotEmpty && _destinatariosSeleccionados.length < _participantes.length,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _destinatariosSeleccionados = _participantes.map((p) => p['uid']!).toList();
                      } else {
                        _destinatariosSeleccionados = [];
                      }
                    }),
                    activeColor: const Color(0xFF8B5CF6),
                    title: Text('Todos (${_participantes.length})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  ..._participantes.map((p) => CheckboxListTile(
                        dense: true,
                        value: _destinatariosSeleccionados.contains(p['uid']),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _destinatariosSeleccionados.add(p['uid']!);
                          } else {
                            _destinatariosSeleccionados.remove(p['uid']);
                          }
                        }),
                        activeColor: const Color(0xFF8B5CF6),
                        secondary: CircleAvatar(
                          radius: 13,
                          backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                          child: Text((p['nombre'] ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        title: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        subtitle: Text(p['email'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      )),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Asunto
          const Text('Asunto:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _asuntoCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ej: Actualización de avances',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1A1F3A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Text('Mensaje:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _generandoIA ? null : _generarBorradorIA,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                  ),
                  child: _generandoIA
                      ? const SizedBox(width: 60, height: 14,
                          child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF8B5CF6)))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Color(0xFF8B5CF6)),
                            SizedBox(width: 4),
                            Text('IA redacta', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11)),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cuerpoCtrl,
            maxLines: 7,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Escribe tu mensaje o usa "IA redacta" para generarlo automáticamente...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF1A1F3A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _participantes.isEmpty ? null : _abrirClienteCorreo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 17),
              label: Text(
                'Abrir Gmail para ${_destinatariosSeleccionados.length} persona(s)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    if (_historialCorreos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 52, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 14),
            const Text('No se han enviado correos', style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _mostrandoFormulario = true),
              icon: const Icon(Icons.edit_note, color: Color(0xFF8B5CF6), size: 16),
              label: const Text('Redactar primer correo', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _historialCorreos.length,
      itemBuilder: (context, index) {
        final correo = _historialCorreos[index];
        final fecha = correo['fechaEnvio'] is Timestamp
            ? DateFormat('dd/MM/yy HH:mm').format((correo['fechaEnvio'] as Timestamp).toDate())
            : '—';
        final nombres = (correo['destinatariosNombres'] as List<dynamic>?)?.join(', ') ?? '';
        final total = correo['totalDestinatarios'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.email, color: Color(0xFF8B5CF6), size: 17),
            ),
            title: Text(correo['asunto'] ?? 'Sin asunto',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            subtitle: Text('Para $total • $fecha', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            iconColor: Colors.white38,
            collapsedIconColor: Colors.white24,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Colors.white12),
                    if (nombres.isNotEmpty)
                      Text('Para: $nombres', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(correo['cuerpo'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        onPressed: () {
                          _asuntoCtrl.text = correo['asunto'] ?? '';
                          _cuerpoCtrl.text = correo['cuerpo'] ?? '';
                          setState(() => _mostrandoFormulario = true);
                        },
                        icon: const Icon(Icons.copy, size: 12, color: Color(0xFF8B5CF6)),
                        label: const Text('Usar como plantilla', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
