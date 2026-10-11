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

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getTeacherDashboard();

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load dashboard. Please check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final data = await ApiService.getTeacherProfile();

      if (!mounted || data['success'] != true) return;

      final profile = data['profile'];

      if (profile is Map) {
        setState(() {
          teacherProfile = Map<String, dynamic>.from(profile);
        });
      } else {
        final teacher = dashboardData?['teacher'];

        if (teacher is Map) {
          setState(() {
            teacherProfile = Map<String, dynamic>.from(teacher);
          });
        }
      }
    } catch (e) {
      debugPrint('Unable to load teacher profile: $e');

      final teacher = dashboardData?['teacher'];

      if (!mounted) return;

      if (teacher is Map) {
        setState(() {
          teacherProfile = Map<String, dynamic>.from(teacher);
        });
      }
    }
  }

  String _resolvePhotoUrl(String? value) {
    final path = value?.trim().replaceAll(r'\', '/') ?? '';

    if (path.isEmpty) return '';

    final baseUri = Uri.parse(ApiService.baseUrl);
    final serverOrigin = '${baseUri.scheme}://${baseUri.authority}';
    final projectPath = baseUri.path.replaceFirst(RegExp(r'/api/?$'), '');

    final uri = Uri.tryParse(path);

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (uri.host == 'localhost' ||
          uri.host == '10.40.32.233' ||
          uri.host == '::1') {
        return uri
            .replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.hasPort ? baseUri.port : null,
            )
            .toString();
      }

      return path;
    }

    final cleanPath = path
        .replaceFirst(RegExp(r'^\./'), '')
        .replaceFirst(RegExp(r'^/+'), '');

    if (cleanPath.startsWith('BKHS/')) {
      return '$serverOrigin/$cleanPath';
    }

    if (cleanPath.startsWith('public/')) {
      return '$serverOrigin$projectPath/$cleanPath';
    }

    if (cleanPath.startsWith('uploads/')) {
      return '$serverOrigin$projectPath/public/$cleanPath';
    }

    if (cleanPath.contains('/')) {
      return '$serverOrigin$projectPath/$cleanPath';
    }

    return '$serverOrigin$projectPath/public/uploads/profiles/$cleanPath';
  }

  String? _getTeacherPhotoUrl() {
    final profile = teacherProfile;
    final dashboardTeacher = dashboardData?['teacher'];

    final candidates = [
      if (dashboardTeacher is Map) dashboardTeacher['photo_url'],
      if (profile != null) profile['photo_url'],
      if (dashboardTeacher is Map) dashboardTeacher['photo_path'],
      if (profile != null) profile['photo_path'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();

      if (value == null || value.isEmpty) continue;

      final resolvedUrl = _resolvePhotoUrl(value);

      if (resolvedUrl.isNotEmpty) {
        debugPrint('Teacher photo URL: $resolvedUrl');
        return resolvedUrl;
      }
    }

    debugPrint('No teacher photo URL was found.');
    return null;
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TeacherProfilePage()));

    if (!mounted) return;

    await _loadTeacherProfile();
  }

  Future<void> _handleLogout() async {
    if (isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

    if (shouldLogout != true || !mounted) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await ApiService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

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
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional teacher tools',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                ),
                const SizedBox(height: 14),
                _moreBottomItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Roster',
                  subtitle: 'View assigned students',
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RosterScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _moreBottomItem(
                  icon: Icons.folder_outlined,
                  title: 'Materials',
                  subtitle: 'Manage teaching materials',
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    Navigator.of(context).push(
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _buildPage(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 54,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: textColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Text(
        navigationTitles[selectedIndex],
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'Profile',
          onPressed: _openProfile,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.person_outline, color: primaryColor, size: 23),
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: isLoggingOut ? null : _handleLogout,
          visualDensity: VisualDensity.compact,
          icon: isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.redAccent,
                  ),
                )
              : const Icon(Icons.logout, color: Colors.redAccent, size: 21),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, -2),
              color: Colors.black.withValues(alpha: 0.04),
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
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 21,
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
        child: CircularProgressIndicator(color: primaryColor),
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
      color: primaryColor,
      onRefresh: loadDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360 ? 10.0 : 14.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeCard(
                      teacherName: teacherName,
                      today: todayFormatted,
                      academicYear: academicYearName,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      title: 'Overview',
                      subtitle: 'Your teaching summary',
                    ),
                    const SizedBox(height: 9),
                    _statisticsSection(
                      subjectCount: subjectAssignments.length,
                      homeroomCount: homeroomAssignments.length,
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      title: 'Subject Assignments',
                      subtitle: 'Your assigned classes and subjects',
                    ),
                    const SizedBox(height: 9),
                    if (subjectAssignments.isEmpty)
                      _emptyCard(
                        icon: Icons.menu_book_outlined,
                        message: 'No subject assignments found.',
                      )
                    else
                      ...subjectAssignments.map((item) {
                        final assignment = Map<String, dynamic>.from(
                          item as Map,
                        );

                        final grade = assignment['grade']?.toString() ?? '';

                        final section = assignment['section']?.toString() ?? '';

                        final subject =
                            assignment['subject_name']?.toString() ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _assignmentCard(
                            icon: Icons.menu_book_outlined,
                            title: subject,
                            grade: 'Grade $grade',
                            section: 'Section $section',
                          ),
                        );
                      }),
                    const SizedBox(height: 10),
                    _sectionTitle(
                      title: 'Homeroom',
                      subtitle: 'Your homeroom responsibilities',
                    ),
                    const SizedBox(height: 9),
                    if (homeroomAssignments.isEmpty)
                      _emptyCard(
                        icon: Icons.groups_outlined,
                        message: 'No homeroom assignment found.',
                      )
                    else
                      ...homeroomAssignments.map((item) {
                        final assignment = Map<String, dynamic>.from(
                          item as Map,
                        );

                        final grade = assignment['grade']?.toString() ?? '';

                        final section = assignment['section']?.toString() ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
            ),
          );
        },
      ),
    );
  }

  Widget _welcomeCard({
    required String teacherName,
    required String today,
    required String academicYear,
  }) {
    final photoUrl = _getTeacherPhotoUrl();

    final initials =
        teacherProfile?['initials']?.toString() ?? _getInitials(teacherName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTeacherPhoto(photoUrl: photoUrl ?? '', initials: initials),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacherName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (today.isNotEmpty || academicYear.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (today.isNotEmpty)
              _welcomeInfoRow(icon: Icons.calendar_today_outlined, text: today),
            if (today.isNotEmpty && academicYear.isNotEmpty)
              const SizedBox(height: 7),
            if (academicYear.isNotEmpty)
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
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return _initialAvatar(initials);
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Teacher photo failed to load: $photoUrl');
                  debugPrint('Image error: $error');

                  return _initialAvatar(initials);
                },
              )
            : _initialAvatar(initials),
      ),
    );
  }

  Widget _initialAvatar(String initials) {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
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

    if (parts.isEmpty) return 'T';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _welcomeInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12,
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: secondaryTextColor),
        ),
      ],
    );
  }

  Widget _statisticsSection({
    required int subjectCount,
    required int homeroomCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.menu_book_outlined,
            title: 'Subjects',
            value: subjectCount.toString(),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statCard(
            icon: Icons.class_outlined,
            title: 'Classes',
            value: subjectCount.toString(),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statCard(
            icon: Icons.groups_outlined,
            title: 'Homeroom',
            value: homeroomCount.toString(),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 17),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: secondaryTextColor),
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Untitled' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _badge(icon: Icons.school_outlined, text: grade),
                    _badge(icon: Icons.group_outlined, text: section),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: secondaryTextColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          const Icon(
            Icons.cloud_off_outlined,
            color: Colors.redAccent,
            size: 48,
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to load dashboard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: loadDashboard,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
