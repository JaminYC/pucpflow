import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class InformeItem {
  final String id;
  final String nombre;
  final String tipo; // 'pdf', 'word', 'excel', 'ppt', 'otro'
  final String url;
  final int tamanoBytes;
  final String subidoPor;
  final String nombreSubidor;
  final DateTime fechaSubida;
  final String? descripcion;

  InformeItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.url,
    required this.tamanoBytes,
    required this.subidoPor,
    required this.nombreSubidor,
    required this.fechaSubida,
    this.descripcion,
  });

  factory InformeItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InformeItem(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      tipo: data['tipo'] ?? 'otro',
      url: data['url'] ?? '',
      tamanoBytes: data['tamanoBytes'] ?? 0,
      subidoPor: data['subidoPor'] ?? '',
      nombreSubidor: data['nombreSubidor'] ?? 'Usuario',
      fechaSubida: data['fechaSubida'] is Timestamp
          ? (data['fechaSubida'] as Timestamp).toDate()
          : DateTime.now(),
      descripcion: data['descripcion'],
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'tipo': tipo,
        'url': url,
        'tamanoBytes': tamanoBytes,
        'subidoPor': subidoPor,
        'nombreSubidor': nombreSubidor,
        'fechaSubida': fechaSubida,
        'descripcion': descripcion,
      };

  static String detectarTipo(String nombreArchivo) {
    final ext = nombreArchivo.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    if (['doc', 'docx'].contains(ext)) return 'word';
    if (['xls', 'xlsx', 'csv'].contains(ext)) return 'excel';
    if (['ppt', 'pptx'].contains(ext)) return 'ppt';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'imagen';
    return 'otro';
  }
}

class InformesView extends StatefulWidget {
  final String proyectoId;

  const InformesView({super.key, required this.proyectoId});

  @override
  State<InformesView> createState() => _InformesViewState();
}

class _InformesViewState extends State<InformesView> {
  bool _subiendo = false;
  double _progreso = 0;

  Stream<List<InformeItem>> _streamInformes() {
    return FirebaseFirestore.instance
        .collection('proyectos')
        .doc(widget.proyectoId)
        .collection('informes')
        .orderBy('fechaSubida', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(InformeItem.fromFirestore).toList());
  }

  Future<void> _subirInforme() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'ppt', 'pptx', 'txt', 'png', 'jpg', 'jpeg'],
      withData: true,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Obtener nombre del usuario
    String nombreSubidor = user.displayName ?? 'Usuario';
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        nombreSubidor = userDoc.data()?['full_name'] ?? nombreSubidor;
      }
    } catch (_) {}

    setState(() { _subiendo = true; _progreso = 0; });

    try {
      for (int i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (file.bytes == null) continue;

        setState(() => _progreso = i / result.files.length);

        final tipo = InformeItem.detectarTipo(file.name);
        final storagePath = 'proyectos/${widget.proyectoId}/informes/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        // Subir a Storage
        final ref = FirebaseStorage.instance.ref(storagePath);
        final uploadTask = ref.putData(
          file.bytes!,
          SettableMetadata(contentType: _getMimeType(tipo)),
        );

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();

        // Guardar en Firestore
        await FirebaseFirestore.instance
            .collection('proyectos')
            .doc(widget.proyectoId)
            .collection('informes')
            .add({
          'nombre': file.name,
          'tipo': tipo,
          'url': url,
          'tamanoBytes': file.bytes!.length,
          'subidoPor': user.uid,
          'nombreSubidor': nombreSubidor,
          'fechaSubida': FieldValue.serverTimestamp(),
          'descripcion': null,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} archivo(s) subido(s) correctamente'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _subiendo = false; _progreso = 0; });
    }
  }

  Future<void> _eliminarInforme(InformeItem informe) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Eliminar informe', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${informe.nombre}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      // Eliminar de Storage
      try {
        final ref = FirebaseStorage.instance.refFromURL(informe.url);
        await ref.delete();
      } catch (_) {}

      // Eliminar de Firestore
      await FirebaseFirestore.instance
          .collection('proyectos')
          .doc(widget.proyectoId)
          .collection('informes')
          .doc(informe.id)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _abrirInforme(InformeItem informe) async {
    final uri = Uri.parse(informe.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getMimeType(String tipo) {
    switch (tipo) {
      case 'pdf': return 'application/pdf';
      case 'word': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'excel': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'imagen': return 'image/jpeg';
      default: return 'application/octet-stream';
    }
  }

  String _formatTamano(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getIcono(String tipo) {
    switch (tipo) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'word': return Icons.description;
      case 'excel': return Icons.table_chart;
      case 'ppt': return Icons.slideshow;
      case 'imagen': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getColor(String tipo) {
    switch (tipo) {
      case 'pdf': return Colors.red.shade300;
      case 'word': return Colors.blue.shade300;
      case 'excel': return Colors.green.shade300;
      case 'ppt': return Colors.orange.shade300;
      case 'imagen': return Colors.purple.shade300;
      default: return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con botón subir
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _subiendo
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subiendo... ${(_progreso * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _progreso,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                          ),
                        ],
                      )
                    : const Text(
                        'Documentos e informes del proyecto',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _subiendo ? null : _subirInforme,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload_file, color: Colors.white, size: 16),
                label: const Text('Subir', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),

        // Lista de informes
        Expanded(
          child: StreamBuilder<List<InformeItem>>(
            stream: _streamInformes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
              }

              final informes = snapshot.data ?? [];

              if (informes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 56, color: Colors.white.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      const Text('Sin informes subidos', style: TextStyle(color: Colors.white38, fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text(
                        'Sube PDFs, Word, Excel, PPT u otros documentos',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _subirInforme,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.upload_file, color: Colors.white),
                        label: const Text('Subir primer documento', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: informes.length,
                itemBuilder: (context, index) => _buildInformeCard(informes[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInformeCard(InformeItem informe) {
    final color = _getColor(informe.tipo);
    final icono = _getIcono(informe.tipo);
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(informe.fechaSubida);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color, size: 22),
        ),
        title: Text(
          informe.nombre,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Text(informe.nombreSubidor, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(width: 10),
                Icon(Icons.access_time, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Text(fecha, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 2),
            Text(_formatTamano(informe.tamanoBytes), style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Color(0xFF8B5CF6), size: 20),
              tooltip: 'Abrir',
              onPressed: () => _abrirInforme(informe),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
              tooltip: 'Eliminar',
              onPressed: () => _eliminarInforme(informe),
            ),
          ],
        ),
        onTap: () => _abrirInforme(informe),
      ),
    );
  }
}
