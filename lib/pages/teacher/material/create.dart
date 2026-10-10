import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as picker;

import '/api_service.dart';

class CreateTeacherMaterialPage extends StatefulWidget {
  const CreateTeacherMaterialPage({super.key});

  @override
  State<CreateTeacherMaterialPage> createState() =>
      _CreateTeacherMaterialPageState();
}

class _CreateTeacherMaterialPageState extends State<CreateTeacherMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<dynamic> _assignments = [];
  int? _selectedAssignmentId;

  List<int>? _fileBytes;
  String? _fileName;
  int? _fileSize;

  bool _isLoadingAssignments = true;
  bool _isUploading = false;

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
    _loadAssignments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _loadAssignments() async {
    if (mounted) {
      setState(() {
        _isLoadingAssignments = true;
      });
    }

    try {
      final response = await ApiService.getTeacherMaterialAssignments();

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Failed to load subject assignments.',
        );
      }

      final data = response['data'];

      final assignments = data is Map && data['assignments'] is List
          ? List<dynamic>.from(data['assignments'] as List)
          : <dynamic>[];

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAssignments = false;
      });

      _showMessage(
        'Failed to load assignments: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _pickFile() async {
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
        _fileBytes = bytes;
        _fileName = file.name;
        _fileSize = bytes.length;
      });
    } catch (e) {
      _showMessage(
        'Unable to select file: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _createMaterial() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedAssignmentId == null) {
      _showMessage('Please select a subject assignment.', isError: true);
      return;
    }

    final fileBytes = _fileBytes;
    final fileName = _fileName;

    if (fileBytes == null ||
        fileBytes.isEmpty ||
        fileName == null ||
        fileName.trim().isEmpty) {
      _showMessage('Please select a learning material file.', isError: true);
      return;
    }

    if (fileBytes.length > _maxFileSize) {
      _showMessage('The file must not exceed 20 MB.', isError: true);
      return;
    }

    if (ApiService.token == null || ApiService.token!.isEmpty) {
      _showMessage(
        'Your session has expired. Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ApiService.createTeacherMaterial(
        assignmentId: _selectedAssignmentId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (!mounted) return;

      _showMessage(
        response['message'] ?? 'Learning material uploaded successfully.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(
        'Upload failed: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Learning Material')),
      body: _isLoadingAssignments
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Learning Material',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your subject, enter the material details, '
                      'and upload a file.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      value: _selectedAssignmentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Subject Assignment',
                        prefixIcon: Icon(Icons.menu_book),
                        border: OutlineInputBorder(),
                      ),
                      hint: Text(
                        _assignments.isEmpty
                            ? 'No subject assignments available'
                            : 'Select a subject assignment',
                      ),
                      items: _assignments
                          .where((assignment) => assignment is Map)
                          .map<DropdownMenuItem<int>>((assignment) {
                            final id = int.tryParse(
                              assignment['assignment_id']?.toString() ?? '',
                            );

                            final subject =
                                assignment['subject_name']?.toString() ??
                                'Subject';

                            final grade = assignment['grade']?.toString() ?? '';

                            final section =
                                assignment['section']?.toString() ?? '';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '$subject - Grade $grade, Section $section',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .where((item) => item.value != null)
                          .toList(),
                      onChanged: _isUploading || _assignments.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _selectedAssignmentId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a subject.';
                        }

                        return null;
                      },
                    ),
                    if (_assignments.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'No active subject assignments were found. '
                        'Contact your administrator if this is unexpected.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _isUploading ? null : _loadAssignments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Material Title',
                        hintText: 'e.g. Introduction to Computers',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a material title.';
                        }

                        if (value.trim().length > 255) {
                          return 'Title must not exceed 255 characters.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Describe this learning material...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Material File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _fileName == null
                                ? Icons.cloud_upload_outlined
                                : Icons.insert_drive_file,
                            size: 42,
                            color: Colors.indigo,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _fileName ?? 'No file selected',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (_fileSize != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${(_fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          const Text(
                            'PDF, Office documents, images or ZIP. '
                            'Maximum 20 MB.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choose File'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _createMaterial,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Create Material',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
