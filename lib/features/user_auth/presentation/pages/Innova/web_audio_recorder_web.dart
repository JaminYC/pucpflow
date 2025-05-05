// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';


class WebAudioRecorder {
  html.MediaRecorder? _recorder;
  List<html.Blob> _chunks = [];
  late StreamController<List<int>> _audioStreamController;

  Future<void> startRecording() async {
    final mediaStream = await html.window.navigator.getUserMedia(audio: true);

    _chunks = [];
    _audioStreamController = StreamController<List<int>>();

    _recorder = html.MediaRecorder(mediaStream);
    _recorder!.addEventListener('dataavailable', (html.Event e) {
      final blobEvent = e as html.BlobEvent;
      if (blobEvent.data != null) {
        _chunks.add(blobEvent.data!);
      }
    });


    _recorder!.start();
  }

  Future<String> stopAndExportAsUrl() async {
    final completer = Completer<String>();

    _recorder?.addEventListener('stop', (_) {
      final blob = html.Blob(_chunks, 'audio/webm');
      final url = html.Url.createObjectUrlFromBlob(blob);
      completer.complete(url);
    });


    _recorder?.stop();
    return completer.future;
  }

  void dispose() {
    _recorder?.stop();
    _chunks.clear();
  }
}
