import 'package:flutter/material.dart';

import 'view.dart';
import 'create.dart';
import 'edit.dart';
import 'delete.dart';

import '/api_service.dart';

class TeacherMaterialPage extends StatefulWidget {
  const TeacherMaterialPage({super.key});

  @override
  State<TeacherMaterialPage> createState() => _TeacherMaterialPageState();
}

class _TeacherMaterialPageState extends State<TeacherMaterialPage> {
  bool isLoading = true;
  String? errorMessage;

  final Set<int> deletingMaterialIds = {};

  List<Map<String, dynamic>> materials = [];

  Map<String, dynamic> filterOptions = {};
  Map<String, dynamic> pagination = {};
  Map<String, dynamic> statistics = {};

  final TextEditingController searchController = TextEditingController();

  int? selectedGrade;
  int? selectedSubjectId;
  String? selectedSection;

  int currentPage = 1;
  int perPage = 10;

  @override
  void initState() {
    super.initState();
    loadMaterials();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMaterials({int? page}) async {
    if (page != null) {
      currentPage = page;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getTeacherMaterials(
        grade: selectedGrade,
        section: selectedSection,
        subjectId: selectedSubjectId,
        search: searchController.text.trim(),
        perPage: perPage,
        page: currentPage,
      );

      if (!mounted) return;

      final materialList = data['materials'] as List<dynamic>? ?? [];

      setState(() {
        materials = materialList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        filterOptions = Map<String, dynamic>.from(
          data['filter_options'] as Map? ?? {},
        );

        pagination = Map<String, dynamic>.from(
          data['pagination'] as Map? ?? {},
        );

        statistics = Map<String, dynamic>.from(
          data['statistics'] as Map? ?? {},
        );

        currentPage =
            int.tryParse(pagination['current_page']?.toString() ?? '') ??
            currentPage;

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

  List<dynamic> get gradeOptions =>
      filterOptions['grades'] as List<dynamic>? ?? [];

  List<dynamic> get sectionOptions =>
      filterOptions['sections'] as List<dynamic>? ?? [];

  List<dynamic> get subjectOptions =>
      filterOptions['subjects'] as List<dynamic>? ?? [];

  int get totalPages =>
      int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;

  int get totalMaterials =>
      int.tryParse(
        pagination['total_records']?.toString() ??
            pagination['total_items']?.toString() ??
            pagination['total']?.toString() ??
            '0',
      ) ??
      0;

  Future<void> openMaterialAction({
    required String action,
    Map<String, dynamic>? material,
  }) async {
    if (action == 'Create') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => const CreateTeacherMaterialPage(),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        await loadMaterials(page: 1);
      }

      return;
    }

    if (action == 'View') {
      final materialId = int.tryParse(material?['id']?.toString() ?? '');

      if (materialId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid material ID.')));
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaterialViewPage(materialId: materialId),
        ),
      );

      if (mounted) {
        await loadMaterials();
      }

      return;
    }

    if (action == 'Edit') {
      if (material == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material details are missing.')),
        );
        return;
      }

      final materialId = int.tryParse(material['id']?.toString() ?? '');

      if (materialId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid material ID.')));
        return;
      }

      try {
        final assignmentResponse =
            await ApiService.getTeacherMaterialAssignments();

        if (!mounted) return;

        final responseData = assignmentResponse['data'] is Map
            ? Map<String, dynamic>.from(assignmentResponse['data'] as Map)
            : assignmentResponse;

        final rawAssignments =
            responseData['assignments'] as List<dynamic>? ?? [];

        final assignments = rawAssignments
            .whereType<Map>()
            .map((item) {
              final assignment = Map<String, dynamic>.from(item);

              assignment['id'] ??= assignment['assignment_id'];

              return assignment;
            })
            .where(
              (assignment) =>
                  int.tryParse(assignment['id']?.toString() ?? '') != null,
            )
            .toList();

        final token = ApiService.token;

        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please log in again.')));
          return;
        }

        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (context) => EditTeacherMaterialPage(
              token: token,
              material: material,
              assignments: assignments,
            ),
          ),
        );

        if (!mounted) return;

        if (result == true) {
          await loadMaterials(page: currentPage);
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MaterialActionPlaceholderPage(action: action, material: material),
      ),
    );

    if (mounted) {
      await loadMaterials();
    }
  }

  Future<void> confirmDelete(Map<String, dynamic> material) async {
    final materialId = int.tryParse(material['id']?.toString() ?? '');

    if (materialId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid material ID.')));
      return;
    }

    if (deletingMaterialIds.contains(materialId)) {
      return;
    }

    final token = ApiService.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in again.')));
      return;
    }

    setState(() {
      deletingMaterialIds.add(materialId);
    });

    try {
      final deleted = await deleteTeacherMaterial(
        context: context,
        token: token,
        materialId: materialId,
      );

      if (!mounted) return;

      if (deleted) {
        final remainingItems = materials.length - 1;
        final nextPage = remainingItems <= 0 && currentPage > 1
            ? currentPage - 1
            : currentPage;

        await loadMaterials(page: nextPage);
      }
    } finally {
      if (mounted) {
        setState(() {
          deletingMaterialIds.remove(materialId);
        });
      }
    }
  }

  void clearFilters() {
    setState(() {
      selectedGrade = null;
      selectedSection = null;
      selectedSubjectId = null;
      searchController.clear();
      currentPage = 1;
    });

    loadMaterials(page: 1);
  }

  String formatFileSize(dynamic value) {
    final bytes = int.tryParse(value?.toString() ?? '') ?? 0;

    if (bytes <= 0) return 'Unknown';

    if (bytes < 1024) return '$bytes B';

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData fileIcon(Map<String, dynamic> material) {
    final fileName = material['file_name']?.toString().toLowerCase() ?? '';
    final fileType = material['file_type']?.toString().toLowerCase() ?? '';

    if (fileType.contains('pdf') || fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }

    if (fileType.contains('image') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.webp')) {
      return Icons.image;
    }

    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    }

    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    }

    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Icons.slideshow;
    }

    return Icons.insert_drive_file;
  }

  Color fileColor(Map<String, dynamic> material) {
    final fileName = material['file_name']?.toString().toLowerCase() ?? '';
    final fileType = material['file_type']?.toString().toLowerCase() ?? '';

    if (fileType.contains('pdf') || fileName.endsWith('.pdf')) {
      return Colors.red;
    }

    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Colors.blue;
    }

    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Colors.green;
    }

    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Colors.orange;
    }

    if (fileType.contains('image')) {
      return Colors.purple;
    }

    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teacher Materials',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : () => loadMaterials(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMaterialAction(action: 'Create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Material'),
      ),
      body: RefreshIndicator(
        onRefresh: () => loadMaterials(page: currentPage),
        child: isLoading && materials.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null && materials.isEmpty
            ? _buildErrorView()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Materials ($totalMaterials)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear filters',
                        onPressed: clearFilters,
                        icon: const Icon(Icons.filter_alt_off),
                      ),
                    ],
                  ),
                  if (isLoading) const LinearProgressIndicator(),
                  if (errorMessage != null) _buildInlineError(),
                  if (materials.isEmpty && !isLoading)
                    _buildEmptyView()
                  else if (materials.isNotEmpty)
                    _buildMaterialsTable(),
                  if (materials.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildPagination(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Materials',
            totalMaterials.toString(),
            Icons.folder_open,
            Colors.indigo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Assignments',
            statistics['assignment_count']?.toString() ?? '0',
            Icons.class_,
            Colors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Subjects',
            statistics['subject_count']?.toString() ?? '0',
            Icons.menu_book,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => loadMaterials(page: 1),
      decoration: InputDecoration(
        hintText: 'Search materials...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Search',
          onPressed: () => loadMaterials(page: 1),
          icon: const Icon(Icons.arrow_forward),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: selectedGrade,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All grades'),
                  ),
                  ...gradeOptions
                      .map((item) {
                        final rawGrade = item is Map
                            ? item['grade'] ??
                                  item['grade_number'] ??
                                  item['id']
                            : item;

                        final grade = int.tryParse(rawGrade.toString());

                        return DropdownMenuItem<int?>(
                          value: grade,
                          child: Text('Grade $rawGrade'),
                        );
                      })
                      .where((item) => item.value != null),
                ],
                onChanged: (value) {
                  setState(() => selectedGrade = value);
                  loadMaterials(page: 1);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: selectedSection,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All sections'),
                  ),
                  ...sectionOptions.map((item) {
                    final section = item is Map
                        ? (item['section'] ?? item['name'] ?? '').toString()
                        : item.toString();

                    return DropdownMenuItem<String?>(
                      value: section,
                      child: Text('Section $section'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => selectedSection = value);
                  loadMaterials(page: 1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: selectedSubjectId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.menu_book),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All subjects'),
            ),
            ...subjectOptions
                .map((item) {
                  final rawId = item is Map
                      ? item['id'] ??
                            item['grade_subject_id'] ??
                            item['subject_id']
                      : null;

                  final id = int.tryParse(rawId.toString());

                  final name = item is Map
                      ? (item['subject_name'] ??
                                item['name'] ??
                                item['subject'] ??
                                'Subject')
                            .toString()
                      : item.toString();

                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  );
                })
                .where((item) => item.value != null),
          ],
          onChanged: (value) {
            setState(() => selectedSubjectId = value);
            loadMaterials(page: 1);
          },
        ),
      ],
    );
  }

  Widget _buildMaterialsTable() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          columnSpacing: 22,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('No.')),
            DataColumn(label: Text('Material')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('File')),
            DataColumn(label: Text('Size')),
            DataColumn(label: Text('Uploaded')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List.generate(materials.length, (index) {
            final material = materials[index];

            final materialId = int.tryParse(material['id']?.toString() ?? '');

            final isDeleting =
                materialId != null && deletingMaterialIds.contains(materialId);

            final title = material['title']?.toString() ?? 'Untitled material';

            final subject = material['subject_name']?.toString() ?? '-';

            final grade = material['grade']?.toString() ?? '-';

            final sections =
                material['sections_text']?.toString() ??
                (material['sections'] is List
                    ? (material['sections'] as List).join(', ')
                    : '-');

            final fileName =
                material['file_name']?.toString() ?? 'Unknown file';

            final size =
                material['formatted_file_size']?.toString() ??
                formatFileSize(material['file_size']);

            final uploaded =
                material['uploaded_ethiopian']?.toString() ??
                material['created_at']?.toString() ??
                '-';

            final color = fileColor(material);

            return DataRow(
              cells: [
                DataCell(Text('${(currentPage - 1) * perPage + index + 1}')),
                DataCell(
                  SizedBox(
                    width: 190,
                    child: Row(
                      children: [
                        Icon(fileIcon(material), color: color, size: 23),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Tooltip(
                            message: title,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Text(
                      subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 115,
                    child: Text('Grade $grade\nSection $sections'),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Tooltip(
                      message: fileName,
                      child: Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(size)),
                DataCell(
                  SizedBox(
                    width: 115,
                    child: Text(
                      uploaded,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'View material',
                        onPressed: isDeleting
                            ? null
                            : () => openMaterialAction(
                                action: 'View',
                                material: material,
                              ),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit material',
                        onPressed: isDeleting
                            ? null
                            : () => openMaterialAction(
                                action: 'Edit',
                                material: material,
                              ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete material',
                        onPressed: isDeleting
                            ? null
                            : () => confirmDelete(material),
                        icon: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Column(
      children: [
        Text(
          'Page $currentPage of ${totalPages < 1 ? 1 : totalPages}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed: currentPage > 1 && !isLoading
                  ? () => loadMaterials(page: currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            DropdownButton<int>(
              value: perPage,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 per page')),
                DropdownMenuItem(value: 20, child: Text('20 per page')),
                DropdownMenuItem(value: 30, child: Text('30 per page')),
                DropdownMenuItem(value: 50, child: Text('50 per page')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() => perPage = value);
                loadMaterials(page: 1);
              },
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: currentPage < totalPages && !isLoading
                  ? () => loadMaterials(page: currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No materials found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or filters, or add a new material.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: clearFilters,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 55, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Unable to load materials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => loadMaterials(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            onPressed: () => loadMaterials(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class MaterialActionPlaceholderPage extends StatelessWidget {
  final String action;
  final Map<String, dynamic>? material;

  const MaterialActionPlaceholderPage({
    super.key,
    required this.action,
    this.material,
  });

  @override
  Widget build(BuildContext context) {
    final title = material?['title']?.toString() ?? 'New material';

    return Scaffold(
      appBar: AppBar(title: Text('$action Material')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action == 'Create'
                    ? Icons.add_box_outlined
                    : action == 'Edit'
                    ? Icons.edit_note
                    : action == 'Delete'
                    ? Icons.delete_outline
                    : Icons.visibility_outlined,
                size: 64,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              Text(
                '$action Material',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action == 'Create'
                    ? 'The create material page will be implemented here.'
                    : action == 'Edit'
                    ? 'The edit page for "$title" will be implemented here.'
                    : action == 'Delete'
                    ? 'The delete page for "$title" will be implemented here.'
                    : 'The material details and file viewer will be implemented here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Materials'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
