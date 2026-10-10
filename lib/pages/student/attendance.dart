import 'package:flutter/material.dart';

import '../../student_api.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  bool isLoading = true;

  String? errorMessage;

  Map<String, dynamic>? attendanceData;

  int currentPage = 1;

  @override
  void initState() {
    super.initState();

    loadAttendance();
  }

  Future<void> loadAttendance({int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await StudentApi.getStudentAttendance(page: page);

      if (!mounted) {
        return;
      }

      setState(() {
        attendanceData = data;
        currentPage = page;
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

  Future<void> _refreshAttendance() async {
    await loadAttendance(page: currentPage);
  }

  void _changePage(int page) {
    if (page < 1) {
      return;
    }

    final pagination = attendanceData?['pagination'];

    if (pagination == null) {
      return;
    }

    final totalPages = (pagination['total_pages'] ?? 1) as int;

    if (page > totalPages) {
      return;
    }

    loadAttendance(page: page);
  }

  Color _getStatusBackground(String status) {
    if (status == 'Absent') {
      return const Color(0xFFFEF2F2);
    }

    if (status == 'Late') {
      return const Color(0xFFFFF7ED);
    }

    return const Color(0xFFF3F4F6);
  }

  Color _getStatusColor(String status) {
    if (status == 'Absent') {
      return const Color(0xFFDC2626);
    }

    if (status == 'Late') {
      return const Color(0xFFEA580C);
    }

    return const Color(0xFF4B5563);
  }

  IconData _getStatusIcon(String status) {
    if (status == 'Absent') {
      return Icons.event_busy_rounded;
    }

    if (status == 'Late') {
      return Icons.schedule_rounded;
    }

    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAttendance,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.35),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load attendance',
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    loadAttendance(page: currentPage);
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final data = attendanceData;

    if (data == null) {
      return const SizedBox.shrink();
    }

    final attendance = (data['attendance'] as List?) ?? [];

    final statistics = (data['statistics'] as Map?) ?? {};

    final pagination = (data['pagination'] as Map?) ?? {};

    final student = (data['student'] as Map?) ?? {};

    final total = (statistics['total'] ?? 0) as int;

    final absent = (statistics['absent'] ?? 0) as int;

    final late = (statistics['late'] ?? 0) as int;

    final totalPages = (pagination['total_pages'] ?? 1) as int;

    final studentCode = student['student_code']?.toString() ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      children: [
        _buildHeader(studentCode, data['ethiopian_today']?.toString() ?? ''),

        const SizedBox(height: 20),

        _buildStatistics(total: total, absent: absent, late: late),

        const SizedBox(height: 20),

        _buildAttendanceCard(attendance, total),

        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(totalPages),
        ],
      ],
    );
  }

  Widget _buildHeader(String studentCode, String today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Your absent and late attendance records.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (studentCode.isNotEmpty)
              _buildInfoChip(Icons.badge_outlined, studentCode),
            if (today.isNotEmpty) ...[
              const SizedBox(width: 8),
              _buildInfoChip(Icons.calendar_today_outlined, today),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics({
    required int total,
    required int absent,
    required int late,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            'Total',
            total,
            Icons.fact_check_outlined,
            const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatisticCard(
            'Absent',
            absent,
            Icons.event_busy_outlined,
            const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatisticCard(
            'Late',
            late,
            Icons.schedule_outlined,
            const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(height: 9),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(List attendance, int total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Records',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '$total ${total == 1 ? 'record' : 'records'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (attendance.isEmpty)
            _buildEmptyState()
          else
            ...attendance.map((record) {
              final item = record as Map;

              return _buildAttendanceRow(item);
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 55),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 30,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No attendance issues',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'You have no absent or late attendance records.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(Map record) {
    final ethiopianDate = record['ethiopian_date']?.toString() ?? '';

    final dayName = record['day_name']?.toString() ?? '';

    final gregorianDate = record['gregorian_date']?.toString() ?? '';

    final status = record['status']?.toString() ?? '';

    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEF0F3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _getStatusBackground(status),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_getStatusIcon(status), color: statusColor, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ethiopianDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  gregorianDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _getStatusBackground(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    final startPage = (currentPage - 2).clamp(1, totalPages);

    final endPage = (currentPage + 2).clamp(1, totalPages);

    final pages = <int>[];

    for (int page = startPage; page <= endPage; page++) {
      pages.add(page);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            'Page $currentPage of $totalPages',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPageButton(
                icon: Icons.chevron_left_rounded,
                enabled: currentPage > 1,
                onPressed: () {
                  _changePage(currentPage - 1);
                },
              ),
              if (startPage > 1) _buildPageNumber(1),
              if (startPage > 2) _buildDisabledPage('...'),
              ...pages.map((page) => _buildPageNumber(page)),
              if (endPage < totalPages - 1) _buildDisabledPage('...'),
              if (endPage < totalPages) _buildPageNumber(totalPages),
              _buildPageButton(
                icon: Icons.chevron_right_rounded,
                enabled: currentPage < totalPages,
                onPressed: () {
                  _changePage(currentPage + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(int page) {
    final active = page == currentPage;

    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: active ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: active
              ? null
              : () {
                  _changePage(page);
                },
          child: Center(
            child: Text(
              page.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: enabled ? onPressed : null,
          child: Icon(
            icon,
            size: 21,
            color: enabled ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledPage(String text) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }
}
