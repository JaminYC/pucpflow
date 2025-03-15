import 'package:flutter/material.dart';
import 'package:pucpflow/adaptive_webview/adaptive_webview.dart';

class WhatsAppFloatingWindow extends StatelessWidget {
  const WhatsAppFloatingWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: const AdaptiveWebView(
            url: 'https://web.whatsapp.com/',
            height: 600,
            width: 800,
          ),
        ),
      ),
    );
  }
}
