import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'proyecto_model.dart';
import 'ProyectoDetallePage.dart';
import 'package:flutter/foundation.dart';

import 'dart:typed_data';
import 'dart:io' as io;


class ProyectosPage extends StatefulWidget {
  @override
  _ProyectosPageState createState() => _ProyectosPageState();
}

class _ProyectosPageState extends State<ProyectosPage>  with AutomaticKeepAliveClientMixin  {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  String filtroVisibilidad = "Todos";
  late VideoPlayerController _videoController;
  Map<String, String> nombresPropietarios = {};
  @override
  bool get wantKeepAlive => true; // ✅ requerido por el mixin
  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset("assets/videoPrincipalblanco.mp4")
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {}); // actualiza para mostrar el video
        _videoController.play(); // asegúrate que se reproduzca
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

Stream<List<Proyecto>> obtenerProyectos() async* {
  final prefs = await SharedPreferences.getInstance();
  final user = _auth.currentUser;
  final uidEmpresarial = prefs.getString("uid_empresarial");

  final uid = user != null ? user.uid : prefs.getString("uid_empresarial");


  if (uid == null) {
    yield [];
    return;
  }

  yield* _firestore
      .collection("proyectos")
      .where("participantes", arrayContains: uid)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Proyecto.fromJson(doc.data())).where((proyecto) {
      if (filtroVisibilidad == "Todos") return true;
      return proyecto.visibilidad == filtroVisibilidad;
    }).toList();
  });
}

Future<void> cargarNombresPropietarios(List<Proyecto> proyectos) async {
  final uids = proyectos.map((p) => p.propietario).toSet();

  for (final uid in uids) {
    if (!nombresPropietarios.containsKey(uid)) {
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        final nombre = doc.data()?["full_name"] ?? "Usuario";
        nombresPropietarios[uid] = nombre;
      } else {
        nombresPropietarios[uid] = "Usuario";
      }
    }
  }

  setState(() {}); // Redibuja la vista para mostrar los nombres
}
Future<void> _eliminarProyecto(Proyecto proyecto) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("¿Eliminar proyecto?"),
      content: Text("¿Estás seguro de que quieres eliminar \"${proyecto.nombre}\"? Esta acción no se puede deshacer."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          label: const Text("Eliminar"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await _firestore.collection("proyectos").doc(proyecto.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Proyecto \"${proyecto.nombre}\" eliminado")),
    );
  }
}

Future<String?> _subirImagenPlataforma(XFile archivo) async {
  try {
    final nombreArchivo = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child("proyecto_imagenes/$nombreArchivo.jpg");

    debugPrint('🛠️ Subiendo imagen como: $nombreArchivo.jpg');

    UploadTask uploadTask;

    if (kIsWeb) {
      final bytes = await archivo.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      uploadTask = ref.putData(bytes, metadata);
    } else {
      final file = io.File(archivo.path);
      uploadTask = ref.putFile(file);
    }

    // Espera a que termine la subida y obtén la URL
    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();

    debugPrint('✅ Imagen subida correctamente. URL: $url');
    return url;

  } catch (e) {
    debugPrint('❌ Error al subir imagen: $e');
    return null;
  }
}



Future<void> _crearProyecto(String nombre, String visibilidad, XFile? imagenFile) async {
  final prefs = await SharedPreferences.getInstance();
  final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString("uid_empresarial");
  if (uid == null) return;

  String urlImagen;

  if (imagenFile != null) {
    urlImagen = await _subirImagenPlataforma(imagenFile) ?? _imagenPorDefecto();
  } else {
    urlImagen = _imagenPorDefecto();
  }

  final nuevoProyecto = Proyecto(
    id: FirebaseFirestore.instance.collection('proyectos').doc().id,
    nombre: nombre,
    descripcion: "Descripción del proyecto...",
    fechaInicio: DateTime.now(),
    propietario: uid,
    participantes: [uid],
    visibilidad: visibilidad,
    imagenUrl: urlImagen,
  );

  await FirebaseFirestore.instance.collection("proyectos").doc(nuevoProyecto.id).set(nuevoProyecto.toJson());
}


String _imagenPorDefecto() {
  return "https://firebasestorage.googleapis.com/v0/b/pucp-flow.firebasestorage.app/o/proyecto_imagenes%2Fimagen_por_defecto.jpg?alt=media&token=67db12bf-0ce4-4697-98f3-3c6126467595";
}



void _mostrarDialogoNuevoProyecto() {
  String nombreProyecto = "";
  String visibilidad = "Privado";
  XFile? imagenSeleccionada;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Nuevo Proyecto"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: "Nombre del proyecto"),
                    onChanged: (value) => nombreProyecto = value,
                  ),
                  DropdownButton<String>(
                    value: visibilidad,
                    onChanged: (value) => setStateDialog(() => visibilidad = value!),
                    items: ["Privado", "Publico"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("Seleccionar imagen"),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateDialog(() => imagenSeleccionada = picked);
                      }
                    },
                  ),
                  if (imagenSeleccionada != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: kIsWeb
                          ? Image.network(imagenSeleccionada!.path, height: 100)
                          : Image.file(io.File(imagenSeleccionada!.path), height: 100),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nombreProyecto.isNotEmpty) {
                    await _crearProyecto(nombreProyecto, visibilidad, imagenSeleccionada);
                    Navigator.pop(context);
                  } else {
                    print("⚠️ Falta nombre o imagen");
                  }
                },
                child: const Text("Crear"),
              )
            ],
          );
        },
      );
    },
  );
}





void _editarProyecto(Proyecto proyecto) {
  final nombreController = TextEditingController(text: proyecto.nombre);
  final descripcionController = TextEditingController(text: proyecto.descripcion);
  String visibilidad = proyecto.visibilidad;
  XFile? imagenSeleccionada;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Editar Proyecto"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Nombre"),
                    controller: nombreController,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Descripción"),
                    controller: descripcionController,
                  ),
                  DropdownButton<String>(
                    value: visibilidad,
                    onChanged: (value) => setStateDialog(() => visibilidad = value!),
                    items: ["Privado", "Publico"]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text("Cambiar imagen"),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateDialog(() => imagenSeleccionada = picked);
                      }
                    },
                  ),
                  if (imagenSeleccionada != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: kIsWeb
                          ? Image.network(imagenSeleccionada!.path, height: 100)
                          : Image.file(io.File(imagenSeleccionada!.path), height: 100),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString("uid_empresarial");
                  if (uid == null) return;

                  String? imagenUrl = proyecto.imagenUrl;

                  if (imagenSeleccionada != null) {
                    imagenUrl = await _subirImagenPlataforma(imagenSeleccionada!);
                  }

                  await FirebaseFirestore.instance.collection("proyectos").doc(proyecto.id).update({
                    "nombre": nombreController.text,
                    "descripcion": descripcionController.text,
                    "visibilidad": visibilidad,
                    "imagenUrl": imagenUrl,
                    "propietario": uid,
                    "participantes": FieldValue.arrayUnion([uid]),
                  });

                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );
    },
  );
}



ImageProvider _obtenerImagenProyecto(String? url) {
  if (url != null && url.startsWith("http")) {
    return NetworkImage(url);
  } else {
    return const AssetImage("assets/FondoCoheteNegro2.jpg");
  }
}

@override
Widget build(BuildContext context) {
  super.build(context);
  final isMobile = MediaQuery.of(context).size.width < 600;
  final aspectRatio = isMobile ? 3 / 4 : 16 / 9;

  return Scaffold(
    appBar: AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text("Mis Proyectos", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      actions: [
        DropdownButton<String>(
          dropdownColor: Colors.black,
          value: filtroVisibilidad,
          onChanged: (value) => setState(() => filtroVisibilidad = value!),
          items: ["Todos", "Publico", "Privado"]
              .map((f) => DropdownMenuItem(
                  value: f, child: Text(f, style: const TextStyle(color: Colors.white))))
              .toList(),
        ),
      ],
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: _videoController.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              : Container(color: Colors.black),
        ),
        Container(color: Colors.black.withOpacity(0.3)),
        FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnapshot) {
            if (!prefsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final uidEmpresarial = prefsSnapshot.data!.getString("uid_empresarial");
            return StreamBuilder<List<Proyecto>>(
              stream: obtenerProyectos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final proyectos = snapshot.data!;

                final nuevosUids = proyectos
                    .map((p) => p.propietario)
                    .where((uid) => !nombresPropietarios.containsKey(uid))
                    .toSet();
                if (nuevosUids.isNotEmpty) {
                  Future.microtask(() => cargarNombresPropietarios(proyectos));
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: proyectos.length,
                  itemBuilder: (context, index) {
                    final proyecto = proyectos[index];
                    final isOwner = proyecto.propietario == FirebaseAuth.instance.currentUser?.uid || proyecto.propietario == uidEmpresarial;

                    final imagenUrl = (proyecto.imagenUrl != null && proyecto.imagenUrl!.isNotEmpty)
                        ? proyecto.imagenUrl!
                        : _imagenPorDefecto();

                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.white24,
                        onTap: () async {
                          _videoController.pause();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProyectoDetallePage(proyectoId: proyecto.id),
                            ),
                          );
                          _videoController.play();
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: imagenUrl,
                                placeholder: (context, url) => Image.asset('assets/FondoCoheteNegro2.jpg', fit: BoxFit.cover),
                                errorWidget: (context, url, error) => Image.asset('assets/FondoCoheteNegro2.jpg', fit: BoxFit.cover),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.bottomLeft,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            proyecto.nombre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            "${proyecto.visibilidad} · ${nombresPropietarios[proyecto.propietario] ?? 'Usuario'}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            proyecto.descripcion,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (isOwner)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.white),
                                                  onPressed: () => _editarProyecto(proyecto),
                                                  tooltip: "Editar",
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                  onPressed: () => _eliminarProyecto(proyecto),
                                                  tooltip: "Eliminar",
                                                ),
                                              ],
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
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _mostrarDialogoNuevoProyecto,
      backgroundColor: Colors.black,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}



}
