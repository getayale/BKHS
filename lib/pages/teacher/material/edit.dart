import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as picker;

import '/api_service.dart';

class EditTeacherMaterialPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> material;
  final List<Map<String, dynamic>> assignments;

  const EditTeacherMaterialPage({
    super.key,
    required this.token,
    required this.material,
    required this.assignments,
  });

  @override
  State<EditTeacherMaterialPage> createState() =>
      _EditTeacherMaterialPageState();
}

class _EditTeacherMaterialPageState extends State<EditTeacherMaterialPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  int? _selectedAssignmentId;

  Uint8List? _fileBytes;
  String? _fileName;
  int? _fileSize;

  bool _isSaving = false;
  bool _isPickingFile = false;

  static const int _maxFileSize = 20 * 1024 * 1024;

  static const List<String> _allowedExtensions = [
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
    'gif',
    'webp',
    'zip',
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.material['title']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.material['description']?.toString() ?? '',
    );

    final currentAssignmentId = int.tryParse(
      widget.material['assignment_id']?.toString() ?? '',
    );

    final currentGradeSubjectId = int.tryParse(
      widget.material['grade_subject_id']?.toString() ?? '',
    );

    for (final assignment in widget.assignments) {
      final assignmentId = int.tryParse(assignment['id']?.toString() ?? '');

      final gradeSubjectId = int.tryParse(
        assignment['grade_subject_id']?.toString() ?? '',
      );

      if (currentAssignmentId != null && assignmentId == currentAssignmentId) {
        _selectedAssignmentId = assignmentId;
        break;
      }

      if (currentAssignmentId == null &&
          currentGradeSubjectId != null &&
          gradeSubjectId == currentGradeSubjectId) {
        _selectedAssignmentId = assignmentId;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _getExistingFileName() {
    final possibleNames = [
      widget.material['file_name'],
      widget.material['original_file_name'],
      widget.material['filename'],
      widget.material['original_filename'],
      widget.material['file'],
    ];

    for (final value in possibleNames) {
      if (value == null) continue;

      final name = value.toString().trim();

      if (name.isEmpty) continue;

      return name.split('/').last.split(r'\').last;
    }

    return '';
  }

  Future<void> _pickFile() async {
    if (_isPickingFile || _isSaving) {
      return;
    }

    setState(() {
      _isPickingFile = true;
    });

    try {
      final file = await picker.FilePicker.pickFile(
        type: picker.FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (file == null) return;

      final extension = file.extension?.toLowerCase() ?? '';

      if (!_allowedExtensions.contains(extension)) {
        throw Exception('This file type is not supported.');
      }

      final fileSize = await file.length();

      if (fileSize == null || fileSize == 0) {
        throw Exception(
          'Unable to read the selected file. Please choose another file.',
        );
      }

      if (fileSize > _maxFileSize) {
        throw Exception('The file must not exceed 20 MB.');
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read the selected file. Please choose another file.',
        );
      }

      if (bytes.length > _maxFileSize) {
        throw Exception('The file must not exceed 20 MB.');
      }

      if (!mounted) return;

      setState(() {
        _fileBytes = Uint8List.fromList(bytes);
        _fileName = file.name;
        _fileSize = bytes.length;
      });

      _showMessage('File selected successfully.', isError: false);
    } catch (e) {
      _showMessage(
        'Unable to select file: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
        });
      }
    }
  }

  Future<void> _saveMaterial() async {
    if (_isSaving || _isPickingFile) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAssignmentId == null) {
      _showMessage('Please select a subject assignment.');
      return;
    }

    final materialId = int.tryParse(widget.material['id']?.toString() ?? '');

    if (materialId == null) {
      _showMessage('Invalid material ID.');
      return;
    }

    if (widget.token.trim().isEmpty) {
      _showMessage('Your session has expired. Please log in again.');
      return;
    }

    if (_fileBytes != null &&
        (_fileBytes!.isEmpty ||
            _fileName == null ||
            _fileName!.trim().isEmpty)) {
      _showMessage('Please select the file again.');
      return;
    }

    if (_fileBytes != null && _fileBytes!.length > _maxFileSize) {
      _showMessage('The file must not exceed 20 MB.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.editTeacherMaterial(
        token: widget.token,
        materialId: materialId,
        assignmentId: _selectedAssignmentId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileBytes: _fileBytes,
        fileName: _fileName,
      );

      if (!mounted) return;

      _showMessage('Material updated successfully.', isError: false);

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _assignmentLabel(Map<String, dynamic> assignment) {
    final subject =
        assignment['subject_name']?.toString() ??
        assignment['subject']?.toString() ??
        'Subject';

    final grade = assignment['grade']?.toString() ?? '';
    final section = assignment['section']?.toString() ?? '';

    return '$subject - Grade $grade, Section $section';
  }

  @override
  Widget build(BuildContext context) {
    final existingFileName = _getExistingFileName();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Material')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Material Title',
                  hintText: 'Enter material title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title.';
                  }

                  if (value.trim().length > 255) {
                    return 'Title cannot exceed 255 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter material description',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _selectedAssignmentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Subject Assignment',
                  prefixIcon: Icon(Icons.school_outlined),
                  border: OutlineInputBorder(),
                ),
                items: widget.assignments
                    .map((assignment) {
                      final id = int.tryParse(
                        assignment['id']?.toString() ?? '',
                      );

                      if (id == null) {
                        return null;
                      }

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          _assignmentLabel(assignment),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })
                    .whereType<DropdownMenuItem<int>>()
                    .toList(),
                onChanged: _isSaving || _isPickingFile
                    ? null
                    : (value) {
                        setState(() {
                          _selectedAssignmentId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a subject assignment.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Material File',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fileName ??
                                (existingFileName.isNotEmpty
                                    ? existingFileName
                                    : 'No file selected'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _isSaving || _isPickingFile
                              ? null
                              : _pickFile,
                          tooltip: 'Replace file',
                          icon: _isPickingFile
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.attach_file),
                        ),
                      ],
                    ),
                    if (_fileSize != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'New file size: '
                        '${(_fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Supported formats: PDF, Word, PowerPoint, Excel, '
                      'images and ZIP. Maximum size: 20 MB. '
                      'Choose a new file only if you want to replace '
                      'the existing one.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isPickingFile ? null : _saveMaterial,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
