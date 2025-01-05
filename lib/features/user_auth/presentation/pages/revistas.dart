import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RevistasPage extends StatefulWidget {
  const RevistasPage({super.key});

  @override
  _RevistasPageState createState() => _RevistasPageState();
}

class _RevistasPageState extends State<RevistasPage> {
  late final Map<String, Map<String, String>> universitiesByContinent;
  late final WebViewController webController;
  String? selectedContinent;
  String? selectedUniversity;

  @override
  void initState() {
    super.initState();

    universitiesByContinent = {
'América': {
        'PUCP (Perú)': 'https://puntoedu.pucp.edu.pe/investigacion-y-publicaciones/investigacion/',
        'Tec de Monterrey (México)': 'https://live.tec.mx/browse',
        'MIT (EE.UU.)': 'https://news.mit.edu/',
        'Stanford University (EE.UU.)': 'https://news.stanford.edu/',
        'Harvard University (EE.UU.)': 'https://news.harvard.edu/gazette/',
        'University of Toronto (Canadá)': 'https://www.utoronto.ca/news',
        'UC Berkeley (EE.UU.)': 'https://news.berkeley.edu/',
      },
      'Europa': {
        'University of Cambridge (Reino Unido)': 'https://www.cam.ac.uk/news',
        'University of Oxford (Reino Unido)': 'https://www.ox.ac.uk/news',
        'TU Munich (Alemania)': 'https://www.tum.de/en/',
        'University of Heidelberg (Alemania)': 'https://www.uni-heidelberg.de/en',
        'RWTH Aachen (Alemania)': 'https://www.rwth-aachen.de/go/id/a/?lidx=1',
        'ETH Zurich (Suiza)': 'https://ethz.ch/en/news-and-events.html',
        'Sorbonne University (Francia)': 'https://www.sorbonne-universite.fr/en',
        'KU Leuven (Bélgica)': 'https://nieuws.kuleuven.be/en',
      },
      'Asia': {
        'University of Tokyo (Japón)': 'https://www.u-tokyo.ac.jp/en/',
        'Tsinghua University (China)': 'https://www.tsinghua.edu.cn/en/',
        'Kyoto University (Japón)': 'https://www.kyoto-u.ac.jp/en/news',
        'National University of Singapore (NUS)': 'https://news.nus.edu.sg/',
        'University of Hong Kong': 'https://www.hku.hk/press/',
        'Seoul National University (Corea del Sur)': 'https://en.snu.ac.kr/research',
      },
      'Oceanía': {
        'University of Melbourne (Australia)': 'https://pursuit.unimelb.edu.au/',
        'Australian National University (Australia)': 'https://www.anu.edu.au/news',
        'University of Sydney (Australia)': 'https://www.sydney.edu.au/news-opinion.html',
      },
      'África': {
        'University of Cape Town (Sudáfrica)': 'https://www.news.uct.ac.za/',
        'Stellenbosch University (Sudáfrica)': 'https://www.sun.ac.za/english/Pages/default.aspx',
      },
    };

    selectedContinent = universitiesByContinent.keys.first;
    selectedUniversity = universitiesByContinent[selectedContinent]?.keys.first;

    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => print('Cargando: $url'),
          onPageFinished: (String url) => print('Página cargada: $url'),
          onNavigationRequest: (NavigationRequest request) {
            if (universitiesByContinent.values
                .expand((universities) => universities.values)
                .any((url) => request.url.startsWith(url))) {
              return NavigationDecision.navigate;
            } else {
              _launchURL(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      );

    if (selectedContinent != null && selectedUniversity != null) {
      webController.loadRequest(
        Uri.parse(universitiesByContinent[selectedContinent]![selectedUniversity]!),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
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
          "Universidades del Mundo",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.teal, // Cambiado a un color más fresco
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  dropdownColor: Colors.teal.shade100, // Fondo del dropdown
                  value: selectedContinent,
                  onChanged: (String? newContinent) {
                    if (newContinent != null) {
                      setState(() {
                        selectedContinent = newContinent;
                        selectedUniversity = universitiesByContinent[selectedContinent]?.keys.first;
                        if (selectedUniversity != null) {
                          webController.loadRequest(
                            Uri.parse(universitiesByContinent[selectedContinent]![selectedUniversity]!),
                          );
                        }
                      });
                    }
                  },
                  items: universitiesByContinent.keys.map<DropdownMenuItem<String>>((String continent) {
                    return DropdownMenuItem<String>(
                      value: continent,
                      child: Text(
                        continent,
                        style: TextStyle(color: Colors.teal.shade900), // Texto oscuro para mejor visibilidad
                      ),
                    );
                  }).toList(),
                  isExpanded: true,
                  underline: Container(height: 2, color: Colors.teal.shade700),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  dropdownColor: Colors.teal.shade100, // Fondo del dropdown
                  value: selectedUniversity,
                  onChanged: (String? newUniversity) {
                    if (newUniversity != null) {
                      setState(() {
                        selectedUniversity = newUniversity;
                        webController.loadRequest(
                          Uri.parse(universitiesByContinent[selectedContinent]![selectedUniversity]!),
                        );
                      });
                    }
                  },
                  items: selectedContinent != null
                      ? universitiesByContinent[selectedContinent]!.keys
                          .map<DropdownMenuItem<String>>((String university) {
                          return DropdownMenuItem<String>(
                            value: university,
                            child: Text(
                              university,
                              style: TextStyle(color: Colors.teal.shade900),
                            ),
                          );
                        }).toList()
                      : [],
                  isExpanded: true,
                  underline: Container(height: 2, color: Colors.teal.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                width: MediaQuery.of(context).size.width * 0.95,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.teal.shade400, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: WebViewWidget(controller: webController),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
