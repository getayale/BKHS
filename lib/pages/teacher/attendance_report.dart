import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '/api_service.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  bool isLoading = false;
  bool isLoadingWeeks = false;
  bool isExporting = false;

  String? errorMessage;

  Map<String, dynamic>? reportData;

  String selectedMode = 'monthly';
  int selectedMonth = 1;
  int? selectedWeek;

  List<int> recordedWeeks = [];

  static const int studentsPerPage = 10;
  int currentPage = 1;

  final List<Map<String, dynamic>> ethiopianMonths = [
    {'number': 1, 'name': 'Meskerem'},
    {'number': 2, 'name': 'Tikimt'},
    {'number': 3, 'name': 'Hidar'},
    {'number': 4, 'name': 'Tahsas'},
    {'number': 5, 'name': 'Tir'},
    {'number': 6, 'name': 'Yekatit'},
    {'number': 7, 'name': 'Megabit'},
    {'number': 8, 'name': 'Miyazya'},
    {'number': 9, 'name': 'Ginbot'},
    {'number': 10, 'name': 'Sene'},
    {'number': 11, 'name': 'Hamle'},
    {'number': 12, 'name': 'Nehase'},
    {'number': 13, 'name': 'Pagume'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (selectedMode == 'weekly') {
        if (recordedWeeks.isEmpty) {
          final discoveryData = await ApiService.getTeacherAttendanceReport(
            mode: 'monthly',
            month: selectedMonth,
          );

          final weeks = _extractWeeks(discoveryData);

          if (!mounted) {
            return;
          }

          setState(() {
            recordedWeeks = weeks;

            if (recordedWeeks.isEmpty) {
              selectedWeek = null;
            } else if (!recordedWeeks.contains(selectedWeek)) {
              selectedWeek = recordedWeeks.first;
            }
          });
        }

        if (recordedWeeks.isEmpty || selectedWeek == null) {
          if (!mounted) {
            return;
          }

          setState(() {
            isLoading = false;
            reportData = null;
            currentPage = 1;
          });

          return;
        }

        final data = await ApiService.getTeacherAttendanceReport(
          mode: 'weekly',
          month: selectedMonth,
          week: selectedWeek,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          reportData = data;
          recordedWeeks = _extractWeeks(data);
          isLoading = false;
          currentPage = 1;
        });

        return;
      }

      final data = await ApiService.getTeacherAttendanceReport(
        mode: 'monthly',
        month: selectedMonth,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        reportData = data;
        recordedWeeks = _extractWeeks(data);
        isLoading = false;
        currentPage = 1;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadWeeklyOptions() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingWeeks = true;
      errorMessage = null;
      recordedWeeks = [];
      selectedWeek = null;
      currentPage = 1;
    });

    try {
      final data = await ApiService.getTeacherAttendanceReport(
        mode: 'monthly',
        month: selectedMonth,
      );

      final weeks = _extractWeeks(data);

      if (!mounted) {
        return;
      }

      setState(() {
        recordedWeeks = weeks;
        selectedWeek = weeks.isNotEmpty ? weeks.first : null;
        isLoadingWeeks = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingWeeks = false;
        recordedWeeks = [];
        selectedWeek = null;
        currentPage = 1;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<int> _extractWeeks(Map<String, dynamic> data) {
    final raw = data['weeks'];

    if (raw is! List) {
      return [];
    }

    final weeks = <int>[];

    for (final item in raw) {
      if (item is! Map) {
        continue;
      }

      final week = int.tryParse('${item['week_number'] ?? item['week'] ?? ''}');

      if (week != null && week >= 1 && week <= 5) {
        weeks.add(week);
      }
    }

    weeks.sort();

    return weeks.toSet().toList();
  }

  String _monthName(int month) {
    for (final item in ethiopianMonths) {
      if (item['number'] == month) {
        return item['name'].toString();
      }
    }

    return 'Unknown';
  }

  String _weekLabel(int week) {
    switch (week) {
      case 1:
        return 'Week 1 — Days 1–7';
      case 2:
        return 'Week 2 — Days 8–14';
      case 3:
        return 'Week 3 — Days 15–21';
      case 4:
        return 'Week 4 — Days 22–28';
      case 5:
        return 'Week 5 — Days 29–30';
      default:
        return 'Week $week';
    }
  }

  List<Map<String, dynamic>> _students() {
    final raw = reportData?['students'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _attendanceDates() {
    final raw = reportData?['attendance_dates'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _paginatedStudents() {
    final students = _students();

    if (students.isEmpty) {
      return [];
    }

    final startIndex = (currentPage - 1) * studentsPerPage;

    if (startIndex >= students.length) {
      return [];
    }

    final endIndex = (startIndex + studentsPerPage).clamp(0, students.length);

    return students.sublist(startIndex, endIndex);
  }

  int _totalPages() {
    final totalStudents = _students().length;

    if (totalStudents == 0) {
      return 1;
    }

    return (totalStudents / studentsPerPage).ceil();
  }

  void _goToPage(int page) {
    final totalPages = _totalPages();

    if (page < 1 || page > totalPages || page == currentPage) {
      return;
    }

    setState(() {
      currentPage = page;
    });
  }

  Map<String, dynamic> _academicYear() {
    final raw = reportData?['academic_year'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  Map<String, dynamic> _selectedClass() {
    final raw = reportData?['selected_class'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  Map<String, dynamic> _selectedMonthData() {
    final raw = reportData?['selected_month'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  Map<String, dynamic> _selectedWeekData() {
    final raw = reportData?['selected_week'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  Map<String, dynamic> _overallStatistics() {
    final raw = reportData?['overall_statistics'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {'Present': 0, 'Absent': 0, 'Late': 0, 'Excused': 0};
  }

  String _ethiopianDate(Map<String, dynamic> date) {
    final rawEth = date['ethiopian'];

    if (rawEth is Map) {
      final eth = Map<String, dynamic>.from(rawEth);

      final day = int.tryParse('${eth['day'] ?? ''}') ?? 0;
      final month = int.tryParse('${eth['month'] ?? ''}') ?? 0;
      final year = int.tryParse('${eth['year'] ?? ''}') ?? 0;

      final formatted = eth['formatted']?.toString();

      if (formatted != null && formatted.trim().isNotEmpty) {
        return formatted;
      }

      if (day > 0 && month > 0 && year > 0) {
        return '${day.toString().padLeft(2, '0')} '
            '${_monthName(month)} $year';
      }
    }

    final fallback = date['ethiopian_date']?.toString();

    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback;
    }

    return date['gregorian']?.toString() ?? '-';
  }

  String _statusCode(String? status) {
    switch (status) {
      case 'Present':
        return 'P';
      case 'Absent':
        return 'A';
      case 'Late':
        return 'L';
      case 'Excused':
        return 'E';
      default:
        return '-';
    }
  }

  Color _statusColor(String? status) {
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

  String? _getStatus(Map<String, dynamic> student, String gregorianDate) {
    final rawAttendance = student['attendance'];

    if (rawAttendance is! List) {
      return null;
    }

    for (final item in rawAttendance) {
      if (item is! Map) {
        continue;
      }

      final attendance = Map<String, dynamic>.from(item);

      if (attendance['gregorian']?.toString() == gregorianDate) {
        final status = attendance['status'];

        if (status == null) {
          return null;
        }

        return status.toString();
      }
    }

    return null;
  }

  int _statValue(Map<String, dynamic> statistics, String key) {
    return int.tryParse('${statistics[key] ?? 0}') ?? 0;
  }

  Future<void> _applyFilters() async {
    if (selectedMode == 'weekly' && selectedWeek == null) {
      return;
    }

    setState(() {
      currentPage = 1;
    });

    await _loadReport();
  }

  Future<void> _changeMode(String? value) async {
    if (value == null || value == selectedMode) {
      return;
    }

    setState(() {
      selectedMode = value;
      currentPage = 1;

      if (selectedMode == 'monthly') {
        selectedWeek = null;
        recordedWeeks = [];
      }
    });

    if (value == 'weekly') {
      await _loadWeeklyOptions();
    }
  }

  Future<void> _changeMonth(int? value) async {
    if (value == null) {
      return;
    }

    setState(() {
      selectedMonth = value;
      selectedWeek = null;
      recordedWeeks = [];
      currentPage = 1;
    });

    if (selectedMode == 'weekly') {
      await _loadWeeklyOptions();
    }
  }

  void _changeWeek(int? value) {
    if (value == null) {
      return;
    }

    setState(() {
      selectedWeek = value;
      currentPage = 1;
    });
  }

  Future<void> _exportAttendance() async {
    if (isExporting) {
      return;
    }

    if (reportData == null) {
      return;
    }

    if (_students().isEmpty || _attendanceDates().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no attendance data to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (selectedMode == 'weekly' && selectedWeek == null) {
      return;
    }

    setState(() {
      isExporting = true;
    });

    try {
      final fileBytes = await ApiService.downloadTeacherAttendanceExport(
        mode: selectedMode,
        month: selectedMonth,
        week: selectedMode == 'weekly' ? selectedWeek : null,
      );

      final monthName = _monthName(selectedMonth);

      final fileName = selectedMode == 'monthly'
          ? 'Attendance_${monthName}.xlsx'
          : 'Attendance_${monthName}_Week$selectedWeek.xlsx';

      await FileSaver.instance.saveToDownloads(
        name: fileName,
        bytes: Uint8List.fromList(fileBytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedMode == 'monthly'
                ? '$monthName attendance exported successfully. Check your Downloads folder.'
                : '$monthName Week $selectedWeek attendance exported successfully. Check your Downloads folder.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(onRefresh: _loadReport, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading && reportData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && reportData == null) {
      return _buildErrorState();
    }

    if (selectedMode == 'weekly' &&
        !isLoading &&
        !isLoadingWeeks &&
        recordedWeeks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 12),
            if (errorMessage != null) _buildErrorBanner(),
            _buildInformationCard(),
            const SizedBox(height: 12),
            _buildNoWeeklyRecords(),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: 12),
          if (isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          if (errorMessage != null) _buildErrorBanner(),
          _buildInformationCard(),
          const SizedBox(height: 12),
          _buildSummaryCard(),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 12),
          _buildAttendanceTable(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _buildDropdownLabel('View'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedMode,
              decoration: _dropdownDecoration(),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: isLoading || isLoadingWeeks || isExporting
                  ? null
                  : _changeMode,
            ),
            const SizedBox(height: 12),
            _buildDropdownLabel('Ethiopian Month'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: selectedMonth,
              decoration: _dropdownDecoration(),
              items: ethiopianMonths.map((month) {
                final number = month['number'] as int;
                final name = month['name'].toString();

                return DropdownMenuItem<int>(
                  value: number,
                  child: Text('$number. $name'),
                );
              }).toList(),
              onChanged: isLoading || isLoadingWeeks || isExporting
                  ? null
                  : _changeMonth,
            ),
            if (selectedMode == 'weekly') ...[
              const SizedBox(height: 12),
              _buildDropdownLabel('Recorded Week'),
              const SizedBox(height: 6),
              if (isLoadingWeeks)
                Container(
                  height: 48,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading recorded weeks...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                )
              else if (recordedWeeks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No recorded weeks for '
                    '${_monthName(selectedMonth)}.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: selectedWeek,
                  decoration: _dropdownDecoration(),
                  items: recordedWeeks.map((week) {
                    return DropdownMenuItem<int>(
                      value: week,
                      child: Text(_weekLabel(week)),
                    );
                  }).toList(),
                  onChanged: isLoading || isExporting ? null : _changeWeek,
                ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading ||
                        isLoadingWeeks ||
                        isExporting ||
                        (selectedMode == 'weekly' && selectedWeek == null)
                    ? null
                    : _applyFilters,
                icon: const Icon(Icons.search, size: 19),
                label: const Text(
                  'Apply',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildDropdownLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildInformationCard() {
    final academicYear = _academicYear();
    final selectedClass = _selectedClass();
    final monthData = _selectedMonthData();
    final weekData = _selectedWeekData();

    final academicYearName = academicYear['name']?.toString() ?? '-';

    final className = selectedClass['name']?.toString() ?? '-';

    final monthName =
        monthData['name']?.toString() ?? _monthName(selectedMonth);

    String weekLabel = '-';

    if (selectedMode == 'weekly') {
      weekLabel =
          weekData['label']?.toString() ??
          (selectedWeek != null ? _weekLabel(selectedWeek!) : '-');
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.school_outlined, 'Academic Year', academicYearName),
            _infoRow(Icons.class_outlined, 'Class', className),
            _infoRow(Icons.calendar_month_outlined, 'Month', monthName),
            _infoRow(
              Icons.visibility_outlined,
              'View',
              selectedMode == 'weekly' ? 'Weekly' : 'Monthly',
            ),
            if (selectedMode == 'weekly')
              _infoRow(Icons.date_range_outlined, 'Week', weekLabel),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 9),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final students = _students();
    final dates = _attendanceDates();
    final statistics = _overallStatistics();

    final present = _statValue(statistics, 'Present');
    final absent = _statValue(statistics, 'Absent');
    final late = _statValue(statistics, 'Late');
    final excused = _statValue(statistics, 'Excused');

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                _summaryItem(
                  'Students',
                  '${students.length}',
                  Icons.people_outline,
                ),
                _summaryItem(
                  'Attendance Days',
                  '${dates.length}',
                  Icons.calendar_today_outlined,
                ),
                _summaryItem('Present', '$present', Icons.check_circle_outline),
                _summaryItem('Absent', '$absent', Icons.cancel_outlined),
                _summaryItem('Late', '$late', Icons.schedule_outlined),
                _summaryItem('Excused', '$excused', Icons.info_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem('P', 'Present', Colors.green),
            _legendItem('A', 'Absent', Colors.red),
            _legendItem('L', 'Late', Colors.orange),
            _legendItem('E', 'Excused', Colors.blue),
            _legendItem('-', 'No Record', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            code,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAttendanceTable() {
    final students = _paginatedStudents();
    final allStudents = _students();
    final dates = _attendanceDates();

    if (dates.isEmpty) {
      return _buildEmptyAttendance();
    }

    if (allStudents.isEmpty) {
      return _buildEmptyStudents();
    }

    final totalStudents = allStudents.length;

    final startStudent = ((currentPage - 1) * studentsPerPage) + 1;

    final endStudent = (startStudent + students.length - 1).clamp(
      0,
      totalStudents,
    );

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedMode == 'weekly'
                              ? 'Week ${selectedWeek ?? '-'} Attendance'
                              : 'Monthly Attendance',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Showing $startStudent–$endStudent '
                          'of $totalStudents students',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: isLoading || isLoadingWeeks || isExporting
                          ? null
                          : _exportAttendance,
                      icon: isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_outlined, size: 18),
                      label: Text(
                        isExporting ? 'Exporting...' : 'Export Excel',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 58,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 58,
                columnSpacing: 18,
                horizontalMargin: 10,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                columns: [
                  const DataColumn(
                    label: SizedBox(width: 150, child: Text('Student')),
                  ),
                  ...dates.map((date) {
                    final dateLabel = _ethiopianDate(date);

                    return DataColumn(
                      label: SizedBox(
                        width: 90,
                        child: Center(
                          child: Text(dateLabel, textAlign: TextAlign.center),
                        ),
                      ),
                    );
                  }),
                ],
                rows: students.map((student) {
                  final fullName = student['full_name']?.toString() ?? '-';

                  final studentCode = student['student_code']?.toString() ?? '';

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (studentCode.isNotEmpty)
                                Text(
                                  studentCode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ...dates.map((date) {
                        final gregorian = date['gregorian']?.toString() ?? '';

                        final status = _getStatus(student, gregorian);

                        return DataCell(Center(child: _statusBadge(status)));
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _totalPages();

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: currentPage > 1
                ? () => _goToPage(currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...List.generate(totalPages, (index) {
            final page = index + 1;
            final isSelected = page == currentPage;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: SizedBox(
                width: 36,
                height: 36,
                child: isSelected
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          '$page',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => _goToPage(page),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: Text('$page'),
                      ),
              ),
            );
          }),
          IconButton(
            tooltip: 'Next page',
            onPressed: currentPage < totalPages
                ? () => _goToPage(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final code = _statusCode(status);
    final color = _statusColor(status);

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyAttendance() {
    final month = _monthName(selectedMonth);

    final message = selectedMode == 'weekly'
        ? selectedWeek == null
              ? 'No recorded week is available for $month.'
              : 'No attendance records found for Week '
                    '$selectedWeek of $month.'
        : 'No attendance records found for $month.';

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 42,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoWeeklyRecords() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 42,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                'No attendance was recorded for '
                '${_monthName(selectedMonth)}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStudents() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 42, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                'No students found in the assigned class.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Text(
                  errorMessage ?? 'Unable to load attendance history.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _loadReport,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
