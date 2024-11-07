import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PSIDRecursosPage extends StatefulWidget {
  const PSIDRecursosPage({super.key});

  @override
  _PSIDRecursosPageState createState() => _PSIDRecursosPageState();
}

class _PSIDRecursosPageState extends State<PSIDRecursosPage> {
  late final WebViewController _controller;
  bool isLoading = true; // Estado para mostrar el indicador de carga

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true; // Inicia el indicador de carga
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false; // Termina el indicador de carga
            });
          },
          onWebResourceError: (WebResourceError error) {
            // ignore: avoid_print
            print('Error de recurso: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al cargar el contenido')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://drive.google.com/drive/folders/1aBehDXCZorAEVmbHm-UtU1L9qKzVlzfR'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recursos de PSID"),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Recursos para PSID",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Accede a los videos de PSID disponibles en Google Drive:",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),
          if (isLoading) // Mostrar indicador de carga mientras isLoading es true
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
