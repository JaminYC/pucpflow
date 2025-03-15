import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pucpflow/features/user_auth/Usuario/UserModel.dart';

class OpenAIAssistantService {
  /// Llama a la función de Firebase para generar habilidades y resumen con IA
  Future<void> generarResumenYHabilidades(UserModel user) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('procesarPerfilUsuario');

      final result = await callable.call({
        "nombre": user.nombre,
        "tipoPersonalidad": user.tipoPersonalidad,
        "tareasHechas": user.tareasHechas,
        "estadoAnimo": user.estadoAnimo,
        "nivelEstres": user.nivelEstres,
      });

      final data = result.data;

      if (data != null && data["habilidades"] != null && data["resumenIA"] != null) {
        final habilidades = Map<String, int>.from(data["habilidades"]);
        final resumenIA = data["resumenIA"];

        await FirebaseFirestore.instance.collection("users").doc(user.id).update({
          "habilidades": habilidades,
          "resumenIA": resumenIA,
        });

        print("✅ Perfil IA actualizado para ${user.nombre}");
      } else {
        print("⚠️ Respuesta de IA incompleta o inesperada.");
      }
    } catch (e) {
      print("❌ Error llamando a procesarPerfilUsuario: $e");
    }
  }
}
