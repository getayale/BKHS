import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

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
  PdfControllerPinch? _controller;
  String? _errorMessage;
  bool _isLoading = true;

  bool get _isPdf {
    final extension = widget.fileName.toLowerCase().split('.').last;
    final type = widget.fileType.toLowerCase();

    return extension == 'pdf' ||
        type.contains('pdf') ||
        widget.url.toLowerCase().split('?').first.endsWith('.pdf');
  }

  @override
  void initState() {
    super.initState();

    if (_isPdf) {
      _loadPdf();
    } else {
      _isLoading = false;
      _errorMessage = 'Previewing Word and PowerPoint files is not supported in this viewer.';
    }
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode != 200) {
        throw Exception('Unable to load PDF. HTTP ${response.statusCode}');
      }

      final document = PdfDocument.openData(response.bodyBytes);

      if (!mounted) {
        (await document).close();
        return;
      }

      setState(() {
        _controller = PdfControllerPinch(document: document);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final controller = _controller;

    if (controller == null) {
      return const Center(child: Text('Unable to open this material.'));
    }

    return PdfViewPinch(controller: controller);
  }
}
