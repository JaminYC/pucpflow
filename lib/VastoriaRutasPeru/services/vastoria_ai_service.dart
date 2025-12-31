import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de IA para VASTORIA Rutas Perú
///
/// Proporciona:
/// - Chat conversacional sobre lugares turísticos
/// - Recomendaciones personalizadas
/// - Generación de itinerarios inteligentes
/// - Información cultural e histórica enriquecida
class VastoriaAIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Historial de conversación por sesión
  final List<Map<String, String>> _conversationHistory = [];

  /// ID de la conversación actual (para guardar en Firestore)
  String? _currentConversationId;

  /// Obtiene el user ID actual
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Limpia el historial de conversación
  void clearHistory() {
    _conversationHistory.clear();
    _currentConversationId = null;
  }

  /// Inicia una nueva conversación con contexto de VASTORIA
  Future<void> startNewConversation() async {
    clearHistory();

    // Crear nueva conversación en Firestore
    if (_userId != null) {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('vastoria_conversations')
          .add({
        'createdAt': FieldValue.serverTimestamp(),
        'title': 'Nueva conversación',
        'messages': [],
      });

      _currentConversationId = docRef.id;
    }
  }

  /// Envía un mensaje al asistente de IA de VASTORIA
  ///
  /// [userMessage] - Mensaje del usuario
  /// [departmentContext] - Contexto opcional del departamento actual
  /// [attractionsContext] - Contexto opcional de atracciones cercanas
  ///
  /// Returns: Respuesta de la IA
  Future<String> sendMessage({
    required String userMessage,
    String? departmentContext,
    List<String>? attractionsContext,
  }) async {
    try {
      // Construir contexto enriquecido
      String systemContext = '''
Eres ADAN, el asistente inteligente de VASTORIA - la app de turismo #1 del Perú.

Tu rol:
- Ayudar a los usuarios a descubrir y planificar viajes por Perú
- Proporcionar información cultural, histórica y práctica de lugares turísticos
- Generar itinerarios personalizados e inteligentes
- Recomendar lugares basándote en preferencias del usuario
- Dar tips de viaje, gastronomía, clima, costos aproximados

Tono: Amigable, entusiasta, conocedor de Perú. Usa emojis ocasionalmente.
''';

      if (departmentContext != null) {
        systemContext += '\n\nDepartamento actual: $departmentContext';
      }

      if (attractionsContext != null && attractionsContext.isNotEmpty) {
        systemContext += '\n\nAtracciones cercanas: ${attractionsContext.join(", ")}';
      }

      // Agregar mensaje del usuario al historial
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // Llamar a Cloud Function de OpenAI
      final callable = _functions.httpsCallable('chatWithAI');

      final result = await callable.call({
        'messages': [
          {'role': 'system', 'content': systemContext},
          ..._conversationHistory,
        ],
        'userId': _userId,
        'conversationId': _currentConversationId,
      });

      // Parsear respuesta con manejo seguro de tipos
      final data = result.data as Map<Object?, Object?>;
      final response = data['message']?.toString() ?? 'No se recibió respuesta';

      // Convertir usage de manera segura
      Map<String, dynamic>? usage;
      if (data['usage'] != null) {
        final usageData = data['usage'] as Map<Object?, Object?>;
        usage = {
          'promptTokens': usageData['promptTokens'] as int? ?? 0,
          'completionTokens': usageData['completionTokens'] as int? ?? 0,
          'totalTokens': usageData['totalTokens'] as int? ?? 0,
        };
      }

      // Agregar respuesta de la IA al historial
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
      });

      // Guardar en Firestore
      await _saveMessageToFirestore(userMessage, response, usage);

      return response;
    } catch (e) {
      print('❌ Error en VastoriaAIService.sendMessage: $e');
      rethrow;
    }
  }

  /// Genera un itinerario inteligente para múltiples lugares
  ///
  /// [places] - Lista de lugares a visitar
  /// [days] - Número de días disponibles
  /// [preferences] - Preferencias del usuario (ej: aventura, cultura, gastronomía)
  Future<Map<String, dynamic>> generateItinerary({
    required List<Map<String, dynamic>> places,
    required int days,
    List<String>? preferences,
  }) async {
    try {
      final placesText = places.map((p) => '${p['name']} (${p['type']})').join(', ');
      final prefsText = preferences?.join(', ') ?? 'ninguna en particular';

      final prompt = '''
Genera un itinerario de $days día(s) para visitar estos lugares en Perú:

$placesText

Preferencias del usuario: $prefsText

Por favor estructura el itinerario en formato JSON con:
- Día a día
- Horarios sugeridos
- Tiempo estimado en cada lugar
- Orden óptimo de visita
- Tips especiales
- Costos aproximados en soles (S/)
- Comidas recomendadas

Sé específico y práctico.
''';

      final response = await sendMessage(userMessage: prompt);

      // Intentar parsear JSON de la respuesta
      try {
        // Buscar JSON en la respuesta
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0)!;
          return json.decode(jsonString) as Map<String, dynamic>;
        }
      } catch (e) {
        print('⚠️ No se pudo parsear JSON del itinerario, devolviendo texto plano');
      }

      // Si no hay JSON, devolver respuesta como texto
      return {
        'itinerary': response,
        'days': days,
        'places': places.map((p) => p['name']).toList(),
      };
    } catch (e) {
      print('❌ Error generando itinerario: $e');
      rethrow;
    }
  }

  /// Obtiene recomendaciones personalizadas basadas en un lugar
  ///
  /// [currentPlace] - Lugar actual o seleccionado
  /// [preferences] - Preferencias del usuario
  Future<List<String>> getRecommendations({
    required String currentPlace,
    List<String>? preferences,
  }) async {
    try {
      final prefsText = preferences?.join(', ') ?? 'turismo general';

      final prompt = '''
Estoy visitando $currentPlace en Perú.

Mis intereses: $prefsText

Dame 5 recomendaciones específicas de:
1. Lugares cercanos para visitar
2. Platos típicos que debo probar
3. Actividades imperdibles
4. Tips locales importantes

Responde en formato de lista corta y directa.
''';

      final response = await sendMessage(userMessage: prompt);

      // Separar por líneas y filtrar vacías
      final recommendations = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      return recommendations;
    } catch (e) {
      print('❌ Error obteniendo recomendaciones: $e');
      return [];
    }
  }

  /// Obtiene información enriquecida de un lugar con IA
  ///
  /// [placeName] - Nombre del lugar
  /// [placeType] - Tipo (histórico, natural, cultural, etc.)
  Future<Map<String, String>> getEnrichedPlaceInfo({
    required String placeName,
    required String placeType,
  }) async {
    try {
      final prompt = '''
Dame información completa sobre $placeName en Perú (tipo: $placeType):

1. Historia breve (2-3 líneas)
2. Por qué visitarlo (2-3 líneas)
3. Mejor época para ir
4. Costo aproximado de entrada (en soles S/)
5. Tiempo recomendado de visita
6. Nivel de dificultad (fácil/medio/difícil)
7. Un dato curioso

Sé conciso y práctico. Responde en formato clave: valor.
''';

      final response = await sendMessage(userMessage: prompt);

      // Parsear respuesta en mapa
      final info = <String, String>{};
      final lines = response.split('\n');

      for (var line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().replaceAll(RegExp(r'^\d+\.\s*'), '');
            final value = parts.sublist(1).join(':').trim();
            info[key] = value;
          }
        }
      }

      return info;
    } catch (e) {
      print('❌ Error obteniendo info enriquecida: $e');
      return {};
    }
  }

  /// Guarda un mensaje en Firestore
  Future<void> _saveMessageToFirestore(
    String userMessage,
    String aiResponse,
    Map<String, dynamic>? usage,
  ) async {
    if (_userId == null || _currentConversationId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('vastoria_conversations')
          .doc(_currentConversationId)
          .update({
        'messages': FieldValue.arrayUnion([
          {
            'user': userMessage,
            'ai': aiResponse,
            'timestamp': FieldValue.serverTimestamp(),
            'usage': usage,
          }
        ]),
        'lastMessage': aiResponse,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Error guardando mensaje en Firestore: $e');
    }
  }

  /// Obtiene historial de conversaciones previas
  Stream<List<Map<String, dynamic>>> getConversationHistory() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('vastoria_conversations')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Carga una conversación previa
  Future<void> loadConversation(String conversationId) async {
    if (_userId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('vastoria_conversations')
          .doc(conversationId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final messages = data['messages'] as List<dynamic>? ?? [];

      // Reconstruir historial
      _conversationHistory.clear();
      for (var msg in messages) {
        _conversationHistory.add({'role': 'user', 'content': msg['user']});
        _conversationHistory.add({'role': 'assistant', 'content': msg['ai']});
      }

      _currentConversationId = conversationId;
    } catch (e) {
      print('❌ Error cargando conversación: $e');
    }
  }
}
