import 'package:flutter/material.dart';

import '/api_service.dart';
import '/parent_apiservice.dart';
import '/pages/parent/child_details.dart';
import '/pages/parent/parent_profile_page.dart';

class ParentDashboardPage extends StatefulWidget {
  final String token;

  const ParentDashboardPage({super.key, required this.token});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  late final ParentApiService _apiService;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _parent;
  Map<String, dynamic>? _academicYear;
  List<Map<String, dynamic>> _children = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _apiService = ParentApiService(baseUrl: 'http://localhost/BKHS/api');

    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getDashboard(widget.token);

      if (!mounted) return;

      final parentData = data['parent'];
      final academicYearData = data['academic_year'];
      final childrenData = data['children'];

      final children = <Map<String, dynamic>>[];

      if (childrenData is List) {
        for (final child in childrenData) {
          if (child is Map) {
            children.add(Map<String, dynamic>.from(child));
          }
        }
      }

      setState(() {
        _parent = parentData is Map
            ? Map<String, dynamic>.from(parentData)
            : null;

        _academicYear = academicYearData is Map
            ? Map<String, dynamic>.from(academicYearData)
            : null;

        _children = children;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');

        _isLoading = false;
      });
    }
  }

  String _getParentName() {
    final name = _parent?['full_name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Parent';
    }

    return name;
  }

  String _getAcademicYear() {
    final year = _academicYear?['name']?.toString().trim();

    if (year == null || year.isEmpty) {
      return 'No active academic year';
    }

    return year;
  }

  String _getParentPhoto() {
    final photoUrl = _parent?['photo_url']?.toString().trim();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return photoUrl;
    }

    final photo = _parent?['photo']?.toString().trim();

    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return photo;
      }

      return 'http://localhost/BKHS/${photo.replaceFirst(RegExp(r'^/+'), '')}';
    }

    return '';
  }

  Future<void> _logout() async {
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
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
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

    if (!mounted) return;

    try {
      await ApiService.logout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );

      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _openProfile() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: _buildAppBar(),

      body: _buildSelectedPage(),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,

      titleSpacing: 20,

      title: Text(
        _getPageTitle(),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      actions: [
        GestureDetector(
          onTap: _openProfile,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildProfileAvatar(),
          ),
        ),

        IconButton(
          onPressed: _logout,
          tooltip: 'Logout',
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFDC2626),
            size: 22,
          ),
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Parent Dashboard';

      case 1:
        return 'My Children';

      case 2:
        return 'Homework';

      case 3:
        return 'Announcements';

      case 4:
        return 'Profile';

      default:
        return 'Parent Portal';
    }
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();

      case 1:
        return _buildComingSoonPage(
          icon: Icons.people_outline_rounded,
          title: 'My Children',
          message: 'Your children details will appear here.',
        );

      case 2:
        return _buildComingSoonPage(
          icon: Icons.assignment_outlined,
          title: 'Homework',
          message: 'Your children homework will appear here.',
        );

      case 3:
        return _buildComingSoonPage(
          icon: Icons.campaign_outlined,
          title: 'Announcements',
          message: 'School announcements will appear here.',
        );

      case 4:
        return ParentProfilePage(token: widget.token);

      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          _buildWelcomeSection(),

          const SizedBox(height: 28),

          _buildChildrenHeader(),

          const SizedBox(height: 15),

          if (_children.isEmpty)
            _buildNoChildrenCard()
          else
            ..._children.map(_buildChildCard),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, ${_getParentName()}',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 26,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          "Here's an overview of your children's "
          'school information.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildChildrenHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'My Children',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              'Academic Year: ${_getAcademicYear()}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    final childName = child['full_name']?.toString().trim().isNotEmpty == true
        ? child['full_name'].toString().trim()
        : 'Unknown Student';

    final studentCode =
        child['student_code']?.toString().trim().isNotEmpty == true
        ? child['student_code'].toString().trim()
        : 'N/A';

    final relationship =
        child['relationship']?.toString().trim().isNotEmpty == true
        ? child['relationship'].toString().trim()
        : 'Parent';

    final gradeNumber = int.tryParse(child['grade_number']?.toString() ?? '');

    final section = child['section']?.toString().trim() ?? '';

    final studentId = int.tryParse(child['student_id']?.toString() ?? '') ?? 0;

    final firstLetter = childName.isNotEmpty
        ? childName.substring(0, 1).toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(color: const Color(0xFFE5E7EB)),

        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Container(
                width: 52,
                height: 52,

                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),

                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      childName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      studentCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(height: 1, color: Color(0xFFEEF0F3)),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDetail(
                  'Grade',
                  gradeNumber != null ? 'Grade $gradeNumber' : 'N/A',
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _buildDetail(
                  'Section',
                  section.isNotEmpty ? section : 'N/A',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildDetail('Academic Year', _getAcademicYear()),
              ),

              const SizedBox(width: 14),

              Expanded(child: _buildDetail('Relationship', relationship)),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(height: 1, color: Color(0xFFEEF0F3)),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: studentId > 0
                  ? () {
                      _viewChild(child);
                    }
                  : null,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),

                foregroundColor: Colors.white,

                elevation: 0,

                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    'View Child',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),

                  SizedBox(width: 7),

                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _viewChild(Map<String, dynamic> child) {
    final studentId = int.tryParse(child['student_id']?.toString() ?? '') ?? 0;

    if (studentId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid student information.')),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChildDetailsPage(studentId: studentId)),
    );
  }

  Widget _buildNoChildrenCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 55),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(color: const Color(0xFFE5E7EB)),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.people_outline_rounded,
              color: Color(0xFF6B7280),
              size: 25,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No children found',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'No children with active account access '
            'were found for the current academic year.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 64,
              height: 64,

              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadDashboard,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final photoUrl = _getParentPhoto();

    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Container(
          width: 38,
          height: 38,

          color: const Color(0xFFEFF6FF),

          child: Image.network(
            photoUrl,

            width: 38,
            height: 38,

            fit: BoxFit.cover,

            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,

            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF2563EB),
                size: 21,
              );
            },
          ),
        ),
      );
    }

    return const CircleAvatar(
      radius: 19,

      backgroundColor: Color(0xFFEFF6FF),

      child: Icon(
        Icons.person_outline_rounded,
        color: Color(0xFF2563EB),
        size: 21,
      ),
    );
  }

  Widget _buildComingSoonPage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(22),
              ),

              child: Icon(icon, color: const Color(0xFF2563EB), size: 34),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,

      onDestinationSelected: _onNavigationTap,

      backgroundColor: Colors.white,

      surfaceTintColor: Colors.white,

      elevation: 8,

      indicatorColor: const Color(0xFFEFF6FF),

      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Dashboard',
        ),

        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Children',
        ),

        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Homework',
        ),

        NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign_rounded),
          label: 'News',
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
