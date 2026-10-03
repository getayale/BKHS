import 'package:flutter/material.dart';

import '/api_service.dart';

class TakeAttendancePage extends StatefulWidget {
  const TakeAttendancePage({super.key});

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  Map<String, dynamic>? attendanceData;

  List<dynamic> allStudents = [];
  List<dynamic> students = [];

  String? selectedClass;

  int currentPage = 1;
  int totalPages = 1;

  bool attendanceTaken = false;

  final Map<int, String?> attendanceStatuses = {};

  Map<String, dynamic> statistics = {
    'Present': 0,
    'Absent': 0,
    'Late': 0,
    'Excused': 0,
  };

  final List<String> statusOptions = ['Present', 'Absent', 'Late', 'Excused'];

  static const int studentsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance({String? className, int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getAllTeacherAttendance(
        className: className ?? selectedClass,
      );

      if (!mounted) return;

      final returnedStudents = data['students'] as List<dynamic>? ?? [];

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      final returnedStatistics =
          data['statistics'] as Map<String, dynamic>? ?? {};

      final returnedAttendanceTaken = data['attendance_taken'] == true;

      final returnedSelectedClass =
          data['selected_class'] as Map<String, dynamic>?;

      final newStatuses = <int, String?>{};

      for (final student in returnedStudents) {
        if (student is! Map) {
          continue;
        }

        final studentId = int.tryParse(student['student_id']?.toString() ?? '');

        if (studentId == null) {
          continue;
        }

        final rawStatus = student['status']?.toString().trim();

        final returnedStatus = rawStatus == null || rawStatus.isEmpty
            ? null
            : statusOptions.contains(rawStatus)
            ? rawStatus
            : null;

        newStatuses[studentId] = returnedStatus;
      }

      final returnedTotalStudents =
          int.tryParse(pagination['total_students']?.toString() ?? '') ??
          returnedStudents.length;

      final calculatedTotalPages = returnedTotalStudents == 0
          ? 1
          : (returnedTotalStudents / studentsPerPage).ceil();

      final safePage = page.clamp(1, calculatedTotalPages);

      final startIndex = (safePage - 1) * studentsPerPage;

      final endIndex = (startIndex + studentsPerPage).clamp(
        0,
        returnedStudents.length,
      );

      final currentStudents = startIndex < returnedStudents.length
          ? returnedStudents.sublist(startIndex, endIndex)
          : <dynamic>[];

      attendanceStatuses.clear();
      attendanceStatuses.addAll(newStatuses);

      setState(() {
        attendanceData = data;

        allStudents = returnedStudents;

        students = currentStudents;

        selectedClass = returnedSelectedClass?['key']?.toString();

        currentPage = safePage;

        totalPages = calculatedTotalPages;

        attendanceTaken = returnedAttendanceTaken;

        statistics = {
          'Present':
              int.tryParse(returnedStatistics['Present']?.toString() ?? '') ??
              0,
          'Absent':
              int.tryParse(returnedStatistics['Absent']?.toString() ?? '') ?? 0,
          'Late':
              int.tryParse(returnedStatistics['Late']?.toString() ?? '') ?? 0,
          'Excused':
              int.tryParse(returnedStatistics['Excused']?.toString() ?? '') ??
              0,
        };

        isLoading = false;
      });

      _updateLocalStatistics();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages || page == currentPage || isSaving) {
      return;
    }

    final startIndex = (page - 1) * studentsPerPage;

    final endIndex = (startIndex + studentsPerPage).clamp(
      0,
      allStudents.length,
    );

    final pageStudents = startIndex < allStudents.length
        ? allStudents.sublist(startIndex, endIndex)
        : <dynamic>[];

    setState(() {
      currentPage = page;
      students = pageStudents;
    });
  }

  void _changeStatus(int studentId, String? status) {
    final normalizedStatus = status?.trim();

    setState(() {
      attendanceStatuses[studentId] =
          normalizedStatus == null || normalizedStatus.isEmpty
          ? null
          : statusOptions.contains(normalizedStatus)
          ? normalizedStatus
          : null;
    });

    _updateLocalStatistics();
  }

  void _markAllPresent() {
    setState(() {
      for (final student in allStudents) {
        if (student is! Map) {
          continue;
        }

        final studentId = int.tryParse(student['student_id']?.toString() ?? '');

        if (studentId != null) {
          attendanceStatuses[studentId] = 'Present';
        }
      }

      statistics = {
        'Present': allStudents.length,
        'Absent': 0,
        'Late': 0,
        'Excused': 0,
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All students marked Present.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateLocalStatistics() {
    final updatedStatistics = {
      'Present': 0,
      'Absent': 0,
      'Late': 0,
      'Excused': 0,
    };

    for (final student in allStudents) {
      if (student is! Map) {
        continue;
      }

      final studentId = int.tryParse(student['student_id']?.toString() ?? '');

      if (studentId == null) {
        continue;
      }

      final status = attendanceStatuses[studentId];

      if (status != null && updatedStatistics.containsKey(status)) {
        updatedStatistics[status] = (updatedStatistics[status] as int) + 1;
      }
    }

    if (!mounted) return;

    setState(() {
      statistics = updatedStatistics;
    });
  }

  bool _allStudentsSelected() {
    if (allStudents.isEmpty) {
      return false;
    }

    for (final student in allStudents) {
      if (student is! Map) {
        return false;
      }

      final studentId = int.tryParse(student['student_id']?.toString() ?? '');

      if (studentId == null) {
        return false;
      }

      final status = attendanceStatuses[studentId];

      if (status == null ||
          status.trim().isEmpty ||
          !statusOptions.contains(status)) {
        return false;
      }
    }

    return true;
  }

  int _unselectedCount() {
    int count = 0;

    for (final student in allStudents) {
      if (student is! Map) {
        continue;
      }

      final studentId = int.tryParse(student['student_id']?.toString() ?? '');

      if (studentId == null) {
        continue;
      }

      final status = attendanceStatuses[studentId];

      if (status == null ||
          status.trim().isEmpty ||
          !statusOptions.contains(status)) {
        count++;
      }
    }

    return count;
  }

  Future<void> _saveAttendance() async {
    if (selectedClass == null ||
        selectedClass!.isEmpty ||
        allStudents.isEmpty) {
      return;
    }

    if (!_allStudentsSelected()) {
      final count = _unselectedCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count student${count == 1 ? '' : 's'} still need a status.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final studentAttendance = <Map<String, dynamic>>[];

      for (final student in allStudents) {
        if (student is! Map) {
          throw Exception('Invalid student data.');
        }

        final studentId = int.tryParse(student['student_id']?.toString() ?? '');

        final registrationId = int.tryParse(
          student['registration_id']?.toString() ?? '',
        );

        if (studentId == null || studentId <= 0) {
          throw Exception('Invalid student ID.');
        }

        if (registrationId == null || registrationId <= 0) {
          throw Exception('Invalid registration ID for student ID $studentId.');
        }

        final status = attendanceStatuses[studentId]?.trim();

        if (status == null || status.isEmpty) {
          throw Exception(
            'Attendance status is required for student ID $studentId.',
          );
        }

        if (!statusOptions.contains(status)) {
          throw Exception(
            'Invalid attendance status for student ID $studentId.',
          );
        }

        studentAttendance.add({
          'student_id': studentId,
          'registration_id': registrationId,
          'status': status,
        });
      }

      final result = await ApiService.saveTeacherAttendance(
        className: selectedClass!,
        students: studentAttendance,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;

        attendanceTaken = result['attendance_taken'] == true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Attendance saved successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadAttendance(className: selectedClass, page: currentPage);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;

      case 'Absent':
        return Colors.red;

      case 'Late':
        return Colors.orange;

      case 'Excused':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              _loadAttendance(className: selectedClass, page: currentPage),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && attendanceData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && attendanceData == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.red),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _loadAttendance(className: selectedClass, page: currentPage),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeader(),

        const SizedBox(height: 16),

        _buildClassInfo(),

        const SizedBox(height: 16),

        if (attendanceTaken)
          _buildAttendanceAlreadyTaken()
        else ...[
          _buildStatistics(),

          const SizedBox(height: 16),

          _buildActionButtons(),

          const SizedBox(height: 16),

          _buildAttendanceTable(),

          const SizedBox(height: 16),

          _buildPagination(),

          const SizedBox(height: 16),

          _buildSaveButton(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final today = attendanceData?['today'] as Map<String, dynamic>?;

    final formattedDate = today?['formatted']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Take Attendance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          formattedDate.isEmpty ? 'Today' : formattedDate,
          style: const TextStyle(fontSize: 14, color: Color(0xff64748b)),
        ),
      ],
    );
  }

  Widget _buildClassInfo() {
    final selected = attendanceData?['selected_class'] as Map<String, dynamic>?;

    final grade = selected?['grade']?.toString() ?? '';

    final section = selected?['section']?.toString() ?? '';

    final label = grade.isEmpty
        ? 'Assigned Class'
        : 'Grade $grade - Section $section';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffeef2ff),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_outlined, color: Color(0xff4f46e5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Class',
                  style: TextStyle(fontSize: 12, color: Color(0xff64748b)),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0f172a),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceAlreadyTaken() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 54, color: Colors.green.shade600),
          const SizedBox(height: 14),
          const Text(
            'You already took today’s attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xff166534),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the EDIT tab above if you need to modify today’s attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xff475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Present',
            statistics['Present'],
            Colors.green,
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'Absent',
            statistics['Absent'],
            Colors.red,
            Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'Late',
            statistics['Late'],
            Colors.orange,
            Icons.access_time,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            'Excused',
            statistics['Excused'],
            Colors.blue,
            Icons.info_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    dynamic value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 5),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xff64748b)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isSaving || allStudents.isEmpty ? null : _markAllPresent,
        icon: const Icon(Icons.done_all, size: 19),
        label: const Text('Mark All Present'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          side: const BorderSide(color: Color(0xff4f46e5)),
          foregroundColor: const Color(0xff4f46e5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.people_outline, size: 45, color: Color(0xff94a3b8)),
            SizedBox(height: 10),
            Text(
              'No students found.',
              style: TextStyle(fontSize: 14, color: Color(0xff64748b)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Students',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff0f172a),
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 46,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 72,
              columnSpacing: 20,
              horizontalMargin: 14,
              columns: const [
                DataColumn(label: Text('No.')),
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Status')),
              ],
              rows: List.generate(students.length, (index) {
                final student = students[index];

                final name = student['full_name']?.toString() ?? '';

                final studentId = int.tryParse(
                  student['student_id']?.toString() ?? '',
                );

                final status = studentId == null
                    ? null
                    : attendanceStatuses[studentId];

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${((currentPage - 1) * studentsPerPage) + index + 1}',
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 230),
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 145,
                        child: DropdownButtonFormField<String>(
                          value: status,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff94a3b8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: statusOptions.map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(item),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: studentId == null || isSaving
                              ? null
                              : (value) {
                                  _changeStatus(studentId, value);
                                },
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: currentPage > 1 && !isSaving
                ? () => _changePage(currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff475569),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages && !isSaving
                ? () => _changePage(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _allStudentsSelected() && !isSaving;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: canSave ? _saveAttendance : null,
        icon: isSaving
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(isSaving ? 'Saving Attendance...' : 'Save Attendance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4f46e5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xffcbd5e1),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
