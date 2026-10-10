import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../../student_api.dart';

class StudentAnnouncementsPage extends StatefulWidget {
  const StudentAnnouncementsPage({super.key});

  @override
  State<StudentAnnouncementsPage> createState() =>
      _StudentAnnouncementsPageState();
}

class _StudentAnnouncementsPageState extends State<StudentAnnouncementsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _announcements = [];

  Map<String, dynamic>? _student;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadAnnouncements({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await StudentApi.getStudentAnnouncements(
        page: page,
        search: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      final pagination = data['pagination'] as Map<String, dynamic>?;

      setState(() {
        _announcements = (data['announcements'] as List<dynamic>?) ?? [];

        _student = data['student'] as Map<String, dynamic>?;

        _currentPage = (pagination?['current_page'] as num?)?.toInt() ?? page;

        _totalPages = (pagination?['total_pages'] as num?)?.toInt() ?? 1;

        _totalItems = (pagination?['total_items'] as num?)?.toInt() ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _search() {
    _loadAnnouncements(page: 1);
  }

  void _clearSearch() {
    _searchController.clear();

    _loadAnnouncements(page: 1);
  }

  void _openMedia({
    required String url,
    required String title,
    required String mimeType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AnnouncementMediaViewer(
          url: url,
          title: title,
          mimeType: mimeType,
        );
      },
    );
  }

  String _formatFileSize(dynamic value) {
    final size = (value as num?)?.toInt() ?? 0;

    if (size <= 0) {
      return '';
    }

    if (size < 1024) {
      return '$size B';
    }

    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }

    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _attachmentIcon(String mimeType, String fileName) {
    final lowerMime = mimeType.toLowerCase();

    final lowerName = fileName.toLowerCase();

    if (lowerMime.contains('pdf') || lowerName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }

    if (lowerMime.contains('word') ||
        lowerName.endsWith('.doc') ||
        lowerName.endsWith('.docx')) {
      return Icons.description;
    }

    if (lowerMime.contains('excel') ||
        lowerName.endsWith('.xls') ||
        lowerName.endsWith('.xlsx')) {
      return Icons.table_chart;
    }

    if (lowerMime.contains('powerpoint') ||
        lowerName.endsWith('.ppt') ||
        lowerName.endsWith('.pptx')) {
      return Icons.slideshow;
    }

    if (lowerMime.contains('zip') || lowerName.endsWith('.zip')) {
      return Icons.folder_zip;
    }

    if (lowerMime.startsWith('image/')) {
      return Icons.image;
    }

    if (lowerMime.contains('text') || lowerName.endsWith('.txt')) {
      return Icons.article;
    }

    return Icons.attach_file;
  }

  bool _isPreviewable(String mimeType, String fileName) {
    final lowerMime = mimeType.toLowerCase();

    final lowerName = fileName.toLowerCase();

    return lowerMime == 'application/pdf' ||
        lowerMime.startsWith('image/') ||
        lowerName.endsWith('.pdf') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Announcements',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : () {
                    _loadAnnouncements(page: _currentPage);
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: () => _loadAnnouncements(page: _currentPage),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(isMobile)),
                  SliverToBoxAdapter(child: _buildSearch()),
                  SliverToBoxAdapter(child: _buildResultSummary()),
                  _announcements.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 28,
                            8,
                            isMobile ? 16 : 28,
                            24,
                          ),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _buildAnnouncementCard(
                                _announcements[index],
                              );
                            }, childCount: _announcements.length),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 520,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  mainAxisExtent: 520,
                                ),
                          ),
                        ),
                  if (_announcements.isNotEmpty)
                    SliverToBoxAdapter(child: _buildPagination()),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final studentCode = _student?['student_code']?.toString() ?? '';

    final grade = _student?['grade_label']?.toString() ?? '';

    final section = _student?['section']?.toString() ?? '';

    final academicYear = _student?['academic_year']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 28,
        24,
        isMobile ? 16 : 28,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'School Announcements',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay updated with the latest news and important information from BKHS.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (studentCode.isNotEmpty)
                _contextPill(Icons.badge_outlined, studentCode),
              if (grade.isNotEmpty) _contextPill(Icons.school_outlined, grade),
              if (section.isNotEmpty)
                _contextPill(Icons.class_outlined, 'Section $section'),
              if (academicYear.isNotEmpty)
                _contextPill(Icons.calendar_today_outlined, academicYear),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contextPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search announcements...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        _totalItems == 1 ? '1 announcement' : '$_totalItems announcements',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final data = announcement as Map<String, dynamic>;

    final title = data['title']?.toString() ?? '';

    final content = data['content']?.toString() ?? '';

    final publishedAt = data['published_at']?.toString() ?? '';

    final images = (data['images'] as List<dynamic>?) ?? [];

    final attachments = (data['attachments'] as List<dynamic>?) ?? [];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 19,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          if (publishedAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                publishedAt,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Text(
                content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          if (images.isNotEmpty) _buildImages(images),
          if (attachments.isNotEmpty) _buildAttachments(attachments),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    publishedAt.isNotEmpty
                        ? 'Published $publishedAt'
                        : 'School announcement',
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

  Widget _buildImages(List<dynamic> images) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final image = images[index] as Map<String, dynamic>;

          final url = image['file_url']?.toString() ?? '';

          if (url.isEmpty) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: () {
              _openMedia(
                url: url,
                title: image['original_name']?.toString() ?? 'Image',
                mimeType: image['mime_type']?.toString() ?? 'image/*',
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: 190,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 190,
                    height: 150,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachments(List<dynamic> attachments) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          ...attachments.map((item) {
            final attachment = item as Map<String, dynamic>;

            final fileName =
                attachment['original_name']?.toString() ?? 'Attachment';

            final url = attachment['file_url']?.toString() ?? '';

            final mimeType = attachment['mime_type']?.toString() ?? '';

            final fileSize = _formatFileSize(attachment['file_size']);

            final previewable = _isPreviewable(mimeType, fileName);

            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: url.isEmpty
                    ? null
                    : previewable
                    ? () {
                        _openMedia(
                          url: url,
                          title: fileName,
                          mimeType: mimeType,
                        );
                      }
                    : () {
                        html.window.open(url, '_blank');
                      },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _attachmentIcon(mimeType, fileName),
                          size: 19,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            if (fileSize.isNotEmpty) const SizedBox(height: 3),
                            if (fileSize.isNotEmpty)
                              Text(
                                fileSize,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        previewable
                            ? Icons.visibility_outlined
                            : Icons.open_in_new,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) {
      return const SizedBox(height: 20);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous',
            onPressed: _currentPage > 1 && !_isLoading
                ? () {
                    _loadAnnouncements(page: _currentPage - 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ..._buildPageButtons(),
          IconButton(
            tooltip: 'Next',
            onPressed: _currentPage < _totalPages && !_isLoading
                ? () {
                    _loadAnnouncements(page: _currentPage + 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final buttons = <Widget>[];

    int start = _currentPage - 2;

    int end = _currentPage + 2;

    if (start < 1) {
      start = 1;
      end = 5;
    }

    if (end > _totalPages) {
      end = _totalPages;
      start = _totalPages - 4;
    }

    if (start < 1) {
      start = 1;
    }

    for (int page = start; page <= end; page++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: 38,
            height: 38,
            child: TextButton(
              onPressed: page == _currentPage
                  ? null
                  : () {
                      _loadAnnouncements(page: page);
                    },
              style: TextButton.styleFrom(
                backgroundColor: page == _currentPage
                    ? const Color(0xFF4F46E5)
                    : Colors.transparent,
                foregroundColor: page == _currentPage
                    ? Colors.white
                    : const Color(0xFF475569),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '$page',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFDC2626)),
            const SizedBox(height: 14),
            const Text(
              'Unable to load announcements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.campaign_outlined,
              size: 56,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            Text(
              searching
                  ? 'No announcements found'
                  : 'No announcements available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Try a different search term.'
                  : 'There are no published announcements for you right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementMediaViewer extends StatefulWidget {
  final String url;
  final String title;
  final String mimeType;

  const _AnnouncementMediaViewer({
    required this.url,
    required this.title,
    required this.mimeType,
  });

  @override
  State<_AnnouncementMediaViewer> createState() =>
      _AnnouncementMediaViewerState();
}

class _AnnouncementMediaViewerState extends State<_AnnouncementMediaViewer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();

    _viewId = 'announcement-viewer-${DateTime.now().microsecondsSinceEpoch}';

    final lowerMime = widget.mimeType.toLowerCase();

    final isPdf =
        lowerMime.contains('pdf') ||
        widget.url.toLowerCase().split('?').first.endsWith('.pdf');

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement();

      iframe.src = isPdf ? '${widget.url}#zoom=page-width' : widget.url;

      iframe.style.border = 'none';

      iframe.style.width = '100%';

      iframe.style.height = '100%';

      iframe.setAttribute('allowfullscreen', 'true');

      return iframe;
    });
  }

  bool get _isPdf {
    final lowerMime = widget.mimeType.toLowerCase();

    return lowerMime.contains('pdf') ||
        widget.url.toLowerCase().split('?').first.endsWith('.pdf');
  }

  bool get _isImage {
    final lowerMime = widget.mimeType.toLowerCase();

    final lowerUrl = widget.url.toLowerCase().split('?').first;

    return lowerMime.startsWith('image/') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        height: height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFF1E293B),
                child: _isImage
                    ? Center(
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 5,
                          child: Image.network(
                            widget.url,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  'Unable to display this image.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : _isPdf
                    ? HtmlElementView(viewType: _viewId)
                    : const Center(
                        child: Text(
                          'This file cannot be previewed here.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
