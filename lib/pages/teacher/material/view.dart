import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../../api_service.dart';

class MaterialViewPage extends StatefulWidget {
  final int materialId;

  const MaterialViewPage({super.key, required this.materialId});

  @override
  State<MaterialViewPage> createState() => _MaterialViewPageState();
}

class _MaterialViewPageState extends State<MaterialViewPage> {
  bool isLoading = true;
  bool isDownloading = false;
  String? errorMessage;

  Map<String, dynamic>? material;
  Map<String, dynamic>? subject;
  List<dynamic> assignments = [];

  @override
  void initState() {
    super.initState();
    loadMaterial();
  }

  Future<void> loadMaterial() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getTeacherMaterialDetails(
        widget.materialId,
      );

      if (!mounted) return;

      if (response['success'] == false) {
        throw Exception(
          response['message']?.toString() ?? 'Could not load material details.',
        );
      }

      final details = response['material'];

      if (details is! Map<String, dynamic>) {
        throw Exception('Material details are unavailable.');
      }

      setState(() {
        material = details;

        subject = details['subject'] is Map<String, dynamic>
            ? details['subject'] as Map<String, dynamic>
            : null;

        assignments = details['assignments'] is List
            ? details['assignments'] as List<dynamic>
            : [];

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  String getFileExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index == -1) return '';

    return fileName.substring(index + 1).toLowerCase();
  }

  String getFileNameWithoutExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index <= 0) return fileName;

    return fileName.substring(0, index);
  }

  bool isPowerPointFile(String extension) {
    return extension == 'ppt' || extension == 'pptx';
  }

  IconData getFileIcon(String fileName) {
    switch (getFileExtension(fileName)) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return Icons.image_rounded;
      case 'zip':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  bool isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  Future<void> openMaterial() async {
    final details = material;

    if (details == null) {
      showMessage('Material details are unavailable.');
      return;
    }

    final fileName = details['file_name']?.toString() ?? '';
    final extension = getFileExtension(fileName);
    final materialId = int.tryParse(details['id']?.toString() ?? '');

    if (details['file_exists'] != true) {
      showMessage('The material file could not be found on the server.');
      return;
    }

    if (materialId == null || materialId <= 0) {
      showMessage('The material ID is invalid.');
      return;
    }

    if (isPowerPointFile(extension)) {
      await downloadMaterial(materialId, fileName, extension);
      return;
    }

    if (extension != 'pdf' && !isImageFile(extension)) {
      showMessage(
        'This file format is not supported in the in-app viewer yet.',
      );
      return;
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaterialFileViewerPage(
          materialId: materialId,
          fileName: fileName,
          isPdf: extension == 'pdf',
        ),
      ),
    );
  }

  Future<void> downloadMaterial(
    int materialId,
    String fileName,
    String extension,
  ) async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final fileUri = ApiService.getTeacherMaterialFileUri(
        materialId: materialId,
      );

      final response = await http
          .get(fileUri, headers: ApiService.authOnlyHeaders)
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        throw Exception(
          'Download failed with HTTP ${response.statusCode}. '
          'Check your login and file API permissions.',
        );
      }

      final bytes = response.bodyBytes;

      if (bytes.isEmpty) {
        throw Exception('The downloaded file is empty.');
      }

      final baseName = getFileNameWithoutExtension(fileName);

      final mimeType = extension == 'pptx'
          ? MimeType.microsoftPresentation
          : MimeType.custom;

      final customMimeType = extension == 'ppt'
          ? 'application/vnd.ms-powerpoint'
          : null;

      await FileSaver.instance.saveToDownloads(
        name: baseName,
        bytes: bytes,
        fileExtension: extension,
        mimeType: mimeType,
        customMimeType: customMimeType,
      );

      if (!mounted) return;

      showMessage('PowerPoint downloaded successfully.');
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Could not download PowerPoint: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    final details = material!;
    final fileName = details['file_name']?.toString() ?? '';
    final description = details['description']?.toString() ?? '';
    final fileExists = details['file_exists'] == true;
    final extension = getFileExtension(fileName);
    final isPowerPoint = isPowerPointFile(extension);

    return RefreshIndicator(
      onRefresh: loadMaterial,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    getFileIcon(fileName),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  details['title']?.toString() ?? 'Untitled Material',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${subject?['name'] ?? 'Subject not available'}'
                  ' • ${extension.isEmpty ? 'FILE' : extension.toUpperCase()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Material Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  buildInfoRow(
                    icon: Icons.tag_rounded,
                    label: 'Material ID',
                    value: details['id']?.toString() ?? '',
                  ),
                  const Divider(height: 1),
                  buildInfoRow(
                    icon: Icons.menu_book_rounded,
                    label: 'Subject',
                    value: subject?['name']?.toString() ?? '',
                  ),
                  const Divider(height: 1),
                  buildInfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Academic Year',
                    value: details['academic_year']?.toString() ?? '',
                  ),
                  const Divider(height: 1),
                  buildInfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Uploaded',
                    value: details['created_at']?.toString() ?? '',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Assignments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (assignments.isEmpty)
                    const Text(
                      'No class assignments available.',
                      style: TextStyle(color: Colors.blueGrey),
                    )
                  else
                    ...assignments.map((item) {
                      if (item is! Map) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Grade ${item['grade']}'
                                ' • Section ${item['section']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description.isEmpty
                        ? 'No description provided.'
                        : description,
                    style: const TextStyle(height: 1.6, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attached File',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getFileIcon(fileName),
                          color: Colors.blue.shade700,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName.isEmpty ? 'Unknown file' : fileName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              details['formatted_file_size']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: fileExists && !isDownloading
                          ? openMaterial
                          : null,
                      icon: isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPowerPoint
                                  ? Icons.download_rounded
                                  : Icons.visibility_rounded,
                            ),
                      label: Text(
                        !fileExists
                            ? 'File Not Found'
                            : isDownloading
                            ? 'Downloading...'
                            : isPowerPoint
                            ? 'Download PowerPoint'
                            : 'View Material',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (!fileExists) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'The file could not be found on the server.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'View Material',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadMaterial,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 52,
                    ),
                    const SizedBox(height: 16),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: loadMaterial,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : material == null
          ? const Center(child: Text('Material not found.'))
          : buildContent(),
    );
  }
}

class MaterialFileViewerPage extends StatefulWidget {
  final int materialId;
  final String fileName;
  final bool isPdf;

  const MaterialFileViewerPage({
    super.key,
    required this.materialId,
    required this.fileName,
    required this.isPdf,
  });

  @override
  State<MaterialFileViewerPage> createState() => _MaterialFileViewerPageState();
}

class _MaterialFileViewerPageState extends State<MaterialFileViewerPage> {
  bool isLoading = true;
  String? errorMessage;

  Uint8List? fileBytes;
  PdfControllerPinch? pdfController;

  @override
  void initState() {
    super.initState();
    loadFile();
  }

  Future<void> loadFile() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final fileUri = ApiService.getTeacherMaterialFileUri(
        materialId: widget.materialId,
      );

      debugPrint('MATERIAL FILE URL: $fileUri');

      final response = await http
          .get(fileUri, headers: ApiService.authOnlyHeaders)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'File request failed with HTTP ${response.statusCode}. '
          'Check your login and file API permissions.',
        );
      }

      final bytes = response.bodyBytes;

      if (bytes.isEmpty) {
        throw Exception('The downloaded file is empty.');
      }

      PdfControllerPinch? controller;

      if (widget.isPdf) {
        controller = PdfControllerPinch(document: PdfDocument.openData(bytes));
      }

      if (!mounted) {
        controller?.dispose();
        return;
      }

      pdfController?.dispose();

      setState(() {
        fileBytes = bytes;
        pdfController = controller;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  Widget buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading material...'),
        ],
      ),
    );
  }

  Widget buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.broken_image_rounded,
              color: Colors.red,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load this material.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadFile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPdfContent() {
    if (pdfController == null) {
      return const Center(child: Text('PDF viewer is unavailable.'));
    }

    return PdfViewPinch(
      controller: pdfController!,
      scrollDirection: Axis.vertical,
    );
  }

  Widget buildImageContent() {
    final bytes = fileBytes;

    if (bytes == null) {
      return const Center(child: Text('Image is unavailable.'));
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5,
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 56,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Could not display this image.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? buildLoading()
            : errorMessage != null
            ? buildError()
            : widget.isPdf
            ? buildPdfContent()
            : buildImageContent(),
      ),
    );
  }
}
