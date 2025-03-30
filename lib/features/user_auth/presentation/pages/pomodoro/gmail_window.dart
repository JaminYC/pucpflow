import 'package:flutter/material.dart';
import 'package:pucpflow/adaptive_webview/adaptive_webview.dart';

class GmailFloatingWindow extends StatefulWidget {
  const GmailFloatingWindow({super.key});

  @override
  State<GmailFloatingWindow> createState() => _GmailFloatingWindowState();
}

class _GmailFloatingWindowState extends State<GmailFloatingWindow> {
  Widget _buildWindow(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: AdaptiveWebView(
          url: 'https://mail.google.com',
          height: 600,
          width: 800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: _buildWindow(context),
    );
  }
}
