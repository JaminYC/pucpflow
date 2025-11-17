import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/skills_service.dart';
import '../models/skill_model.dart';
import '../models/cv_profile_model.dart';
import 'review_skills_page.dart';

class UploadCVPage extends StatefulWidget {
  const UploadCVPage({super.key});

  @override
  State<UploadCVPage> createState() => _UploadCVPageState();
}

class _UploadCVPageState extends State<UploadCVPage> {
  final SkillsService _skillsService = SkillsService();

  bool _isProcessing = false;
  String? _fileName;
  String? _errorMessage;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mapeo de Habilidades desde CV',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con icono
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                const Text(
                  'Extrae tus habilidades automáticamente',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Descripción
                Text(
                  'Sube tu CV en formato PDF y nuestra IA extraerá automáticamente tus habilidades profesionales',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Botón de carga
                if (!_isProcessing)
                  ElevatedButton.icon(
                    onPressed: _pickAndProcessCV,
                    icon: const Icon(Icons.upload_file, size: 28),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Seleccionar CV (PDF)',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                // Estado de procesamiento
                if (_isProcessing) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.shade400.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          color: Colors.blue.shade400,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getProcessingMessage(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_fileName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _fileName!,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Mensaje de error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade400,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade200,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade400, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Cómo funciona',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem('1. Selecciona tu CV en formato PDF'),
                      _buildInfoItem('2. La IA extrae automáticamente tus habilidades'),
                      _buildInfoItem('3. Revisa y confirma las habilidades detectadas'),
                      _buildInfoItem('4. Ajusta los niveles de competencia (1-10)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade400, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProcessingMessage() {
    if (_progress < 0.3) {
      return 'Leyendo archivo PDF...';
    } else if (_progress < 0.6) {
      return 'Extrayendo información con IA...';
    } else if (_progress < 0.9) {
      return 'Mapeando habilidades...';
    } else {
      return 'Finalizando...';
    }
  }

  Future<void> _pickAndProcessCV() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    try {
      // 1. Seleccionar archivo PDF
      setState(() => _progress = 0.1);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Importante para web
      );

      if (result == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'No se seleccionó ningún archivo';
        });
        return;
      }

      setState(() {
        _fileName = result.files.single.name;
        _progress = 0.2;
      });

      // 2. Convertir a base64
      String cvBase64;
      if (kIsWeb) {
        // Web: usar bytes
        final bytes = result.files.single.bytes;
        if (bytes == null) {
          throw Exception('No se pudo leer el archivo');
        }
        cvBase64 = base64Encode(bytes);
      } else {
        // Móvil/Desktop: usar bytes directamente
        final bytes = result.files.single.bytes;
        if (bytes == null) {
          throw Exception('No se pudo leer el archivo');
        }
        cvBase64 = base64Encode(bytes);
      }

      setState(() => _progress = 0.4);

      // 3. Llamar a Cloud Function para extraer CV
      final result2 = await _skillsService.extractCVProfile(cvBase64);

      if (result2 == null) {
        throw Exception('Error procesando el CV. Intenta de nuevo.');
      }

      setState(() => _progress = 0.8);

      final profile = result2['profile'] as CVProfileModel;
      final skills = result2['skills'] as List<MappedSkill>;

      setState(() => _progress = 1.0);

      // 4. Navegar a página de revisión
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewSkillsPage(
            profile: profile,
            mappedSkills: skills,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error: ${e.toString()}';
        _progress = 0.0;
      });
    }
  }
}
