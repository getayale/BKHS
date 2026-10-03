import 'package:flutter/material.dart';

import '/api_service.dart';

class EditAttendancePage extends StatefulWidget {
  const EditAttendancePage({super.key});

  @override
  State<EditAttendancePage> createState() => _EditAttendancePageState();
}

class _EditAttendancePageState extends State<EditAttendancePage> {
  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  Map<String, dynamic>? attendanceData;

  List<dynamic> students = [];
  List<dynamic> attendanceDates = [];

  String? selectedDate;
  String? selectedClassLabel;

  int currentPage = 1;

  static const int studentsPerPage = 10;

  final Map<int, String?> attendanceStatuses = {};

  final List<String> statusOptions = ['Present', 'Absent', 'Late', 'Excused'];

  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  String? _formatEthiopianDate(dynamic value) {
    if (value is Map) {
      final year = int.tryParse(value['year']?.toString() ?? '');
      final month = int.tryParse(value['month']?.toString() ?? '');
      final day = int.tryParse(value['day']?.toString() ?? '');

      if (year != null && month != null && day != null) {
        return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
    }

    if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return value;
    }

    return null;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getTeacherAttendanceEdit();

      if (!mounted) return;

      final selectedClass = data['selected_class'] as Map<String, dynamic>?;

      final attendanceDate = data['attendance_date'] as Map<String, dynamic>?;

      final returnedStudents = data['students'] as List<dynamic>? ?? [];

      final returnedAttendanceDates =
          data['attendance_dates'] as List<dynamic>? ?? [];

      final initialDate = _formatEthiopianDate(attendanceDate?['ethiopian']);

      attendanceStatuses.clear();

      for (final student in returnedStudents) {
        final studentId = int.tryParse(student['student_id']?.toString() ?? '');

        if (studentId == null) {
          continue;
        }

        final status = student['status']?.toString();

        attendanceStatuses[studentId] =
            status != null &&
                status.isNotEmpty &&
                statusOptions.contains(status)
            ? status
            : null;
      }

      setState(() {
        attendanceData = data;

        selectedClassLabel = selectedClass == null
            ? null
            : _getClassLabel(selectedClass);

        selectedDate = initialDate;

        dateController.text = initialDate ?? '';

        students = returnedStudents;

        attendanceDates = returnedAttendanceDates;

        currentPage = 1;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadAttendance() async {
    final date = dateController.text.trim();

    if (date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an Ethiopian date.')),
      );

      return;
    }

    if (!_isValidEthiopianDateFormat(date)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid Ethiopian date.')));

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      students = [];
      attendanceStatuses.clear();
      currentPage = 1;
    });

    try {
      final data = await ApiService.getTeacherAttendanceEdit(
        ethiopianDate: date,
      );

      if (!mounted) return;

      final returnedStudents = data['students'] as List<dynamic>? ?? [];

      final returnedAttendanceDates =
          data['attendance_dates'] as List<dynamic>? ?? [];

      final selectedClass = data['selected_class'] as Map<String, dynamic>?;

      attendanceStatuses.clear();

      for (final student in returnedStudents) {
        final studentId = int.tryParse(student['student_id']?.toString() ?? '');

        if (studentId == null) {
          continue;
        }

        final status = student['status']?.toString();

        attendanceStatuses[studentId] =
            status != null &&
                status.isNotEmpty &&
                statusOptions.contains(status)
            ? status
            : null;
      }

      setState(() {
        attendanceData = data;

        selectedClassLabel = selectedClass == null
            ? null
            : _getClassLabel(selectedClass);

        selectedDate = date;

        dateController.text = date;

        students = returnedStudents;

        attendanceDates = returnedAttendanceDates;

        currentPage = 1;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        students = [];
        attendanceStatuses.clear();

        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _isValidEthiopianDateFormat(String date) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    return regex.hasMatch(date);
  }

  void _changeStatus(int studentId, String? status) {
    setState(() {
      attendanceStatuses[studentId] = status;
    });
  }

  int get totalPages {
    if (students.isEmpty) {
      return 1;
    }

    return (students.length / studentsPerPage).ceil();
  }

  List<dynamic> get currentStudents {
    final start = (currentPage - 1) * studentsPerPage;

    final end = (start + studentsPerPage) > students.length
        ? students.length
        : start + studentsPerPage;

    if (start >= students.length) {
      return [];
    }

    return students.sublist(start, end);
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages || page == currentPage) {
      return;
    }

    setState(() {
      currentPage = page;
    });
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

  bool _allStudentsHaveStatus() {
    if (students.isEmpty) {
      return false;
    }

    for (final student in students) {
      final studentId = int.tryParse(student['student_id']?.toString() ?? '');

      if (studentId == null) {
        return false;
      }

      final status = attendanceStatuses[studentId];

      if (status == null || !statusOptions.contains(status)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _saveAttendance() async {
    if (selectedDate == null || selectedDate!.isEmpty || students.isEmpty) {
      return;
    }

    if (!_allStudentsHaveStatus()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every student must have an attendance status.'),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final attendance = students.map((student) {
        final studentId = int.parse(student['student_id'].toString());

        final registrationId = int.parse(student['registration_id'].toString());

        return {
          'student_id': studentId,
          'registration_id': registrationId,
          'status': attendanceStatuses[studentId],
        };
      }).toList();

      final result = await ApiService.saveTeacherAttendanceEdit(
        ethiopianDate: selectedDate!,
        students: attendance,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Attendance updated successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadAttendance();
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

  String _getClassLabel(Map<String, dynamic> item) {
    final grade = item['grade_name']?.toString().isNotEmpty == true
        ? item['grade_name'].toString()
        : 'Grade ${item['grade']}';

    final section = item['section_name']?.toString().isNotEmpty == true
        ? item['section_name'].toString()
        : 'Section ${item['section']}';

    return '$grade - $section';
  }

  Future<void> _showEthiopianDatePicker() async {
    if (isSaving || attendanceDates.isEmpty) {
      return;
    }

    final availableDates = <String, Map<String, dynamic>>{};

    for (final item in attendanceDates) {
      if (item is! Map) {
        continue;
      }

      final ethiopianDate = _formatEthiopianDate(item['ethiopian']);

      if (ethiopianDate == null) {
        continue;
      }

      availableDates[ethiopianDate] = {
        'ethiopian': ethiopianDate,
        'gregorian': item['gregorian']?.toString() ?? '',
      };
    }

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance dates are available.')),
      );

      return;
    }

    final sortedDates = availableDates.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xffeef2ff),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xff4f46e5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Ethiopian Date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0f172a),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a date with recorded attendance.',
                    style: TextStyle(fontSize: 13, color: Color(0xff64748b)),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: sortedDates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final date = sortedDates[index];

                        final isSelected = date == selectedDate;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xff4f46e5)
                                  : const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 19,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xff475569),
                            ),
                          ),
                          title: Text(
                            date,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xff4f46e5)
                                  : const Color(0xff0f172a),
                            ),
                          ),
                          subtitle: const Text(
                            'Attendance recorded',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xff94a3b8),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xff4f46e5),
                                )
                              : const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xff94a3b8),
                                ),
                          onTap: () {
                            Navigator.pop(context, date);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || selected.isEmpty || !mounted) {
      return;
    }

    dateController.text = selected;

    setState(() {
      selectedDate = selected;
    });

    await _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
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
              onPressed: _loadInitialData,
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
        const SizedBox(height: 18),
        _buildAssignedClass(),
        const SizedBox(height: 14),
        _buildDateSelector(),
        const SizedBox(height: 12),
        _buildLoadButton(),
        if (isLoading) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
        if (!isLoading &&
            selectedDate != null &&
            selectedDate!.isNotEmpty &&
            students.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildStudentTable(),
          const SizedBox(height: 16),
          _buildPagination(),
          const SizedBox(height: 16),
          _buildSaveButton(),
        ],
        if (!isLoading &&
            selectedDate != null &&
            selectedDate!.isNotEmpty &&
            students.isEmpty) ...[
          const SizedBox(height: 16),
          _buildEmptyState(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Attendance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Select an Ethiopian date to edit attendance.',
          style: TextStyle(fontSize: 14, color: Color(0xff64748b)),
        ),
      ],
    );
  }

  Widget _buildAssignedClass() {
    return Container(
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
                  selectedClassLabel ?? 'Loading...',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: TextField(
        controller: dateController,
        readOnly: true,
        enabled: !isSaving,
        onTap: _showEthiopianDatePicker,
        decoration: InputDecoration(
          labelText: 'Ethiopian Date',
          hintText: 'Select Ethiopian date',
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: isSaving ? null : _showEthiopianDatePicker,
                icon: const Icon(Icons.calendar_today_outlined),
              ),
              IconButton(
                onPressed: isSaving
                    ? null
                    : () {
                        dateController.clear();

                        setState(() {
                          selectedDate = null;
                          students = [];
                          attendanceStatuses.clear();
                          currentPage = 1;
                          errorMessage = null;
                        });
                      },
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildLoadButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed:
            isLoading ||
                isSaving ||
                selectedDate == null ||
                selectedDate!.isEmpty
            ? null
            : _loadAttendance,
        icon: const Icon(Icons.search),
        label: const Text('Load Attendance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4f46e5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xffcbd5e1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTable() {
    final pageStudents = currentStudents;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0f172a),
                    ),
                  ),
                ),
                Text(
                  '${students.length} students',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
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
              rows: List.generate(pageStudents.length, (index) {
                final student = pageStudents[index];

                final studentId = int.tryParse(
                  student['student_id']?.toString() ?? '',
                );

                final name = student['full_name']?.toString() ?? '';

                final rawStatus = studentId == null
                    ? null
                    : attendanceStatuses[studentId];

                final status =
                    rawStatus != null && statusOptions.contains(rawStatus)
                    ? rawStatus
                    : null;

                final number =
                    ((currentPage - 1) * studentsPerPage) + index + 1;

                return DataRow(
                  cells: [
                    DataCell(Text('$number')),
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
                ? () {
                    _changePage(currentPage - 1);
                  }
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : _saveAttendance,
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
        label: Text(isSaving ? 'Saving Changes...' : 'Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4f46e5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xffcbd5e1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 48, color: Color(0xff94a3b8)),
          SizedBox(height: 12),
          Text(
            'No attendance records found for this date.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xff64748b)),
          ),
        ],
      ),
    );
  }
}
