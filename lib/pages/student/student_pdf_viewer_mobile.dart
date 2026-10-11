import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

class StudentPdfViewer extends StatefulWidget {
  final String pdfUrl;

  const StudentPdfViewer({super.key, required this.pdfUrl});

  @override
  State<StudentPdfViewer> createState() => _StudentPdfViewerState();
}

class _StudentPdfViewerState extends State<StudentPdfViewer> {
  late final PdfControllerPinch controller;
  String? errorMessage;

  Future<PdfDocument> _loadDocument() async {
    final response = await http.get(Uri.parse(widget.pdfUrl));

    if (response.statusCode != 200) {
      throw Exception('Unable to load PDF. HTTP ${response.statusCode}');
    }

    return PdfDocument.openData(response.bodyBytes);
  }

  @override
  void initState() {
    super.initState();

    controller = PdfControllerPinch(document: _loadDocument());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: controller,
      onDocumentError: (error) {
        if (!mounted) return;

        setState(() {
          errorMessage = error.toString();
        });
      },
    );
  }
}
