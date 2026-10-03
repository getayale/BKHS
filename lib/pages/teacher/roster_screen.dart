import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../../api_service.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  String _rosterType = 'first';

  bool _loading = true;
  bool _exporting = false;

  String? _errorMessage;

  Map<String, dynamic>? _rosterData;

  final ScrollController _fixedVerticalController = ScrollController();
  final ScrollController _dataVerticalController = ScrollController();

  bool _syncingScroll = false;

  @override
  void initState() {
    super.initState();

    _fixedVerticalController.addListener(_syncFixedToData);
    _dataVerticalController.addListener(_syncDataToFixed);

    _loadRoster();
  }

  void _syncFixedToData() {
    if (_syncingScroll) {
      return;
    }

    if (!_dataVerticalController.hasClients ||
        !_fixedVerticalController.hasClients) {
      return;
    }

    _syncingScroll = true;

    final position = _dataVerticalController.position;

    _dataVerticalController.jumpTo(
      _fixedVerticalController.offset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );

    _syncingScroll = false;
  }

  void _syncDataToFixed() {
    if (_syncingScroll) {
      return;
    }

    if (!_fixedVerticalController.hasClients ||
        !_dataVerticalController.hasClients) {
      return;
    }

    _syncingScroll = true;

    final position = _fixedVerticalController.position;

    _fixedVerticalController.jumpTo(
      _dataVerticalController.offset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );

    _syncingScroll = false;
  }

  @override
  void dispose() {
    _fixedVerticalController.removeListener(_syncFixedToData);
    _dataVerticalController.removeListener(_syncDataToFixed);

    _fixedVerticalController.dispose();
    _dataVerticalController.dispose();

    super.dispose();
  }

  Future<void> _loadRoster() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getTeacherRoster(rosterType: _rosterType);

      if (!mounted) {
        return;
      }

      setState(() {
        _rosterData = data;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_fixedVerticalController.hasClients) {
          _fixedVerticalController.jumpTo(0);
        }

        if (_dataVerticalController.hasClients) {
          _dataVerticalController.jumpTo(0);
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeRosterType(String value) async {
    if (_rosterType == value) {
      return;
    }

    setState(() {
      _rosterType = value;
      _rosterData = null;
    });

    await _loadRoster();
  }

  Future<void> _exportRoster() async {
    if (_exporting) {
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      final bytes = await ApiService.downloadTeacherRosterExport(
        rosterType: _rosterType,
      );

      if (bytes.isEmpty) {
        throw Exception('The Excel file is empty.');
      }

      final fileBytes = Uint8List.fromList(bytes);

      final homeroom = _mapData(_rosterData?['homeroom']);

      final gradeName = homeroom['grade_name']?.toString().trim() ?? '';

      final sectionName = homeroom['section_name']?.toString().trim() ?? '';

      final gradeNumber = homeroom['grade_number']?.toString().trim() ?? '';

      String gradePart;

      if (gradeNumber.isNotEmpty) {
        gradePart = 'Grade$gradeNumber';
      } else {
        gradePart = gradeName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      }

      if (gradePart.isEmpty) {
        gradePart = 'Grade';
      }

      final sectionPart = sectionName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

      final rosterTypePart = _rosterType == 'first'
          ? 'First'
          : _rosterType == 'second'
          ? 'Second'
          : 'Annual';

      final fileName = sectionPart.isNotEmpty
          ? '${gradePart}_${sectionPart}_$rosterTypePart'
          : '${gradePart}_$rosterTypePart';

      final savedPath = await FileSaver.instance.saveToDownloads(
        name: fileName,
        bytes: fileBytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Text(
            savedPath != null && savedPath.isNotEmpty
                ? 'Roster downloaded successfully.'
                : 'Roster exported successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            'Export failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  String _formatAverage(dynamic value) {
    if (value == null) {
      return '-';
    }

    final number = double.tryParse(value.toString());

    if (number == null || !number.isFinite) {
      return '-';
    }

    return number.toStringAsFixed(2);
  }

  String _formatMark(dynamic value) {
    if (value == null) {
      return '-';
    }

    final number = double.tryParse(value.toString());

    if (number == null || !number.isFinite) {
      return '-';
    }

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(2);
  }

  String _subjectName(dynamic subject) {
    if (subject is Map) {
      return subject['name']?.toString() ??
          subject['subject_name']?.toString() ??
          '-';
    }

    return subject?.toString() ?? '-';
  }

  List<dynamic> _marks(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  dynamic _findMark(List<dynamic> marks, String subjectName) {
    for (final item in marks) {
      if (item is! Map) {
        continue;
      }

      final itemName =
          item['subject_name']?.toString() ?? item['name']?.toString() ?? '';

      if (itemName.trim().toLowerCase() == subjectName.trim().toLowerCase()) {
        return item['mark'];
      }
    }

    return null;
  }

  Map<String, dynamic> _mapData(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  double? _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '');
  }

  dynamic _calculateAnnualSubjectAverage(
    dynamic firstMark,
    dynamic secondMark,
  ) {
    final first = _toDouble(firstMark);
    final second = _toDouble(secondMark);

    if (first == null && second == null) {
      return null;
    }

    if (first == null) {
      return second;
    }

    if (second == null) {
      return first;
    }

    return (first + second) / 2;
  }

  List<double> _availableNumbers(List<dynamic> values) {
    return values
        .map(_toDouble)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
  }

  double? _calculateSum(List<dynamic> values) {
    final numbers = _availableNumbers(values);

    if (numbers.isEmpty) {
      return null;
    }

    return numbers.reduce((a, b) => a + b);
  }

  double? _calculateAverage(List<dynamic> values) {
    final numbers = _availableNumbers(values);

    if (numbers.isEmpty) {
      return null;
    }

    final sum = numbers.reduce((a, b) => a + b);

    return sum / numbers.length;
  }

  double? _semesterSum(
    Map<String, dynamic> semesterData,
    List<dynamic> subjects,
  ) {
    final marks = _marks(semesterData['marks']);

    final values = subjects.map((subject) {
      return _findMark(marks, _subjectName(subject));
    }).toList();

    return _calculateSum(values);
  }

  double? _semesterAverage(
    Map<String, dynamic> semesterData,
    List<dynamic> subjects,
  ) {
    final marks = _marks(semesterData['marks']);

    final values = subjects.map((subject) {
      return _findMark(marks, _subjectName(subject));
    }).toList();

    return _calculateAverage(values);
  }

  double? _annualSum(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
    List<dynamic> subjects,
  ) {
    final firstMarks = _marks(first['marks']);
    final secondMarks = _marks(second['marks']);

    final annualValues = subjects.map((subject) {
      final name = _subjectName(subject);

      final firstMark = _findMark(firstMarks, name);

      final secondMark = _findMark(secondMarks, name);

      return _calculateAnnualSubjectAverage(firstMark, secondMark);
    }).toList();

    return _calculateSum(annualValues);
  }

  double? _annualAverage(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
    List<dynamic> subjects,
  ) {
    final firstMarks = _marks(first['marks']);
    final secondMarks = _marks(second['marks']);

    final annualValues = subjects.map((subject) {
      final name = _subjectName(subject);

      final firstMark = _findMark(firstMarks, name);

      final secondMark = _findMark(secondMarks, name);

      return _calculateAnnualSubjectAverage(firstMark, secondMark);
    }).toList();

    return _calculateAverage(annualValues);
  }

  int? _calculateRank(double? average, List<double?> averages) {
    if (average == null || !average.isFinite) {
      return null;
    }

    final validAverages = averages
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();

    if (validAverages.isEmpty) {
      return null;
    }

    final higherCount = validAverages.where((value) {
      return value > average + 0.000001;
    }).length;

    return higherCount + 1;
  }

  List<double?> _getSemesterAverages(
    List<dynamic> students,
    List<dynamic> subjects,
    String semesterKey,
  ) {
    return students.map<double?>((student) {
      final data = _mapData(student);

      final nestedSemester = _mapData(data[semesterKey]);

      if (nestedSemester.isNotEmpty) {
        return _semesterAverage(nestedSemester, subjects);
      }

      return _semesterAverage(data, subjects);
    }).toList();
  }

  List<double?> _getAnnualAverages(
    List<dynamic> students,
    List<dynamic> subjects,
  ) {
    return students.map<double?>((student) {
      final data = _mapData(student);

      final first = _mapData(data['first_semester']);

      final second = _mapData(data['second_semester']);

      return _annualAverage(first, second, subjects);
    }).toList();
  }

  Widget _buildTopSection() {
    final academicYear = _mapData(_rosterData?['academic_year']);

    final homeroom = _mapData(_rosterData?['homeroom']);

    final title = _rosterData?['title']?.toString() ?? 'Teacher Roster';

    final academicYearName = academicYear['name']?.toString() ?? '-';

    final gradeName = homeroom['grade_name']?.toString() ?? '-';

    final sectionName = homeroom['section_name']?.toString() ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            _buildSmallExportButton(),
          ],
        ),
        const SizedBox(height: 4),
        _buildAcademicInfo(
          academicYearName: academicYearName,
          gradeName: gradeName,
          sectionName: sectionName,
        ),
      ],
    );
  }

  Widget _buildAcademicInfo({
    required String academicYearName,
    required String gradeName,
    required String sectionName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _compactInfo(
              Icons.school_outlined,
              'Year',
              academicYearName,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _compactInfo(Icons.class_outlined, 'Grade', gradeName),
          ),
          _verticalDivider(),
          Expanded(
            child: _compactInfo(Icons.groups_outlined, 'Section', sectionName),
          ),
        ],
      ),
    );
  }

  Widget _compactInfo(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 2),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 7,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 22,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildSmallExportButton() {
    return FilledButton.icon(
      onPressed: _exporting ? null : _exportRoster,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        minimumSize: const Size(0, 29),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: _exporting
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : const Icon(Icons.file_download_outlined, size: 14),
      label: Text(
        _exporting ? 'Saving' : 'Excel',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildRosterTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment<String>(value: 'first', label: Text('First')),
          ButtonSegment<String>(value: 'second', label: Text('Second')),
          ButtonSegment<String>(value: 'annual', label: Text('Annual')),
        ],
        selected: {_rosterType},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            _changeRosterType(selection.first);
          }
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildRosterTable() {
    final subjects = _rosterData?['subjects'] as List<dynamic>? ?? [];

    final students = _rosterData?['students'] as List<dynamic>? ?? [];

    if (students.isEmpty) {
      return _buildEmptyState();
    }

    if (_rosterType == 'annual') {
      return _buildAnnualTable(subjects, students);
    }

    return _buildSemesterTable(subjects, students);
  }

  Widget _buildSemesterTable(List<dynamic> subjects, List<dynamic> students) {
    final semesterKey = _rosterType == 'first'
        ? 'first_semester'
        : 'second_semester';

    final averages = _getSemesterAverages(students, subjects, semesterKey);

    final fixedRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        children: [_tableHeaderCell('No'), _tableHeaderCell('Student')],
      ),
    ];

    final dataRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        children: [
          ...subjects.map((subject) {
            return _tableHeaderCell(_shortSubjectName(_subjectName(subject)));
          }),
          _tableHeaderCell('Sum'),
          _tableHeaderCell('Avg'),
          _tableHeaderCell('Rank'),
        ],
      ),
    ];

    for (var index = 0; index < students.length; index++) {
      final data = _mapData(students[index]);

      final marks = _marks(data['marks']);

      final values = subjects.map((subject) {
        return _findMark(marks, _subjectName(subject));
      }).toList();

      final calculatedSum = _calculateSum(values);

      final calculatedAverage = _calculateAverage(values);

      final calculatedRank = _calculateRank(calculatedAverage, averages);

      fixedRows.add(
        TableRow(
          children: [
            _tableBodyCell(
              data['no']?.toString() ?? '-',
              centered: true,
              bold: true,
            ),
            _tableBodyCell(data['student_name']?.toString() ?? '-', bold: true),
          ],
        ),
      );

      dataRows.add(
        TableRow(
          children: [
            ...subjects.map((subject) {
              final mark = _findMark(marks, _subjectName(subject));

              return _tableBodyCell(_formatMark(mark), centered: true);
            }),
            _tableBodyCell(
              _formatMark(calculatedSum),
              centered: true,
              bold: true,
            ),
            _tableBodyCell(
              _formatAverage(calculatedAverage),
              centered: true,
              bold: true,
            ),
            _tableBodyCell(
              calculatedRank?.toString() ?? '-',
              centered: true,
              bold: true,
            ),
          ],
        ),
      );
    }

    return _buildSplitTable(
      fixedWidth: 150,
      fixedRows: fixedRows,
      dataRows: dataRows,
      dataColumnWidths: {
        for (var i = 0; i < subjects.length; i++) i: const FixedColumnWidth(42),
        subjects.length: const FixedColumnWidth(45),
        subjects.length + 1: const FixedColumnWidth(50),
        subjects.length + 2: const FixedColumnWidth(40),
      },
    );
  }

  Widget _buildAnnualTable(List<dynamic> subjects, List<dynamic> students) {
    final annualAverages = _getAnnualAverages(students, subjects);

    final firstAverages = _getSemesterAverages(
      students,
      subjects,
      'first_semester',
    );

    final secondAverages = _getSemesterAverages(
      students,
      subjects,
      'second_semester',
    );

    final fixedRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        children: [
          _tableHeaderCell('No'),
          _tableHeaderCell('Student'),
          _tableHeaderCell('Sem'),
        ],
      ),
    ];

    final dataRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        children: [
          ...subjects.map((subject) {
            return _tableHeaderCell(_shortSubjectName(_subjectName(subject)));
          }),
          _tableHeaderCell('Sum'),
          _tableHeaderCell('Avg'),
          _tableHeaderCell('Rank'),
        ],
      ),
    ];

    for (var index = 0; index < students.length; index++) {
      final data = _mapData(students[index]);

      final first = _mapData(data['first_semester']);

      final second = _mapData(data['second_semester']);

      final firstAverage = _semesterAverage(first, subjects);

      final secondAverage = _semesterAverage(second, subjects);

      final annualAverage = _annualAverage(first, second, subjects);

      final firstRank = _calculateRank(firstAverage, firstAverages);

      final secondRank = _calculateRank(secondAverage, secondAverages);

      final annualRank = _calculateRank(annualAverage, annualAverages);

      final annualSum = _annualSum(first, second, subjects);

      fixedRows.add(
        _annualFixedRow(
          no: data['no']?.toString() ?? '-',
          studentName: data['student_name']?.toString() ?? '-',
          semester: '1st',
          showStudentInfo: true,
        ),
      );

      dataRows.add(
        _annualDataRow(
          semesterData: first,
          subjects: subjects,
          calculatedSum: _semesterSum(first, subjects),
          calculatedAverage: firstAverage,
          calculatedRank: firstRank,
        ),
      );

      fixedRows.add(
        _annualFixedRow(
          no: '',
          studentName: '',
          semester: '2nd',
          showStudentInfo: false,
        ),
      );

      dataRows.add(
        _annualDataRow(
          semesterData: second,
          subjects: subjects,
          calculatedSum: _semesterSum(second, subjects),
          calculatedAverage: secondAverage,
          calculatedRank: secondRank,
        ),
      );

      fixedRows.add(
        _annualFixedRow(
          no: '',
          studentName: '',
          semester: 'Annual',
          showStudentInfo: false,
          annual: true,
        ),
      );

      dataRows.add(
        _annualAverageDataRow(
          first: first,
          second: second,
          subjects: subjects,
          calculatedSum: annualSum,
          calculatedAverage: annualAverage,
          calculatedRank: annualRank,
        ),
      );
    }

    return _buildSplitTable(
      fixedWidth: 190,
      fixedRows: fixedRows,
      dataRows: dataRows,
      dataColumnWidths: {
        for (var i = 0; i < subjects.length; i++) i: const FixedColumnWidth(42),
        subjects.length: const FixedColumnWidth(45),
        subjects.length + 1: const FixedColumnWidth(50),
        subjects.length + 2: const FixedColumnWidth(40),
      },
    );
  }

  Widget _buildSplitTable({
    required double fixedWidth,
    required List<TableRow> fixedRows,
    required List<TableRow> dataRows,
    required Map<int, TableColumnWidth> dataColumnWidths,
  }) {
    final isAnnual = fixedWidth == 190;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: fixedWidth,
          child: SingleChildScrollView(
            controller: _fixedVerticalController,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
              columnWidths: isAnnual
                  ? const {
                      0: FixedColumnWidth(30),
                      1: FixedColumnWidth(105),
                      2: FixedColumnWidth(55),
                    }
                  : const {0: FixedColumnWidth(30), 1: FixedColumnWidth(120)},
              children: fixedRows,
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _dataVerticalController,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                  columnWidths: dataColumnWidths,
                  children: dataRows,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _annualFixedRow({
    required String no,
    required String studentName,
    required String semester,
    required bool showStudentInfo,
    bool annual = false,
  }) {
    return TableRow(
      decoration: annual
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            )
          : null,
      children: [
        _tableBodyCell(
          showStudentInfo ? no : '',
          centered: true,
          bold: showStudentInfo,
        ),
        _tableBodyCell(
          showStudentInfo ? studentName : '',
          bold: showStudentInfo,
        ),
        _tableBodyCell(semester, centered: true, bold: true),
      ],
    );
  }

  TableRow _annualDataRow({
    required Map<String, dynamic> semesterData,
    required List<dynamic> subjects,
    required double? calculatedSum,
    required double? calculatedAverage,
    required int? calculatedRank,
  }) {
    final marks = _marks(semesterData['marks']);

    return TableRow(
      children: [
        ...subjects.map((subject) {
          final mark = _findMark(marks, _subjectName(subject));

          return _tableBodyCell(_formatMark(mark), centered: true);
        }),
        _tableBodyCell(_formatMark(calculatedSum), centered: true, bold: true),
        _tableBodyCell(
          _formatAverage(calculatedAverage),
          centered: true,
          bold: true,
        ),
        _tableBodyCell(
          calculatedRank?.toString() ?? '-',
          centered: true,
          bold: true,
        ),
      ],
    );
  }

  TableRow _annualAverageDataRow({
    required Map<String, dynamic> first,
    required Map<String, dynamic> second,
    required List<dynamic> subjects,
    required double? calculatedSum,
    required double? calculatedAverage,
    required int? calculatedRank,
  }) {
    final firstMarks = _marks(first['marks']);

    final secondMarks = _marks(second['marks']);

    return TableRow(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      children: [
        ...subjects.map((subject) {
          final name = _subjectName(subject);

          final firstMark = _findMark(firstMarks, name);

          final secondMark = _findMark(secondMarks, name);

          final average = _calculateAnnualSubjectAverage(firstMark, secondMark);

          return _tableBodyCell(
            _formatMark(average),
            centered: true,
            bold: true,
          );
        }),
        _tableBodyCell(_formatMark(calculatedSum), centered: true, bold: true),
        _tableBodyCell(
          _formatAverage(calculatedAverage),
          centered: true,
          bold: true,
        ),
        _tableBodyCell(
          calculatedRank?.toString() ?? '-',
          centered: true,
          bold: true,
        ),
      ],
    );
  }

  String _shortSubjectName(String name) {
    final value = name.trim();
    final lower = value.toLowerCase();

    if (lower == 'mathematics') {
      return 'Maths';
    }

    if (lower == 'english') {
      return 'Eng';
    }

    if (lower == 'amharic') {
      return 'Amh';
    }

    if (lower == 'physical and health education' ||
        lower == 'physical education') {
      return 'HPE';
    }

    if (value.length <= 7) {
      return value;
    }

    return '${value.substring(0, 7)}.';
  }

  Widget _tableHeaderCell(String text) {
    return SizedBox(
      height: 26,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _tableBodyCell(
    String text, {
    bool centered = false,
    bool bold = false,
  }) {
    return SizedBox(
      height: 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          textAlign: centered ? TextAlign.center : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            const Text(
              'No students found in this roster.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 6),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loadRoster,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rosterData == null) {
      return const Center(child: Text('No roster data available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopSection(),
        const SizedBox(height: 4),
        _buildRosterTypeSelector(),
        const SizedBox(height: 4),
        Expanded(child: _buildRosterTable()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Roster', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRoster,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
          child: _buildContent(),
        ),
      ),
    );
  }
}
