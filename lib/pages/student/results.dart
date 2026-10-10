import 'package:flutter/material.dart';

import '../../student_api.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? student;
  List<dynamic> subjects = [];
  List<dynamic> semesters = [];

  int selectedSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await StudentApi.getStudentResults();

      if (!mounted) {
        return;
      }

      setState(() {
        student = data['student'] is Map<String, dynamic>
            ? data['student'] as Map<String, dynamic>
            : null;

        subjects = data['subjects'] is List ? data['subjects'] as List : [];

        semesters = data['semesters'] is List ? data['semesters'] as List : [];

        if (selectedSemesterIndex >= semesters.length) {
          selectedSemesterIndex = 0;
        }

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

  String _formatMark(dynamic mark) {
    if (mark == null) {
      return 'Not Entered';
    }

    if (mark is num) {
      return mark.toStringAsFixed(2);
    }

    final parsed = double.tryParse(mark.toString());

    if (parsed == null) {
      return 'Not Entered';
    }

    return parsed.toStringAsFixed(2);
  }

  Widget _buildStudentInfo() {
    if (student == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?['full_name']?.toString() ?? 'Student',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student?['student_code']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoItem(
                Icons.class_outlined,
                student?['grade_label']?.toString() ?? '-',
              ),
              _buildInfoItem(
                Icons.groups_outlined,
                'Section ${student?['section']?.toString() ?? '-'}',
              ),
              _buildInfoItem(
                Icons.calendar_month_outlined,
                student?['academic_year']?.toString() ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2563EB)),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterDropdown() {
    if (semesters.isEmpty) {
      return const SizedBox.shrink();
    }

    if (selectedSemesterIndex >= semesters.length) {
      selectedSemesterIndex = 0;
    }

    final selectedSemester = semesters[selectedSemesterIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSemesterIndex,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB)),
          hint: const Text(
            'Select Semester',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          items: List.generate(semesters.length, (index) {
            final semester = semesters[index];

            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                '${semester['name']?.toString() ?? '-'} /${semester['maximum_mark']?.toString() ?? '-'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              selectedSemesterIndex = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMark(dynamic mark) {
    final isEntered = mark != null;

    return Container(
      constraints: const BoxConstraints(minWidth: 85),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isEntered ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatMark(mark),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isEntered ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    if (subjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 45),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'No Results Available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'No subject results have been entered yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    if (semesters.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 45),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 12),
            Text(
              'No Semesters Available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      );
    }

    if (selectedSemesterIndex >= semesters.length) {
      selectedSemesterIndex = 0;
    }

    final selectedSemester = semesters[selectedSemesterIndex];

    final semesterName = selectedSemester['name']?.toString() ?? '';

    final maximumMark = selectedSemester['maximum_mark']?.toString() ?? '-';

    String markKey = '';

    if (semesterName == 'Mid Semester') {
      markKey = 'mid_mark';
    } else if (semesterName == 'First Semester') {
      markKey = 'first_mark';
    } else if (semesterName == 'Quarter Semester') {
      markKey = 'quarter_mark';
    } else if (semesterName == 'Second Semester') {
      markKey = 'second_mark';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                children: [
                  const SizedBox(
                    width: 45,
                    child: Center(
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Column(
                      children: [
                        Text(
                          'Mark',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '/$maximumMark',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(subjects.length, (index) {
              final subject = subjects[index];

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          subject['subject_name']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Center(child: _buildMark(subject[markKey])),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildStudentInfo(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 21,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Academic Results',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '${subjects.length} Subjects',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSemesterDropdown(),
          const SizedBox(height: 12),
          _buildResultsTable(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to Load Results',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadResults,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildPage();
  }
}
