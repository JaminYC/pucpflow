import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';
import 'package:flutter/material.dart';


class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signUpWithEmailAndPassword(String email, String password, String nombre) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        UserModel newUser = UserModel(
          id: user.uid,
          nombre: nombre,
          correoElectronico: email,
          fotoPerfil: null,
          fechaNacimiento: null,
          periodoEjercicio: "Mañana",
          horaEjercicio: TimeOfDay(hour: 7, minute: 0),
          horaDormir: TimeOfDay(hour: 23, minute: 0),
          nivelActividad: 5.0,
          habitoHidratacion: "1-2 litros",
          preferenciasFitness: ["Cardio", "Pesas"],
          calidadSueno: 7.5,
          horasSueno: 7,
          usaWearables: false,
          frecuenciaInteracciones: "Moderada",
          hobbyPrincipal: "Leer",
          horaSalida: TimeOfDay(hour: 18, minute: 0),
          horaRegreso: TimeOfDay(hour: 22, minute: 0),
          actividadSocialFavorita: "Salir con amigos",
          usoRedesSociales: "1-2 horas",
          tipoEventosPreferidos: "Reuniones pequeñas",
          interaccionesSignificativas: 5,
          canalesComunicacion: ["Llamadas", "Mensajes"],
          nivelEstres: 4.5,
          estadoAnimo: "Neutral",
          estrategiasManejoEstres: "Meditación y ejercicio",
          frecuenciaAbrumamiento: 3.0,
          metodoEstudio: "Visual",
          habilidadTecnologica: 8.0,
          appsFavoritas: ["Notion", "Duolingo"],
          horasEstudio: 4,
          objetivoAprendizaje: "Mejorar habilidades técnicas",
          formatoContenidoPreferido: "Videos",
          metasPersonales: "Aprender desarrollo móvil",
          entornoEstudio: "Ambiente silencioso y organizado",
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
          historialInteracciones: [],
          preferenciasNotificaciones: {
            "email": true,
            "push": true,
            "sms": false,
          },
          tareasHechas: [],
          tareasAsignadas: [],
          tareasPorHacer: [],
          habilidades: {},
          puntosTotales: 0,
          tipoPersonalidad: null,
          resumenIA: null,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      print("Error al registrar usuario: $e");
      return null;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = credential.user;
      if (user != null) {
        return await getUserFromFirestore(user.uid);
      }
      return null;
    } catch (e) {
      print("Error en inicio de sesión: $e");
      return null;
    }
  }

  Future<UserModel?> getUserFromFirestore(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();

        if (!doc.exists) {
          UserModel newUser = UserModel(
            id: user.uid,
            nombre: googleUser.displayName ?? "Usuario",
            correoElectronico: user.email!,
            fotoPerfil: user.photoURL,
            fechaNacimiento: null,
            periodoEjercicio: "Mañana",
            horaEjercicio: TimeOfDay(hour: 7, minute: 0),
            horaDormir: TimeOfDay(hour: 23, minute: 0),
            nivelActividad: 5.0,
            habitoHidratacion: "1-2 litros",
            preferenciasFitness: ["Cardio", "Pesas"],
            calidadSueno: 7.5,
            horasSueno: 7,
            usaWearables: false,
            frecuenciaInteracciones: "Moderada",
            hobbyPrincipal: "Leer",
            horaSalida: TimeOfDay(hour: 18, minute: 0),
            horaRegreso: TimeOfDay(hour: 22, minute: 0),
            actividadSocialFavorita: "Salir con amigos",
            usoRedesSociales: "1-2 horas",
            tipoEventosPreferidos: "Reuniones pequeñas",
            interaccionesSignificativas: 5,
            canalesComunicacion: ["Llamadas", "Mensajes"],
            nivelEstres: 4.5,
            estadoAnimo: "Neutral",
            estrategiasManejoEstres: "Meditación y ejercicio",
            frecuenciaAbrumamiento: 3.0,
            metodoEstudio: "Visual",
            habilidadTecnologica: 8.0,
            appsFavoritas: ["Notion", "Duolingo"],
            horasEstudio: 4,
            objetivoAprendizaje: "Mejorar habilidades técnicas",
            formatoContenidoPreferido: "Videos",
            metasPersonales: "Aprender desarrollo móvil",
            entornoEstudio: "Ambiente silencioso y organizado",
            fechaCreacion: DateTime.now(),
            fechaActualizacion: DateTime.now(),
            historialInteracciones: [],
            preferenciasNotificaciones: {"email": true, "push": true},
            tareasHechas: [],
            tareasAsignadas: [],
            tareasPorHacer: [],
            habilidades: {},
            puntosTotales: 0,
            tipoPersonalidad: null,
            resumenIA: null,
          );

          await userRef.set(newUser.toMap());
        }
        return await getUserFromFirestore(user.uid);
      }
      return null;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      return null;
    }
  }
}
