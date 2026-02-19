import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Pantalla de administrador para ver y editar fechas de nacimiento de usuarios.
/// Solo accesible desde el Drawer para el CEO/admin.
class AdminCumpleaniosPage extends StatefulWidget {
  const AdminCumpleaniosPage({super.key});

  @override
  State<AdminCumpleaniosPage> createState() => _AdminCumpleaniosPageState();
}

class _AdminCumpleaniosPageState extends State<AdminCumpleaniosPage> {
  final _searchCtrl = TextEditingController();
  String _filtro = '';
  bool _soloSinFecha = false;

  static const _bg = Color(0xFF050915);
  static const _card = Color(0xFF0E1B2D);
  static const _purple = Color(0xFF8B5CF6);

  /// Elimina tildes y convierte a minúsculas para comparación robusta
  String _normalizar(dynamic texto) {
    var s = texto.toString().toLowerCase();
    const conTilde    = 'áéíóúàèìòùäëïöüâêîôûãõñç';
    const sinTilde    = 'aeiouaeiouaeiouaeiouaoeouaeonc';
    for (var i = 0; i < conTilde.length; i++) {
      s = s.replaceAll(conTilde[i], sinTilde[i]);
    }
    return s;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Cumpleanos — Admin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _purple.withValues(alpha: 0.3)),
        ),
        actions: [
          // Toggle solo sin fecha
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                'Sin fecha',
                style: TextStyle(
                  color: _soloSinFecha ? Colors.white : Colors.white54,
                  fontSize: 11,
                ),
              ),
              selected: _soloSinFecha,
              onSelected: (v) => setState(() => _soloSinFecha = v),
              selectedColor: _purple.withValues(alpha: 0.3),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              side: BorderSide(
                color: _soloSinFecha ? _purple : Colors.white24,
              ),
              showCheckmark: false,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar usuario por nombre o correo...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4), size: 20),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.4), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filtro = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0E1B2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _purple),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _purple),
                  );
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Sin usuarios', style: TextStyle(color: Colors.white38)),
                  );
                }

                // Ordenar en cliente (evita excluir docs sin campo 'nombre')
                final allDocs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final da = a.data() as Map<String, dynamic>;
                    final db = b.data() as Map<String, dynamic>;
                    final na = (da['nombre'] ?? da['full_name'] ?? da['displayName'] ?? '').toString().toLowerCase();
                    final nb = (db['nombre'] ?? db['full_name'] ?? db['displayName'] ?? '').toString().toLowerCase();
                    return na.compareTo(nb);
                  });

                // Filtrar con normalización de tildes
                var docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Buscar en nombre, full_name, displayName, correoElectronico y email
                  final nombre = _normalizar(data['nombre'] ?? data['full_name'] ?? data['displayName'] ?? '');
                  final correo = _normalizar(data['correoElectronico'] ?? data['email'] ?? '');
                  final tieneFecha = data['fechaNacimiento'] != null;

                  if (_soloSinFecha && tieneFecha) return false;
                  if (_filtro.isEmpty) return true;
                  final q = _normalizar(_filtro);
                  return nombre.contains(q) || correo.contains(q);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 40, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 12),
                        Text(
                          _soloSinFecha ? 'Todos tienen fecha registrada!' : 'Sin resultados',
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _UserBirthdayTile(
                      uid: doc.id,
                      data: data,
                      onUpdated: () => setState(() {}),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile de usuario con selector de fecha ───────────────────────────────────
class _UserBirthdayTile extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onUpdated;

  const _UserBirthdayTile({
    required this.uid,
    required this.data,
    required this.onUpdated,
  });

  @override
  State<_UserBirthdayTile> createState() => _UserBirthdayTileState();
}

class _UserBirthdayTileState extends State<_UserBirthdayTile> {
  bool _saving = false;
  static const _purple = Color(0xFF8B5CF6);
  static const _card = Color(0xFF0E1B2D);

  DateTime? _getFechaNacimiento() {
    final raw = widget.data['fechaNacimiento'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  bool get _esCumpleaniosHoy {
    final bd = _getFechaNacimiento();
    if (bd == null) return false;
    final now = DateTime.now();
    return bd.day == now.day && bd.month == now.month;
  }

  Future<void> _seleccionarFecha() async {
    final actual = _getFechaNacimiento();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 5),
      helpText: 'Fecha de nacimiento',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _purple,
            onPrimary: Colors.white,
            surface: Color(0xFF1A1F3A),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'fechaNacimiento': Timestamp.fromDate(picked)});
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fecha guardada: ${DateFormat('dd/MM/yyyy').format(picked)}',
            ),
            backgroundColor: _purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _eliminarFecha() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0E1B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar fecha', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Quitar la fecha de nacimiento de ${widget.data['nombre'] ?? 'este usuario'}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({'fechaNacimiento': FieldValue.delete()});
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.data['nombre'] ?? widget.data['full_name'] ?? widget.data['displayName'] ?? 'Sin nombre';
    final correo = widget.data['correoElectronico'] ?? widget.data['email'] ?? '';
    final foto = (widget.data['fotoPerfil'] ?? widget.data['photoURL']) as String?;
    final bd = _getFechaNacimiento();
    final tieneFecha = bd != null;
    final esCumple = _esCumpleaniosHoy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: esCumple
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
            : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esCumple
              ? _purple.withValues(alpha: 0.4)
              : tieneFecha
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1F3A),
              border: Border.all(
                color: esCumple ? const Color(0xFFFFD700) : Colors.white12,
                width: esCumple ? 2 : 1,
              ),
            ),
            child: foto != null
                ? ClipOval(
                    child: Image.network(
                      foto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(nombre),
                    ),
                  )
                : _buildInitials(nombre),
          ),

          const SizedBox(width: 12),

          // Datos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esCumple)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B9D).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'HOY',
                          style: TextStyle(
                            color: Color(0xFFFF6B9D),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                if (correo.isNotEmpty)
                  Text(
                    correo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      tieneFecha ? Icons.cake : Icons.cake_outlined,
                      size: 13,
                      color: tieneFecha
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tieneFecha
                          ? DateFormat('dd/MM/yyyy').format(bd)
                          : 'Sin fecha registrada',
                      style: TextStyle(
                        color: tieneFecha
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.25),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Acciones
          if (_saving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _purple),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Editar fecha
                GestureDetector(
                  onTap: _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _purple.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.edit_calendar,
                      color: _purple,
                      size: 16,
                    ),
                  ),
                ),

                // Eliminar fecha (solo si tiene)
                if (tieneFecha) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _eliminarFecha,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(String nombre) {
    return Center(
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
