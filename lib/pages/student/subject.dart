import 'package:flutter/material.dart';

import 'student_pdf_viewer_stub.dart'
    if (dart.library.html) 'student_pdf_viewer_web.dart'
    if (dart.library.io) 'student_pdf_viewer_mobile.dart'
    as pdf_viewer;

import '../../student_api.dart';

class StudentSubjectsPage extends StatefulWidget {
  const StudentSubjectsPage({super.key});

  @override
  State<StudentSubjectsPage> createState() => _StudentSubjectsPageState();
}

class _StudentSubjectsPageState extends State<StudentSubjectsPage> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? student;
  List<dynamic> subjects = [];

  int selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  // ============================================================
  // LOAD SUBJECTS
  // ============================================================

  Future<void> loadSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await StudentApi.getStudentSubjects();

      if (!mounted) {
        return;
      }

      setState(() {
        student = data['student'] as Map<String, dynamic>?;

        subjects = data['subjects'] as List<dynamic>? ?? [];

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // ============================================================
  // OPEN SUBJECT BOOK
  // ============================================================

  void _openSubjectBook(Map<String, dynamic> subject) {
    final subjectName = subject['subject_name']?.toString() ?? 'Subject';

    final bookPdf = subject['book_pdf']?.toString().trim() ?? '';

    if (bookPdf.isEmpty) {
      _showNoBookMessage(subjectName);
      return;
    }

    final bookUrl = 'http://10.40.32.233/BKHS/$bookPdf';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentPdfPage(title: subjectName, pdfUrl: bookUrl),
      ),
    );
  }

  // ============================================================
  // NO BOOK MESSAGE
  // ============================================================

  void _showNoBookMessage(String subjectName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: Icon(
            Icons.menu_book_outlined,
            size: 45,
            color: Colors.blue.shade600,
          ),
          title: const Text(
            'Textbook Not Available',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'The textbook for $subjectName '
            'has not been uploaded yet. '
            'Please check again later.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onNavigationItemSelected(int index) {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }

    if (index == 4) {
      _showMoreMenu();
      return;
    }

    setState(() {
      selectedIndex = index;
    });

    String pageName = '';

    if (index == 1) {
      pageName = 'Homework';
    } else if (index == 2) {
      pageName = 'Results';
    } else if (index == 3) {
      pageName = 'Attendance';
    }

    if (pageName.isNotEmpty) {
      _showPlaceholderPage(pageName);
    }
  }

  // ============================================================
  // MORE MENU
  // ============================================================

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const Text(
                'More',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildMoreItem(
                icon: Icons.menu_book_outlined,
                title: 'My Subjects',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildMoreItem(
                icon: Icons.folder_outlined,
                title: 'Materials',
                onTap: () {
                  Navigator.pop(context);

                  _showPlaceholderPage('Materials');
                },
              ),
              _buildMoreItem(
                icon: Icons.campaign_outlined,
                title: 'Announcements',
                onTap: () {
                  Navigator.pop(context);

                  _showPlaceholderPage('Announcements');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // ============================================================
  // PLACEHOLDER PAGE
  // ============================================================

  void _showPlaceholderPage(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPlaceholderPage(title: title),
      ),
    );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final subjectName = subject['subject_name']?.toString() ?? 'Subject';

    final teacherNames = subject['teacher_names']?.toString() ?? '';

    final bookPdf = subject['book_pdf']?.toString().trim() ?? '';

    final hasBook = bookPdf.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _openSubjectBook(subject);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hasBook ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasBook ? Icons.menu_book_outlined : Icons.book_outlined,
                  size: 20,
                  color: hasBook ? Colors.blue.shade700 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subjectName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                teacherNames.isNotEmpty ? teacherNames : 'No teacher',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Icon(
                hasBook ? Icons.touch_app_outlined : Icons.info_outline,
                size: 14,
                color: hasBook ? Colors.green.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 55,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'No subjects found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(
              'No active subjects are available '
              'for your grade.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 55, color: Colors.red.shade400),
            const SizedBox(height: 15),
            const Text(
              'Unable to load subjects',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadSubjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _buildError();
    }

    final studentName = student?['full_name']?.toString() ?? 'Student';

    final gradeNumber = student?['grade_number']?.toString() ?? '';

    final section = student?['section']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: loadSubjects,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hi, $studentName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Grade $gradeNumber'
                  '${section.isNotEmpty ? ' • $section' : ''}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Subjects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${subjects.length}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (subjects.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: _buildEmptyState(),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final subject = subjects[index] as Map<String, dynamic>;

                return _buildSubjectCard(subject);
              },
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text(
          'My Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onNavigationItemSelected,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STUDENT PDF PAGE
// ============================================================

class StudentPdfPage extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const StudentPdfPage({super.key, required this.title, required this.pdfUrl});

  @override
  State<StudentPdfPage> createState() => _StudentPdfPageState();
}

class _StudentPdfPageState extends State<StudentPdfPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        toolbarHeight: 54,
        leadingWidth: 48,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, size: 24),
          tooltip: 'Back to Subjects',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: pdf_viewer.StudentPdfViewer(pdfUrl: widget.pdfUrl),
        ),
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER PAGE
// ============================================================

class StudentPlaceholderPage extends StatelessWidget {
  final String title;

  const StudentPlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title page coming soon.',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
