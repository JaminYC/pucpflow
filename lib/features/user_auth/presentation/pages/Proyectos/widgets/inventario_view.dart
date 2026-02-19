import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/inventario_item_model.dart';
import 'package:pucpflow/features/user_auth/presentation/pages/Proyectos/inventario_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class InventarioView extends StatefulWidget {
  final String proyectoId;

  const InventarioView({super.key, required this.proyectoId});

  @override
  State<InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<InventarioView> {
  final InventarioService _service = InventarioService();
  String _filtroTipo = 'todos';
  String _filtroEstado = 'todos';

  // Para guardar items snapshot para exportar
  List<InventarioItem> _itemsActuales = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventarioItem>>(
      stream: _service.streamInventario(widget.proyectoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        _itemsActuales = items;
        final filtrados = _aplicarFiltros(items);

        double costoTotal = 0;
        for (var item in items) {
          costoTotal += (item.costoEstimado ?? 0) * item.cantidad;
        }

        return Column(
          children: [
            _buildCostoCard(costoTotal, items.length),
            const SizedBox(height: 8),
            // Botones Importar / Exportar
            _buildImportExportBar(),
            const SizedBox(height: 8),
            _buildFiltros(),
            const SizedBox(height: 8),
            Expanded(
              child: filtrados.isEmpty
                  ? _buildEmptyState()
                  : _buildTablaInventario(filtrados),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImportExportBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _mostrarOpcionesImportar,
              icon: const Icon(Icons.upload_file, size: 16, color: Color(0xFF10B981)),
              label: const Text('Importar', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF10B981), width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _itemsActuales.isEmpty ? null : _exportarCSV,
              icon: Icon(Icons.download, size: 16, color: _itemsActuales.isEmpty ? Colors.white24 : const Color(0xFF3B82F6)),
              label: Text('Exportar CSV', style: TextStyle(color: _itemsActuales.isEmpty ? Colors.white24 : const Color(0xFF3B82F6), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _itemsActuales.isEmpty ? Colors.white12 : const Color(0xFF3B82F6), width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoCard(double costoTotal, int totalItems) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.3),
            const Color(0xFF6D28D9).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Costo Total Estimado',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${costoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalItems items en inventario',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
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

  // ==========================================
  // IMPORTAR
  // ==========================================

  void _mostrarOpcionesImportar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Importar Inventario',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'La IA extraerá los items automáticamente',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              // Opción 1: Foto/Imagen
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF8B5CF6)),
                ),
                title: const Text('Desde foto o imagen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Sube una foto de tabla, lista o captura de Excel', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _importarDesdeImagen();
                },
              ),
              const SizedBox(height: 8),
              // Opción 2: Texto copiado
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.content_paste, color: Color(0xFF10B981)),
                ),
                title: const Text('Desde texto / tabla copiada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Pega el contenido de una tabla o lista', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _importarDesdeTexto();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importarDesdeImagen() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

    if (!mounted) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF1A1F3A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            SizedBox(height: 16),
            Text('Analizando imagen con IA...', style: TextStyle(color: Colors.white)),
            SizedBox(height: 4),
            Text('Extrayendo items del inventario', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final items = await _service.importarDesdeImagen(
        imageBytes: result.files.first.bytes!,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (items.isEmpty) {
        _mostrarSnack('No se encontraron items en la imagen', Colors.orange);
        return;
      }

      _mostrarPreviewImportacion(items);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarSnack('Error al procesar imagen: $e', Colors.red);
    }
  }

  void _importarDesdeTexto() {
    final textoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0E27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool procesando = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                  const Text('Pegar tabla o lista', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Pega el contenido copiado de Excel, Google Sheets, o escribe una lista',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textoCtrl,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ej:\nResistencias 10kΩ, 50 unidades, S/0.10 c/u\nArduino Uno, 2 unidades, S/35.00\nLED rojo, 100 unidades, S/0.05',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1A1F3A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: procesando ? null : () async {
                        if (textoCtrl.text.trim().isEmpty) return;
                        setModalState(() => procesando = true);

                        try {
                          final items = await _service.importarDesdeTexto(
                            textoTabla: textoCtrl.text.trim(),
                          );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (items.isEmpty) {
                            _mostrarSnack('No se pudieron extraer items del texto', Colors.orange);
                            return;
                          }

                          _mostrarPreviewImportacion(items);
                        } catch (e) {
                          setModalState(() => procesando = false);
                          _mostrarSnack('Error: $e', Colors.red);
                        }
                      },
                      icon: procesando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                      label: Text(
                        procesando ? 'Procesando con IA...' : 'Extraer items con IA',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Mostrar preview de items extraídos antes de confirmar
  void _mostrarPreviewImportacion(List<Map<String, dynamic>> items) {
    // Track cuáles se van a importar
    final seleccionados = List<bool>.filled(items.length, true);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final countSeleccionados = seleccionados.where((s) => s).length;

            return AlertDialog(
              backgroundColor: const Color(0xFF0D1229),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${items.length} items encontrados',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final esFisico = item['tipo'] == 'fisico';

                    return CheckboxListTile(
                      value: seleccionados[index],
                      onChanged: (v) => setDialogState(() => seleccionados[index] = v ?? true),
                      activeColor: const Color(0xFF8B5CF6),
                      title: Text(
                        item['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            esFisico ? Icons.inventory_2 : Icons.cloud,
                            color: esFisico ? Colors.orange : Colors.cyan,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'x${item['cantidad'] ?? 1}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          if (item['costoEstimado'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'S/ ${item['costoEstimado']}',
                              style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11),
                            ),
                          ],
                          if (item['categoria'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(item['categoria'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                  onPressed: () async {
                    Navigator.pop(ctx);

                    final itemsParaGuardar = <Map<String, dynamic>>[];
                    for (int i = 0; i < items.length; i++) {
                      if (seleccionados[i]) itemsParaGuardar.add(items[i]);
                    }

                    if (itemsParaGuardar.isEmpty) return;

                    final count = await _service.guardarItemsParseados(
                      proyectoId: widget.proyectoId,
                      items: itemsParaGuardar,
                      creadoPor: FirebaseAuth.instance.currentUser?.uid,
                    );

                    _mostrarSnack('$count items importados al inventario', const Color(0xFF10B981));
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: Text(
                    'Importar $countSeleccionados items',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // EXPORTAR
  // ==========================================

  void _exportarCSV() {
    final csv = _service.exportarACSV(_itemsActuales);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'inventario_${DateTime.now().millisecondsSinceEpoch}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    _mostrarSnack('Inventario exportado como CSV', const Color(0xFF3B82F6));
  }

  void _mostrarSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ==========================================
  // FILTROS Y LISTA
  // ==========================================

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Todos', 'todos', _filtroTipo, (v) => setState(() => _filtroTipo = v)),
          const SizedBox(width: 8),
          _buildFilterChip('Físico', 'fisico', _filtroTipo, (v) => setState(() => _filtroTipo = v)),
          const SizedBox(width: 8),
          _buildFilterChip('Digital', 'digital', _filtroTipo, (v) => setState(() => _filtroTipo = v)),
          const SizedBox(width: 16),
          const Text('|', style: TextStyle(color: Colors.white24)),
          const SizedBox(width: 16),
          ...InventarioItem.getEstados().entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildFilterChip(
              e.value, e.key, _filtroEstado,
              (v) => setState(() => _filtroEstado = _filtroEstado == v ? 'todos' : v),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue, Function(String) onSelect) {
    final selected = currentValue == value;
    return FilterChip(
      label: Text(label, style: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontSize: 12,
      )),
      selected: selected,
      onSelected: (_) => onSelect(value),
      backgroundColor: const Color(0xFF1A1F3A),
      selectedColor: const Color(0xFF8B5CF6),
      checkmarkColor: Colors.white,
      side: BorderSide(color: selected ? const Color(0xFF8B5CF6) : Colors.white24),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildTablaInventario(List<InventarioItem> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: Theme.of(context).copyWith(
            dataTableTheme: DataTableThemeData(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1A1F3A)),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFF252B4A);
                }
                return Colors.transparent;
              }),
              dividerThickness: 0.5,
            ),
          ),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 12,
            headingRowHeight: 42,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 52,
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            columns: const [
              DataColumn(label: Text('Nombre', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tipo', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Categoría', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Cant.', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('Estado', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Costo Unit.', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('Subtotal', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('Proveedor', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              DataColumn(label: Text('', style: TextStyle(color: Colors.white70, fontSize: 12))),
            ],
            rows: items.map((item) {
              final esFisico = item.tipo == 'fisico';
              final estadoColor = _getEstadoColor(item.estado);
              final subtotal = (item.costoEstimado ?? 0) * item.cantidad;
              final allCategorias = {...InventarioItem.getCategoriasFisicas(), ...InventarioItem.getCategoriasDigitales()};

              return DataRow(
                cells: [
                  // Nombre
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          esFisico ? Icons.inventory_2 : Icons.cloud,
                          color: esFisico ? Colors.orange : Colors.cyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(item.nombre, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    onTap: () => _mostrarFormulario(item: item),
                  ),
                  // Tipo
                  DataCell(Text(
                    esFisico ? 'Físico' : 'Digital',
                    style: TextStyle(color: esFisico ? Colors.orange.shade200 : Colors.cyan.shade200, fontSize: 12),
                  )),
                  // Categoría
                  DataCell(Text(
                    allCategorias[item.categoria] ?? item.categoria,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  )),
                  // Cantidad
                  DataCell(Text(
                    '${item.cantidad}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  )),
                  // Estado
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      InventarioItem.getEstados()[item.estado] ?? item.estado,
                      style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )),
                  // Costo Unitario
                  DataCell(Text(
                    item.costoEstimado != null ? 'S/ ${item.costoEstimado!.toStringAsFixed(2)}' : '-',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  )),
                  // Subtotal
                  DataCell(Text(
                    subtotal > 0 ? 'S/ ${subtotal.toStringAsFixed(2)}' : '-',
                    style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w600),
                  )),
                  // Proveedor
                  DataCell(Text(
                    item.proveedorFuente ?? '-',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  )),
                  // Acciones
                  DataCell(
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
                      color: const Color(0xFF1A1F3A),
                      onSelected: (value) {
                        if (value == 'editar') _mostrarFormulario(item: item);
                        if (value == 'eliminar') _confirmarEliminar(item);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'editar', child: Text('Editar', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Sin items en el inventario', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _mostrarFormulario(),
            icon: const Icon(Icons.add, color: Color(0xFF8B5CF6)),
            label: const Text('Agregar item', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _mostrarOpcionesImportar,
            icon: const Icon(Icons.upload_file, color: Color(0xFF10B981), size: 18),
            label: const Text('Importar desde foto o tabla', style: TextStyle(color: Color(0xFF10B981), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  List<InventarioItem> _aplicarFiltros(List<InventarioItem> items) {
    return items.where((item) {
      if (_filtroTipo != 'todos' && item.tipo != _filtroTipo) return false;
      if (_filtroEstado != 'todos' && item.estado != _filtroEstado) return false;
      return true;
    }).toList();
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'disponible': return Colors.green;
      case 'adquirido': return Colors.blue;
      case 'pendiente': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _confirmarEliminar(InventarioItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Eliminar item', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${item.nombre}" del inventario?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _service.eliminarItem(widget.proyectoId, item.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _mostrarFormulario({InventarioItem? item}) {
    final esEdicion = item != null;
    final nombreCtrl = TextEditingController(text: item?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: item?.descripcion ?? '');
    final cantidadCtrl = TextEditingController(text: (item?.cantidad ?? 1).toString());
    final costoCtrl = TextEditingController(text: item?.costoEstimado?.toString() ?? '');
    final proveedorCtrl = TextEditingController(text: item?.proveedorFuente ?? '');
    final notasCtrl = TextEditingController(text: item?.notas ?? '');

    String tipo = item?.tipo ?? 'fisico';
    String categoria = item?.categoria ?? 'otro';
    String estado = item?.estado ?? 'pendiente';

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
            final categorias = tipo == 'fisico'
                ? InventarioItem.getCategoriasFisicas()
                : InventarioItem.getCategoriasDigitales();
            if (!categorias.containsKey(categoria)) {
              categoria = 'otro';
            }

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
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      esEdicion ? 'Editar Item' : 'Nuevo Item',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nombreCtrl, 'Nombre del item', Icons.label),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionButton('Físico', Icons.inventory_2, tipo == 'fisico', () {
                            setModalState(() => tipo = 'fisico');
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOptionButton('Digital', Icons.cloud, tipo == 'digital', () {
                            setModalState(() => tipo = 'digital');
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown('Categoría', categoria, categorias, (v) {
                      setModalState(() => categoria = v!);
                    }),
                    const SizedBox(height: 12),
                    _buildDropdown('Estado', estado, InventarioItem.getEstados(), (v) {
                      setModalState(() => estado = v!);
                    }),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(cantidadCtrl, 'Cantidad', Icons.numbers, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(costoCtrl, 'Costo (S/)', Icons.attach_money, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(proveedorCtrl, 'Proveedor / Fuente', Icons.store),
                    const SizedBox(height: 12),
                    _buildTextField(descripcionCtrl, 'Descripción', Icons.description, maxLines: 2),
                    const SizedBox(height: 12),
                    _buildTextField(notasCtrl, 'Notas', Icons.note, maxLines: 2),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nombreCtrl.text.trim().isEmpty) return;

                          final datos = {
                            'nombre': nombreCtrl.text.trim(),
                            'descripcion': descripcionCtrl.text.trim(),
                            'tipo': tipo,
                            'categoria': categoria,
                            'cantidad': int.tryParse(cantidadCtrl.text) ?? 1,
                            'estado': estado,
                            'costoEstimado': double.tryParse(costoCtrl.text),
                            'proveedorFuente': proveedorCtrl.text.trim().isEmpty ? null : proveedorCtrl.text.trim(),
                            'notas': notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                          };

                          if (esEdicion) {
                            await _service.actualizarItem(widget.proyectoId, item.id, datos);
                          } else {
                            final nuevoItem = InventarioItem(
                              id: '',
                              nombre: datos['nombre'] as String,
                              descripcion: datos['descripcion'] as String? ?? '',
                              tipo: tipo,
                              categoria: categoria,
                              cantidad: datos['cantidad'] as int,
                              estado: estado,
                              costoEstimado: datos['costoEstimado'] as double?,
                              proveedorFuente: datos['proveedorFuente'] as String?,
                              notas: datos['notas'] as String?,
                              creadoPor: FirebaseAuth.instance.currentUser?.uid,
                              fechaCreacion: DateTime.now(),
                            );
                            await _service.agregarItem(widget.proyectoId, nuevoItem);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(
                          esEdicion ? 'Guardar cambios' : 'Agregar al inventario',
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

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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

  Widget _buildOptionButton(String label, IconData icon, bool selected, VoidCallback onTap) {
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
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, Map<String, String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1F3A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      items: options.entries.map((e) => DropdownMenuItem(
        value: e.key,
        child: Text(e.value),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
