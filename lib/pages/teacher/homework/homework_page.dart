import 'package:flutter/material.dart';

import '/api_service.dart';
import '/pages/teacher/homework/homework_create_page.dart';
import '/pages/teacher/homework/homework_edit_page.dart';
import '/pages/teacher/homework/homework_view_page.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  bool isLoading = true;
  bool isLoadingMore = false;

  String? errorMessage;

  List<Map<String, dynamic>> homework = [];
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> subjects = [];

  int currentPage = 1;
  int totalPages = 1;

  int? selectedGrade;
  String? selectedSection;
  int? selectedSubjectId;
  String? selectedStatus;

  DateTime? selectedFromDate;
  DateTime? selectedToDate;

  @override
  void initState() {
    super.initState();
    loadHomework();
  }

  Future<void> loadHomework({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getTeacherHomework(
        grade: selectedGrade,
        section: selectedSection,
        subjectId: selectedSubjectId,
        fromDate: _formatApiDate(selectedFromDate),
        toDate: _formatApiDate(selectedToDate),
        status: selectedStatus,
        page: currentPage,
      );

      if (!mounted) {
        return;
      }

      final homeworkData = data['homework'] is List
          ? data['homework'] as List
          : <dynamic>[];

      final classesData = data['classes'] is List
          ? data['classes'] as List
          : <dynamic>[];

      final subjectsData = data['subjects'] is List
          ? data['subjects'] as List
          : <dynamic>[];

      final pagination = data['pagination'] is Map
          ? Map<String, dynamic>.from(data['pagination'] as Map)
          : <String, dynamic>{};

      final parsedHomework = homeworkData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final parsedClasses = <Map<String, dynamic>>[];

      for (final item in classesData) {
        if (item is! Map) {
          continue;
        }

        final classItem = Map<String, dynamic>.from(item);

        final grade = int.tryParse(classItem['grade']?.toString() ?? '');

        final section = classItem['section']?.toString().trim().toUpperCase();

        if (grade == null || grade <= 0) {
          continue;
        }

        if (section == null || section.isEmpty) {
          continue;
        }

        classItem['grade'] = grade;
        classItem['section'] = section;

        parsedClasses.add(classItem);
      }

      final parsedSubjects = <Map<String, dynamic>>[];
      final subjectIds = <int>{};

      for (final item in subjectsData) {
        if (item is! Map) {
          continue;
        }

        final subject = Map<String, dynamic>.from(item);

        final gradeSubjectId = int.tryParse(
          subject['grade_subject_id']?.toString() ?? '',
        );

        if (gradeSubjectId == null || gradeSubjectId <= 0) {
          continue;
        }

        if (subjectIds.contains(gradeSubjectId)) {
          continue;
        }

        final subjectName = subject['subject_name']?.toString().trim() ?? '';

        if (subjectName.isEmpty) {
          continue;
        }

        subject['grade_subject_id'] = gradeSubjectId;

        subjectIds.add(gradeSubjectId);
        parsedSubjects.add(subject);
      }

      parsedSubjects.sort(
        (a, b) => (a['subject_name']?.toString() ?? '').compareTo(
          b['subject_name']?.toString() ?? '',
        ),
      );

      final totalPagesValue =
          int.tryParse(pagination['total_pages']?.toString() ?? '') ?? 1;

      final safeTotalPages = totalPagesValue < 1 ? 1 : totalPagesValue;

      if (currentPage > safeTotalPages) {
        currentPage = safeTotalPages;
      }

      setState(() {
        homework = parsedHomework;
        classes = parsedClasses;
        subjects = parsedSubjects;
        totalPages = safeTotalPages;
        isLoading = false;
        isLoadingMore = false;
        errorMessage = null;

        _validateSelectedFilters();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        isLoadingMore = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _validateSelectedFilters() {
    final availableGrades = _availableGrades;

    if (selectedGrade != null && !availableGrades.contains(selectedGrade)) {
      selectedGrade = null;
    }

    final availableSections = _availableSections;

    if (selectedSection != null &&
        !availableSections.contains(selectedSection)) {
      selectedSection = null;
    }

    final availableSubjectIds = _availableSubjectIds;

    if (selectedSubjectId != null &&
        !availableSubjectIds.contains(selectedSubjectId)) {
      selectedSubjectId = null;
    }

    if (selectedStatus != null &&
        selectedStatus != 'Active' &&
        selectedStatus != 'Closed') {
      selectedStatus = null;
    }
  }

  List<int> get _availableGrades {
    final values = <int>{};

    for (final item in classes) {
      final grade = int.tryParse(item['grade']?.toString() ?? '');

      if (grade != null && grade > 0) {
        values.add(grade);
      }
    }

    final result = values.toList()..sort();

    return result;
  }

  List<String> get _availableSections {
    final values = <String>{};

    for (final item in classes) {
      final grade = int.tryParse(item['grade']?.toString() ?? '');

      final section = item['section']?.toString().trim().toUpperCase();

      if (selectedGrade != null && grade != selectedGrade) {
        continue;
      }

      if (section != null && section.isNotEmpty) {
        values.add(section);
      }
    }

    final result = values.toList()..sort();

    return result;
  }

  List<Map<String, dynamic>> get _availableSubjects {
    final result = <Map<String, dynamic>>[];
    final seenIds = <int>{};

    for (final subject in subjects) {
      final id = int.tryParse(subject['grade_subject_id']?.toString() ?? '');

      if (id == null || id <= 0) {
        continue;
      }

      if (seenIds.contains(id)) {
        continue;
      }

      final name = subject['subject_name']?.toString().trim() ?? '';

      if (name.isEmpty) {
        continue;
      }

      seenIds.add(id);
      result.add(subject);
    }

    result.sort(
      (a, b) => (a['subject_name']?.toString() ?? '').compareTo(
        b['subject_name']?.toString() ?? '',
      ),
    );

    return result;
  }

  Set<int> get _availableSubjectIds {
    final values = <int>{};

    for (final subject in _availableSubjects) {
      final id = int.tryParse(subject['grade_subject_id']?.toString() ?? '');

      if (id != null && id > 0) {
        values.add(id);
      }
    }

    return values;
  }

  Future<void> applyFilters() async {
    currentPage = 1;
    await loadHomework();
  }

  Future<void> nextPage() async {
    if (currentPage >= totalPages || isLoadingMore) {
      return;
    }

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    try {
      await loadHomework();
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> previousPage() async {
    if (currentPage <= 1 || isLoadingMore) {
      return;
    }

    setState(() {
      isLoadingMore = true;
      currentPage--;
    });

    try {
      await loadHomework();
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> clearFilters() async {
    setState(() {
      selectedGrade = null;
      selectedSection = null;
      selectedSubjectId = null;
      selectedStatus = null;
      selectedFromDate = null;
      selectedToDate = null;
      currentPage = 1;
    });

    await loadHomework();
  }

  Future<void> openCreatePage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HomeworkCreatePage()),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await loadHomework(refresh: true);
    }
  }

  Future<void> openEditPage(int homeworkId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkEditPage(homeworkId: homeworkId),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await loadHomework(refresh: true);
    }
  }

  Future<void> openViewPage(int homeworkId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeworkViewPage(homeworkId: homeworkId),
      ),
    );

    if (!mounted) {
      return;
    }

    await loadHomework(refresh: true);
  }

  Future<void> _showHomeworkActions(int homeworkId) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(
                      Icons.visibility_outlined,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  title: const Text('View Homework'),
                  subtitle: const Text('View details and student status'),
                  onTap: () {
                    Navigator.pop(context, 'view');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3F4F6),
                    child: Icon(Icons.edit_outlined, color: Color(0xFF4B5563)),
                  ),
                  title: const Text('Edit Homework'),
                  subtitle: const Text('Update homework information'),
                  onTap: () {
                    Navigator.pop(context, 'edit');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == 'view') {
      await openViewPage(homeworkId);
    } else if (action == 'edit') {
      await openEditPage(homeworkId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Homework',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: isLoading ? null : () => loadHomework(refresh: true),
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : openCreatePage,
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _gradeDropdown()),
                  const SizedBox(width: 8),
                  Expanded(child: _sectionDropdown()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _subjectDropdown()),
                  const SizedBox(width: 8),
                  Expanded(child: _statusDropdown()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dateButton(
                      label: selectedFromDate == null
                          ? 'From Date'
                          : _formatDisplayDate(selectedFromDate!),
                      icon: Icons.calendar_today_outlined,
                      onPressed: () => _selectDate(isFromDate: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateButton(
                      label: selectedToDate == null
                          ? 'To Date'
                          : _formatDisplayDate(selectedToDate!),
                      icon: Icons.calendar_today_outlined,
                      onPressed: () => _selectDate(isFromDate: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: _clearFilterButton(),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _gradeDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _sectionDropdown()),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _subjectDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _statusDropdown()),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dateButton(
                    label: selectedFromDate == null
                        ? 'From Date'
                        : _formatDisplayDate(selectedFromDate!),
                    icon: Icons.calendar_today_outlined,
                    onPressed: () => _selectDate(isFromDate: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateButton(
                    label: selectedToDate == null
                        ? 'To Date'
                        : _formatDisplayDate(selectedToDate!),
                    icon: Icons.calendar_today_outlined,
                    onPressed: () => _selectDate(isFromDate: false),
                  ),
                ),
                const SizedBox(width: 10),
                _clearFilterButton(),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _gradeDropdown() {
    final availableGrades = _availableGrades;

    final safeValue =
        selectedGrade != null && availableGrades.contains(selectedGrade)
        ? selectedGrade
        : null;

    return DropdownButtonFormField<int?>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: _inputDecoration(label: 'Grade', icon: Icons.school_outlined),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All Grades')),
        ...availableGrades.map(
          (grade) =>
              DropdownMenuItem<int?>(value: grade, child: Text('Grade $grade')),
        ),
      ],
      onChanged: isLoading
          ? null
          : (value) async {
              setState(() {
                selectedGrade = value;
                selectedSection = null;
                selectedSubjectId = null;
              });

              await applyFilters();
            },
    );
  }

  Widget _sectionDropdown() {
    final availableSections = _availableSections;

    final safeValue =
        selectedSection != null && availableSections.contains(selectedSection)
        ? selectedSection
        : null;

    return DropdownButtonFormField<String?>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Section',
        icon: Icons.groups_outlined,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Sections'),
        ),
        ...availableSections.map(
          (section) => DropdownMenuItem<String?>(
            value: section,
            child: Text('Section $section'),
          ),
        ),
      ],
      onChanged: isLoading
          ? null
          : (value) async {
              setState(() {
                selectedSection = value;
                selectedSubjectId = null;
              });

              await applyFilters();
            },
    );
  }

  Widget _subjectDropdown() {
    final availableSubjects = _availableSubjects;

    final availableIds = availableSubjects
        .map(
          (subject) =>
              int.tryParse(subject['grade_subject_id']?.toString() ?? ''),
        )
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();

    final safeValue =
        selectedSubjectId != null && availableIds.contains(selectedSubjectId)
        ? selectedSubjectId
        : null;

    return DropdownButtonFormField<int?>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Subject',
        icon: Icons.menu_book_outlined,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All Subjects')),
        ...availableSubjects.map((subject) {
          final gradeSubjectId = int.tryParse(
            subject['grade_subject_id']?.toString() ?? '',
          );

          final name = subject['subject_name']?.toString().trim() ?? 'Subject';

          if (gradeSubjectId == null || gradeSubjectId <= 0) {
            return null;
          }

          return DropdownMenuItem<int?>(
            value: gradeSubjectId,
            child: Text(name, overflow: TextOverflow.ellipsis),
          );
        }).whereType<DropdownMenuItem<int?>>(),
      ],
      onChanged: isLoading
          ? null
          : (value) async {
              setState(() {
                selectedSubjectId = value;
              });

              await applyFilters();
            },
    );
  }

  Widget _statusDropdown() {
    final safeValue = selectedStatus == 'Active' || selectedStatus == 'Closed'
        ? selectedStatus
        : null;

    return DropdownButtonFormField<String?>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: _inputDecoration(label: 'Status', icon: Icons.flag_outlined),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('All Status')),
        DropdownMenuItem<String?>(value: 'Active', child: Text('Active')),
        DropdownMenuItem<String?>(value: 'Closed', child: Text('Closed')),
      ],
      onChanged: isLoading
          ? null
          : (value) async {
              setState(() {
                selectedStatus = value;
              });

              await applyFilters();
            },
    );
  }

  Widget _dateButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF9FAFB),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isFromDate}) async {
    final initialGregorian = isFromDate ? selectedFromDate : selectedToDate;

    final initialEthiopian = initialGregorian == null
        ? _todayEthiopian()
        : _gregorianToEthiopian(initialGregorian);

    final picked = await _showEthiopianDatePicker(
      initialDate: initialEthiopian,
    );

    if (picked == null || !mounted) {
      return;
    }

    final pickedGregorian = _ethiopianToGregorian(
      picked.year,
      picked.month,
      picked.day,
    );

    if (isFromDate) {
      if (selectedToDate != null && pickedGregorian.isAfter(selectedToDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('From Date cannot be after To Date.')),
        );
        return;
      }

      setState(() {
        selectedFromDate = pickedGregorian;
      });
    } else {
      if (selectedFromDate != null &&
          pickedGregorian.isBefore(selectedFromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To Date cannot be before From Date.')),
        );
        return;
      }

      setState(() {
        selectedToDate = pickedGregorian;
      });
    }

    await applyFilters();
  }

  Future<_EthiopianDate?> _showEthiopianDatePicker({
    required _EthiopianDate initialDate,
  }) async {
    return showDialog<_EthiopianDate>(
      context: context,
      builder: (context) {
        return _EthiopianDateDialog(initialDate: initialDate);
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Widget _clearFilterButton() {
    final hasFilters =
        selectedGrade != null ||
        selectedSection != null ||
        selectedSubjectId != null ||
        selectedStatus != null ||
        selectedFromDate != null ||
        selectedToDate != null;

    return OutlinedButton.icon(
      onPressed: !hasFilters || isLoading ? null : clearFilters,
      icon: const Icon(Icons.clear, size: 18),
      label: const Text('Clear'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4B5563),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (homework.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () => loadHomework(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          _buildTable(),
          const SizedBox(height: 12),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 72,
            columnSpacing: 22,
            horizontalMargin: 14,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            columns: const [
              DataColumn(
                label: Text('#', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              DataColumn(
                label: Text(
                  'Homework',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Class',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Subject',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Assigned',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Due',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            rows: List.generate(
              homework.length,
              (index) => _buildHomeworkRow(homework[index], index),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildHomeworkRow(Map<String, dynamic> item, int index) {
    final id = int.tryParse(item['id']?.toString() ?? '');

    final title = item['title']?.toString() ?? 'Untitled Homework';

    final grade = item['grade']?.toString() ?? '';

    final section = item['section']?.toString() ?? '';

    final subject = item['subject_name']?.toString() ?? 'Subject';

    final assignedDate = _getEthiopianDate(item['assigned_date_ethiopian']);

    final dueDate = _getEthiopianDate(item['due_date_ethiopian']);

    final status = item['status']?.toString() ?? 'Active';

    return DataRow(
      onSelectChanged: id == null ? null : (_) => _showHomeworkActions(id),
      cells: [
        DataCell(
          Text(
            '${((currentPage - 1) * 10) + index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            'Grade $grade\nSection $section',
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ),
        DataCell(
          SizedBox(
            width: 130,
            child: Text(
              subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
        ),
        DataCell(
          Text(
            assignedDate,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ),
        DataCell(
          Text(
            dueDate,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ),
        DataCell(_statusBadge(status)),
        DataCell(
          IconButton(
            tooltip: 'Actions',
            onPressed: id == null ? null : () => _showHomeworkActions(id),
            icon: const Icon(Icons.more_vert, size: 20),
          ),
        ),
      ],
    );
  }

  String _getEthiopianDate(dynamic value) {
    if (value is Map) {
      final formatted = value['formatted']?.toString();

      if (formatted != null && formatted.isNotEmpty) {
        return formatted;
      }

      final year = value['year']?.toString() ?? '';

      final month = value['month']?.toString() ?? '';

      final day = value['day']?.toString() ?? '';

      if (year.isNotEmpty && month.isNotEmpty && day.isNotEmpty) {
        return '$year-$month-$day';
      }
    }

    if (value != null) {
      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '-';
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final isActive = normalized == 'active';

    final background = isActive
        ? const Color(0xFFECFDF5)
        : const Color(0xFFF3F4F6);

    final foreground = isActive
        ? const Color(0xFF047857)
        : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentPage > 1 && !isLoadingMore
                  ? previousPage
                  : null,
              icon: const Icon(Icons.chevron_left, size: 19),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4B5563),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentPage < totalPages && !isLoadingMore
                  ? nextPage
                  : null,
              icon: const Icon(Icons.chevron_right, size: 19),
              label: const Text('Next'),
              iconAlignment: IconAlignment.end,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4B5563),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final hasFilters =
        selectedGrade != null ||
        selectedSection != null ||
        selectedSubjectId != null ||
        selectedStatus != null ||
        selectedFromDate != null ||
        selectedToDate != null;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () => loadHomework(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 39,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No homework found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try changing or clearing your filters.'
                : 'No homework has been assigned yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: hasFilters ? clearFilters : null,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      onRefresh: () => loadHomework(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Colors.redAccent,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Unable to load homework',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => loadHomework(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatApiDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final ethiopian = _gregorianToEthiopian(date);

    return '${ethiopian.monthName} '
        '${ethiopian.day}, '
        '${ethiopian.year}';
  }

  _EthiopianDate _todayEthiopian() {
    return _gregorianToEthiopian(DateTime.now());
  }

  _EthiopianDate _gregorianToEthiopian(DateTime date) {
    final gregorian = DateTime(date.year, date.month, date.day);

    var ethiopianYear = gregorian.year - 7;

    var newYear = _ethiopianNewYearDate(ethiopianYear);

    if (gregorian.isBefore(newYear)) {
      ethiopianYear--;

      newYear = _ethiopianNewYearDate(ethiopianYear);
    }

    final daysSinceNewYear = gregorian.difference(newYear).inDays;

    final ethiopianMonth = (daysSinceNewYear ~/ 30) + 1;

    final ethiopianDay = (daysSinceNewYear % 30) + 1;

    return _EthiopianDate(
      year: ethiopianYear,
      month: ethiopianMonth,
      day: ethiopianDay,
    );
  }

  DateTime _ethiopianToGregorian(int year, int month, int day) {
    final newYear = _ethiopianNewYearDate(year);

    final daysToAdd = ((month - 1) * 30) + (day - 1);

    return newYear.add(Duration(days: daysToAdd));
  }

  DateTime _ethiopianNewYearDate(int ethiopianYear) {
    final gregorianYear = ethiopianYear + 7;

    final followingYear = gregorianYear + 1;

    final isLeap =
        (followingYear % 400 == 0) ||
        (followingYear % 4 == 0 && followingYear % 100 != 0);

    return DateTime(gregorianYear, 9, isLeap ? 12 : 11);
  }
}

class _EthiopianDate {
  final int year;
  final int month;
  final int day;

  const _EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
  });

  String get monthName {
    const months = [
      '',
      'Meskerem',
      'Tikimt',
      'Hidar',
      'Tahsas',
      'Tir',
      'Yekatit',
      'Megabit',
      'Miyazya',
      'Ginbot',
      'Sene',
      'Hamle',
      'Nehase',
      'Pagume',
    ];

    return months[month];
  }

  int get daysInMonth {
    if (month == 13) {
      return (year % 4) == 3 ? 6 : 5;
    }

    return 30;
  }
}

class _EthiopianDateDialog extends StatefulWidget {
  final _EthiopianDate initialDate;

  const _EthiopianDateDialog({required this.initialDate});

  @override
  State<_EthiopianDateDialog> createState() => _EthiopianDateDialogState();
}

class _EthiopianDateDialogState extends State<_EthiopianDateDialog> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  static const List<String> months = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miyazya',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  @override
  void initState() {
    super.initState();

    selectedYear = widget.initialDate.year;

    selectedMonth = widget.initialDate.month;

    selectedDay = widget.initialDate.day;
  }

  int get daysInSelectedMonth {
    if (selectedMonth == 13) {
      return (selectedYear % 4) == 3 ? 6 : 5;
    }

    return 30;
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(daysInSelectedMonth, (index) => index + 1);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Select Ethiopian Date',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(151, (index) {
                      final year = 1950 + index;

                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedYear = value;

                        if (selectedMonth == 13 &&
                            selectedDay > daysInSelectedMonth) {
                          selectedDay = daysInSelectedMonth;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(13, (index) {
                      final month = index + 1;

                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(
                          months[index],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedMonth = value;

                        if (selectedDay > daysInSelectedMonth) {
                          selectedDay = daysInSelectedMonth;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${months[selectedMonth - 1]} '
                '$selectedDay, '
                '$selectedYear',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 270,
              child: GridView.builder(
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];

                  final selected = day == selectedDay;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _EthiopianDate(
                year: selectedYear,
                month: selectedMonth,
                day: selectedDay,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
