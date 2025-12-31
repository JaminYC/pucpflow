# Guía de Almacenamiento de Conversaciones ADAN

## Estado Actual

**NO se están guardando las conversaciones en Firestore.**

### Datos en Memoria (se pierden al cerrar la app):
- `_history`: Historial visual (List<String>)
- `_conversationHistory`: Últimos mensajes para contexto IA (List<Map>)

## Implementación de Persistencia

### Estructura de Firestore Propuesta:

```
users/
  {userId}/
    adan_conversations/
      {conversationId}/
        - createdAt: Timestamp
        - lastMessageAt: Timestamp
        - messageCount: number
        - title: string (generado por IA o primeras palabras)

        messages/
          {messageId}/
            - role: "user" | "assistant"
            - content: string
            - timestamp: Timestamp
            - metadata: {
                userId: string,
                audioPlayed: boolean,
                context: { proyectos, tareas, skills } // opcional
              }
```

### Paso 1: Modificar Cloud Function para Guardar

```javascript
// En functions/index.js, dentro de adanChat

exports.adanChat = onCall({ secrets:[openaiKey], timeoutSeconds:60, cors: true }, async (request) => {
  try {
    const text = (request.data?.text || "").toString().slice(0, 4000);
    const userId = request.data?.userId;
    const history = Array.isArray(request.data?.history) ? request.data.history : [];
    const conversationId = request.data?.conversationId || null; // nuevo parámetro

    if (!text) return { reply: "¿Qué necesitas?" };
    if (!userId) return { reply: "Necesito que inicies sesión para poder ayudarte mejor." };

    const db = admin.firestore();
    const openai = new OpenAI({ apiKey: openaiKey.value() });

    // ... (código existente para obtener contexto) ...

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.7,
      messages,
      max_tokens: 500
    });

    const reply = completion.choices[0]?.message?.content?.trim() || "…";

    // ===== GUARDAR CONVERSACIÓN EN FIRESTORE =====
    let activeConversationId = conversationId;

    if (!activeConversationId) {
      // Crear nueva conversación
      const newConvRef = await db.collection('users').doc(userId)
        .collection('adan_conversations').add({
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
          messageCount: 0,
          title: text.substring(0, 50) // Primeras palabras como título
        });
      activeConversationId = newConvRef.id;
    }

    const conversationRef = db.collection('users').doc(userId)
      .collection('adan_conversations').doc(activeConversationId);

    // Guardar mensaje del usuario
    await conversationRef.collection('messages').add({
      role: 'user',
      content: text,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: { userId }
    });

    // Guardar respuesta de ADAN
    await conversationRef.collection('messages').add({
      role: 'assistant',
      content: reply,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: {
        userId,
        context: {
          proyectosActivos: proyectos.length,
          tareasPendientes,
          tareasCompletadas
        }
      }
    });

    // Actualizar metadata de conversación
    await conversationRef.update({
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      messageCount: admin.firestore.FieldValue.increment(2) // user + assistant
    });

    logger.info(`ADAN respondió a ${userData.displayName}: ${reply.substring(0, 100)}...`);

    return {
      reply,
      conversationId: activeConversationId, // devolver el ID
      contexto: {
        proyectosActivos: proyectos.length,
        tareasPendientes,
        tareasCompletadas
      }
    };
  } catch (e) {
    logger.error("adanChat error", e);
    return {
      error: "openai_failed",
      message: "Lo siento, tuve un problema técnico. Intenta de nuevo.",
      reply: "Disculpa, tuve un problema al procesar tu solicitud. ¿Podrías repetirlo?"
    };
  }
});
```

### Paso 2: Modificar Frontend para Usar Persistencia

```dart
// En AsistentePage.dart

class _AsistentePageState extends State<AsistentePage> {
  // ... (código existente) ...

  String? _currentConversationId; // nuevo campo

  @override
  void initState() {
    super.initState();
    _initEverything();
    _loadOrCreateConversation(); // nuevo
  }

  Future<void> _loadOrCreateConversation() async {
    if (_userId == null) return;

    final db = FirebaseFirestore.instance;

    // Buscar conversación activa (menos de 24h)
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    final snapshot = await db
      .collection('users')
      .doc(_userId)
      .collection('adan_conversations')
      .where('lastMessageAt', isGreaterThan: yesterday)
      .orderBy('lastMessageAt', descending: true)
      .limit(1)
      .get();

    if (snapshot.docs.isNotEmpty) {
      // Continuar conversación existente
      _currentConversationId = snapshot.docs.first.id;
      await _loadConversationHistory(_currentConversationId!);
    } else {
      // Nueva conversación (se creará al enviar primer mensaje)
      _currentConversationId = null;
    }
  }

  Future<void> _loadConversationHistory(String conversationId) async {
    if (_userId == null) return;

    final db = FirebaseFirestore.instance;

    final messagesSnapshot = await db
      .collection('users')
      .doc(_userId)
      .collection('adan_conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .get();

    setState(() {
      _history.clear();
      _conversationHistory.clear();

      for (var doc in messagesSnapshot.docs) {
        final role = doc.data()['role'];
        final content = doc.data()['content'];

        if (role == 'user') {
          _history.add('Tú: $content');
          _conversationHistory.add({'role': 'user', 'content': content});
        } else {
          _history.add('ADAN: $content');
          _conversationHistory.add({'role': 'assistant', 'content': content});
        }
      }
    });
  }

  Future<String> _callAdan(String text) async {
    debugPrint('📞 _callAdan iniciado');

    if (_userId == null) {
      debugPrint('❌ userId es null');
      return "Por favor, inicia sesión para que pueda ayudarte mejor.";
    }

    try {
      debugPrint('🔥 Llamando a Cloud Function adanChat...');
      final callable = functions.httpsCallable('adanChat');

      final payload = {
        'text': text,
        'userId': _userId,
        'history': _conversationHistory,
        'conversationId': _currentConversationId // nuevo parámetro
      };

      debugPrint('📦 Payload: ${payload.toString().substring(0, 100)}...');

      final res = await callable.call(payload);

      debugPrint('📥 Respuesta recibida: ${res.data}');

      final data = Map<String, dynamic>.from(res.data as Map);
      final reply = (data['reply'] as String?) ?? '…';

      // Guardar conversationId para siguientes mensajes
      if (data['conversationId'] != null) {
        _currentConversationId = data['conversationId'];
      }

      debugPrint('💬 Reply extraído: $reply');

      return reply;
    } catch (e, stack) {
      debugPrint('❌ Error en _callAdan: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  // Botón para nueva conversación
  void _startNewConversation() {
    setState(() {
      _currentConversationId = null;
      _history.clear();
      _conversationHistory.clear();
    });
  }
}
```

### Paso 3: UI para Ver Conversaciones Pasadas

```dart
// Agregar botón en AppBar
IconButton(
  icon: const Icon(Icons.history),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationHistoryPage(userId: _userId!),
      ),
    );
  },
  tooltip: 'Ver historial',
)
```

## Ventajas de Guardar Conversaciones

1. **Persistencia**: No pierdes el contexto al cerrar la app
2. **Historial**: Puedes revisar conversaciones pasadas
3. **Análisis**: Ver patrones en tus consultas
4. **Continuidad**: Retomar conversaciones después de días
5. **Búsqueda**: Buscar información en conversaciones antiguas

## Costos de Firestore

- **Reads**: ~$0.06 por 100,000 lecturas
- **Writes**: ~$0.18 por 100,000 escrituras
- **Storage**: ~$0.18 por GB/mes

Para uso personal: **prácticamente gratis** (dentro del plan gratuito).

## Siguiente Paso

¿Quieres que implemente el sistema de persistencia de conversaciones ahora?
