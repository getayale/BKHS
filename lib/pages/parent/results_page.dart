import 'package:flutter/material.dart';

import '/api_service.dart';
import '/parent_apiservice.dart';
import '/pages/parent/attendance_page.dart';
import '/pages/parent/announcements_page.dart';
import '/pages/parent/homework_page.dart';

class ParentResultsPage extends StatefulWidget {
  final int studentId;

  const ParentResultsPage({super.key, required this.studentId});

  @override
  State<ParentResultsPage> createState() => _ParentResultsPageState();
}

class _ParentResultsPageState extends State<ParentResultsPage> {
  late final ParentApiService _apiService;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _academicYear;
  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _results = [];

  String _selectedSemester = 'First Semester';

  final List<Map<String, String>> _semesters = [
    {'name': 'Mid Semester', 'maximum': '50'},
    {'name': 'First Semester', 'maximum': '100'},
    {'name': 'Quarter Semester', 'maximum': '50'},
    {'name': 'Second Semester', 'maximum': '100'},
  ];

  @override
  void initState() {
    super.initState();

    _apiService = ParentApiService(baseUrl: ApiService.baseUrl);

    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = ApiService.token;

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication token is missing.');
      }

      final data = await _apiService.getResults(token, widget.studentId);

      if (!mounted) return;

      final academicYearData = data['academic_year'];
      final studentData = data['student'];
      final resultsData = data['results'];

      final results = <Map<String, dynamic>>[];

      if (resultsData is List) {
        for (final result in resultsData) {
          if (result is Map) {
            results.add(Map<String, dynamic>.from(result));
          }
        }
      }

      setState(() {
        _academicYear = academicYearData is Map
            ? Map<String, dynamic>.from(academicYearData)
            : null;

        _student = studentData is Map
            ? Map<String, dynamic>.from(studentData)
            : null;

        _results = results;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');

        _isLoading = false;
      });
    }
  }

  String _studentName() {
    final name = _student?['full_name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Student';
    }

    return name;
  }

  String _studentCode() {
    final code = _student?['student_code']?.toString().trim();

    if (code == null || code.isEmpty) {
      return 'N/A';
    }

    return code;
  }

  String _grade() {
    final grade = _student?['grade_number']?.toString().trim();

    if (grade == null || grade.isEmpty) {
      return 'N/A';
    }

    return 'Grade $grade';
  }

  String _section() {
    final section = _student?['section']?.toString().trim();

    if (section == null || section.isEmpty) {
      return 'N/A';
    }

    return section;
  }

  String _academicYearName() {
    final name = _academicYear?['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'N/A';
    }

    return name;
  }

  String _formatMark(dynamic value) {
    if (value == null) {
      return 'Not Entered';
    }

    final mark = double.tryParse(value.toString());

    if (mark == null) {
      return 'Not Entered';
    }

    if (mark == mark.truncateToDouble()) {
      return mark.toInt().toString();
    }

    return mark.toStringAsFixed(1);
  }

  String _getMarkKey() {
    switch (_selectedSemester) {
      case 'Mid Semester':
        return 'mid_mark';

      case 'First Semester':
        return 'first_mark';

      case 'Quarter Semester':
        return 'quarter_mark';

      case 'Second Semester':
        return 'second_mark';

      default:
        return 'first_mark';
    }
  }

  String _getGradeKey() {
    switch (_selectedSemester) {
      case 'First Semester':
        return 'first_grade';

      case 'Second Semester':
        return 'second_grade';

      default:
        return '';
    }
  }

  String _getMaximumMark() {
    for (final semester in _semesters) {
      if (semester['name'] == _selectedSemester) {
        return semester['maximum'] ?? '100';
      }
    }

    return '100';
  }

  String _getLetterGrade(dynamic value) {
    if (value == null) {
      return '—';
    }

    final grade = value.toString().trim();

    if (grade.isEmpty || grade == 'Not Entered') {
      return '—';
    }

    return grade;
  }

  bool _isFailed(dynamic value) {
    if (value == null) {
      return false;
    }

    final mark = double.tryParse(value.toString());

    if (mark == null) {
      return false;
    }

    return mark < 60;
  }

  Color _markColor(dynamic value) {
    if (value == null) {
      return const Color(0xFF6B7280);
    }

    if (_isFailed(value)) {
      return const Color(0xFFDC2626);
    }

    return const Color(0xFF111827);
  }

  Color _gradeColor(dynamic value) {
    if (value == null) {
      return const Color(0xFF6B7280);
    }

    final grade = value.toString().trim();

    if (grade == 'F') {
      return const Color(0xFFDC2626);
    }

    if (grade == 'A+' || grade == 'A') {
      return const Color(0xFF059669);
    }

    return const Color(0xFF2563EB);
  }

  void _onBottomNavigationTap(int index) {
    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (index == 1) {
      return;
    }

    switch (index) {
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ParentAttendancePage(studentId: widget.studentId),
          ),
        );
        break;

      case 3:
        final token = ApiService.token;

        if (token == null || token.trim().isEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication token is missing.'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                HomeworkPage(token: token, studentId: widget.studentId),
          ),
        );
        break;

      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ParentAnnouncementsPage(studentId: widget.studentId),
          ),
        );
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon.'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Results',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: _loadResults,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        children: [
          _buildStudentHeader(),

          const SizedBox(height: 16),

          _buildAcademicYearCard(),

          const SizedBox(height: 20),

          _buildSemesterSelector(),

          const SizedBox(height: 16),

          _buildResultsTable(),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    final name = _studentName();

    final firstLetter = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'S';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _studentCode(),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_grade()} • Section ${_section()}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicYearCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFF2563EB),
            size: 21,
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Academic Year',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            _academicYearName(),
            style: const TextStyle(
              color: Color(0xFF1E40AF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Semester',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: _selectedSemester,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.school_outlined,
                color: Color(0xFF2563EB),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            items: _semesters.map((semester) {
              final name = semester['name']!;

              return DropdownMenuItem<String>(
                value: name,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedSemester = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable() {
    if (_results.isEmpty) {
      return _buildNoResultsCard();
    }

    final markKey = _getMarkKey();

    final gradeKey = _getGradeKey();

    final maximum = _getMaximumMark();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.assessment_outlined,
                  color: Color(0xFF2563EB),
                  size: 21,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    _selectedSemester,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Text(
                  '/ $maximum',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 26,
              horizontalMargin: 14,
              headingRowHeight: 46,
              dataRowMinHeight: 54,
              dataRowMaxHeight: 64,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'Subject',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                DataColumn(
                  numeric: true,
                  label: Text(
                    'Mark',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                DataColumn(
                  label: Text(
                    'Grade',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              rows: _results.map((result) {
                final subjectName =
                    result['subject_name']?.toString().trim().isNotEmpty == true
                    ? result['subject_name'].toString().trim()
                    : 'Unknown Subject';

                final mark = result[markKey];

                final grade = gradeKey.isEmpty ? null : result[gradeKey];

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 145,
                        child: Text(
                          subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    DataCell(
                      Text(
                        '${_formatMark(mark)} / $maximum',
                        style: TextStyle(
                          color: _markColor(mark),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    DataCell(
                      grade == null
                          ? const Text(
                              '—',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Container(
                              constraints: const BoxConstraints(minWidth: 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _gradeColor(grade).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getLetterGrade(grade),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _gradeColor(grade),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          if (_selectedSemester == 'First Semester' ||
              _selectedSemester == 'Second Semester')
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResultsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assessment_outlined,
              color: Color(0xFF6B7280),
              size: 28,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No results found',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'No subject results have been entered '
            'for this student yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load results',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: 1,
      backgroundColor: Colors.white,
      elevation: 8,
      height: 68,
      indicatorColor: const Color(0xFFEFF6FF),
      onDestinationSelected: _onBottomNavigationTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF2563EB)),
          label: 'Home',
        ),

        NavigationDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(
            Icons.assessment_rounded,
            color: Color(0xFF2563EB),
          ),
          label: 'Results',
        ),

        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(
            Icons.fact_check_rounded,
            color: Color(0xFF2563EB),
          ),
          label: 'Attendance',
        ),

        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB)),
          label: 'Homework',
        ),

        NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign_rounded, color: Color(0xFF2563EB)),
          label: 'News',
        ),
      ],
    );
  }
}
