import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../student_api.dart';
import 'homework_history.dart';

class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({super.key});

  @override
  State<StudentHomeworkPage> createState() => _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends State<StudentHomeworkPage> {
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  Map<String, dynamic>? student;
  List<dynamic> homeworks = [];
  Map<String, dynamic> statistics = {};

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await StudentApi.getStudentHomework();

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

  bool _isSubmitted(Map<String, dynamic> homework) {
    return homework['is_submitted'] == true;
  }

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'closed') {
      return Colors.grey;
    }

    return Colors.green;
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
          const Icon(Icons.assignment_outlined, color: Colors.white, size: 34),
          const SizedBox(height: 12),
          const Text(
            'Homework',
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
    final total = statistics['total'] ?? 0;
    final submitted = statistics['submitted'] ?? 0;
    final notSubmitted = statistics['not_submitted'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildStatCard(
                'Total',
                total.toString(),
                Icons.assignment_outlined,
              ),
              const SizedBox(height: 10),
              _buildStatCard(
                'Submitted',
                submitted.toString(),
                Icons.check_circle_outline,
              ),
              const SizedBox(height: 10),
              _buildStatCard(
                'Not Submitted',
                notSubmitted.toString(),
                Icons.warning_amber_outlined,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                total.toString(),
                Icons.assignment_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Submitted',
                submitted.toString(),
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Not Submitted',
                notSubmitted.toString(),
                Icons.warning_amber_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
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

    final submitted = _isSubmitted(homework);

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
                  color: submitted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  submitted ? 'Submitted' : 'Not Submitted',
                  style: TextStyle(
                    color: submitted ? Colors.green : Colors.orange,
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
              maxLines: 2,
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
          if (submitted) ...[
            const SizedBox(height: 8),
            _buildHomeworkInfo(
              Icons.description_outlined,
              'Submission',
              homework['submission']?['original_file_name']?.toString() ??
                  'Submitted file',
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () {
                      _openHomeworkDetails(homework);
                    },
              icon: Icon(
                submitted
                    ? Icons.visibility_outlined
                    : Icons.upload_file_outlined,
              ),
              label: Text(submitted ? 'View Submission' : 'Submit Homework'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
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

  Future<bool> _submitHomework(Map<String, dynamic> homework) async {
    if (isSubmitting) {
      return false;
    }

    final homeworkId = int.tryParse(homework['id']?.toString() ?? '');

    if (homeworkId == null) {
      _showMessage('Invalid homework ID.');
      return false;
    }

    final selectedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'jpg',
        'jpeg',
        'png',
        'zip',
      ],
    );

    if (selectedFile == null) {
      return false;
    }

    try {
      final fileBytes = await selectedFile.readAsBytes();

      if (fileBytes.isEmpty) {
        _showMessage('The selected file could not be read.');
        return false;
      }

      if (!mounted) {
        return false;
      }

      setState(() {
        isSubmitting = true;
      });

      await StudentApi.submitStudentHomework(
        homeworkId: homeworkId,
        fileName: selectedFile.name,
        fileBytes: fileBytes,
      );

      if (!mounted) {
        return false;
      }

      await _loadHomework();

      if (!mounted) {
        return false;
      }

      _showMessage('Homework submitted successfully.');

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openHomeworkDetails(Map<String, dynamic> homework) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final submitted = homework['is_submitted'] == true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        homework['title']?.toString() ?? 'Homework',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        homework['description']?.toString() ??
                            'No instructions available.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (submitted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  homework['submission']?['original_file_name']
                                          ?.toString() ??
                                      'Submission uploaded',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final success = await _submitHomework(
                                    homework,
                                  );

                                  if (success && modalContext.mounted) {
                                    Navigator.of(modalContext).pop();
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(
                            isSubmitting
                                ? 'Submitting...'
                                : submitted
                                ? 'Replace Submission'
                                : 'Submit Homework',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openHomeworkHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentHomeworkHistoryPage(),
      ),
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
                onPressed: _loadHomework,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHomework,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatistics(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openHomeworkHistory,
              icon: const Icon(Icons.history),
              label: const Text('Homework History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current Homework',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${homeworks.length} available',
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
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 55,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No homework available',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'You have no current or upcoming homework.',
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
    return Container(color: const Color(0xFFF8FAFC), child: _buildContent());
  }
}
