import 'package:flutter/material.dart';

class StudentPdfViewer extends StatelessWidget {
  final String pdfUrl;

  const StudentPdfViewer({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('PDF viewing is not supported on this platform.'),
    );
  }
}
