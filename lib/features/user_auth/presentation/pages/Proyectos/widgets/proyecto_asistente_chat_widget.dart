import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/proyecto_asistente_service.dart';

/// Widget de chat para asistente contextual de proyectos
/// Puede usarse en modo modal o panel lateral
class ProyectoAsistenteChatWidget extends StatefulWidget {
  final String proyectoId;
  final String proyectoNombre;
  final bool modoPanel; // true = panel lateral, false = modal

  const ProyectoAsistenteChatWidget({
    super.key,
    required this.proyectoId,
    required this.proyectoNombre,
    this.modoPanel = false,
  });

  @override
  State<ProyectoAsistenteChatWidget> createState() => _ProyectoAsistenteChatWidgetState();
}

class _ProyectoAsistenteChatWidgetState extends State<ProyectoAsistenteChatWidget> {
  final ProyectoAsistenteService _asistenteService = ProyectoAsistenteService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final List<Map<String, dynamic>> _mensajes = [];
  bool _cargandoContexto = true;
  bool _procesando = false;
  String? _contextoProyecto;
  Map<String, dynamic>? _datosProyecto;

  @override
  void initState() {
    super.initState();
    _cargarContextoProyecto();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Cargar contexto completo del proyecto
  Future<void> _cargarContextoProyecto() async {
    if (!mounted) return;
    setState(() => _cargandoContexto = true);

    try {
      final contexto = await _asistenteService.obtenerContextoProyecto(widget.proyectoId);
      if (!mounted) return;

      setState(() {
        _datosProyecto = contexto;
        _contextoProyecto = contexto['contextoTexto'] as String;
        _cargandoContexto = false;
      });

      // Mensaje de bienvenida
      _agregarMensaje(
        role: 'assistant',
        content: '👋 ¡Hola! Soy tu asistente para el proyecto **${widget.proyectoNombre}**.\n\n'
            'Tengo acceso completo a toda la información del proyecto. Puedo:\n'
            '• Responder preguntas sobre el estado\n'
            '• Crear y modificar tareas\n'
            '• Analizar problemas y sugerir soluciones\n'
            '• Generar reportes y resúmenes\n\n'
            '¿En qué puedo ayudarte?',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoContexto = false);
      _agregarMensaje(
        role: 'assistant',
        content: '❌ Error cargando información del proyecto: $e',
      );
    }
  }

  /// Agregar mensaje al chat
  void _agregarMensaje({required String role, required String content}) {
    if (!mounted) return;
    setState(() {
      _mensajes.add({
        'role': role,
        'content': content,
        'timestamp': DateTime.now(),
      });
    });

    // Auto-scroll al último mensaje
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Enviar mensaje al asistente
  Future<void> _enviarMensaje() async {
    final texto = _inputController.text.trim();
    if (texto.isEmpty || _procesando) return;

    _inputController.clear();
    _agregarMensaje(role: 'user', content: texto);

    if (!mounted) return;
    setState(() => _procesando = true);

    try {
      // Preparar historial de conversación
      final historial = _mensajes.map((m) => {
        'role': m['role'],
        'content': m['content'],
      }).toList();

      // Llamar a Cloud Function con contexto del proyecto
      final callable = _functions.httpsCallable('adanProyectoConsulta');

      final result = await callable.call({
        'pregunta': texto,
        'contextoProyecto': _contextoProyecto,
        'proyectoId': widget.proyectoId,
        'historialConversacion': historial,
      });

      if (!mounted) return;

      final respuesta = result.data['respuesta'] as String? ??
          'Lo siento, no pude procesar tu pregunta.';

      _agregarMensaje(role: 'assistant', content: respuesta);

      // Si la respuesta incluye acciones realizadas, recargar contexto
      if (result.data['accionRealizada'] == true) {
        await _cargarContextoProyecto();
      }
    } catch (e) {
      if (!mounted) return;
      _agregarMensaje(
        role: 'assistant',
        content: '❌ Error: No pude procesar tu mensaje. $e',
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modoPanel) {
      return _buildPanelLateral();
    } else {
      return _buildModal();
    }
  }

  /// Construir como panel lateral
  Widget _buildPanelLateral() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1229),
        border: Border(left: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: _buildChatContent(),
    );
  }

  /// Construir como modal centrado
  Widget _buildModal() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1229),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: _buildChatContent(),
      ),
    );
  }

  /// Contenido principal del chat
  Widget _buildChatContent() {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Mensajes
        Expanded(
          child: _cargandoContexto
              ? _buildCargando()
              : _buildListaMensajes(),
        ),

        // Input
        _buildInputBar(),
      ],
    );
  }

  /// Header del chat
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asistente de Proyecto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.proyectoNombre,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_datosProyecto != null) ...[
            const SizedBox(width: 8),
            _buildEstadisticasChip(),
          ],
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Chip con estadísticas rápidas
  Widget _buildEstadisticasChip() {
    final stats = _datosProyecto?['estadisticas'] as Map<String, dynamic>?;
    if (stats == null) return const SizedBox();

    return Tooltip(
      message: 'Progreso del proyecto',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Text(
          '${stats['progresoPercent']}%',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Indicador de carga
  Widget _buildCargando() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6366F1)),
          SizedBox(height: 16),
          Text(
            'Analizando proyecto...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// Lista de mensajes
  Widget _buildListaMensajes() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length,
      itemBuilder: (context, index) {
        final mensaje = _mensajes[index];
        final esUsuario = mensaje['role'] == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!esUsuario) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: esUsuario
                        ? const Color(0xFF6366F1).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: esUsuario
                          ? const Color(0xFF6366F1).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: esUsuario
                      ? Text(
                          mensaje['content'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        )
                      : MarkdownBody(
                          data: mensaje['content'],
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.white, fontSize: 14),
                            h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            strong: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                            em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                            code: TextStyle(
                              color: const Color(0xFF10B981),
                              backgroundColor: Colors.white.withOpacity(0.1),
                              fontFamily: 'monospace',
                            ),
                            listBullet: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 14),
                          ),
                        ),
                ),
              ),
              if (esUsuario) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Barra de input
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_procesando && !_cargandoContexto,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _procesando ? 'Procesando...' : 'Pregunta sobre el proyecto...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _enviarMensaje(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: _procesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _procesando ? null : _enviarMensaje,
            ),
          ),
        ],
      ),
    );
  }
}
