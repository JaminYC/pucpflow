// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
// import 'dart:ui_web' as ui;
// import 'package:flutter/material.dart';

// class AdaptiveWebView extends StatelessWidget {
//   final String url;
//   final double height;
//   final double width;

//   const AdaptiveWebView({
//     super.key,
//     required this.url,
//     this.height = 400,
//     this.width = 600,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final String viewId = 'webview-${url.hashCode}';

//     ui.platformViewRegistry.registerViewFactory(
//       viewId,
//       (int _) => html.IFrameElement()
//         ..src = url
//         ..style.border = 'none'
//         ..style.width = '100%'
//         ..style.height = '100%'
//         ..allow = 'fullscreen; clipboard-read; clipboard-write',
//     );

//     return SizedBox(
//       width: width,
//       height: height,
//       child: HtmlElementView(viewType: viewId),
//     );
//   }
// }
