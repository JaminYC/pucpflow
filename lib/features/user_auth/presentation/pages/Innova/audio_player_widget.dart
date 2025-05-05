import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onFinished;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.onFinished,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => _isPlaying = false);
        widget.onFinished?.call();
      }
    });

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 10),
          Text("Cargando audio..."),
        ],
      );
    }

    if (_hasError) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 10),
          Text("Error al cargar audio"),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
          iconSize: 36,
          onPressed: _togglePlayPause,
        ),
        const SizedBox(width: 8),
        const Text("Reproducir audio"),
      ],
    );
  }
}
