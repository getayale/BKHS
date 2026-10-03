import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/api_service.dart';

class HomeworkEditPage extends StatefulWidget {
  final int homeworkId;

  const HomeworkEditPage({super.key, required this.homeworkId});

  @override
  State<HomeworkEditPage> createState() => _HomeworkEditPageState();
}

class _HomeworkEditPageState extends State<HomeworkEditPage> {
  bool isLoading = true;
  bool isSaving = false;
  bool isDeletingMaterial = false;

  String? errorMessage;

  int? academicYearId;
  String academicYearName = '';

  int homeworkId = 0;
  int grade = 0;
  String section = '';
  int gradeSubjectId = 0;
  String subjectName = '';

  String assignedDate = '';
  int assignedYear = 0;
  int assignedMonth = 0;
  int assignedDay = 0;

  int dueYear = 0;
  int dueMonth = 0;
  int dueDay = 0;

  String homeworkStatus = '';

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  bool materialExists = false;
  String? materialPath;
  String? materialOriginalName;
  String? materialType;
  int? materialSize;

  List<int>? selectedFileBytes;
  String? selectedFileName;
  int? selectedFileSize;

  @override
  void initState() {
    super.initState();

    homeworkId = widget.homeworkId;

    debugPrint('');
    debugPrint('========================================');
    debugPrint('HOMEWORK EDIT PAGE');
    debugPrint('HOMEWORK ID: $homeworkId');
    debugPrint('========================================');

    loadHomework();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadHomework() async {
    try {
      debugPrint('');
      debugPrint('========== LOAD HOMEWORK ==========');
      debugPrint('HOMEWORK ID: $homeworkId');

      final data = await ApiService.getTeacherHomeworkEdit(
        homeworkId: homeworkId,
      );

      debugPrint('HOMEWORK LOAD SUCCESS');
      debugPrint('API DATA KEYS: ${data.keys.toList()}');

      final academicYear = data['academic_year'];
      final homework = data['homework'];

      if (academicYear is! Map) {
        throw Exception('Invalid academic year data returned by the server.');
      }

      if (homework is! Map) {
        throw Exception('Invalid homework data returned by the server.');
      }

      final academicYearData = Map<String, dynamic>.from(academicYear);

      final homeworkData = Map<String, dynamic>.from(homework);

      final assignedEthiopian = data['assigned_date_ethiopian'];

      final dueEthiopian = data['due_date_ethiopian'];

      if (assignedEthiopian is! Map || dueEthiopian is! Map) {
        throw Exception('Homework Ethiopian dates are missing.');
      }

      final assignedDateData = Map<String, dynamic>.from(assignedEthiopian);

      final dueDateData = Map<String, dynamic>.from(dueEthiopian);

      final teacherMaterial = data['teacher_material'];

      debugPrint('TEACHER MATERIAL FROM API: $teacherMaterial');

      final loadedAcademicYearId =
          int.tryParse('${academicYearData['id']}') ?? 0;

      final loadedHomeworkId =
          int.tryParse('${homeworkData['id']}') ?? widget.homeworkId;

      final loadedGrade = int.tryParse('${homeworkData['grade']}') ?? 0;

      final loadedSection = '${homeworkData['section'] ?? ''}';

      final loadedGradeSubjectId =
          int.tryParse('${homeworkData['grade_subject_id']}') ?? 0;

      final loadedSubjectName = '${homeworkData['subject_name'] ?? ''}';

      final loadedAssignedYear =
          int.tryParse('${assignedDateData['year']}') ?? 0;

      final loadedAssignedMonth =
          int.tryParse('${assignedDateData['month']}') ?? 0;

      final loadedAssignedDay = int.tryParse('${assignedDateData['day']}') ?? 0;

      final loadedDueYear = int.tryParse('${dueDateData['year']}') ?? 0;

      final loadedDueMonth = int.tryParse('${dueDateData['month']}') ?? 0;

      final loadedDueDay = int.tryParse('${dueDateData['day']}') ?? 0;

      bool loadedMaterialExists = false;
      String? loadedMaterialPath;
      String? loadedMaterialOriginalName;
      String? loadedMaterialType;
      int? loadedMaterialSize;

      if (teacherMaterial is Map) {
        loadedMaterialExists = teacherMaterial['exists'] == true;

        loadedMaterialPath = teacherMaterial['path'] != null
            ? '${teacherMaterial['path']}'
            : null;

        loadedMaterialOriginalName = teacherMaterial['original_name'] != null
            ? '${teacherMaterial['original_name']}'
            : null;

        loadedMaterialType = teacherMaterial['type'] != null
            ? '${teacherMaterial['type']}'
            : null;

        loadedMaterialSize = teacherMaterial['size'] != null
            ? int.tryParse('${teacherMaterial['size']}')
            : null;
      }

      debugPrint(
        'LOADED MATERIAL EXISTS: '
        '$loadedMaterialExists',
      );

      debugPrint(
        'LOADED MATERIAL PATH: '
        '$loadedMaterialPath',
      );

      debugPrint(
        'LOADED MATERIAL NAME: '
        '$loadedMaterialOriginalName',
      );

      debugPrint(
        'LOADED MATERIAL TYPE: '
        '$loadedMaterialType',
      );

      debugPrint(
        'LOADED MATERIAL SIZE: '
        '$loadedMaterialSize',
      );

      debugPrint('===================================');

      if (!mounted) {
        return;
      }

      setState(() {
        academicYearId = loadedAcademicYearId;

        academicYearName = '${academicYearData['name'] ?? ''}';

        homeworkId = loadedHomeworkId;

        grade = loadedGrade;

        section = loadedSection;

        gradeSubjectId = loadedGradeSubjectId;

        subjectName = loadedSubjectName;

        assignedDate = '${homeworkData['assigned_date'] ?? ''}';

        assignedYear = loadedAssignedYear;

        assignedMonth = loadedAssignedMonth;

        assignedDay = loadedAssignedDay;

        dueYear = loadedDueYear;

        dueMonth = loadedDueMonth;

        dueDay = loadedDueDay;

        homeworkStatus = '${homeworkData['status'] ?? ''}';

        titleController.text = '${homeworkData['title'] ?? ''}';

        descriptionController.text = homeworkData['description'] != null
            ? '${homeworkData['description']}'
            : '';

        materialExists = loadedMaterialExists;

        materialPath = loadedMaterialPath;

        materialOriginalName = loadedMaterialOriginalName;

        materialType = loadedMaterialType;

        materialSize = loadedMaterialSize;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('');
      debugPrint('========== LOAD HOMEWORK ERROR ==========');
      debugPrint('$e');
      debugPrint('=========================================');

      if (!mounted) {
        return;
      }

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
    if (assignedYear <= 0) {
      return [];
    }

    final years = <int>[];

    for (int year = assignedYear - 2; year <= assignedYear + 2; year++) {
      years.add(year);
    }

    if (!years.contains(dueYear) && dueYear > 0) {
      years.add(dueYear);
      years.sort();
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

    if (month < 1 || month > 13 || day < 1 || year <= 0) {
      return 'Invalid date';
    }

    return '$day ${months[month]} $year';
  }

  Future<void> pickDueDate() async {
    if (assignedYear <= 0) {
      return;
    }

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
              content: SingleChildScrollView(
                child: Column(
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
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text('$year'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

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
                      items: List.generate(13, (index) {
                        const months = [
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

                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(months[index]),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          tempMonth = value;

                          final newMaxDay = daysInMonth(tempYear, tempMonth);

                          if (tempDay > newMaxDay) {
                            tempDay = newMaxDay;
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
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          tempDay = value;
                        });
                      },
                    ),
                  ],
                ),
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

    if (result == null) {
      return;
    }

    final newYear = result['year']!;

    final newMonth = result['month']!;

    final newDay = result['day']!;

    final selectedDate = newYear * 10000 + newMonth * 100 + newDay;

    final assignedDateValue =
        assignedYear * 10000 + assignedMonth * 100 + assignedDay;

    if (selectedDate < assignedDateValue) {
      if (!mounted) {
        return;
      }

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
    if (assignedYear <= 0 ||
        assignedMonth <= 0 ||
        assignedDay <= 0 ||
        dueYear <= 0 ||
        dueMonth <= 0 ||
        dueDay <= 0) {
      return false;
    }

    final assignedDateValue =
        assignedYear * 10000 + assignedMonth * 100 + assignedDay;

    final dueDateValue = dueYear * 10000 + dueMonth * 100 + dueDay;

    return dueDateValue >= assignedDateValue;
  }

  Future<void> pickMaterial() async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('========== FILE PICKER START ==========');
    debugPrint('========================================');

    try {
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
        return;
      }

      debugPrint(
        'FILE NAME FROM PICKER: '
        '${pickedFile.name}',
      );

      debugPrint(
        'FILE PATH FROM PICKER: '
        '${pickedFile.path}',
      );

      debugPrint(
        'FILE URI FROM PICKER: '
        '${pickedFile.uri}',
      );

      int? fileSize = pickedFile.lengthSync();

      if (fileSize == null) {
        fileSize = await pickedFile.length();
      }

      debugPrint('FILE SIZE: $fileSize bytes');

      if (fileSize == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine the file size.')),
        );

        return;
      }

      if (fileSize > 10 * 1024 * 1024) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must not exceed 10 MB.')),
        );

        return;
      }

      debugPrint('READING FILE BYTES...');

      final bytes = await pickedFile.readAsBytes();

      debugPrint('BYTES READ: ${bytes.length}');

      if (bytes.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The selected file is empty.')),
        );

        return;
      }

      setState(() {
        selectedFileBytes = List<int>.from(bytes);

        selectedFileName = pickedFile.name;

        selectedFileSize = bytes.length;
      });

      debugPrint('');
      debugPrint('========== FILE SELECTED ==========');

      debugPrint(
        'SELECTED FILE NAME: '
        '$selectedFileName',
      );

      debugPrint(
        'SELECTED FILE SIZE: '
        '$selectedFileSize bytes',
      );

      debugPrint(
        'SELECTED FILE BYTES: '
        '${selectedFileBytes?.length}',
      );

      debugPrint('===================================');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Material selected: '
            '${pickedFile.name}',
          ),
        ),
      );
    } catch (e) {
      debugPrint('========== FILE PICKER ERROR ==========');

      debugPrint('$e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to select file: $e')));
    }
  }

  Future<void> deleteMaterial() async {
    if (!materialExists || homeworkId <= 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Material'),
          content: const Text(
            'Are you sure you want to delete the teacher material?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isDeletingMaterial = true;
    });

    try {
      await ApiService.deleteTeacherHomeworkMaterial(homeworkId: homeworkId);

      if (!mounted) {
        return;
      }

      setState(() {
        materialExists = false;
        materialPath = null;
        materialOriginalName = null;
        materialType = null;
        materialSize = null;
        isDeletingMaterial = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher material deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isDeletingMaterial = false;
      });

      showMessage(e.toString());
    }
  }

  Future<void> updateHomework() async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('======= UPDATE HOMEWORK START =========');
    debugPrint('========================================');

    final title = titleController.text.trim();

    if (title.isEmpty) {
      showMessage('Homework title is required.');
      return;
    }

    if (title.length > 255) {
      showMessage('Homework title cannot exceed 255 characters.');
      return;
    }

    if (descriptionController.text.trim().length > 10000) {
      showMessage('Homework description cannot exceed 10,000 characters.');
      return;
    }

    if (!isDueDateValid()) {
      showMessage('Due date cannot be earlier than the assigned date.');
      return;
    }

    if (selectedFileBytes != null && selectedFileBytes!.isNotEmpty) {
      debugPrint('SAVE FILE SELECTED: YES');

      debugPrint(
        'SAVE FILE NAME: '
        '$selectedFileName',
      );

      debugPrint(
        'SAVE FILE SIZE: '
        '${selectedFileBytes!.length} bytes',
      );
    } else {
      debugPrint('SAVE FILE SELECTED: NO');
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await ApiService.updateTeacherHomework(
        homeworkId: homeworkId,
        title: title,
        description: descriptionController.text.trim(),
        dueYear: dueYear,
        dueMonth: dueMonth,
        dueDay: dueDay,
        teacherMaterialBytes: selectedFileBytes,
        teacherMaterialFileName: selectedFileName,
      );

      debugPrint(
        'FULL API RESPONSE: '
        '$response',
      );

      final diagnostic = response['upload_diagnostic'];

      final updatedHomework = response['homework'];

      if (!mounted) {
        return;
      }

      final materialWasReceived =
          diagnostic is Map && diagnostic['received'] == true;

      final materialPathFromResponse = updatedHomework is Map
          ? updatedHomework['teacher_material_path']
          : null;

      if (selectedFileBytes != null &&
          selectedFileBytes!.isNotEmpty &&
          !materialWasReceived) {
        setState(() {
          isSaving = false;
        });

        showMessage(
          'Homework was updated, but PHP did not receive the selected material.',
        );

        return;
      }

      if (selectedFileBytes != null &&
          selectedFileBytes!.isNotEmpty &&
          (materialPathFromResponse == null ||
              '$materialPathFromResponse'.isEmpty)) {
        setState(() {
          isSaving = false;
        });

        showMessage(
          'Homework was updated, but the material path was not saved.',
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Homework updated successfully.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('========== API UPDATE ERROR ==========');

      debugPrint('$e');

      if (!mounted) {
        return;
      }

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

  String formatFileSize(int? size) {
    if (size == null || size <= 0) {
      return '';
    }

    if (size < 1024) {
      return '$size B';
    }

    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }

    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget buildLockedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.lock_outline, size: 19),
        border: const OutlineInputBorder(),
        filled: true,
      ),
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
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ).copyWith(labelText: label),
        child: Text(value, style: const TextStyle(fontSize: 15)),
      ),
    );
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
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

  Widget buildExistingMaterial() {
    if (!materialExists && selectedFileName == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No teacher material attached.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSaving ? null : pickMaterial,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Add Material'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (materialExists)
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materialOriginalName ?? 'Teacher material',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (materialSize != null)
                        Text(
                          formatFileSize(materialSize),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete material',
                  onPressed: isDeletingMaterial || isSaving
                      ? null
                      : deleteMaterial,
                  icon: isDeletingMaterial
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
        if (materialExists) const SizedBox(height: 12),
        if (selectedFileName != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFileName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isSaving ? null : pickMaterial,
          icon: const Icon(Icons.change_circle_outlined),
          label: Text(materialExists ? 'Replace Material' : 'Choose Material'),
        ),
      ],
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
                            : () {
                                Navigator.pop(context);
                              },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Edit Homework',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      'Update homework details and due date.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildSectionCard(
                    title: 'Class & Subject',
                    icon: Icons.school_outlined,
                    child: Column(
                      children: [
                        if (isSmallScreen)
                          Column(
                            children: [
                              buildLockedField(
                                label: 'Academic Year',
                                value: academicYearName,
                                icon: Icons.calendar_month_outlined,
                              ),
                              const SizedBox(height: 16),
                              buildLockedField(
                                label: 'Grade',
                                value: 'Grade $grade',
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(height: 16),
                              buildLockedField(
                                label: 'Section',
                                value: section,
                                icon: Icons.class_outlined,
                              ),
                              const SizedBox(height: 16),
                              buildLockedField(
                                label: 'Subject',
                                value: subjectName,
                                icon: Icons.menu_book_outlined,
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: buildLockedField(
                                      label: 'Academic Year',
                                      value: academicYearName,
                                      icon: Icons.calendar_month_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildLockedField(
                                      label: 'Grade',
                                      value: 'Grade $grade',
                                      icon: Icons.school_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildLockedField(
                                      label: 'Section',
                                      value: section,
                                      icon: Icons.class_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildLockedField(
                                      label: 'Subject',
                                      value: subjectName,
                                      icon: Icons.menu_book_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
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
                    child: Column(
                      children: [
                        if (isSmallScreen)
                          Column(
                            children: [
                              buildDateField(
                                label: 'Assigned Date',
                                value: formatEthiopianDate(
                                  assignedYear,
                                  assignedMonth,
                                  assignedDay,
                                ),
                                onTap: () {},
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
                        else
                          Row(
                            children: [
                              Expanded(
                                child: buildDateField(
                                  label: 'Assigned Date',
                                  value: formatEthiopianDate(
                                    assignedYear,
                                    assignedMonth,
                                    assignedDay,
                                  ),
                                  onTap: () {},
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
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Assigned date is locked. Only the due date can be changed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  buildSectionCard(
                    title: 'Teacher Material',
                    icon: Icons.attach_file_outlined,
                    child: buildExistingMaterial(),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : updateHomework,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSaving ? 'Saving Changes...' : 'Save Changes',
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
              'Unable to load homework.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred.',
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

                loadHomework();
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
      appBar: AppBar(title: const Text('Edit Homework'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : _buildForm(),
    );
  }
}
