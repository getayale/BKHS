import 'package:flutter/material.dart';

import '/api_service.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;
  String? successMessage;

  List<Map<String, dynamic>> semesters = [];
  List<Map<String, dynamic>> assignments = [];
  List<int> grades = [];
  List<Map<String, dynamic>> students = [];

  Map<String, dynamic> sectionsByGrade = {};
  Map<String, dynamic> subjectsByClass = {};
  Map<String, dynamic> summary = {};
  Map<String, dynamic> pagination = {};
  Map<String, dynamic> academicYear = {};
  Map<String, dynamic> permissions = {};
  Map<String, dynamic> selected = {};
  Map<String, dynamic> subject = {};
  Map<String, dynamic> activeSemester = {};

  int? selectedSemesterId;
  int? selectedGrade;
  String? selectedSection;
  int? selectedSubjectId;

  int currentPage = 1;
  int totalPages = 1;

  final TextEditingController searchController = TextEditingController();

  final Map<int, TextEditingController> markControllers = {};

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  @override
  void dispose() {
    searchController.dispose();

    for (final controller in markControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> loadResults({int page = 1}) async {
    if (!mounted) return;

    if (page < 1) {
      page = 1;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      currentPage = page;
    });

    try {
      final data = await ApiService.getTeacherResults(
        semesterId: selectedSemesterId,
        grade: selectedGrade,
        section: selectedSection,
        subjectId: selectedSubjectId,
        search: searchController.text.trim(),
        page: page,
      );

      if (!mounted) return;

      _readResponse(data);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _cleanError(e);
      });
    }
  }

  void _readResponse(Map<String, dynamic> data) {
    semesters = _mapList(data['semesters']);
    assignments = _mapList(data['assignments']);

    grades = _readGrades(data['grades']);

    sectionsByGrade = _mapValue(data['sections_by_grade']);
    subjectsByClass = _mapValue(data['subjects_by_class']);

    summary = _mapValue(data['summary']);
    pagination = _mapValue(data['pagination']);
    academicYear = _mapValue(data['academic_year']);
    permissions = _mapValue(data['permissions']);
    selected = _mapValue(data['selected']);
    subject = _mapValue(data['subject']);
    activeSemester = _mapValue(data['active_semester']);

    students = _mapList(data['students']);

    final apiSemesterId = _toInt(selected['semester_id']);
    final apiGrade = _toInt(selected['grade']);
    final apiSection = selected['section']?.toString();
    final apiSubjectId = _toInt(selected['subject_id']);

    if (selectedSemesterId == null && apiSemesterId != null) {
      selectedSemesterId = apiSemesterId;
    }

    if (selectedGrade == null &&
        apiGrade != null &&
        grades.contains(apiGrade)) {
      selectedGrade = apiGrade;
    }

    if (selectedSection == null &&
        apiSection != null &&
        apiSection.trim().isNotEmpty) {
      final normalizedSection = apiSection.trim().toUpperCase();

      if (_sectionStringsForGrade(selectedGrade).contains(normalizedSection)) {
        selectedSection = normalizedSection;
      }
    }

    if (selectedSubjectId == null &&
        apiSubjectId != null &&
        _subjectIdsForClass(
          selectedGrade,
          selectedSection,
        ).contains(apiSubjectId)) {
      selectedSubjectId = apiSubjectId;
    }

    if (selectedSemesterId == null && semesters.isNotEmpty) {
      Map<String, dynamic>? active;

      for (final semester in semesters) {
        if (semester['status']?.toString().toLowerCase() == 'active') {
          active = semester;
          break;
        }
      }

      active ??= semesters.first;

      selectedSemesterId = _toInt(active['id']);
    }

    currentPage = _toInt(pagination['current_page']) ?? 1;
    totalPages = _toInt(pagination['total_pages']) ?? 1;

    if (currentPage < 1) {
      currentPage = 1;
    }

    if (totalPages < 1) {
      totalPages = 1;
    }

    _syncMarkControllers();
  }

  List<int> _readGrades(dynamic value) {
    if (value is! List) {
      return [];
    }

    final result = <int>[];

    for (final item in value) {
      final grade = _toInt(item);

      if (grade != null && grade > 0) {
        result.add(grade);
      }
    }

    result.sort();
    return result;
  }

  List<String> _sectionStringsForGrade(int? grade) {
    if (grade == null) {
      return [];
    }

    final raw = sectionsByGrade[grade.toString()];

    if (raw is! List) {
      return [];
    }

    final sections = <String>[];

    for (final item in raw) {
      final value = item.toString().trim().toUpperCase();

      if (value.isNotEmpty && !sections.contains(value)) {
        sections.add(value);
      }
    }

    sections.sort();
    return sections;
  }

  List<int> _subjectIdsForClass(int? grade, String? section) {
    if (grade == null || section == null || section.trim().isEmpty) {
      return [];
    }

    final key = '$grade|${section.trim().toUpperCase()}';
    final raw = subjectsByClass[key];

    if (raw is! List) {
      return [];
    }

    final ids = <int>[];

    for (final item in raw) {
      if (item is Map) {
        final id = _toInt(item['id']);

        if (id != null && !ids.contains(id)) {
          ids.add(id);
        }
      }
    }

    return ids;
  }

  void _syncMarkControllers() {
    final currentIds = <int>{};

    for (final student in students) {
      final registrationId = _studentRegistrationId(student);

      if (registrationId == null) {
        continue;
      }

      currentIds.add(registrationId);

      final mark = _studentMark(student);
      final expectedText = mark == null ? '' : _formatMark(mark);

      if (!markControllers.containsKey(registrationId)) {
        markControllers[registrationId] = TextEditingController(
          text: expectedText,
        );
      } else {
        final controller = markControllers[registrationId]!;

        if (controller.text != expectedText) {
          controller.text = expectedText;
        }
      }
    }

    final oldIds = markControllers.keys
        .where((id) => !currentIds.contains(id))
        .toList();

    for (final id in oldIds) {
      markControllers[id]?.dispose();
      markControllers.remove(id);
    }
  }

  Future<void> saveResults() async {
    if (!_canEditResults) {
      _showMessage('The selected semester is read-only.', isError: true);
      return;
    }

    if (selectedSemesterId == null) {
      _showMessage('Please select a semester.', isError: true);
      return;
    }

    if (selectedGrade == null) {
      _showMessage('Please select a grade.', isError: true);
      return;
    }

    if (selectedSection == null || selectedSection!.trim().isEmpty) {
      _showMessage('Please select a section.', isError: true);
      return;
    }

    if (selectedSubjectId == null) {
      _showMessage('Please select a subject.', isError: true);
      return;
    }

    final maxMark = _maxMark;
    final marks = <int, dynamic>{};

    for (final student in students) {
      final registrationId = _studentRegistrationId(student);

      if (registrationId == null) {
        continue;
      }

      final controller = markControllers[registrationId];

      if (controller == null) {
        continue;
      }

      final text = controller.text.trim();

      if (text.isEmpty) {
        continue;
      }

      final mark = double.tryParse(text);

      if (mark == null) {
        _showMessage(
          'Invalid mark for ${_studentName(student)}.',
          isError: true,
        );
        return;
      }

      if (mark < 0 || mark > maxMark) {
        _showMessage(
          'Mark for ${_studentName(student)} must be between 0 and ${_formatMark(maxMark)}.',
          isError: true,
        );
        return;
      }

      marks[registrationId] = _cleanNumber(mark);
    }

    if (marks.isEmpty) {
      _showMessage('Please enter at least one mark.', isError: true);
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final data = await ApiService.saveTeacherResults(
        semesterId: selectedSemesterId!,
        grade: selectedGrade!,
        section: selectedSection!.trim().toUpperCase(),
        subjectId: selectedSubjectId!,
        marks: marks,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
        successMessage =
            data['message']?.toString() ?? 'Results saved successfully.';
      });

      await loadResults(page: currentPage);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
        errorMessage = _cleanError(e);
      });
    }
  }

  void _onSemesterChanged(int? value) {
    if (value == null) return;

    setState(() {
      selectedSemesterId = value;
      currentPage = 1;
    });

    loadResults(page: 1);
  }

  void _onGradeChanged(int? value) {
    if (value == null) return;

    setState(() {
      selectedGrade = value;
      selectedSection = null;
      selectedSubjectId = null;
      subject = {};
      students = [];
      summary = {};
      pagination = {};
      currentPage = 1;
    });

    loadResults(page: 1);
  }

  void _onSectionChanged(String? value) {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    setState(() {
      selectedSection = value.trim().toUpperCase();
      selectedSubjectId = null;
      subject = {};
      students = [];
      summary = {};
      pagination = {};
      currentPage = 1;
    });

    loadResults(page: 1);
  }

  void _onSubjectChanged(int? value) {
    if (value == null) return;

    setState(() {
      selectedSubjectId = value;
      currentPage = 1;
    });

    loadResults(page: 1);
  }

  void _search() {
    loadResults(page: 1);
  }

  void _clearSearch() {
    searchController.clear();
    loadResults(page: 1);
  }

  bool get _canEditResults {
    final permission = permissions['can_edit'];

    if (permission is bool) {
      return permission;
    }

    if (permission != null) {
      final value = permission.toString().toLowerCase();

      if (value == 'true' || value == '1') {
        return true;
      }

      if (value == 'false' || value == '0') {
        return false;
      }
    }

    return _selectedSemesterStatus.toLowerCase() == 'active';
  }

  String get _selectedSemesterStatus {
    final status = selected['semester_status'] ?? selected['status'];

    if (status != null && status.toString().trim().isNotEmpty) {
      return status.toString();
    }

    if (selectedSemesterId != null) {
      for (final semester in semesters) {
        if (_toInt(semester['id']) == selectedSemesterId) {
          return semester['status']?.toString() ?? '';
        }
      }
    }

    return '';
  }

  String get _selectedSemesterName {
    if (selectedSemesterId != null) {
      for (final semester in semesters) {
        if (_toInt(semester['id']) == selectedSemesterId) {
          return semester['name']?.toString() ?? 'Semester';
        }
      }
    }

    return 'Semester';
  }

  double get _maxMark {
    final value = subject['max_mark'] ?? selected['max_mark'];

    return double.tryParse(value?.toString() ?? '') ?? 100;
  }

  List<String> get _availableSections {
    return _sectionStringsForGrade(selectedGrade);
  }

  List<Map<String, dynamic>> get _availableSubjects {
    if (selectedGrade == null ||
        selectedSection == null ||
        selectedSection!.trim().isEmpty) {
      return [];
    }

    final key = '${selectedGrade!}|${selectedSection!.trim().toUpperCase()}';

    final raw = subjectsByClass[key];

    return _mapList(raw);
  }

  String _studentName(Map<String, dynamic> student) {
    return student['full_name']?.toString() ??
        student['name']?.toString() ??
        'Student';
  }

  String _studentCode(Map<String, dynamic> student) {
    return student['student_code']?.toString() ??
        student['code']?.toString() ??
        '';
  }

  int? _studentRegistrationId(Map<String, dynamic> student) {
    return _toInt(
      student['registration_id'] ??
          student['student_registration_id'] ??
          student['id'],
    );
  }

  double? _studentMark(Map<String, dynamic> student) {
    final value = student['mark'] ?? student['result'] ?? student['score'];

    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.toString());
  }

  String _formatMark(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  dynamic _cleanNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt();
    }

    return value;
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  String _academicYearText() {
    if (academicYear.isEmpty) {
      return '';
    }

    final name = academicYear['name']?.toString();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          'Results',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => loadResults(page: currentPage),
          child: isLoading && semesters.isEmpty && students.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 10 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 12),
              if (errorMessage != null) _buildMessage(errorMessage!, true),
              if (successMessage != null) _buildMessage(successMessage!, false),
              _buildFilters(isMobile),
              const SizedBox(height: 12),
              _buildSemesterStatus(),
              const SizedBox(height: 12),
              _buildSummary(),
              const SizedBox(height: 12),
              _buildResultCard(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final year = _academicYearText();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 46,
            height: isMobile ? 40 : 46,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: isMobile ? 21 : 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Results',
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Academic Year $year',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildSemesterDropdown()),
        const SizedBox(width: 10),
        Expanded(child: _buildGradeDropdown()),
        const SizedBox(width: 10),
        Expanded(child: _buildSectionDropdown()),
        const SizedBox(width: 10),
        Expanded(child: _buildSubjectDropdown()),
        const SizedBox(width: 10),
        Expanded(child: _buildSearchField()),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSemesterDropdown()),
            const SizedBox(width: 8),
            Expanded(child: _buildGradeDropdown()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSectionDropdown()),
            const SizedBox(width: 8),
            Expanded(child: _buildSubjectDropdown()),
          ],
        ),
        const SizedBox(height: 8),
        _buildSearchField(),
      ],
    );
  }

  Widget _buildSemesterDropdown() {
    return _buildDropdownContainer(
      label: 'Semester',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _validSemesterValue ? selectedSemesterId : null,
          isExpanded: true,
          hint: const Text('Select'),
          items: semesters
              .map((semester) {
                final id = _toInt(semester['id']);

                if (id == null) {
                  return null;
                }

                final name = semester['name']?.toString() ?? 'Semester';

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              })
              .whereType<DropdownMenuItem<int>>()
              .toList(),
          onChanged: _onSemesterChanged,
        ),
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return _buildDropdownContainer(
      label: 'Grade',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _validGradeValue ? selectedGrade : null,
          isExpanded: true,
          hint: const Text('Select'),
          items: grades
              .map(
                (grade) => DropdownMenuItem<int>(
                  value: grade,
                  child: Text('Grade $grade', overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: grades.isEmpty ? null : _onGradeChanged,
        ),
      ),
    );
  }

  Widget _buildSectionDropdown() {
    final sections = _availableSections;

    return _buildDropdownContainer(
      label: 'Section',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _validSectionValue ? selectedSection : null,
          isExpanded: true,
          hint: const Text('Select'),
          items: sections
              .map(
                (section) => DropdownMenuItem<String>(
                  value: section,
                  child: Text(section, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: sections.isEmpty ? null : _onSectionChanged,
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    final subjects = _availableSubjects;

    return _buildDropdownContainer(
      label: 'Subject',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _validSubjectValue ? selectedSubjectId : null,
          isExpanded: true,
          hint: const Text('Select'),
          items: subjects
              .map((item) {
                final id = _toInt(item['id']);

                if (id == null) {
                  return null;
                }

                final name =
                    item['name']?.toString() ??
                    item['subject_name']?.toString() ??
                    'Subject';

                return DropdownMenuItem<int>(
                  value: id,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              })
              .whereType<DropdownMenuItem<int>>()
              .toList(),
          onChanged: subjects.isEmpty ? null : _onSubjectChanged,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: (_) {
            setLocalState(() {});
          },
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            labelText: 'Search student',
            hintText: 'Name or code',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.trim().isEmpty
                ? IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward),
                  )
                : IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      ),
      child: child,
    );
  }

  bool get _validSemesterValue {
    return semesters.any(
      (semester) => _toInt(semester['id']) == selectedSemesterId,
    );
  }

  bool get _validGradeValue {
    return grades.contains(selectedGrade);
  }

  bool get _validSectionValue {
    if (selectedSection == null) {
      return false;
    }

    return _availableSections.contains(selectedSection!.trim().toUpperCase());
  }

  bool get _validSubjectValue {
    return _availableSubjects.any(
      (item) => _toInt(item['id']) == selectedSubjectId,
    );
  }

  Widget _buildSemesterStatus() {
    final status = _selectedSemesterStatus.trim();

    final editable = _canEditResults;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedSemesterName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: editable ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  editable ? Icons.edit_outlined : Icons.lock_outline,
                  size: 15,
                  color: editable
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
                const SizedBox(width: 5),
                Text(
                  status.isEmpty
                      ? editable
                            ? 'Active'
                            : 'Read only'
                      : status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: editable
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final total =
        summary['students']?.toString() ??
        summary['total_students']?.toString() ??
        '0';

    final recorded =
        summary['recorded']?.toString() ??
        summary['results_recorded']?.toString() ??
        '0';

    final missing =
        summary['missing']?.toString() ??
        summary['missing_results']?.toString() ??
        '0';

    return Row(
      children: [
        Expanded(child: _summaryCard('Students', total, Icons.people_outline)),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard('Recorded', recorded, Icons.check_circle_outline),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard('Missing', missing, Icons.warning_amber_outlined),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    final primary = Theme.of(context).colorScheme.primary;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: primary),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildResultHeader(isMobile),
          const Divider(height: 1),
          if (students.isEmpty)
            _buildEmptyState()
          else
            _buildStudentsTable(isMobile),
          if (students.isNotEmpty) _buildPagination(isMobile),
        ],
      ),
    );
  }

  Widget _buildResultHeader(bool isMobile) {
    final subjectName =
        subject['name']?.toString() ??
        subject['subject_name']?.toString() ??
        '';

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  subjectName.isEmpty ? 'Student Results' : subjectName,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '• ${_selectedSemesterName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  '• ${_selectedSemesterStatus.isEmpty ? 'Active' : _selectedSemesterStatus}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _canEditResults
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
                Text(
                  '• Max ${_formatMark(_maxMark)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (_canEditResults) ...[
            const SizedBox(width: 8),
            _buildSaveButton(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isMobile) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: isSaving || students.isEmpty ? null : saveResults,
        icon: isSaving
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 17),
        label: Text(
          isSaving ? 'Saving' : 'Save',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }

  Widget _buildStudentsTable(bool isMobile) {
    final table = DataTable(
      columnSpacing: isMobile ? 12 : 28,
      horizontalMargin: isMobile ? 10 : 16,
      headingRowHeight: 44,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 62,
      headingTextStyle: TextStyle(
        fontSize: isMobile ? 12 : 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
      ),
      columns: const [
        DataColumn(label: Text('No')),
        DataColumn(label: Text('Student')),
        DataColumn(label: Text('Student Code')),
        DataColumn(label: Text('Mark')),
      ],
      rows: List.generate(
        students.length,
        (index) => _buildStudentTableRow(students[index], index, isMobile),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: isMobile ? table : SizedBox(width: 760, child: table),
    );
  }

  DataRow _buildStudentTableRow(
    Map<String, dynamic> student,
    int index,
    bool isMobile,
  ) {
    final registrationId = _studentRegistrationId(student);

    final number = ((currentPage - 1) * 10) + index + 1;

    return DataRow(
      cells: [
        DataCell(
          Text(
            number.toString(),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
        DataCell(
          SizedBox(
            width: isMobile ? 150 : 230,
            child: Text(
              _studentName(student),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            _studentCode(student).isEmpty ? '-' : _studentCode(student),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
        DataCell(
          SizedBox(
            width: isMobile ? 80 : 150,
            child: _buildMarkField(registrationId),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkField(int? registrationId) {
    if (registrationId == null) {
      return const Text('-');
    }

    final controller = markControllers[registrationId];

    if (controller == null) {
      return const Text('-');
    }

    if (!_canEditResults) {
      final value = controller.text.trim();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: value.isEmpty ? Colors.grey.shade500 : Colors.grey.shade800,
          ),
        ),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '0-${_formatMark(_maxMark)}',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(bool isMobile) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous',
            onPressed: currentPage > 1 && !isLoading
                ? () => loadResults(page: currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 4),
          Text(
            '$currentPage / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Next',
            onPressed: currentPage < totalPages && !isLoading
                ? () => loadResults(page: currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasGrade = selectedGrade != null;
    final hasSection =
        selectedSection != null && selectedSection!.trim().isNotEmpty;
    final hasSubject = selectedSubjectId != null;

    String message;

    if (!hasGrade) {
      message = 'Select a grade to continue.';
    } else if (!hasSection) {
      message = 'Select a section to continue.';
    } else if (!hasSubject) {
      message = 'Select a subject to view students.';
    } else {
      message = 'No students found for the selected filters.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 45),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'No students found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String message, bool isError) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 19,
            color: isError ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isError ? Colors.red.shade800 : Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
