import 'package:flutter/material.dart';

import '/api_service.dart';

class HomeworkViewPage extends StatefulWidget {
  final int homeworkId;

  const HomeworkViewPage({super.key, required this.homeworkId});

  @override
  State<HomeworkViewPage> createState() => _HomeworkViewPageState();
}

class _HomeworkViewPageState extends State<HomeworkViewPage> {
  bool isLoading = true;
  bool isUpdating = false;
  bool isMarkingAllDone = false;

  String? errorMessage;

  Map<String, dynamic> homework = {};
  List<Map<String, dynamic>> students = [];

  int totalStudents = 0;
  int doneStudents = 0;
  int notDoneStudents = 0;
  int submittedStudents = 0;
  int notSubmittedStudents = 0;

  int studentCurrentPage = 1;

  static const int studentsPerPage = 10;

  @override
  void initState() {
    super.initState();
    loadHomework();
  }

  Future<void> loadHomework() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getTeacherHomeworkView(
        homeworkId: widget.homeworkId,
      );

      final homeworkData = Map<String, dynamic>.from(data['homework'] ?? {});

      final studentData = data['students'];

      final parsedStudents = <Map<String, dynamic>>[];

      if (studentData is List) {
        for (final student in studentData) {
          if (student is Map) {
            parsedStudents.add(Map<String, dynamic>.from(student));
          }
        }
      }

      final stats = data['statistics'];

      int getStat(String key, int fallback) {
        if (stats is Map) {
          return int.tryParse('${stats[key] ?? fallback}') ?? fallback;
        }

        return fallback;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        homework = homeworkData;
        students = parsedStudents;

        studentCurrentPage = 1;

        totalStudents = getStat('total_students', parsedStudents.length);

        doneStudents = getStat('done', _countStatus(parsedStudents, 'Done'));

        notDoneStudents = getStat(
          'not_done',
          _countStatus(parsedStudents, 'Not Done'),
        );

        submittedStudents = getStat(
          'submitted',
          _countSubmission(parsedStudents, true),
        );

        notSubmittedStudents = getStat(
          'not_submitted',
          _countSubmission(parsedStudents, false),
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  int _countStatus(List<Map<String, dynamic>> items, String status) {
    return items.where((student) {
      return '${student['homework_status'] ?? ''}' == status;
    }).length;
  }

  int _countSubmission(List<Map<String, dynamic>> items, bool submitted) {
    return items.where((student) {
      final value = student['submitted'];

      final isSubmitted =
          value == true || value == 1 || value == '1' || value == 'true';

      return isSubmitted == submitted;
    }).length;
  }

  Future<void> updateStudentStatus(int studentId, String status) async {
    if (isUpdating) {
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      await ApiService.updateTeacherHomeworkStatus(
        homeworkId: widget.homeworkId,
        studentId: studentId,
        status: status,
      );

      await loadHomework();

      if (!mounted) {
        return;
      }

      setState(() {
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Done'
                ? 'Student marked as Done.'
                : 'Student marked as Not Done.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> markAllDone() async {
    if (isMarkingAllDone) {
      return;
    }

    setState(() {
      isMarkingAllDone = true;
    });

    try {
      await ApiService.markAllTeacherHomeworkDone(
        homeworkId: widget.homeworkId,
      );

      await loadHomework();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All students marked as Done.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isMarkingAllDone = false;
        });
      }
    }
  }

  String getValue(String key, {String fallback = '-'}) {
    final value = homework[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String getEthiopianDate(String key) {
    final value = homework[key];

    if (value is Map) {
      final formatted = value['formatted'];

      if (formatted != null && formatted.toString().trim().isNotEmpty) {
        return formatted.toString();
      }

      final year = value['year'];
      final month = value['month'];
      final day = value['day'];

      if (year != null && month != null && day != null) {
        return '$year/$month/$day';
      }
    }

    return '-';
  }

  String getStudentSubmittedDate(Map<String, dynamic> student) {
    final value = student['submitted_at_ethiopian'];

    if (value is Map) {
      final formatted = value['formatted'];

      if (formatted != null && formatted.toString().trim().isNotEmpty) {
        return formatted.toString();
      }
    }

    return '';
  }

  bool isStudentDone(Map<String, dynamic> student) {
    return '${student['homework_status'] ?? ''}' == 'Done';
  }

  bool isStudentSubmitted(Map<String, dynamic> student) {
    final value = student['submitted'];

    return value == true || value == 1 || value == '1' || value == 'true';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homework Details'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: loadHomework,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHomeworkHeader(),
                  const SizedBox(height: 16),
                  _buildStatistics(),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  const SizedBox(height: 16),
                  _buildMaterial(),
                  const SizedBox(height: 16),
                  _buildStudentsHeader(),
                  const SizedBox(height: 10),
                  _buildStudents(),
                ],
              ),
            ),
      floatingActionButton: !isLoading && errorMessage == null
          ? FloatingActionButton.extended(
              onPressed: isMarkingAllDone ? null : markAllDone,
              icon: isMarkingAllDone
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.done_all),
              label: const Text('Mark All Done'),
            )
          : null,
    );
  }

  Widget _buildHomeworkHeader() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getValue('title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.book_outlined, getValue('subject_name')),
                _infoChip(Icons.school_outlined, 'Grade ${getValue('grade')}'),
                _infoChip(
                  Icons.people_outline,
                  'Section ${getValue('section')}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _dateInfo(
                    'Assigned',
                    getEthiopianDate('assigned_date_ethiopian'),
                    Icons.event_available_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateInfo(
                    'Due',
                    getEthiopianDate('due_date_ethiopian'),
                    Icons.event_busy_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dateInfo(String label, String date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _statCard('Total', totalStudents, Icons.people_outline),
        _statCard('Done', doneStudents, Icons.check_circle_outline),
        _statCard('Not Done', notDoneStudents, Icons.pending_outlined),
        _statCard('Submitted', submittedStudents, Icons.upload_file_outlined),
      ],
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final description = getValue('description', fallback: '');

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterial() {
    final material = homework['teacher_material'];

    if (material is! Map) {
      return const SizedBox.shrink();
    }

    final exists = material['exists'] == true;

    if (!exists) {
      return const SizedBox.shrink();
    }

    final name = '${material['original_name'] ?? 'Teacher Material'}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.attach_file),
        ),
        title: const Text(
          'Teacher Material',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _buildStudentsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Students',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$totalStudents students',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStudents() {
    if (students.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(
              'No students found.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    final totalPages = (students.length / studentsPerPage).ceil();

    if (studentCurrentPage > totalPages) {
      studentCurrentPage = totalPages;
    }

    final startIndex = (studentCurrentPage - 1) * studentsPerPage;

    final endIndex = (startIndex + studentsPerPage).clamp(0, students.length);

    final paginatedStudents = students.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              headingRowHeight: 48,
              dataRowMinHeight: 58,
              dataRowMaxHeight: 70,
              headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
              columns: const [
                DataColumn(
                  label: Text(
                    'No.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Student',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Code',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Homework',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Submission',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Submitted Date',
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
              rows: List.generate(paginatedStudents.length, (index) {
                final student = paginatedStudents[index];

                final studentId =
                    int.tryParse(
                      '${student['student_id'] ?? student['id'] ?? 0}',
                    ) ??
                    0;

                final name =
                    '${student['full_name'] ?? student['name'] ?? 'Unknown Student'}';

                final code = '${student['student_code'] ?? '-'}';

                final done = isStudentDone(student);

                final submitted = isStudentSubmitted(student);

                final submittedAt = getStudentSubmittedDate(student);

                final rowNumber = startIndex + index + 1;

                return DataRow(
                  cells: [
                    DataCell(Text('$rowNumber')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(code)),
                    DataCell(_statusBadge(done ? 'Done' : 'Not Done', done)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            submitted
                                ? Icons.check_circle_outline
                                : Icons.schedule_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(submitted ? 'Submitted' : 'Not Submitted'),
                        ],
                      ),
                    ),
                    DataCell(Text(submittedAt.isNotEmpty ? submittedAt : '-')),
                    DataCell(
                      PopupMenuButton<String>(
                        enabled: studentId > 0 && !isUpdating,
                        onSelected: (value) {
                          updateStudentStatus(studentId, value);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'Done',
                            child: Text('Mark Done'),
                          ),
                          PopupMenuItem(
                            value: 'Not Done',
                            child: Text('Mark Not Done'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),

        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: studentCurrentPage > 1
                    ? () {
                        setState(() {
                          studentCurrentPage--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 8),
              Text(
                'Page $studentCurrentPage of $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Next page',
                onPressed: studentCurrentPage < totalPages
                    ? () {
                        setState(() {
                          studentCurrentPage++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statusBadge(String text, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDone ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52),
            const SizedBox(height: 14),
            Text(
              errorMessage!.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadHomework,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
