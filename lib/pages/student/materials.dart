import 'package:flutter/material.dart';

import '../../student_api.dart';
import 'subject.dart';

import 'student_material_platform_viewer_stub.dart'
    if (dart.library.html) 'student_material_platform_viewer_web.dart'
    if (dart.library.io) 'student_material_platform_viewer_mobile.dart'
    as platform_viewer;

import '../../student_api.dart';
import 'subject.dart';

class StudentMaterialsPage extends StatefulWidget {
  const StudentMaterialsPage({super.key});

  @override
  State<StudentMaterialsPage> createState() => _StudentMaterialsPageState();
}

class _StudentMaterialsPageState extends State<StudentMaterialsPage> {
  bool isLoading = true;

  String? errorMessage;

  List<dynamic> subjects = [];

  List<dynamic> materials = [];

  int selectedSubject = 0;

  int currentPage = 1;

  int totalPages = 1;

  int totalMaterials = 0;

  @override
  void initState() {
    super.initState();

    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await StudentApi.getStudentMaterials(
        page: currentPage,
        subject: selectedSubject,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        subjects = (data['subjects'] as List<dynamic>?) ?? [];

        materials = (data['materials'] as List<dynamic>?) ?? [];

        final pagination = data['pagination'] as Map<String, dynamic>?;

        totalPages = (pagination?['total_pages'] as int?) ?? 1;

        totalMaterials = (pagination?['total_materials'] as int?) ?? 0;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');

        isLoading = false;
      });
    }
  }

  void _changeSubject(int subjectId) {
    setState(() {
      selectedSubject = subjectId;

      currentPage = 1;
    });

    _loadMaterials();
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages) {
      return;
    }

    setState(() {
      currentPage = page;
    });

    _loadMaterials();
  }

  String _getFileExtension(dynamic fileName) {
    final name = fileName?.toString().toLowerCase() ?? '';

    if (!name.contains('.')) {
      return '';
    }

    return name.split('.').last;
  }

  IconData _getFileIcon(dynamic fileType, dynamic fileName) {
    final type = fileType?.toString().toLowerCase() ?? '';

    final extension = _getFileExtension(fileName);

    if (extension == 'pdf' || type.contains('pdf')) {
      return Icons.picture_as_pdf;
    }

    if (extension == 'doc' || extension == 'docx' || type.contains('word')) {
      return Icons.description;
    }

    if (extension == 'ppt' ||
        extension == 'pptx' ||
        type.contains('presentation')) {
      return Icons.slideshow;
    }

    if (extension == 'xls' ||
        extension == 'xlsx' ||
        type.contains('excel') ||
        type.contains('spreadsheet')) {
      return Icons.table_chart;
    }

    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'gif' ||
        extension == 'webp' ||
        type.contains('image')) {
      return Icons.image;
    }

    if (extension == 'zip' ||
        extension == 'rar' ||
        extension == '7z' ||
        type.contains('zip')) {
      return Icons.folder_zip;
    }

    return Icons.insert_drive_file;
  }

  String _getFileUrl(Map<String, dynamic> material) {
    final filePath = material['file_path']?.toString().trim() ?? '';

    final normalizedPath = filePath
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');

    return 'http://10.40.32.233/BKHS/$normalizedPath';
  }

  void _openMaterial(Map<String, dynamic> material) {
    final filePath = material['file_path']?.toString().trim() ?? '';

    final title = material['title']?.toString() ?? 'Material';

    final fileName = material['file_name']?.toString() ?? '';

    final fileType = material['file_type']?.toString() ?? '';

    if (filePath.isEmpty) {
      _showMessage('This material does not have a file.');

      return;
    }

    final fileUrl = _getFileUrl(material);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StudentMaterialViewer(
          title: title,
          fileName: fileName,
          fileType: fileType,
          fileUrl: fileUrl,
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSubjects() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentSubjectsPage()),
    );
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'More',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('My Subjects'),
                    onTap: () {
                      Navigator.pop(context);

                      _openSubjects();
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.folder_copy),
                    title: const Text('Materials'),
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.campaign),
                    title: const Text('Announcements'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedSubject == 0,
              onSelected: (_) {
                _changeSubject(0);
              },
            ),
          ),

          ...subjects.map((subject) {
            final id = int.tryParse(subject['id']?.toString() ?? '') ?? 0;

            final name = subject['subject_name']?.toString() ?? 'Subject';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(name),
                selected: selectedSubject == id,
                onSelected: (_) {
                  _changeSubject(id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaterialTable() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          horizontalMargin: 16,
          headingRowHeight: 52,
          dataRowMinHeight: 68,
          dataRowMaxHeight: 82,
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text('Material')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('View')),
          ],
          rows: materials.map((material) {
            final item = Map<String, dynamic>.from(material as Map);

            return _buildMaterialRow(item);
          }).toList(),
        ),
      ),
    );
  }

  DataRow _buildMaterialRow(Map<String, dynamic> material) {
    final title = material['title']?.toString() ?? 'Untitled Material';

    final subjectName =
        material['subject_name']?.toString() ?? 'Unknown Subject';

    final fileName = material['file_name']?.toString() ?? '';

    final fileType = material['file_type']?.toString() ?? '';

    final icon = _getFileIcon(fileType, fileName);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 280,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: Colors.indigo.shade600),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            _openMaterial(material);
          },
        ),

        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              subjectName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () {
            _openMaterial(material);
          },
        ),

        DataCell(
          IconButton(
            tooltip: 'View material',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {
              _openMaterial(material);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous',
            onPressed: currentPage > 1
                ? () {
                    _changePage(currentPage - 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Next',
            onPressed: currentPage < totalPages
                ? () {
                    _changePage(currentPage + 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 52, color: Colors.red.shade300),

              const SizedBox(height: 12),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _loadMaterials,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMaterials,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learning Materials',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalMaterials',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Study materials for your current grade.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 18),

          _buildSubjectFilter(),

          const SizedBox(height: 18),

          if (materials.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 58,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'No materials found',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    selectedSubject > 0
                        ? 'There are no materials for this subject yet.'
                        : 'No learning materials have been uploaded yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            _buildMaterialTable(),

          _buildPagination(),
        ],
      ),
    );
  }

  void _onNavigationChanged(int index) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);

      return;
    }

    if (index == 1) {
      _openSubjects();

      return;
    }

    if (index == 2) {
      return;
    }

    if (index == 3) {
      return;
    }

    if (index == 4) {
      _openMoreMenu();

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,

        title: const Text(
          'Materials',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadMaterials,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _buildContent(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,

        onDestinationSelected: _onNavigationChanged,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),

          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Materials',
          ),

          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Result',
          ),

          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/*
|--------------------------------------------------------------------------
| Student Material Viewer
|--------------------------------------------------------------------------
*/

/*
|--------------------------------------------------------------------------
| Student Material Viewer
|--------------------------------------------------------------------------
*/

class StudentMaterialViewer extends StatefulWidget {
  final String title;

  final String fileName;

  final String fileType;

  final String fileUrl;

  const StudentMaterialViewer({
    super.key,
    required this.title,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
  });

  @override
  State<StudentMaterialViewer> createState() => _StudentMaterialViewerState();
}

class _StudentMaterialViewerState extends State<StudentMaterialViewer> {
  String _getExtension() {
    final name = widget.fileName.toLowerCase();

    if (!name.contains('.')) {
      return '';
    }

    return name.split('.').last;
  }

  bool _isPdf() {
    final extension = _getExtension();

    final type = widget.fileType.toLowerCase();

    return extension == 'pdf' ||
        type.contains('pdf') ||
        widget.fileUrl.toLowerCase().split('?').first.endsWith('.pdf');
  }

  bool _isWord() {
    final extension = _getExtension();

    final type = widget.fileType.toLowerCase();

    return extension == 'doc' || extension == 'docx' || type.contains('word');
  }

  bool _isPowerPoint() {
    final extension = _getExtension();

    final type = widget.fileType.toLowerCase();

    return extension == 'ppt' ||
        extension == 'pptx' ||
        type.contains('presentation') ||
        type.contains('powerpoint');
  }

  bool _isImage() {
    final extension = _getExtension();

    final type = widget.fileType.toLowerCase();

    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'gif' ||
        extension == 'webp' ||
        type.contains('image');
  }

  String _getViewerDescription() {
    if (_isPdf()) {
      return 'PDF document';
    }

    if (_isWord()) {
      return 'Word document';
    }

    if (_isPowerPoint()) {
      return 'PowerPoint presentation';
    }

    if (_isImage()) {
      return 'Image';
    }

    return 'Learning material';
  }

  Widget _buildViewer() {
    if (_isPdf() || _isWord() || _isPowerPoint()) {
      return SizedBox.expand(
        child: platform_viewer.StudentMaterialPlatformViewer(
          url: widget.fileUrl,
          fileName: widget.fileName,
          fileType: widget.fileType,
        ),
      );
    }

    if (_isImage()) {
      return SizedBox.expand(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: Image.network(
              widget.fileUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildError();
              },
            ),
          ),
        ),
      );
    }

    return _buildUnsupported();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 52, color: Colors.red.shade300),
            const SizedBox(height: 14),
            const Text(
              'Unable to open this material.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check the file and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 58,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'Preview is not available',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This file type cannot be previewed inside the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  double _getViewerHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (size.width < 600) {
      return size.height * 0.90;
    }

    if (size.width < 1024) {
      return size.height * 0.88;
    }

    return size.height * 0.82;
  }

  double _getViewerWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (size.width < 600) {
      return size.width;
    }

    if (size.width < 1024) {
      return size.width * 0.94;
    }

    return size.width > 1400 ? 1200 : size.width * 0.90;
  }

  @override
  Widget build(BuildContext context) {
    final viewerHeight = _getViewerHeight(context);

    final viewerWidth = _getViewerWidth(context);

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: viewerWidth,
          height: viewerHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                MediaQuery.sizeOf(context).width < 600 ? 18 : 22,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < 600 ? 12 : 16,
                    10,
                    8,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: MediaQuery.sizeOf(context).width < 600
                                    ? 15
                                    : 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getViewerDescription(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xFFF8FAFC),
                    child: _buildViewer(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
