// ignore_for_file: avoid_print, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RevistasPage extends StatefulWidget {
  const RevistasPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RevistasPageState createState() => _RevistasPageState();
}

class _RevistasPageState extends State<RevistasPage> {
  late final WebViewController controllerPUCP;
  late final WebViewController controllerTec;
  bool showPUCP = true; // Variable para controlar qué página mostrar

  @override
  void initState() {
    super.initState();

    controllerPUCP = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // ignore: avoid_print
            print('Iniciando carga de página: $url');
          },
          onPageFinished: (String url) {
            print('Página cargada: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('Error al cargar el recurso: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://puntoedu.pucp.edu.pe/')) {
              return NavigationDecision.navigate;
            } else {
              _launchURL(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://puntoedu.pucp.edu.pe/investigacion-y-publicaciones/investigacion/'));

    controllerTec = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Iniciando carga de página: $url');
          },
          onPageFinished: (String url) {
            print('Página cargada: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('Error al cargar el recurso: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://live.tec.mx/')) {
              return NavigationDecision.navigate;
            } else {
              _launchURL(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://live.tec.mx/browse'));
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('No se pudo abrir el enlace: $url');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace en el navegador')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Revistas",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.deepPurple[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showPUCP = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: showPUCP ? Colors.deepPurple : Colors.grey,
                ),
                child: const Text("PUCP"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showPUCP = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !showPUCP ? Colors.deepPurple : Colors.grey,
                ),
                child: const Text("Tec de Monterrey"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                height: 400,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black54, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: showPUCP
                    ? WebViewWidget(controller: controllerPUCP)
                    : WebViewWidget(controller: controllerTec),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
