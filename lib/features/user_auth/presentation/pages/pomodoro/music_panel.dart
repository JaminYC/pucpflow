import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pucpflow/adaptive_webview/adaptive_webview.dart';

class MusicPanel extends StatefulWidget {
  const MusicPanel({super.key});

  @override
  State<MusicPanel> createState() => _MusicPanelState();
}

class _MusicPanelState extends State<MusicPanel> {
  final TextEditingController _controller = TextEditingController();
  final String defaultLofiUrl = 'https://open.spotify.com/embed/playlist/37i9dQZF1DXcBWIGoYBM5M';
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUrl = prefs.getString('music_url') ?? defaultLofiUrl;
    });
  }

  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('music_url', url);
    setState(() {
      _currentUrl = url;
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '🎧 Personaliza tu música (Spotify, YouTube, etc.)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Pega una URL de música',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveUrl(_controller.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_currentUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AdaptiveWebView(
                url: _currentUrl!,
                height: 400,
                width: MediaQuery.of(context).size.width * 0.9,
              ),
            ),
          ),
      ],
    );
  }
}
