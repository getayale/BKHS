import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

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

  int? downloadingSubmissionId;

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

  Future<void> downloadSubmission(Map<String, dynamic> student) async {
    if (downloadingSubmissionId != null) {
      return;
    }

    final submissionId = int.tryParse('${student['submission_id'] ?? 0}') ?? 0;

    if (submissionId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission file is not available.')),
      );

      return;
    }

    final originalFileName =
        '${student['submission_original_name'] ?? 'submitted_material'}'.trim();

    if (originalFileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The submitted file name is missing.')),
      );

      return;
    }

    setState(() {
      downloadingSubmissionId = submissionId;
    });

    try {
      final List<int> fileBytes =
          await ApiService.downloadTeacherHomeworkSubmission(
            submissionId: submissionId,
          );

      if (fileBytes.isEmpty) {
        throw Exception('The submitted material file is empty.');
      }

      String fileName = originalFileName;
      String fileExtension = '';

      final lastDotIndex = originalFileName.lastIndexOf('.');

      if (lastDotIndex > 0 && lastDotIndex < originalFileName.length - 1) {
        fileName = originalFileName.substring(0, lastDotIndex);

        fileExtension = originalFileName
            .substring(lastDotIndex + 1)
            .trim()
            .toLowerCase();
      }

      if (kIsWeb) {
        await _downloadFileOnWeb(
          fileBytes: fileBytes,
          fileName: originalFileName,
          fileExtension: fileExtension,
        );
      } else {
        final mimeType = _getMimeType(fileExtension);

        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          fileExtension: fileExtension,
          includeExtension: fileExtension.isNotEmpty,
          mimeType: mimeType,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$originalFileName downloaded successfully.')),
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
          downloadingSubmissionId = null;
        });
      }
    }
  }

  Future<void> _downloadFileOnWeb({
    required List<int> fileBytes,
    required String fileName,
    required String fileExtension,
  }) async {
    final mimeType = _getWebMimeType(fileExtension);

    final blob = html.Blob([Uint8List.fromList(fileBytes)], mimeType);

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.append(anchor);

    anchor.click();

    anchor.remove();

    html.Url.revokeObjectUrl(url);
  }

  String _getWebMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';

      case 'ppt':
        return 'application/vnd.ms-powerpoint';

      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'xls':
        return 'application/vnd.ms-excel';

      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      case 'csv':
        return 'text/csv';

      case 'txt':
        return 'text/plain';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'gif':
        return 'image/gif';

      case 'zip':
        return 'application/zip';

      case 'mp3':
        return 'audio/mpeg';

      case 'mp4':
        return 'video/mp4';

      default:
        return 'application/octet-stream';
    }
  }

  MimeType _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;

      case 'ppt':
      case 'pptx':
        return MimeType.microsoftPresentation;

      case 'doc':
      case 'docx':
        return MimeType.microsoftWord;

      case 'xls':
      case 'xlsx':
        return MimeType.microsoftExcel;

      case 'csv':
        return MimeType.csv;

      case 'txt':
        return MimeType.text;

      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;

      case 'png':
        return MimeType.png;

      case 'gif':
        return MimeType.gif;

      case 'zip':
        return MimeType.zip;

      case 'mp3':
        return MimeType.mp3;

      default:
        return MimeType.other;
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
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 500) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isMarkingAllDone ? null : markAllDone,
              icon: isMarkingAllDone
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.done_all, size: 18),
              label: const Text('All Done'),
            ),
          ),
        ],
      );
    }

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
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: isMarkingAllDone ? null : markAllDone,
          icon: isMarkingAllDone
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.done_all, size: 18),
          label: const Text('All Done'),
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

    final screenWidth = MediaQuery.of(context).size.width;

    final double horizontalMargin = screenWidth < 500
        ? 4
        : screenWidth < 800
        ? 7
        : 12;

    final double columnSpacing = screenWidth < 500
        ? 5
        : screenWidth < 800
        ? 10
        : 20;

    final double headingHeight = screenWidth < 500
        ? 38
        : screenWidth < 800
        ? 44
        : 48;

    final double rowMinHeight = screenWidth < 500
        ? 44
        : screenWidth < 800
        ? 50
        : 58;

    final double rowMaxHeight = screenWidth < 500
        ? 56
        : screenWidth < 800
        ? 62
        : 70;

    final double headingFontSize = screenWidth < 500
        ? 9
        : screenWidth < 800
        ? 10
        : 13;

    final double bodyFontSize = screenWidth < 500
        ? 9
        : screenWidth < 800
        ? 10
        : 13;

    final double avatarRadius = screenWidth < 500
        ? 11
        : screenWidth < 800
        ? 14
        : 17;

    final double avatarFontSize = screenWidth < 500
        ? 8
        : screenWidth < 800
        ? 10
        : 13;

    final double iconSize = screenWidth < 500
        ? 13
        : screenWidth < 800
        ? 15
        : 18;

    final double studentNameWidth = screenWidth < 500
        ? 75
        : screenWidth < 800
        ? 120
        : 180;

    final double codeWidth = screenWidth < 500
        ? 55
        : screenWidth < 800
        ? 80
        : 120;

    final double fileWidth = screenWidth < 500
        ? 85
        : screenWidth < 800
        ? 140
        : 240;

    final double dateWidth = screenWidth < 500
        ? 80
        : screenWidth < 800
        ? 120
        : 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth < 500 ? 10 : 14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    horizontalMargin: horizontalMargin,
                    columnSpacing: columnSpacing,
                    headingRowHeight: headingHeight,
                    dataRowMinHeight: rowMinHeight,
                    dataRowMaxHeight: rowMaxHeight,
                    headingRowColor: WidgetStatePropertyAll(
                      Colors.grey.shade50,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'No.',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Student',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Code',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Submission',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Submitted File',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Submitted Date',
                          style: TextStyle(
                            fontSize: headingFontSize,
                            fontWeight: FontWeight.w700,
                          ),
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

                      final submittedFileName =
                          '${student['submission_original_name'] ?? ''}'.trim();

                      final submissionId =
                          int.tryParse('${student['submission_id'] ?? 0}') ?? 0;

                      final isDownloading =
                          downloadingSubmissionId == submissionId &&
                          submissionId > 0;

                      final rowNumber = startIndex + index + 1;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '$rowNumber',
                              style: TextStyle(fontSize: bodyFontSize),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: avatarRadius,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: avatarFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth < 500 ? 3 : 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: studentNameWidth,
                                  ),
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: codeWidth),
                              child: Text(
                                code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              enabled: studentId > 0 && !isUpdating,
                              onSelected: (value) {
                                updateStudentStatus(studentId, value);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'Done',
                                  child: Text('Done'),
                                ),
                                PopupMenuItem(
                                  value: 'Not Done',
                                  child: Text('Not Done'),
                                ),
                              ],
                              child: _statusBadge(
                                done ? 'Done' : 'Not Done',
                                done,
                                compact: screenWidth < 500,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  submitted
                                      ? Icons.check_circle_outline
                                      : Icons.schedule_outlined,
                                  size: iconSize,
                                ),
                                SizedBox(width: screenWidth < 500 ? 2 : 5),
                                Text(
                                  submitted ? 'Submitted' : 'Not Submitted',
                                  style: TextStyle(fontSize: bodyFontSize),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            submitted &&
                                    submissionId > 0 &&
                                    submittedFileName.isNotEmpty
                                ? InkWell(
                                    onTap: downloadingSubmissionId != null
                                        ? null
                                        : () {
                                            downloadSubmission(student);
                                          },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file_outlined,
                                          size: iconSize,
                                          color: Colors.blue.shade700,
                                        ),
                                        SizedBox(
                                          width: screenWidth < 500 ? 2 : 5,
                                        ),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: fileWidth,
                                          ),
                                          child: Text(
                                            submittedFileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: bodyFontSize,
                                              color: Colors.blue.shade700,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isDownloading) ...[
                                          SizedBox(
                                            width: screenWidth < 500 ? 3 : 6,
                                          ),
                                          SizedBox(
                                            width: screenWidth < 500 ? 11 : 15,
                                            height: screenWidth < 500 ? 11 : 15,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : Text(
                                    '-',
                                    style: TextStyle(fontSize: bodyFontSize),
                                  ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: dateWidth),
                              child: Text(
                                submittedAt.isNotEmpty ? submittedAt : '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
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

  Widget _statusBadge(String text, bool isDone, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w700,
              color: isDone ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          SizedBox(width: compact ? 2 : 4),
          Icon(
            Icons.arrow_drop_down,
            size: compact ? 13 : 16,
            color: isDone ? Colors.green.shade700 : Colors.orange.shade700,
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
