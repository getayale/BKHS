import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/api_service.dart';

class HomeworkCreatePage extends StatefulWidget {
  const HomeworkCreatePage({super.key});

  @override
  State<HomeworkCreatePage> createState() => _HomeworkCreatePageState();
}

class _HomeworkCreatePageState extends State<HomeworkCreatePage> {
  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  List<Map<String, dynamic>> subjects = [];

  int? selectedAssignmentId;

  int assignedYear = 2018;
  int assignedMonth = 1;
  int assignedDay = 1;

  int dueYear = 2018;
  int dueMonth = 1;
  int dueDay = 1;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  List<int>? selectedFileBytes;
  String? selectedFileName;
  int? selectedFileSize;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await ApiService.getTeacherHomework();

      final today = data['today'];
      final ethiopian = today?['ethiopian'];

      final todayYear = int.tryParse('${ethiopian?['year'] ?? 2018}') ?? 2018;

      final todayMonth = int.tryParse('${ethiopian?['month'] ?? 1}') ?? 1;

      final todayDay = int.tryParse('${ethiopian?['day'] ?? 1}') ?? 1;

      final subjectData = data['subjects'];

      final loadedSubjects = <Map<String, dynamic>>[];

      if (subjectData is List) {
        for (final item in subjectData) {
          if (item is Map) {
            loadedSubjects.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        subjects = loadedSubjects;

        assignedYear = todayYear;
        assignedMonth = todayMonth;
        assignedDay = todayDay;

        dueYear = todayYear;
        dueMonth = todayMonth;
        dueDay = todayDay;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  int daysInMonth(int year, int month) {
    if (month == 13) {
      return ((year + 1) % 4 == 0) ? 6 : 5;
    }

    return 30;
  }

  List<int> getYearOptions() {
    final years = <int>[];

    for (int year = assignedYear - 2; year <= assignedYear + 2; year++) {
      years.add(year);
    }

    return years;
  }

  String formatEthiopianDate(int year, int month, int day) {
    const months = [
      '',
      'Meskerem',
      'Tikimt',
      'Hidar',
      'Tahsas',
      'Tir',
      'Yekatit',
      'Megabit',
      'Miazia',
      'Ginbot',
      'Sene',
      'Hamle',
      'Nehase',
      'Pagume',
    ];

    return '$day ${months[month]} $year';
  }

  String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return '';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> pickAssignedDate() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        int tempYear = assignedYear;
        int tempMonth = assignedMonth;
        int tempDay = assignedDay;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final maxDay = daysInMonth(tempYear, tempMonth);

            if (tempDay > maxDay) {
              tempDay = maxDay;
            }

            return AlertDialog(
              title: const Text('Assigned Date'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: getYearOptions()
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempYear = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      13,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          [
                            'Meskerem',
                            'Tikimt',
                            'Hidar',
                            'Tahsas',
                            'Tir',
                            'Yekatit',
                            'Megabit',
                            'Miazia',
                            'Ginbot',
                            'Sene',
                            'Hamle',
                            'Nehase',
                            'Pagume',
                          ][index],
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempMonth = value;

                        final maxDay = daysInMonth(tempYear, tempMonth);

                        if (tempDay > maxDay) {
                          tempDay = maxDay;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: tempDay,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      maxDay,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempDay = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'year': tempYear,
                      'month': tempMonth,
                      'day': tempDay,
                    });
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      assignedYear = result['year']!;
      assignedMonth = result['month']!;
      assignedDay = result['day']!;

      if (!isDueDateValid()) {
        dueYear = assignedYear;
        dueMonth = assignedMonth;
        dueDay = assignedDay;
      }
    });
  }

  Future<void> pickDueDate() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        int tempYear = dueYear;
        int tempMonth = dueMonth;
        int tempDay = dueDay;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final maxDay = daysInMonth(tempYear, tempMonth);

            if (tempDay > maxDay) {
              tempDay = maxDay;
            }

            return AlertDialog(
              title: const Text('Due Date'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: getYearOptions()
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempYear = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      13,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          [
                            'Meskerem',
                            'Tikimt',
                            'Hidar',
                            'Tahsas',
                            'Tir',
                            'Yekatit',
                            'Megabit',
                            'Miazia',
                            'Ginbot',
                            'Sene',
                            'Hamle',
                            'Nehase',
                            'Pagume',
                          ][index],
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempMonth = value;

                        final maxDay = daysInMonth(tempYear, tempMonth);

                        if (tempDay > maxDay) {
                          tempDay = maxDay;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: tempDay,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      maxDay,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempDay = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'year': tempYear,
                      'month': tempMonth,
                      'day': tempDay,
                    });
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final newYear = result['year']!;
    final newMonth = result['month']!;
    final newDay = result['day']!;

    final selectedDate = newYear * 10000 + newMonth * 100 + newDay;

    final assignedDate =
        assignedYear * 10000 + assignedMonth * 100 + assignedDay;

    if (selectedDate < assignedDate) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due date cannot be before the assigned date.'),
        ),
      );

      return;
    }

    setState(() {
      dueYear = newYear;
      dueMonth = newMonth;
      dueDay = newDay;
    });
  }

  bool isDueDateValid() {
    final assignedDate =
        assignedYear * 10000 + assignedMonth * 100 + assignedDay;

    final dueDate = dueYear * 10000 + dueMonth * 100 + dueDay;

    return dueDate >= assignedDate;
  }

  Future<void> pickMaterial() async {
    try {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('========== FILE PICKER START ==========');
      debugPrint('========================================');

      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'jpg',
          'jpeg',
          'png',
          'zip',
        ],
      );

      if (pickedFile == null) {
        debugPrint('NO FILE SELECTED');
        debugPrint('========================================');
        return;
      }

      debugPrint('FILE NAME: ${pickedFile.name}');
      debugPrint('FILE PATH: ${pickedFile.path}');
      debugPrint('FILE URI: ${pickedFile.uri}');

      final bytes = await pickedFile.readAsBytes();

      debugPrint('FILE BYTE LENGTH: ${bytes.length}');

      if (bytes.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The selected file is empty.')),
        );

        return;
      }

      final fileSize = bytes.length;

      if (fileSize > 10 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must not exceed 10 MB.')),
        );

        return;
      }

      setState(() {
        selectedFileBytes = List<int>.from(bytes);
        selectedFileName = pickedFile.name;
        selectedFileSize = fileSize;
      });

      debugPrint('');
      debugPrint('========== FILE SELECTED ==========');
      debugPrint('SELECTED FILE NAME: $selectedFileName');
      debugPrint('SELECTED FILE SIZE: $selectedFileSize bytes');
      debugPrint('===================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Material selected: ${pickedFile.name}')),
      );
    } catch (e) {
      debugPrint('FILE PICKER ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to select file: $e')));
    }
  }

  Future<void> createHomework() async {
    if (selectedAssignmentId == null) {
      showMessage('Please select a class and subject.');
      return;
    }

    final title = titleController.text.trim();

    if (title.isEmpty) {
      showMessage('Please enter homework title.');
      return;
    }

    if (title.length > 255) {
      showMessage('Homework title must not exceed 255 characters.');
      return;
    }

    if (!isDueDateValid()) {
      showMessage('Due date cannot be before the assigned date.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      debugPrint('');
      debugPrint('========== CREATE HOMEWORK ==========');
      debugPrint('SELECTED FILE: ${selectedFileName ?? 'NONE'}');
      debugPrint('SELECTED FILE SIZE: ${selectedFileSize ?? 0}');
      debugPrint('====================================');

      await ApiService.createTeacherHomework(
        assignmentId: selectedAssignmentId!,
        title: title,
        description: descriptionController.text.trim(),
        assignedYear: assignedYear,
        assignedMonth: assignedMonth,
        assignedDay: assignedDay,
        dueYear: dueYear,
        dueMonth: dueMonth,
        dueDay: dueDay,
        teacherMaterialBytes: selectedFileBytes,
        teacherMaterialFileName: selectedFileName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Homework created successfully.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage(e.toString());
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget buildSubjectDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: selectedAssignmentId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class & Subject',
        prefixIcon: Icon(Icons.menu_book_outlined),
        border: OutlineInputBorder(),
      ),
      items: subjects.map((subject) {
        final assignmentId = int.tryParse('${subject['assignment_id']}');

        final grade = subject['grade'];
        final section = subject['section'];
        final subjectName = subject['subject_name'] ?? 'Subject';

        return DropdownMenuItem<int>(
          value: assignmentId,
          child: Text(
            'Grade $grade $section • $subjectName',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: isSaving
          ? null
          : (value) {
              setState(() {
                selectedAssignmentId = value;
              });
            },
    );
  }

  Widget buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 24,
            16,
            isSmallScreen ? 12 : 24,
            30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Create Homework',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      'Create and assign homework to your students.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildSectionCard(
                    title: 'Class & Subject',
                    icon: Icons.school_outlined,
                    child: buildSubjectDropdown(),
                  ),
                  buildSectionCard(
                    title: 'Homework Details',
                    icon: Icons.assignment_outlined,
                    child: Column(
                      children: [
                        TextField(
                          controller: titleController,
                          enabled: !isSaving,
                          maxLength: 255,
                          decoration: const InputDecoration(
                            labelText: 'Homework Title',
                            hintText: 'Enter homework title',
                            prefixIcon: Icon(Icons.title_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          enabled: !isSaving,
                          maxLines: 5,
                          maxLength: 10000,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter homework instructions...',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 80),
                              child: Icon(Icons.description_outlined),
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildSectionCard(
                    title: 'Homework Dates',
                    icon: Icons.date_range_outlined,
                    child: isSmallScreen
                        ? Column(
                            children: [
                              buildDateField(
                                label: 'Assigned Date',
                                value: formatEthiopianDate(
                                  assignedYear,
                                  assignedMonth,
                                  assignedDay,
                                ),
                                onTap: pickAssignedDate,
                              ),
                              const SizedBox(height: 16),
                              buildDateField(
                                label: 'Due Date',
                                value: formatEthiopianDate(
                                  dueYear,
                                  dueMonth,
                                  dueDay,
                                ),
                                onTap: pickDueDate,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: buildDateField(
                                  label: 'Assigned Date',
                                  value: formatEthiopianDate(
                                    assignedYear,
                                    assignedMonth,
                                    assignedDay,
                                  ),
                                  onTap: pickAssignedDate,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: buildDateField(
                                  label: 'Due Date',
                                  value: formatEthiopianDate(
                                    dueYear,
                                    dueMonth,
                                    dueDay,
                                  ),
                                  onTap: pickDueDate,
                                ),
                              ),
                            ],
                          ),
                  ),
                  buildSectionCard(
                    title: 'Teacher Material',
                    icon: Icons.attach_file_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedFileName != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFileName!,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (selectedFileSize != null)
                                        Text(
                                          formatFileSize(selectedFileSize),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedFileBytes = null;
                                            selectedFileName = null;
                                            selectedFileSize = null;
                                          });
                                        },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Optional. Maximum file size: 10 MB.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isSaving ? null : pickMaterial,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(
                            selectedFileBytes == null
                                ? 'Choose Material'
                                : 'Change Material',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : createHomework,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        isSaving ? 'Creating Homework...' : 'Create Homework',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Unable to load homework data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });

                loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homework'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : _buildForm(),
    );
  }
}
