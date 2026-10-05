import 'package:flutter/material.dart';

import '/api_service.dart';
import '/parent_apiservice.dart';

class ParentAnnouncementsPage extends StatefulWidget {
  final int studentId;

  const ParentAnnouncementsPage({super.key, required this.studentId});

  @override
  State<ParentAnnouncementsPage> createState() =>
      _ParentAnnouncementsPageState();
}

class _ParentAnnouncementsPageState extends State<ParentAnnouncementsPage> {
  late final ParentApiService _apiService;

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _student;
  Map<String, dynamic>? _academicYear;

  List<dynamic> _announcements = [];

  @override
  void initState() {
    super.initState();

    _apiService = ParentApiService(baseUrl: ApiService.baseUrl);

    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = ApiService.token;

    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Authentication token is missing.';
      });

      return;
    }

    try {
      final data = await _apiService.getAnnouncements(token, widget.studentId);

      if (!mounted) return;

      setState(() {
        _student = data['student'] as Map<String, dynamic>?;
        _academicYear = data['academic_year'] as Map<String, dynamic>?;
        _announcements = data['announcements'] as List<dynamic>? ?? [];
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

  String _studentValue(String key) {
    return (_student?[key] ?? '').toString();
  }

  String _academicYearValue(String key) {
    return (_academicYear?[key] ?? '').toString();
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
          'Announcements',
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

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildStudentHeader(),
          const SizedBox(height: 20),
          _buildPageHeader(),
          const SizedBox(height: 12),
          if (_announcements.isEmpty)
            _buildEmptyState()
          else
            ..._announcements.map(
              (announcement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAnnouncementCard(
                  announcement as Map<String, dynamic>,
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    final name = _studentValue('full_name');
    final code = _studentValue('student_code');
    final grade = _studentValue('grade_label');
    final section = _studentValue('section');

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: const Color(0xFFE0E7FF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF4338CA),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$code • $grade • Section $section',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_academicYearValue('name').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Academic Year: '
                      '${_academicYearValue('name')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'School Announcements',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _announcements.isEmpty
              ? 'No announcements available.'
              : '${_announcements.length} announcement'
                    '${_announcements.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final title = (announcement['title'] ?? '').toString();

    final content = (announcement['content'] ?? '').toString();

    final publishedAt = (announcement['published_at'] ?? '').toString();

    final closedAt = (announcement['closed_at'] ?? '').toString();

    final images = announcement['images'] as List<dynamic>? ?? [];

    final attachments = announcement['attachments'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),

            const SizedBox(height: 7),

            _buildDates(publishedAt, closedAt),

            if (content.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Color(0xFF475569),
                ),
              ),
            ],

            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImages(images),
            ],

            if (attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAttachments(attachments),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDates(String publishedAt, String closedAt) {
    if (publishedAt.isEmpty && closedAt.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 5,
      children: [
        if (publishedAt.isNotEmpty)
          _buildDateItem(
            Icons.publish_outlined,
            'Published',
            _formatDate(publishedAt),
          ),
        if (closedAt.isNotEmpty)
          _buildDateItem(
            Icons.event_outlined,
            'Last Date',
            _formatDate(closedAt),
          ),
      ],
    );
  }

  Widget _buildDateItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  String _formatDate(String value) {
    if (value.isEmpty) {
      return '';
    }

    final datePart = value.length >= 10 ? value.substring(0, 10) : value;

    final parts = datePart.split('-');

    if (parts.length != 3) {
      return value;
    }

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Widget _buildImages(List<dynamic> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: images.map((item) {
        final image = item as Map<String, dynamic>;

        final path = (image['file_path'] ?? '').toString();

        if (path.isEmpty) {
          return const SizedBox.shrink();
        }

        final imageUrl = _buildFileUrl(path);

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 210,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return Container(
                  height: 210,
                  alignment: Alignment.center,
                  color: const Color(0xFFF8FAFC),
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: const Color(0xFFF8FAFC),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 32,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Unable to load image',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttachments(List<dynamic> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ATTACHMENTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        ...attachments.map((item) {
          final attachment = item as Map<String, dynamic>;

          final name = (attachment['original_name'] ?? '').toString();

          final size = (attachment['file_size_formatted'] ?? '').toString();

          final icon = (attachment['file_icon'] ?? '📎').toString();

          final path = (attachment['file_path'] ?? '').toString();

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildAttachmentItem(
              name: name,
              size: size,
              icon: icon,
              path: path,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttachmentItem({
    required String name,
    required String size,
    required String icon,
    required String path,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Attachment' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                if (size.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      size,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (path.isNotEmpty)
            IconButton(
              onPressed: () {
                _showFilePath(path);
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              color: const Color(0xFF2563EB),
              tooltip: 'Open',
            ),
        ],
      ),
    );
  }

  String _buildFileUrl(String path) {
    final cleanPath = path.trim().replaceFirst(RegExp(r'^/+'), '');

    final base = ApiService.baseUrl.replaceFirst(RegExp(r'/api$'), '');

    return '$base/$cleanPath';
  }

  void _showFilePath(String path) {
    final url = _buildFileUrl(path);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Attachment'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.campaign_outlined, size: 42, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No announcements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'There are no announcements available at this time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFDC2626)),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: 3,
      onDestinationSelected: _onBottomNavigationTap,
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
    );
  }

  void _onBottomNavigationTap(int index) {
    if (index == 3) {
      return;
    }

    Navigator.of(context).pop();
  }
}
