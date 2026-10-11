import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class StudentMaterialPlatformViewer extends StatefulWidget {
  final String url;
  final String fileName;
  final String fileType;

  const StudentMaterialPlatformViewer({
    super.key,
    required this.url,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<StudentMaterialPlatformViewer> createState() =>
      _StudentMaterialPlatformViewerState();
}

class _StudentMaterialPlatformViewerState
    extends State<StudentMaterialPlatformViewer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();

    _viewType = 'student-material-${DateTime.now().microsecondsSinceEpoch}';

    final extension = widget.fileName.toLowerCase().split('.').last;
    final type = widget.fileType.toLowerCase();

    String viewerUrl = widget.url;

    if (extension == 'doc' ||
        extension == 'docx' ||
        extension == 'ppt' ||
        extension == 'pptx' ||
        type.contains('word') ||
        type.contains('presentation') ||
        type.contains('powerpoint')) {
      viewerUrl =
          'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(widget.url)}';
    } else if (extension == 'pdf' || type.contains('pdf')) {
      viewerUrl = '${widget.url}#zoom=page-width';
    }

    final iframe = html.IFrameElement()
      ..src = viewerUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.margin = '0'
      ..style.padding = '0'
      ..style.display = 'block'
      ..style.backgroundColor = '#ffffff'
      ..setAttribute('allowfullscreen', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
