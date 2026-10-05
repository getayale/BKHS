import 'package:flutter/material.dart';

import '../../api_service.dart';
import '../../parent_apiservice.dart';
import '/pages/parent/attendance_page.dart';
import '/pages/parent/announcements_page.dart';
import '/pages/parent/homework_history_page.dart';
import '/pages/parent/results_page.dart';

class HomeworkPage extends StatefulWidget {
  final String token;
  final int studentId;

  const HomeworkPage({super.key, required this.token, required this.studentId});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  late ParentApiService _apiService;

  Map<String, dynamic>? _homeworkData;

  bool _isLoading = true;
  String? _error;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();

    _apiService = ParentApiService(baseUrl: ApiService.baseUrl);

    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getHomework(
        widget.token,
        widget.studentId,
        currentPage: _currentPage,
        historyPage: 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _homeworkData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeCurrentPage(int page) {
    setState(() {
      _currentPage = page;
    });

    _loadHomework();
  }

  void _openHomeworkHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeworkHistoryPage(
          token: widget.token,
          studentId: widget.studentId,
        ),
      ),
    );
  }

  void _onBottomNavigationTap(int index) {
    if (index == 3) {
      return;
    }

    switch (index) {
      case 0:
        Navigator.of(context).pop();
        break;

      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ParentResultsPage(studentId: widget.studentId),
          ),
        );
        break;

      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ParentAttendancePage(studentId: widget.studentId),
          ),
        );
        break;

      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ParentAnnouncementsPage(studentId: widget.studentId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = (_homeworkData?['student'] as Map<String, dynamic>?) ?? {};

    final currentHomework =
        (_homeworkData?['current_homework'] as Map<String, dynamic>?) ?? {};

    final currentItems = (currentHomework['items'] as List?) ?? [];

    final pagination =
        (currentHomework['pagination'] as Map<String, dynamic>?) ?? {};

    final totalPages = int.tryParse('${pagination['total_pages'] ?? 1}') ?? 1;

    final hasPrevious = pagination['has_previous'] == true;

    final hasNext = pagination['has_next'] == true;

    final fullName = '${student['full_name'] ?? ''}'.trim();

    final studentCode = '${student['student_code'] ?? ''}'.trim();

    final gradeNumber = '${student['grade_number'] ?? ''}'.trim();

    final section = '${student['section'] ?? ''}'.trim();

    final academicYear =
        '${student['academic_year'] ?? student['academic_year_name'] ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff111827),
        title: const Text(
          'Homework',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Unable to load homework.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _loadHomework,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadHomework,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffe5e7eb)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? 'Student' : fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff111827),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: [
                              if (studentCode.isNotEmpty)
                                Text(
                                  'Code: $studentCode',
                                  style: const TextStyle(
                                    color: Color(0xff6b7280),
                                  ),
                                ),

                              if (gradeNumber.isNotEmpty)
                                Text(
                                  'Grade: $gradeNumber',
                                  style: const TextStyle(
                                    color: Color(0xff6b7280),
                                  ),
                                ),

                              if (section.isNotEmpty)
                                Text(
                                  'Section: $section',
                                  style: const TextStyle(
                                    color: Color(0xff6b7280),
                                  ),
                                ),

                              if (academicYear.isNotEmpty)
                                Text(
                                  'Academic Year: $academicYear',
                                  style: const TextStyle(
                                    color: Color(0xff6b7280),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffe5e7eb)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Current Homework',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff111827),
                                    ),
                                  ),
                                ),

                                OutlinedButton(
                                  onPressed: _openHomeworkHistory,
                                  child: const Text('History'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            if (currentItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'There is no current homework for this student.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xff6b7280)),
                                  ),
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 22,
                                  headingRowHeight: 48,
                                  dataRowMinHeight: 58,
                                  dataRowMaxHeight: 80,
                                  columns: const [
                                    DataColumn(label: Text('Subject')),
                                    DataColumn(label: Text('Homework')),
                                    DataColumn(label: Text('Teacher')),
                                    DataColumn(label: Text('Assigned')),
                                    DataColumn(label: Text('Due')),
                                    DataColumn(label: Text('Status')),
                                  ],
                                  rows: currentItems.map((item) {
                                    final homework = Map<String, dynamic>.from(
                                      item,
                                    );

                                    final subject =
                                        '${homework['subject_name'] ?? ''}';

                                    final title = '${homework['title'] ?? ''}';

                                    final teacher =
                                        '${homework['teacher_name'] ?? ''}';

                                    final assignedDate =
                                        '${homework['assigned_date_ethiopian'] ?? homework['assigned_date'] ?? ''}';

                                    final dueDate =
                                        '${homework['due_date_ethiopian'] ?? homework['due_date'] ?? ''}';

                                    final status =
                                        '${homework['student_status'] ?? 'Not Done'}';

                                    final isDone =
                                        status.toLowerCase() == 'done';

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              subject.isEmpty
                                                  ? 'Unknown Subject'
                                                  : subject,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),

                                        DataCell(
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              title.isEmpty
                                                  ? 'Untitled Homework'
                                                  : title,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),

                                        DataCell(
                                          SizedBox(
                                            width: 130,
                                            child: Text(
                                              teacher.isEmpty
                                                  ? 'Unknown Teacher'
                                                  : teacher,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),

                                        DataCell(Text(assignedDate)),

                                        DataCell(Text(dueDate)),

                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDone
                                                  ? Colors.green.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.orange.withValues(
                                                      alpha: 0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isDone ? 'Done' : 'Not Done',
                                              style: TextStyle(
                                                color: isDone
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),

                            if (currentItems.isNotEmpty && totalPages > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: hasPrevious
                                          ? () {
                                              _changeCurrentPage(
                                                _currentPage - 1,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                    ),

                                    const SizedBox(width: 8),

                                    Text(
                                      'Page $_currentPage of $totalPages',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    IconButton(
                                      onPressed: hasNext
                                          ? () {
                                              _changeCurrentPage(
                                                _currentPage + 1,
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavigationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Results',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Homework',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'News',
          ),
        ],
      ),
    );
  }
}
