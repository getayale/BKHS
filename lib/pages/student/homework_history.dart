import 'package:flutter/material.dart';

import '../../student_api.dart';

class StudentHomeworkHistoryPage extends StatefulWidget {
  const StudentHomeworkHistoryPage({super.key});

  @override
  State<StudentHomeworkHistoryPage> createState() =>
      _StudentHomeworkHistoryPageState();
}

class _StudentHomeworkHistoryPageState
    extends State<StudentHomeworkHistoryPage> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? student;
  List<dynamic> homeworks = [];
  Map<String, dynamic> statistics = {};

  @override
  void initState() {
    super.initState();
    _loadHomeworkHistory();
  }

  Future<void> _loadHomeworkHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await StudentApi.getStudentHomeworkHistory();

      if (!mounted) {
        return;
      }

      setState(() {
        student = data['student'] as Map<String, dynamic>?;

        homeworks = data['homeworks'] is List
            ? data['homeworks'] as List<dynamic>
            : [];

        statistics = data['statistics'] is Map<String, dynamic>
            ? data['statistics'] as Map<String, dynamic>
            : {};

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

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Not available';
    }

    final parts = date.split('-');

    if (parts.length != 3) {
      return date;
    }

    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'closed') {
      return Colors.grey;
    }

    return Colors.orange;
  }

  Widget _buildHeader() {
    final fullName = student?['full_name'] ?? 'Student';
    final grade = student?['grade_label'] ?? '';
    final section = student?['section'] ?? '';
    final academicYear = student?['academic_year'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history, color: Colors.white, size: 34),
          const SizedBox(height: 12),
          const Text(
            'Homework History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fullName.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$grade • Section $section',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            academicYear.toString(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final total = statistics['total'] ?? homeworks.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_outlined,
              color: Colors.orange,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Undone Homework',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  total.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Map<String, dynamic> homework) {
    final title = homework['title']?.toString() ?? 'Untitled Homework';

    final description = homework['description']?.toString() ?? '';

    final subject = homework['subject_name']?.toString() ?? 'Subject';

    final teacher = homework['teacher_name']?.toString() ?? 'Teacher';

    final assignedDate = homework['assigned_date']?.toString();

    final dueDate = homework['due_date']?.toString();

    final status = homework['status']?.toString() ?? 'Active';

    final teacherMaterial = homework['teacher_material_original_name']
        ?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Not Submitted',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildHomeworkInfo(Icons.person_outline, 'Teacher', teacher),
          const SizedBox(height: 8),
          _buildHomeworkInfo(
            Icons.calendar_today_outlined,
            'Assigned',
            _formatDate(assignedDate),
          ),
          const SizedBox(height: 8),
          _buildHomeworkInfo(Icons.event_outlined, 'Due', _formatDate(dueDate)),
          if (teacherMaterial != null && teacherMaterial.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildHomeworkInfo(Icons.attach_file, 'Material', teacherMaterial),
          ],
        ],
      ),
    );
  }

  Widget _buildHomeworkInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade600),
        const SizedBox(width: 9),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 55, color: Colors.red.shade400),
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadHomeworkHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHomeworkHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatistics(),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Undone Homework',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${homeworks.length} item(s)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (homeworks.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(Icons.task_alt, size: 55, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No undone homework',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'You have no overdue homework that is waiting for submission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ...homeworks.map(
              (homework) =>
                  _buildHomeworkCard(homework as Map<String, dynamic>),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Homework History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadHomeworkHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }
}
