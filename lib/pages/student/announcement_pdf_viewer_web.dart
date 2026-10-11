import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class AnnouncementPdfViewer extends StatefulWidget {
  final String url;

  const AnnouncementPdfViewer({super.key, required this.url});

  @override
  State<AnnouncementPdfViewer> createState() => _AnnouncementPdfViewerState();
}

class _AnnouncementPdfViewerState extends State<AnnouncementPdfViewer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();

    _viewId = 'announcement-pdf-${DateTime.now().microsecondsSinceEpoch}';

    final iframe = html.IFrameElement()
      ..src = '${widget.url}#zoom=page-width'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..setAttribute('allowfullscreen', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
