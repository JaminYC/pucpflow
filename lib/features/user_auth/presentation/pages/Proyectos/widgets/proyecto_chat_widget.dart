import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pucpflow/utils/notification_service.dart';

class ProyectoChatWidget extends StatefulWidget {
  final String proyectoId;
  final String proyectoNombre;
  final String currentUserUid;
  final String currentUserNombre;
  final String? currentUserFoto;
  final List<Map<String, String>> participantes;

  const ProyectoChatWidget({
    super.key,
    required this.proyectoId,
    this.proyectoNombre = 'Proyecto',
    required this.currentUserUid,
    required this.currentUserNombre,
    this.currentUserFoto,
    required this.participantes,
  });

  @override
  State<ProyectoChatWidget> createState() => _ProyectoChatWidgetState();
}

class _ProyectoChatWidgetState extends State<ProyectoChatWidget> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  // Sugerencias de menciones (sin OverlayEntry — dentro del layout)
  List<Map<String, String>> _sugerencias = [];
  int _arrobaPos = -1;       // posición del @ en el texto

  bool _subiendoArchivo = false;

  static const _bg     = Color(0xFF0A0E27);
  static const _card   = Color(0xFF111827);
  static const _purple = Color(0xFF8B5CF6);
  static const _emojis = ['👍', '❤️', '😂', '🔥', '✅', '🎉'];

  CollectionReference get _chatRef =>
      _firestore.collection('proyectos').doc(widget.proyectoId).collection('chat');

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onTextChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scroll al último mensaje
  // ─────────────────────────────────────────────────────────────────────────
  void _irAlFondo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Detección de @ para menciones
  // ─────────────────────────────────────────────────────────────────────────
  void _onTextChanged() {
    if (!mounted) return;
    _calcularSugerencias();
  }

  void _calcularSugerencias() {
    final texto  = _inputCtrl.text;
    final cursor = _inputCtrl.selection.baseOffset;

    // Cursor inválido
    if (cursor < 0 || cursor > texto.length) {
      _limpiarSugerencias();
      return;
    }

    // Texto hasta el cursor
    final antes = texto.substring(0, cursor);

    // Buscar el último @ antes del cursor
    final arrobaIdx = antes.lastIndexOf('@');

    if (arrobaIdx < 0) {
      _limpiarSugerencias();
      return;
    }

    // Query: lo que hay entre @ y el cursor (sin espacios = aún escribiendo)
    final query = antes.substring(arrobaIdx + 1);

    // Si la query tiene espacios ya terminó de escribir el nombre
    if (query.contains(' ') || query.contains('\n')) {
      _limpiarSugerencias();
      return;
    }

    // Mostrar todos si query vacía (acaban de escribir @), o filtrar por inicio de nombre
    final filtrados = widget.participantes.where((p) {
      if (p['uid'] == widget.currentUserUid) return false;
      if (query.isEmpty) return true;
      final nombre = (p['nombre'] ?? '').toLowerCase();
      return nombre.contains(query.toLowerCase());
    }).toList();

    if (filtrados.isEmpty) {
      _limpiarSugerencias();
      return;
    }

    setState(() {
      _arrobaPos   = arrobaIdx;
      _sugerencias = filtrados;
    });
  }

  void _limpiarSugerencias() {
    if (_sugerencias.isNotEmpty || _arrobaPos >= 0) {
      setState(() {
        _sugerencias = [];
        _arrobaPos   = -1;
      });
    }
  }

  // Inserta @nombre en el campo de texto
  void _insertarMencion(Map<String, String> p) {
    final nombre = p['nombre'] ?? 'Usuario';
    final texto  = _inputCtrl.text;
    final cursor = _inputCtrl.selection.baseOffset;

    if (_arrobaPos < 0) return;

    final inicio   = texto.substring(0, _arrobaPos);          // antes del @
    final fin      = cursor < texto.length ? texto.substring(cursor) : '';
    final nuevo    = '$inicio@$nombre $fin';
    final newCursor = inicio.length + nombre.length + 2;       // pos después del espacio

    _inputCtrl.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _limpiarSugerencias();
    _focusNode.requestFocus();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Extraer UIDs mencionados en un texto
  // ─────────────────────────────────────────────────────────────────────────
  List<String> _extraerUidsMencionados(String texto) {
    final regex = RegExp(r'@([\w\u00C0-\u017E]+(?:\s[\w\u00C0-\u017E]+)?)');
    final matches = regex.allMatches(texto);
    final uids = <String>[];
    for (final m in matches) {
      final nombreMencionado = m.group(1)?.toLowerCase() ?? '';
      for (final p in widget.participantes) {
        final nombre = (p['nombre'] ?? '').toLowerCase();
        if (nombre == nombreMencionado && p['uid'] != widget.currentUserUid) {
          final uid = p['uid'];
          if (uid != null && !uids.contains(uid)) uids.add(uid);
        }
      }
    }
    return uids;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Enviar mensaje de texto
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _enviarMensaje() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty) return;

    _inputCtrl.clear();
    _limpiarSugerencias();

    await _chatRef.add({
      'texto'      : texto,
      'tipo'       : 'texto',
      'autorUid'   : widget.currentUserUid,
      'autorNombre': widget.currentUserNombre,
      'autorFoto'  : widget.currentUserFoto ?? '',
      'timestamp'  : FieldValue.serverTimestamp(),
      'leidoPor'   : [widget.currentUserUid],
      'reacciones' : {},
    });

    // Notificar a los mencionados
    final mencionados = _extraerUidsMencionados(texto);
    for (final uid in mencionados) {
      await NotificationService.crear(
        uid           : uid,
        titulo        : '${widget.currentUserNombre} te mencion\u00f3',
        cuerpo        : texto.length > 80 ? '${texto.substring(0, 77)}...' : texto,
        tipo          : 'mencionado',
        proyectoId    : widget.proyectoId,
        proyectoNombre: widget.proyectoNombre,
      );
    }

    _irAlFondo();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Guardar archivo también en repositorio_conocimiento
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _guardarEnRepositorio({
    required String url,
    required String nombreArchivo,
    required String tipo, // 'imagen' | 'documento'
  }) async {
    await _firestore
        .collection('proyectos')
        .doc(widget.proyectoId)
        .collection('repositorio_conocimiento')
        .add({
      'titulo'       : nombreArchivo,
      'urlArchivo'   : url,
      'url'          : null,
      'tipo'         : tipo,
      'descripcion'  : 'Compartido en el chat por ${widget.currentUserNombre}',
      'tags'         : ['chat', tipo],
      'categoriaIA'  : null,
      'nombreArchivo': nombreArchivo,
      'creadoPor'    : widget.currentUserUid,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Subir imagen desde galería
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _subirImagen() async {
    try {
      final picked = await _imagePicker.pickImage(
        source      : ImageSource.gallery,
        imageQuality: 75,
        maxWidth    : 1200,
      );
      if (picked == null) return;

      if (mounted) setState(() => _subiendoArchivo = true);

      final file        = File(picked.path);
      final nombreBase  = picked.name.isNotEmpty ? picked.name
          : '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageName = '${DateTime.now().millisecondsSinceEpoch}_$nombreBase';
      final ref = _storage
          .ref()
          .child('proyectos/${widget.proyectoId}/chat/$storageName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Mensaje en el chat
      await _chatRef.add({
        'texto'        : '',
        'tipo'         : 'imagen',
        'imagenUrl'    : url,
        'nombreArchivo': nombreBase,
        'autorUid'     : widget.currentUserUid,
        'autorNombre'  : widget.currentUserNombre,
        'autorFoto'    : widget.currentUserFoto ?? '',
        'timestamp'    : FieldValue.serverTimestamp(),
        'leidoPor'     : [widget.currentUserUid],
        'reacciones'   : {},
      });

      // Auto-guardar en recursos
      await _guardarEnRepositorio(url: url, nombreArchivo: nombreBase, tipo: 'imagen');

      _irAlFondo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content        : Text('Error al subir imagen: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _subiendoArchivo = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Subir documento (PDF, Word, Excel, etc.)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _subirDocumento() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type         : FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
                            'txt', 'csv', 'zip', 'rar'],
        withData     : false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final pf   = result.files.first;
      final path = pf.path;
      if (path == null) return;

      if (mounted) setState(() => _subiendoArchivo = true);

      final file        = File(path);
      final nombreBase  = pf.name;
      final storageName = '${DateTime.now().millisecondsSinceEpoch}_$nombreBase';
      final ref = _storage
          .ref()
          .child('proyectos/${widget.proyectoId}/chat/$storageName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Determinar tipo para el repositorio
      final ext  = nombreBase.split('.').last.toLowerCase();
      final tipo = ['jpg','jpeg','png','gif','webp'].contains(ext)
          ? 'imagen' : 'documento';

      // Mensaje en el chat
      await _chatRef.add({
        'texto'        : '',
        'tipo'         : 'documento',
        'archivoUrl'   : url,
        'nombreArchivo': nombreBase,
        'autorUid'     : widget.currentUserUid,
        'autorNombre'  : widget.currentUserNombre,
        'autorFoto'    : widget.currentUserFoto ?? '',
        'timestamp'    : FieldValue.serverTimestamp(),
        'leidoPor'     : [widget.currentUserUid],
        'reacciones'   : {},
      });

      // Auto-guardar en recursos del proyecto
      await _guardarEnRepositorio(url: url, nombreArchivo: nombreBase, tipo: tipo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '$nombreBase guardado también en Recursos del proyecto',
              style: const TextStyle(color: Colors.white),
            )),
          ]),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ));
      }

      _irAlFondo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content        : Text('Error al subir documento: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _subiendoArchivo = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Marcar mensajes como leídos
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _marcarLeido(List<QueryDocumentSnapshot> docs) async {
    final batch = _firestore.batch();
    for (final doc in docs) {
      final data  = doc.data() as Map<String, dynamic>;
      final leidos = List<String>.from(data['leidoPor'] ?? []);
      if (!leidos.contains(widget.currentUserUid)) {
        batch.update(doc.reference, {
          'leidoPor': FieldValue.arrayUnion([widget.currentUserUid]),
        });
      }
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Toggle reacción (con transaction para evitar race conditions)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _toggleReaccion(String msgId, String emoji) async {
    final ref = _chatRef.doc(msgId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data      = snap.data() as Map<String, dynamic>;
      final reacciones = Map<String, dynamic>.from(data['reacciones'] ?? {});
      final lista     = List<String>.from(reacciones[emoji] ?? []);

      if (lista.contains(widget.currentUserUid)) {
        lista.remove(widget.currentUserUid);
      } else {
        lista.add(widget.currentUserUid);
      }

      if (lista.isEmpty) {
        reacciones.remove(emoji);
      } else {
        reacciones[emoji] = lista;
      }

      tx.update(ref, {'reacciones': reacciones});
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom sheet de emojis
  // ─────────────────────────────────────────────────────────────────────────
  void _mostrarEmojis(String msgId) {
    showModalBottomSheet(
      context          : context,
      backgroundColor  : const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize        : MainAxisSize.min,
          crossAxisAlignment  : CrossAxisAlignment.start,
          children: [
            const Text('Reaccionar',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _emojis.map((emoji) => GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _toggleReaccion(msgId, emoji);
                },
                child: Container(
                  width : 48, height: 48,
                  decoration: BoxDecoration(
                    color       : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Avatar circular
  // ─────────────────────────────────────────────────────────────────────────
  Widget _avatar(String nombre, String? foto, {double r = 16}) {
    final hayFoto = (foto ?? '').isNotEmpty;
    return CircleAvatar(
      radius         : r,
      backgroundColor: _purple,
      backgroundImage: hayFoto ? NetworkImage(foto!) as ImageProvider : null,
      child: hayFoto
          ? null
          : Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: TextStyle(
                color     : Colors.white,
                fontSize  : r * 0.75,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Texto con @menciones resaltadas
  // ─────────────────────────────────────────────────────────────────────────
  Widget _textoConMenciones(String texto) {
    final regex   = RegExp(r'@[\w\u00C0-\u017E]+(?:\s[\w\u00C0-\u017E]+)?');
    final matches = regex.allMatches(texto);
    if (matches.isEmpty) {
      return Text(texto,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45));
    }
    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in matches) {
      if (m.start > last) {
        spans.add(TextSpan(
          text : texto.substring(last, m.start),
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
        ));
      }
      spans.add(TextSpan(
        text : m.group(0),
        style: const TextStyle(
          color     : _purple,
          fontWeight: FontWeight.w700,
          fontSize  : 14,
          height    : 1.45,
        ),
      ));
      last = m.end;
    }
    if (last < texto.length) {
      spans.add(TextSpan(
        text : texto.substring(last),
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bubble de documento adjunto
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDocumentoBubble(String url, String? nombre) {
    final ext = (nombre ?? '').split('.').last.toLowerCase();
    final IconData icono;
    final Color color;
    if (['pdf'].contains(ext)) {
      icono = Icons.picture_as_pdf_rounded;
      color = const Color(0xFFEF4444);
    } else if (['doc', 'docx'].contains(ext)) {
      icono = Icons.description_rounded;
      color = const Color(0xFF3B82F6);
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      icono = Icons.table_chart_rounded;
      color = const Color(0xFF10B981);
    } else if (['ppt', 'pptx'].contains(ext)) {
      icono = Icons.slideshow_rounded;
      color = const Color(0xFFF59E0B);
    } else if (['zip', 'rar'].contains(ext)) {
      icono = Icons.folder_zip_rounded;
      color = const Color(0xFF8B5CF6);
    } else {
      icono = Icons.insert_drive_file_rounded;
      color = Colors.white54;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width : 38, height: 38,
          decoration: BoxDecoration(
            color       : color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre ?? 'Documento',
                style: const TextStyle(
                  color     : Colors.white,
                  fontSize  : 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines : 2,
                overflow : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                ext.toUpperCase(),
                style: TextStyle(
                  color   : color.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bubble de mensaje
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBubble(QueryDocumentSnapshot doc) {
    final data         = doc.data() as Map<String, dynamic>;
    final esPropio     = data['autorUid'] == widget.currentUserUid;
    final texto        = data['texto'] as String? ?? '';
    final tipo         = data['tipo'] as String? ?? 'texto';
    final imagenUrl    = data['imagenUrl'] as String?;
    final archivoUrl   = data['archivoUrl'] as String?;
    final nombreArchivo= data['nombreArchivo'] as String?;
    final nombre       = data['autorNombre'] as String? ?? 'Usuario';
    final foto         = data['autorFoto'] as String?;
    final ts        = data['timestamp'] as Timestamp?;
    final hora      = ts != null ? DateFormat('HH:mm').format(ts.toDate()) : '';
    final leidoPor  = List<String>.from(data['leidoPor'] ?? []);
    final reacciones= Map<String, dynamic>.from(data['reacciones'] ?? {});
    final vistos    = leidoPor.length - 1; // excluir al autor

    return Padding(
      padding: EdgeInsets.only(
        left  : esPropio ? 56 : 8,
        right : esPropio ? 8 : 56,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment : esPropio ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!esPropio) ...[_avatar(nombre, foto), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  esPropio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Nombre (solo en mensajes ajenos)
                if (!esPropio)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(nombre,
                        style: TextStyle(
                            color     : Colors.white.withValues(alpha: 0.55),
                            fontSize  : 11,
                            fontWeight: FontWeight.w600)),
                  ),

                // Burbuja
                GestureDetector(
                  onLongPress: () => _mostrarEmojis(doc.id),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: tipo == 'imagen'
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: esPropio
                          ? _purple.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.only(
                        topLeft    : const Radius.circular(16),
                        topRight   : const Radius.circular(16),
                        bottomLeft : Radius.circular(esPropio ? 16 : 4),
                        bottomRight: Radius.circular(esPropio ? 4 : 16),
                      ),
                      border: Border.all(
                        color: esPropio
                            ? _purple.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: tipo == 'imagen' && (imagenUrl ?? '').isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imagenUrl!,
                              fit  : BoxFit.cover,
                              width: 220,
                              errorBuilder: (_, __, ___) => const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.broken_image,
                                    color: Colors.white38, size: 40),
                              ),
                            ),
                          )
                        : tipo == 'documento' && (archivoUrl ?? '').isNotEmpty
                        ? _buildDocumentoBubble(archivoUrl!, nombreArchivo)
                        : _textoConMenciones(texto),
                  ),
                ),

                // Hora + visto + botón reacción
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(hora,
                          style: TextStyle(
                              color  : Colors.white.withValues(alpha: 0.35),
                              fontSize: 10)),
                      if (esPropio && vistos > 0) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all,
                            size : 12,
                            color: Colors.blueAccent.withValues(alpha: 0.8)),
                        const SizedBox(width: 2),
                        Text('Visto por $vistos',
                            style: TextStyle(
                                color   : Colors.white.withValues(alpha: 0.35),
                                fontSize: 10)),
                      ],
                    ],
                  ),
                ),

                // Reacciones
                if (reacciones.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4, runSpacing: 4,
                      children: reacciones.entries.map((e) {
                        final emoji   = e.key;
                        final lista   = List<String>.from(e.value);
                        final yoRxn   = lista.contains(widget.currentUserUid);
                        return GestureDetector(
                          onTap: () => _toggleReaccion(doc.id, emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color : yoRxn
                                  ? _purple.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: yoRxn
                                    ? _purple.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              '$emoji ${lista.length}',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (esPropio) ...[
            const SizedBox(width: 8),
            _avatar(widget.currentUserNombre, widget.currentUserFoto),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Panel de sugerencias de menciones (encima del input bar)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSugerencias() {
    if (_sugerencias.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          top   : BorderSide(color: _purple.withValues(alpha: 0.4)),
          left  : BorderSide(color: _purple.withValues(alpha: 0.2)),
          right : BorderSide(color: _purple.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Mencionar a...',
              style: TextStyle(
                color     : _purple.withValues(alpha: 0.9),
                fontSize  : 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap  : true,
              padding     : const EdgeInsets.only(bottom: 4),
              itemCount   : _sugerencias.length,
              itemBuilder : (_, i) {
                final p      = _sugerencias[i];
                final nombre = p['nombre'] ?? 'Usuario';
                final foto   = p['foto']   ?? '';
                return InkWell(
                  onTap: () => _insertarMencion(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _avatar(nombre, foto.isNotEmpty ? foto : null, r: 18),
                        const SizedBox(width: 10),
                        Text(
                          '@$nombre',
                          style: const TextStyle(
                            color     : Colors.white,
                            fontSize  : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Input bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color : _card,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón imagen
          GestureDetector(
            onTap: _subiendoArchivo ? null : _subirImagen,
            child: Container(
              width : 40, height: 40,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color       : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border      : Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: _subiendoArchivo
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child  : CircularProgressIndicator(strokeWidth: 2, color: _purple),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.white54, size: 20),
            ),
          ),

          // Botón documento
          GestureDetector(
            onTap: _subiendoArchivo ? null : _subirDocumento,
            child: Container(
              width : 40, height: 40,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color       : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border      : Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.attach_file_rounded, color: Colors.white54, size: 20),
            ),
          ),

          // TextField
          Expanded(
            child: TextField(
              controller     : _inputCtrl,
              focusNode      : _focusNode,
              style          : const TextStyle(color: Colors.white, fontSize: 14),
              maxLines       : 4,
              minLines       : 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText : 'Mensaje\u2026  usa @ para mencionar',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                filled    : true,
                fillColor : Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide  : BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Botón enviar
          GestureDetector(
            onTap: _enviarMensaje,
            child: Container(
              width : 44, height: 44,
              decoration: BoxDecoration(
                gradient    : const LinearGradient(colors: [_purple, Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation      : 0,
        iconTheme      : const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: _purple, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.proyectoNombre,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _purple.withValues(alpha: 0.3)),
        ),
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRef.orderBy('timestamp', descending: false).snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _purple));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size : 48,
                            color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text(
                          'Nadie ha escrito a\u00fan.\n\u00a1S\u00e9 el primero!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color   : Colors.white.withValues(alpha: 0.35),
                              fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _marcarLeido(docs);
                  _irAlFondo();
                });

                return GestureDetector(
                  onTap: () {
                    _limpiarSugerencias();
                    FocusScope.of(context).unfocus();
                  },
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding   : const EdgeInsets.fromLTRB(0, 12, 0, 4),
                    itemCount : docs.length,
                    itemBuilder: (_, i) => _buildBubble(docs[i]),
                  ),
                );
              },
            ),
          ),

          // Sugerencias de menciones (encima del input)
          _buildSugerencias(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }
}
