import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class StudentPdfViewer extends StatefulWidget {
  final String pdfUrl;

  const StudentPdfViewer({super.key, required this.pdfUrl});

  @override
  State<StudentPdfViewer> createState() => _StudentPdfViewerState();
}

class _StudentPdfViewerState extends State<StudentPdfViewer> {
  late final String viewType;

  @override
  void initState() {
    super.initState();

    viewType = 'student-pdf-${DateTime.now().microsecondsSinceEpoch}';

    final iframe = html.IFrameElement()
      ..src = '${widget.pdfUrl}#zoom=page-width'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.display = 'block'
      ..style.backgroundColor = '#ffffff'
      ..style.overflow = 'auto'
      ..setAttribute('allowfullscreen', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewType);
  }
}
