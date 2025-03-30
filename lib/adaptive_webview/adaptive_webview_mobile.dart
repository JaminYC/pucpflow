import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdaptiveWebView extends StatefulWidget {
  final String url;
  final double height;
  final double width;

  const AdaptiveWebView({
    super.key,
    required this.url,
    this.height = 400,
    this.width = 600,
  });

  @override
  State<AdaptiveWebView> createState() => _AdaptiveWebViewState();
}

class _AdaptiveWebViewState extends State<AdaptiveWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: WebViewWidget(controller: _controller),
    );
  }
}
