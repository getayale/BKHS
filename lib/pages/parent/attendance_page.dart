import 'package:flutter/material.dart';

import '/api_service.dart';
import '/parent_apiservice.dart';
import '/pages/parent/announcements_page.dart';
import '/pages/parent/homework_page.dart';

class ParentAttendancePage extends StatefulWidget {
  final int studentId;

  const ParentAttendancePage({super.key, required this.studentId});

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> {
  late final ParentApiService _apiService;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _student;
  Map<String, dynamic>? _academicYear;

  List<dynamic> _attendance = [];

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();

    _apiService = ParentApiService(baseUrl: ApiService.baseUrl);

    _loadAttendance();
  }

  Future<void> _loadAttendance({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = ApiService.token;

      if (token == null || token.trim().isEmpty) {
        throw Exception('Authentication token is missing.');
      }

      final data = await _apiService.getAttendance(
        token,
        widget.studentId,
        page: page,
      );

      if (!mounted) {
        return;
      }

      final student = data['student'] as Map<String, dynamic>?;

      final academicYear = data['academic_year'] as Map<String, dynamic>?;

      final attendance = data['attendance'] as List<dynamic>? ?? [];

      final pagination = data['pagination'] as Map<String, dynamic>?;

      setState(() {
        _student = student;
        _academicYear = academicYear;
        _attendance = attendance;

        _currentPage = (pagination?['current_page'] as num?)?.toInt() ?? page;

        _totalPages = (pagination?['total_pages'] as num?)?.toInt() ?? 1;

        _totalRecords = (pagination?['total_records'] as num?)?.toInt() ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) {
      return;
    }

    _loadAttendance(page: page);
  }

  Color _statusBackground(String status) {
    if (status.toLowerCase() == 'absent') {
      return Colors.red.shade50;
    }

    return Colors.orange.shade50;
  }

  Color _statusForeground(String status) {
    if (status.toLowerCase() == 'absent') {
      return Colors.red.shade700;
    }

    return Colors.orange.shade700;
  }

  String _getStudentValue(String key) {
    return _student?[key]?.toString() ?? '';
  }

  Widget _buildStudentHeader() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
              _getStudentValue('full_name'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              _getStudentValue('student_code'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip('Grade', _getStudentValue('grade_label')),
                _buildInfoChip('Section', _getStudentValue('section')),
                _buildInfoChip(
                  'Academic Year',
                  _academicYear?['name']?.toString() ?? '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    if (_attendance.isEmpty) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No absent or late attendance records found.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '$_totalRecords records',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 35,
              headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text('Ethiopian Date')),
                DataColumn(label: Text('Status')),
              ],
              rows: _attendance.map((record) {
                final item = record as Map<String, dynamic>;

                final date = item['ethiopian_date']?.toString() ?? '';

                final status = item['status']?.toString() ?? '';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBackground(status),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _statusForeground(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          if (_totalPages > 1) ...[
            const Divider(height: 1),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () {
                        _goToPage(_currentPage - 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),

              ..._buildPageButtons(),

              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () {
                        _goToPage(_currentPage + 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final List<Widget> buttons = [];

    final int start = (_currentPage - 2).clamp(1, _totalPages);

    final int end = (_currentPage + 2).clamp(1, _totalPages);

    for (int page = start; page <= end; page++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: 36,
            height: 36,
            child: TextButton(
              onPressed: page == _currentPage
                  ? null
                  : () {
                      _goToPage(page);
                    },
              style: TextButton.styleFrom(
                backgroundColor: page == _currentPage ? Colors.indigo : null,
                foregroundColor: page == _currentPage
                    ? Colors.white
                    : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('$page'),
            ),
          ),
        ),
      );
    }

    return buttons;
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
        final token = ApiService.token;

        if (token == null || token.trim().isEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication token is missing.')),
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

      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ParentAnnouncementsPage(studentId: widget.studentId),
          ),
        );
        break;

      case 4:
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile will be available soon.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance'), centerTitle: false),

      body: RefreshIndicator(
        onRefresh: () {
          return _loadAttendance(page: _currentPage);
        },
        child: _buildBody(),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: _onBottomNavigationTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),

          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Homework',
          ),

          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'News',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),

              const SizedBox(height: 12),

              Text(_errorMessage!, textAlign: TextAlign.center),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  _loadAttendance(page: _currentPage);
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_student != null) _buildStudentHeader(),

        const SizedBox(height: 16),

        _buildAttendanceTable(),
      ],
    );
  }
}
