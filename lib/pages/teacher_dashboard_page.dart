import 'package:flutter/material.dart';

import '/api_service.dart';
import '/pages/login_page.dart';
import '/pages/teacher/attendance_page.dart';
import '/pages/teacher/result_page.dart';
import '/pages/teacher/homework/homework_page.dart';
import '/pages/teacher/roster_screen.dart';
import '/pages/teacher/teacher_profile_page.dart';
import '/pages/teacher/material/material_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int selectedIndex = 0;

  bool isLoading = true;
  bool isLoggingOut = false;

  String? errorMessage;

  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? teacherProfile;

  final List<String> navigationTitles = [
    'Dashboard',
    'Results',
    'Attendance',
    'Homework',
    'More',
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final data = await ApiService.getTeacherDashboard();

      if (!mounted) {
        return;
      }

      if (data['success'] != true) {
        setState(() {
          errorMessage =
              data['message']?.toString() ?? 'Unable to load dashboard.';
          isLoading = false;
        });

        return;
      }

      setState(() {
        dashboardData = data;
        isLoading = false;
        errorMessage = null;
      });

      await _loadTeacherProfile();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Unable to load dashboard.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final data = await ApiService.getTeacherProfile();

      if (!mounted) {
        return;
      }

      if (data['success'] != true) {
        return;
      }

      setState(() {
        teacherProfile = Map<String, dynamic>.from(data['profile'] ?? {});
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TeacherProfilePage()));

    if (!mounted) {
      return;
    }

    await _loadTeacherProfile();
  }

  Future<void> _handleLogout() async {
    if (isLoggingOut) {
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      await ApiService.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logout failed. Please try again.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional teacher tools',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(height: 18),
                _moreBottomItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Roster',
                  subtitle: 'View your assigned students',
                  onTap: () {
                    Navigator.of(context).pop();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RosterScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _moreBottomItem(
                  icon: Icons.folder_outlined,
                  title: 'Material',
                  subtitle: 'Manage your teaching materials',
                  onTap: () {
                    Navigator.of(context).pop();

                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (context) => const TeacherMaterialPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _moreBottomItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: _buildAppBar(),
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF111827),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Text(
        navigationTitles[selectedIndex],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Profile',
          onPressed: _openProfile,
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF4F46E5),
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Logout',
          onPressed: isLoggingOut ? null : _handleLogout,
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoggingOut
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.redAccent,
                      ),
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              offset: const Offset(0, -4),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            if (index == 4) {
              _showMoreMenu();
              return;
            }

            setState(() {
              selectedIndex = index;
            });
          },
          elevation: 0,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Results',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_available_outlined),
              activeIcon: Icon(Icons.event_available),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Homework',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_outlined),
              activeIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (selectedIndex) {
      case 1:
        return const ResultPage();

      case 2:
        return const AttendancePage();

      case 3:
        return const HomeworkPage();

      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    if (errorMessage != null) {
      return _errorView();
    }

    final teacher = dashboardData?['teacher'] as Map<String, dynamic>?;

    final academicYear =
        dashboardData?['academic_year'] as Map<String, dynamic>?;

    final subjectAssignments =
        dashboardData?['subject_assignments'] as List? ?? [];

    final homeroomAssignments =
        dashboardData?['homeroom_assignments'] as List? ?? [];

    final today = dashboardData?['today'] as Map<String, dynamic>?;

    final teacherName =
        teacher?['name']?.toString() ??
        teacherProfile?['full_name']?.toString() ??
        'Teacher';

    final academicYearName =
        academicYear?['name']?.toString() ?? 'Not available';

    final todayFormatted = today?['formatted']?.toString() ?? '';

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(
              teacherName: teacherName,
              today: todayFormatted,
              academicYear: academicYearName,
            ),
            const SizedBox(height: 22),
            _sectionTitle(title: 'Overview', subtitle: 'Your teaching summary'),
            const SizedBox(height: 12),
            _statisticsSection(
              subjectCount: subjectAssignments.length,
              homeroomCount: homeroomAssignments.length,
            ),
            const SizedBox(height: 26),
            _sectionTitle(
              title: 'Subject Assignments',
              subtitle: 'Classes and subjects assigned to you',
            ),
            const SizedBox(height: 12),
            if (subjectAssignments.isEmpty)
              _emptyCard(
                icon: Icons.menu_book_outlined,
                message: 'No subject assignments found.',
              )
            else
              ...subjectAssignments.map((assignment) {
                final grade = assignment['grade']?.toString() ?? '';

                final section = assignment['section']?.toString() ?? '';

                final subject = assignment['subject_name']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _assignmentCard(
                    icon: Icons.menu_book_outlined,
                    title: subject,
                    grade: 'Grade $grade',
                    section: 'Section $section',
                  ),
                );
              }),
            const SizedBox(height: 14),
            _sectionTitle(
              title: 'Homeroom',
              subtitle: 'Your homeroom responsibilities',
            ),
            const SizedBox(height: 12),
            if (homeroomAssignments.isEmpty)
              _emptyCard(
                icon: Icons.groups_outlined,
                message: 'No homeroom assignment found.',
              )
            else
              ...homeroomAssignments.map((assignment) {
                final grade = assignment['grade']?.toString() ?? '';

                final section = assignment['section']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _assignmentCard(
                    icon: Icons.groups_outlined,
                    title: 'Homeroom Teacher',
                    grade: 'Grade $grade',
                    section: 'Section $section',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard({
    required String teacherName,
    required String today,
    required String academicYear,
  }) {
    final photoUrl = teacherProfile?['photo_url']?.toString() ?? '';

    final initials =
        teacherProfile?['initials']?.toString() ?? _getInitials(teacherName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTeacherPhoto(photoUrl: photoUrl, initials: initials),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Welcome back, $teacherName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (today.isNotEmpty)
            _welcomeInfoRow(icon: Icons.calendar_today_outlined, text: today),
          if (academicYear.isNotEmpty) ...[
            const SizedBox(height: 10),
            _welcomeInfoRow(icon: Icons.school_outlined, text: academicYear),
          ],
        ],
      ),
    );
  }

  Widget _buildTeacherPhoto({
    required String photoUrl,
    required String initials,
  }) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _initialAvatar(initials);
                },
              )
            : _initialAvatar(initials),
      ),
    );
  }

  Widget _initialAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'T';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _welcomeInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _statisticsSection({
    required int subjectCount,
    required int homeroomCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              _statCard(
                icon: Icons.menu_book_outlined,
                title: 'Subjects',
                value: subjectCount.toString(),
              ),
              const SizedBox(height: 10),
              _statCard(
                icon: Icons.class_outlined,
                title: 'Classes',
                value: subjectCount.toString(),
              ),
              const SizedBox(height: 10),
              _statCard(
                icon: Icons.groups_outlined,
                title: 'Homeroom',
                value: homeroomCount.toString(),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.menu_book_outlined,
                title: 'Subjects',
                value: subjectCount.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.class_outlined,
                title: 'Classes',
                value: subjectCount.toString(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.groups_outlined,
                title: 'Homeroom',
                value: homeroomCount.toString(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard({
    required IconData icon,
    required String title,
    required String grade,
    required String section,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _badge(icon: Icons.school_outlined, text: grade),
                    _badge(icon: Icons.group_outlined, text: section),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _badge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF9CA3AF), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              color: Colors.redAccent,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Unable to load dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                loadDashboard();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
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
}
