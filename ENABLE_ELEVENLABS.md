# Guía para Reactivar ElevenLabs en ADAN

## Estado Actual (Actualizado 2025-12-13)
- ✅ **CORS CORREGIDO** - El nombre de función correcto es `adanSpeak` (no `generateSpeechElevenLabs`)
- ✅ AsistentePageNew.dart actualizado con integración correcta
- ⚠️ Verificar estado de API Key de ElevenLabs (puede estar bloqueada)
- ✅ TTS Nativo funcionando como fallback

## Pasos para Reactivar ElevenLabs

### 1. Resolver el Bloqueo de ElevenLabs

**Opción A: Comprar Plan de Pago**
```
1. Ir a https://elevenlabs.io
2. Iniciar sesión
3. Comprar plan (desde $5/mes)
4. El bloqueo se levanta automáticamente
```

**Opción B: Contactar Soporte**
```
Email: support@elevenlabs.io
Asunto: "Free tier access blocked - legitimate developer"
Mensaje: "Hi, I'm a developer building a voice assistant. My free tier access was blocked for unusual activity. I'm not using VPN/proxy or multiple accounts. Could you please review my account? Thank you."
```

**Opción C: Nueva API Key** (solo si no usas VPN)
```
1. Crear nueva cuenta con email diferente
2. Ir a Settings > API Keys
3. Generar nuevo API key
4. Actualizar en Firebase (paso 2 abajo)
```

### 2. Actualizar API Key en Firebase (si creaste nueva)

```bash
# En terminal de Firebase
firebase functions:secrets:set ELEVENLABS_API_KEY

# Cuando te pida el valor, pega tu nuevo API key
# Luego despliega las funciones
firebase deploy --only functions:adanSpeak
```

### 3. Modificar AsistentePage.dart

Reemplazar el método `_speak()` con esta versión que intenta ElevenLabs primero:

```dart
Future<void> _speak(String text) async {
  // Detener cualquier audio/TTS anterior primero
  await _audioPlayer.stop();
  await _tts.stop();

  // Guardar mensaje completo para referencia
  setState(() {
    _currentFullMessage = text;
  });

  final polished = ttsPolish(text);

  debugPrint('📝 Mensaje completo: "$text"');
  debugPrint('🧹 Mensaje limpio para TTS: "$polished"');

  // ===== INTENTAR ELEVENLABS PRIMERO =====
  try {
    debugPrint('🔊 Intentando ElevenLabs (voz: $_elevenLabsVoiceId)...');
    final callable = functions.httpsCallable('adanSpeak');
    final res = await callable.call({
      'text': polished,
      'voiceId': _elevenLabsVoiceId
    });

    if (res.data['error'] == null && res.data['audioBase64'] != null) {
      final audioBase64 = res.data['audioBase64'];
      final bytes = base64Decode(audioBase64);

      debugPrint('✅ ElevenLabs audio recibido: ${bytes.length} bytes');

      // Asegurar que el audio anterior está detenido
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 150));

      setState(() {
        _isPlaying = true;
      });

      await _audioPlayer.play(BytesSource(bytes));

      debugPrint('🎵 Reproduciendo con ElevenLabs (voz: $_elevenLabsVoiceId)');
      return; // Salir exitosamente
    } else {
      debugPrint('⚠️ ElevenLabs devolvió error: ${res.data['error']}');
      throw Exception('ElevenLabs failed: ${res.data['error']}');
    }
  } catch (e) {
    debugPrint('⚠️ Error con ElevenLabs, usando TTS nativo: $e');
  }

  // ===== FALLBACK: TTS NATIVO =====
  try {
    debugPrint('🔊 Usando TTS nativo como fallback...');

    setState(() {
      _isPlaying = true;
    });

    // Asegurar configuración de voz
    if (_selectedVoice != null) {
      await _tts.setVoice({
        'name': _selectedVoice!['name']!,
        'locale': _selectedVoice!['locale']!,
      });
    }
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);

    // Reproducir con TTS
    await _tts.speak(polished);
    debugPrint('🎵 TTS nativo iniciado');
  } catch (e) {
    debugPrint('❌ Error en TTS nativo: $e');
    setState(() {
      _isPlaying = false;
    });
  }
}
```

### 4. Verificar que Funciona

1. Hot reload/restart la app
2. Prueba con el botón "Prueba"
3. Revisa los logs:
   - Si ves: `✅ ElevenLabs audio recibido` = FUNCIONANDO ✅
   - Si ves: `⚠️ Error con ElevenLabs` = Aún bloqueado ❌

```bash
# Ver logs en tiempo real
flutter run -d chrome --verbose | grep -i "eleven\|tts\|audio"
```

## Verificar Estado de ElevenLabs

### Desde Firebase Functions Logs:
```bash
firebase functions:log --only adanSpeak
```

**Buscar:**
- ✅ Éxito: `Audio generado exitosamente: XXXX bytes`
- ❌ Bloqueado: `Error de ElevenLabs: 401 - unusual activity`

### Desde Consola de ElevenLabs:
1. Ir a https://elevenlabs.io/app/speech-synthesis
2. Intentar generar audio manualmente
3. Si funciona ahí, debe funcionar en la app

## Diferencias entre TTS Nativo y ElevenLabs

| Característica | TTS Nativo | ElevenLabs |
|----------------|------------|------------|
| Calidad voz | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Naturalidad | Robótica | Muy natural |
| Español | Bueno | Excelente |
| Costo | Gratis | $5+/mes |
| Latencia | Instantáneo | 1-2 segundos |
| Funciona offline | ✅ Sí | ❌ No |

## Notas Importantes

1. **No usar VPN/Proxy**: ElevenLabs bloquea VPNs en tier gratuito
2. **Una cuenta por persona**: No crear múltiples cuentas gratis
3. **Límite gratuito**: 10,000 caracteres/mes en tier gratuito
4. **Actualizar Secret**: Si cambias API key, debes redesplegar la función

## Troubleshooting

### Error persiste después de pagar:
```bash
# Regenerar API key en elevenlabs.io
# Actualizar secret
firebase functions:secrets:set ELEVENLABS_API_KEY
firebase deploy --only functions:adanSpeak
```

### Audio llega pero no reproduce:
- Verificar que `_audioPlayer.stop()` se llama primero
- Aumentar delay: `await Future.delayed(const Duration(milliseconds: 200));`

### Voz incorrecta:
- Verificar que `_elevenLabsVoiceId` se pasa correctamente
- Logs deben mostrar: `voz: pNInz6obpgDQGcFmaJgB` (o el ID que elegiste)
