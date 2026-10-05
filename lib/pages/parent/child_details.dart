import 'package:flutter/material.dart';

import '/api_service.dart';
import '/parent_apiservice.dart';
import '/pages/parent/results_page.dart';
import '/pages/parent/attendance_page.dart';
import '/pages/parent/announcements_page.dart';
import '/pages/parent/homework_page.dart';

class ChildDetailsPage extends StatefulWidget {
  final int studentId;

  const ChildDetailsPage({super.key, required this.studentId});

  @override
  State<ChildDetailsPage> createState() => _ChildDetailsPageState();
}

class _ChildDetailsPageState extends State<ChildDetailsPage> {
  late final ParentApiService _parentApiService;

  Map<String, dynamic>? _child;
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _parentApiService = ParentApiService(baseUrl: ApiService.baseUrl);

    _loadChild();
  }

  Future<void> _loadChild() async {
    final token = ApiService.token;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Authentication token is missing.';
      });
      return;
    }

    try {
      final data = await _parentApiService.getChild(token, widget.studentId);

      if (!mounted) return;

      setState(() {
        _child = data['child'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _value(String key) {
    return (_child?[key] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        title: const Text(
          'My Child',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_child == null) {
      return const Center(child: Text('Child information not found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadChild,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildChildHeader(),

          const SizedBox(height: 20),

          _buildSectionTitle('Student Information'),

          const SizedBox(height: 10),

          _buildStudentDetailsCard(),

          const SizedBox(height: 16),

          _buildCurrentPlacementCard(),

          const SizedBox(height: 20),

          _buildSectionTitle('School Information'),

          const SizedBox(height: 10),

          _buildSchoolInformationCard(),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildChildHeader() {
    final name = _value('full_name');
    final studentCode = _value('student_code');
    final relationship = _value('relationship');

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE0E7FF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF4338CA),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  studentCode,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),

                if (relationship.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      relationship,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildStudentDetailsCard() {
    return _buildInformationCard(
      children: [
        _buildInfoRow(Icons.person_outline, 'Full Name', _value('full_name')),

        _buildDivider(),

        _buildInfoRow(
          Icons.badge_outlined,
          'Student Code',
          _value('student_code'),
        ),

        _buildDivider(),

        _buildInfoRow(
          Icons.family_restroom_outlined,
          'Relationship',
          _value('relationship'),
        ),
      ],
    );
  }

  Widget _buildCurrentPlacementCard() {
    return _buildInformationCard(
      children: [
        _buildInfoRow(Icons.school_outlined, 'Grade', _value('grade_label')),

        _buildDivider(),

        _buildInfoRow(Icons.class_outlined, 'Section', _value('section')),

        _buildDivider(),

        _buildInfoRow(
          Icons.calendar_month_outlined,
          'Academic Year',
          _value('academic_year_name'),
        ),
      ],
    );
  }

  Widget _buildSchoolInformationCard() {
    return _buildInformationCard(
      children: [
        _buildInfoRow(Icons.school_outlined, 'Grade', _value('grade_label')),

        _buildDivider(),

        _buildInfoRow(Icons.class_outlined, 'Section', _value('section')),

        _buildDivider(),

        _buildInfoRow(
          Icons.calendar_today_outlined,
          'Academic Year',
          _value('academic_year_name'),
        ),

        _buildDivider(),

        _buildInfoRow(
          Icons.check_circle_outline,
          'Registration',
          _value('registration_status'),
          valueColor: const Color(0xFF15803D),
        ),
      ],
    );
  }

  Widget _buildInformationCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF64748B)),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 48, endIndent: 16);
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onNavigationSelected,
      backgroundColor: Colors.white,
      elevation: 8,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),

        NavigationDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(Icons.assessment),
          label: 'Results',
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
      ],
    );
  }

  void _onNavigationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pop();
        break;

      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ParentResultsPage(studentId: widget.studentId),
          ),
        );
        break;

      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ParentAttendancePage(studentId: widget.studentId),
          ),
        );
        break;

      case 3:
        final token = ApiService.token;

        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication token is missing.'),
              behavior: SnackBarBehavior.floating,
            ),
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

      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ParentAnnouncementsPage(studentId: widget.studentId),
          ),
        );
        break;
    }
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFDC2626)),

            const SizedBox(height: 14),

            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: _loadChild,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be connected next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
