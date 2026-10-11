import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

class AnnouncementPdfViewer extends StatefulWidget {
  final String url;

  const AnnouncementPdfViewer({super.key, required this.url});

  @override
  State<AnnouncementPdfViewer> createState() => _AnnouncementPdfViewerState();
}

class _AnnouncementPdfViewerState extends State<AnnouncementPdfViewer> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();

    _controller = PdfControllerPinch(document: _loadDocument());
  }

  Future<PdfDocument> _loadDocument() async {
    final response = await http.get(Uri.parse(widget.url));

    if (response.statusCode != 200) {
      throw Exception('Unable to load PDF. HTTP ${response.statusCode}');
    }

    return PdfDocument.openData(response.bodyBytes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(controller: _controller);
  }
}
