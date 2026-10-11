import 'package:flutter/material.dart';

class AnnouncementPdfViewer extends StatelessWidget {
  final String url;

  const AnnouncementPdfViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'PDF viewing is not supported on this platform.',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
