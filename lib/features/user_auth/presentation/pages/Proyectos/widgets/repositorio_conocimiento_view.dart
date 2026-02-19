import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/recurso_conocimiento_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/repositorio_conocimiento_service.dart';

class RepositorioConocimientoView extends StatefulWidget {
  final String proyectoId;

  const RepositorioConocimientoView({super.key, required this.proyectoId});

  @override
  State<RepositorioConocimientoView> createState() => _RepositorioConocimientoViewState();
}

class _RepositorioConocimientoViewState extends State<RepositorioConocimientoView> {
  final RepositorioConocimientoService _service = RepositorioConocimientoService();
  String _filtroTipo = 'todos';
  String _busqueda = '';
  final TextEditingController _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecursoConocimiento>>(
      stream: _service.streamRecursos(widget.proyectoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recursos = snapshot.data ?? [];
        final filtrados = _aplicarFiltros(recursos);

        return Column(
          children: [
            // Barra de búsqueda + botón agregar
            _buildSearchBar(),
            const SizedBox(height: 8),
            // Filtros por tipo
            _buildFiltrosTipo(),
            const SizedBox(height: 8),
            // Lista de recursos
            Expanded(
              child: filtrados.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) => _buildRecursoCard(filtrados[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar recursos...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                filled: true,
                fillColor: const Color(0xFF1A1F3A),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            mini: true,
            backgroundColor: const Color(0xFF8B5CF6),
            onPressed: () => _mostrarFormulario(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosTipo() {
    final filtros = {
      'todos': 'Todos',
      'paper': 'Papers',
      'video': 'Videos',
      'tutorial': 'Tutoriales',
      'documento': 'Docs',
      'imagen': 'Imágenes',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filtros.entries.map((e) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(e.value, style: TextStyle(
              color: _filtroTipo == e.key ? Colors.white : Colors.white70,
              fontSize: 12,
            )),
            selected: _filtroTipo == e.key,
            onSelected: (_) => setState(() => _filtroTipo = e.key),
            backgroundColor: const Color(0xFF1A1F3A),
            selectedColor: const Color(0xFF8B5CF6),
            checkmarkColor: Colors.white,
            side: BorderSide(color: _filtroTipo == e.key ? const Color(0xFF8B5CF6) : Colors.white24),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildRecursoCard(RecursoConocimiento recurso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // YouTube thumbnail
          if (recurso.esYoutube && recurso.youtubeVideoId != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  Image.network(
                    'https://img.youtube.com/vi/${recurso.youtubeVideoId}/hqdefault.jpg',
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 8, right: 8,
                    child: Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 40),
                  ),
                ],
              ),
            ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + icono tipo
                Row(
                  children: [
                    _buildTipoIcon(recurso.tipo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        recurso.titulo,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                      color: const Color(0xFF1A1F3A),
                      onSelected: (value) {
                        if (value == 'eliminar') _confirmarEliminar(recurso);
                      },
                      itemBuilder: (_) => [
                        if (recurso.url != null)
                          const PopupMenuItem(value: 'abrir', child: Text('Abrir enlace', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  ],
                ),

                // Descripción
                if (recurso.descripcion != null && recurso.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    recurso.descripcion!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Archivo adjunto
                if (recurso.nombreArchivo != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _abrirUrl(recurso.urlArchivo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E27),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, color: Color(0xFF8B5CF6), size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              recurso.nombreArchivo!,
                              style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.download, color: Colors.white38, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],

                // URL externa
                if (recurso.url != null && !recurso.esYoutube) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _abrirUrl(recurso.url),
                    child: Text(
                      recurso.url!,
                      style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, decoration: TextDecoration.underline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Tags + badge IA
                if (recurso.tags.isNotEmpty || recurso.categoriaIA != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (recurso.categoriaIA != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              const Color(0xFF8B5CF6).withOpacity(0.3),
                              const Color(0xFF3B82F6).withOpacity(0.3),
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 12),
                              const SizedBox(width: 4),
                              Text(recurso.categoriaIA!, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ...recurso.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(tag, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Botón abrir para YouTube
          if (recurso.esYoutube)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _abrirUrl(recurso.url),
                  icon: const Icon(Icons.play_arrow, color: Colors.redAccent, size: 18),
                  label: const Text('Ver en YouTube', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipoIcon(String tipo) {
    IconData icon;
    Color color;
    switch (tipo) {
      case 'paper':
        icon = Icons.article;
        color = Colors.amber;
        break;
      case 'video':
        icon = Icons.videocam;
        color = Colors.redAccent;
        break;
      case 'tutorial':
        icon = Icons.school;
        color = Colors.green;
        break;
      case 'documento':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'imagen':
        icon = Icons.image;
        color = Colors.pink;
        break;
      default:
        icon = Icons.link;
        color = Colors.grey;
    }

    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Sin recursos guardados', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Agrega links, papers, videos o archivos', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _mostrarFormulario(),
            icon: const Icon(Icons.add, color: Color(0xFF8B5CF6)),
            label: const Text('Agregar recurso', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }

  List<RecursoConocimiento> _aplicarFiltros(List<RecursoConocimiento> recursos) {
    return recursos.where((r) {
      if (_filtroTipo != 'todos' && r.tipo != _filtroTipo) return false;
      if (_busqueda.isNotEmpty) {
        final match = r.titulo.toLowerCase().contains(_busqueda) ||
            (r.descripcion?.toLowerCase().contains(_busqueda) ?? false) ||
            r.tags.any((t) => t.toLowerCase().contains(_busqueda));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _abrirUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmarEliminar(RecursoConocimiento recurso) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Eliminar recurso', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${recurso.titulo}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _service.eliminarRecurso(widget.proyectoId, recurso);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _mostrarFormulario() {
    final tituloCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    bool esArchivo = false;
    PlatformFile? archivoSeleccionado;
    bool subiendo = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0E27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nuevo Recurso', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Toggle link / archivo
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleButton('Link externo', Icons.link, !esArchivo, () {
                            setModalState(() => esArchivo = false);
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildToggleButton('Subir archivo', Icons.upload_file, esArchivo, () {
                            setModalState(() => esArchivo = true);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Título
                    _buildFormField(tituloCtrl, 'Título del recurso', Icons.title),
                    const SizedBox(height: 12),

                    if (!esArchivo) ...[
                      // URL
                      _buildFormField(urlCtrl, 'URL (YouTube, paper, tutorial...)', Icons.link),
                    ] else ...[
                      // Selector de archivo
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(withData: true);
                          if (result != null && result.files.isNotEmpty) {
                            setModalState(() {
                              archivoSeleccionado = result.files.first;
                              if (tituloCtrl.text.isEmpty) {
                                tituloCtrl.text = archivoSeleccionado!.name.split('.').first;
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F3A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: archivoSeleccionado != null ? const Color(0xFF8B5CF6) : Colors.white24,
                              style: archivoSeleccionado != null ? BorderStyle.solid : BorderStyle.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                archivoSeleccionado != null ? Icons.check_circle : Icons.cloud_upload,
                                color: archivoSeleccionado != null ? const Color(0xFF8B5CF6) : Colors.white38,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  archivoSeleccionado?.name ?? 'Seleccionar archivo...',
                                  style: TextStyle(
                                    color: archivoSeleccionado != null ? Colors.white : Colors.white54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    _buildFormField(descripcionCtrl, 'Descripción (opcional)', Icons.description, maxLines: 2),
                    const SizedBox(height: 12),
                    _buildFormField(tagsCtrl, 'Tags (separados por coma)', Icons.tag),
                    const SizedBox(height: 20),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: subiendo ? null : () async {
                          if (tituloCtrl.text.trim().isEmpty) return;

                          setModalState(() => subiendo = true);

                          try {
                            final userId = FirebaseAuth.instance.currentUser?.uid;
                            final tags = tagsCtrl.text.trim().isEmpty
                                ? <String>[]
                                : tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                            if (esArchivo && archivoSeleccionado != null && archivoSeleccionado!.bytes != null) {
                              // Subir archivo
                              await _service.subirArchivoYCrearRecurso(
                                proyectoId: widget.proyectoId,
                                titulo: tituloCtrl.text.trim(),
                                nombreArchivo: archivoSeleccionado!.name,
                                bytes: archivoSeleccionado!.bytes!,
                                contentType: _inferContentType(archivoSeleccionado!.name),
                                creadoPor: userId,
                              );
                            } else {
                              // Link externo
                              String tipo = 'otro';
                              String? categoriaIA;

                              // Intentar categorizar con IA
                              try {
                                final resultado = await _service.categorizarConIA(
                                  titulo: tituloCtrl.text.trim(),
                                  url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                                );
                                tipo = resultado['tipo'] ?? 'otro';
                                categoriaIA = resultado['categoria'];
                                if (resultado['tags'] != null) {
                                  tags.addAll(List<String>.from(resultado['tags']).where((t) => !tags.contains(t)));
                                }
                              } catch (_) {}

                              final recurso = RecursoConocimiento(
                                id: '',
                                titulo: tituloCtrl.text.trim(),
                                url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                                tipo: tipo,
                                descripcion: descripcionCtrl.text.trim().isEmpty ? null : descripcionCtrl.text.trim(),
                                tags: tags,
                                categoriaIA: categoriaIA,
                                creadoPor: userId,
                                fechaCreacion: DateTime.now(),
                              );
                              await _service.agregarRecurso(widget.proyectoId, recurso);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setModalState(() => subiendo = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        child: subiendo
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                esArchivo ? 'Subir y categorizar con IA' : 'Agregar recurso',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B5CF6).withOpacity(0.2) : const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? const Color(0xFF8B5CF6) : Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1F3A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
      ),
    );
  }

  String _inferContentType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'mp4': return 'video/mp4';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }
}
