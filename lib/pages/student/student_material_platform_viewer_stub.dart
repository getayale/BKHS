import 'package:flutter/material.dart';

class StudentMaterialPlatformViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Material preview is not supported on this platform.'),
    );
  }
}
