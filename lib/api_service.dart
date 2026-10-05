import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost/BKHS/api';

  static String? token;

  static void setToken(String value) {
    token = value;
  }

  static void clearToken() {
    token = null;
  }

  static Map<String, String> get authHeaders {
    if (token == null || token!.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Map<String, String> get authOnlyHeaders {
    if (token == null || token!.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    return {'Authorization': 'Bearer $token'};
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final currentToken = token;

    if (currentToken == null || currentToken.isEmpty) {
      clearToken();
      return;
    }

    try {
      final headers = {'Authorization': 'Bearer $currentToken'};

      debugPrint('');
      debugPrint('========================================');
      debugPrint('============= LOGOUT ===================');
      debugPrint('========================================');
      debugPrint('URL: $baseUrl/auth/logout.php');
      debugPrint('TOKEN EXISTS: ${currentToken.isNotEmpty}');
      debugPrint('TOKEN LENGTH: ${currentToken.length}');
      debugPrint('========================================');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout.php'),
        headers: headers,
      );

      debugPrint('LOGOUT STATUS: ${response.statusCode}');
      debugPrint('LOGOUT RESPONSE: ${response.body}');
      debugPrint('========================================');

      final data = _decodeResponse(
        response,
        'The logout API returned an invalid response.',
      );

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to logout.');
      }
    } finally {
      clearToken();

      debugPrint('LOCAL TOKEN CLEARED.');
    }
  }

  // ============================================================
  // TEACHER DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherDashboard() async {
    final uri = Uri.parse('$baseUrl/teacher/dashboard.php');

    final response = await http.get(uri, headers: authHeaders);

    final data = _decodeResponse(
      response,
      'The dashboard API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load dashboard.');
    }

    return data;
  }

  // ============================================================
  // TEACHER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/teacher/profile.php'),
      headers: authHeaders,
    );

    debugPrint('========== TEACHER PROFILE ==========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('=====================================');

    final data = _decodeResponse(
      response,
      'The teacher profile API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load teacher profile.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> uploadTeacherProfilePhoto({
    required List<int> photoBytes,
    required String fileName,
  }) async {
    if (photoBytes.isEmpty) {
      throw Exception('The selected photo is empty.');
    }

    if (fileName.trim().isEmpty) {
      throw Exception('The photo file name is missing.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/teacher/profile.php'),
    );

    request.headers.addAll(authOnlyHeaders);

    request.fields['action'] = 'update_photo';

    request.files.add(
      http.MultipartFile.fromBytes(
        'profile_photo',
        photoBytes,
        filename: fileName,
      ),
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('======= PROFILE PHOTO UPLOAD ===========');
    debugPrint('========================================');
    debugPrint('URL: ${request.url}');
    debugPrint('FILE NAME: $fileName');
    debugPrint('FILE SIZE: ${photoBytes.length} bytes');
    debugPrint('========================================');

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint(
      'PROFILE PHOTO STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'PROFILE PHOTO RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The profile photo API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update profile photo.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> changeTeacherPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.trim().isEmpty) {
      throw Exception('Current password is required.');
    }

    if (newPassword.isEmpty) {
      throw Exception('New password is required.');
    }

    if (confirmPassword.isEmpty) {
      throw Exception('Confirm password is required.');
    }

    if (newPassword.length < 8) {
      throw Exception('New password must be at least 8 characters long.');
    }

    if (newPassword != confirmPassword) {
      throw Exception('New password and confirmation password do not match.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher/profile.php'),
      headers: authHeaders,
      body: jsonEncode({
        'action': 'update_password',
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('======= CHANGE PASSWORD ================');
    debugPrint('========================================');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');
    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The password API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to change password.');
    }

    return data;
  }

  // ============================================================
  // TEACHER ATTENDANCE - TAKE ATTENDANCE
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherAttendance({
    String? className,
    int page = 1,
  }) async {
    if (page < 1) {
      page = 1;
    }

    final queryParameters = <String, String>{'page': page.toString()};

    if (className != null && className.trim().isNotEmpty) {
      queryParameters['class'] = className.trim();
    }

    final uri = Uri.parse('$baseUrl/teacher/attendance.php')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: authHeaders);

    final data = _decodeResponse(
      response,
      'The attendance API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load attendance.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getAllTeacherAttendance({
    String? className,
  }) async {
    final firstPage = await getTeacherAttendance(className: className, page: 1);

    final pagination = firstPage['pagination'] as Map<String, dynamic>? ?? {};

    final totalPages =
        int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;

    final allStudents = <Map<String, dynamic>>[];

    final firstStudents = firstPage['students'] as List<dynamic>? ?? [];

    for (final student in firstStudents) {
      if (student is Map) {
        allStudents.add(Map<String, dynamic>.from(student));
      }
    }

    if (totalPages > 1) {
      for (int page = 2; page <= totalPages; page++) {
        final pageData = await getTeacherAttendance(
          className: className,
          page: page,
        );

        final pageStudents = pageData['students'] as List<dynamic>? ?? [];

        for (final student in pageStudents) {
          if (student is Map) {
            allStudents.add(Map<String, dynamic>.from(student));
          }
        }
      }
    }

    return {...firstPage, 'students': allStudents, 'all_students_loaded': true};
  }

  static Future<Map<String, dynamic>> saveTeacherAttendance({
    required String className,
    required List<Map<String, dynamic>> students,
  }) async {
    if (className.trim().isEmpty) {
      throw Exception('Class is required.');
    }

    if (students.isEmpty) {
      throw Exception('No students to save.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher/attendance.php'),
      headers: authHeaders,
      body: jsonEncode({'class': className.trim(), 'students': students}),
    );

    final data = _decodeResponse(
      response,
      'The attendance API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save attendance.');
    }

    return data;
  }

  // ============================================================
  // TEACHER ATTENDANCE HISTORY
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherAttendanceReport({
    required String mode,
    required int month,
    int? week,
  }) async {
    final normalizedMode = mode.trim().toLowerCase();

    if (normalizedMode != 'weekly' && normalizedMode != 'monthly') {
      throw Exception('Invalid attendance history mode.');
    }

    if (month < 1 || month > 13) {
      throw Exception('Invalid Ethiopian month.');
    }

    if (normalizedMode == 'weekly') {
      if (week == null || week < 1 || week > 5) {
        throw Exception(
          'A valid week is required for weekly attendance history.',
        );
      }
    }

    final queryParameters = <String, String>{
      'mode': normalizedMode,
      'month': month.toString(),
    };

    if (normalizedMode == 'weekly' && week != null) {
      queryParameters['week'] = week.toString();
    }

    final uri = Uri.parse('$baseUrl/teacher/attendance-report.php')
        .replace(queryParameters: queryParameters);

    debugPrint('');
    debugPrint('========================================');
    debugPrint('====== ATTENDANCE HISTORY API ==========');
    debugPrint('========================================');
    debugPrint('MODE: $normalizedMode');
    debugPrint('ETHIOPIAN MONTH: $month');

    if (normalizedMode == 'weekly') {
      debugPrint('ETHIOPIAN WEEK: $week');
    }

    debugPrint('URL: $uri');
    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'ATTENDANCE HISTORY STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'ATTENDANCE HISTORY RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The attendance report API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load attendance history.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getTeacherAttendanceHistory({
    required String mode,
    required int month,
    int? week,
  }) async {
    return getTeacherAttendanceReport(mode: mode, month: month, week: week);
  }

  // ============================================================
  // TEACHER ATTENDANCE EDIT
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherAttendanceEdit({
    String? ethiopianDate,
  }) async {
    final queryParameters = <String, String>{};

    if (ethiopianDate != null && ethiopianDate.trim().isNotEmpty) {
      queryParameters['date'] = ethiopianDate.trim();
    }

    final uri = Uri.parse('$baseUrl/teacher/attendance-edit.php')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: authHeaders);

    final data = _decodeResponse(
      response,
      'The attendance edit API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to load attendance for editing.',
      );
    }

    return data;
  }

  static Future<Map<String, dynamic>> saveTeacherAttendanceEdit({
    required String ethiopianDate,
    required List<Map<String, dynamic>> students,
  }) async {
    if (ethiopianDate.trim().isEmpty) {
      throw Exception('Date is required.');
    }

    if (students.isEmpty) {
      throw Exception('No students to update.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher/attendance-edit.php'),
      headers: authHeaders,
      body: jsonEncode({'date': ethiopianDate.trim(), 'students': students}),
    );

    final data = _decodeResponse(
      response,
      'The attendance edit API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update attendance.');
    }

    return data;
  }

  // ============================================================
  // TEACHER ATTENDANCE EXCEL EXPORT
  // ============================================================

  static Future<List<int>> downloadTeacherAttendanceExport({
    required String mode,
    required int month,
    int? week,
  }) async {
    final normalizedMode = mode.trim().toLowerCase();

    if (normalizedMode != 'monthly' && normalizedMode != 'weekly') {
      throw Exception('Invalid attendance export mode.');
    }

    if (month < 1 || month > 13) {
      throw Exception('Invalid Ethiopian month.');
    }

    if (normalizedMode == 'weekly') {
      if (week == null || week < 1 || week > 5) {
        throw Exception('A valid week is required for weekly export.');
      }
    }

    final queryParameters = <String, String>{
      'mode': normalizedMode,
      'month': month.toString(),
    };

    if (normalizedMode == 'weekly' && week != null) {
      queryParameters['week'] = week.toString();
    }

    final uri = Uri.parse('$baseUrl/teacher/attendance-export.php')
        .replace(queryParameters: queryParameters);

    debugPrint('');
    debugPrint('========================================');
    debugPrint('====== ATTENDANCE EXCEL EXPORT =========');
    debugPrint('========================================');
    debugPrint('MODE: $normalizedMode');
    debugPrint('ETHIOPIAN MONTH: $month');

    if (normalizedMode == 'weekly') {
      debugPrint('ETHIOPIAN WEEK: $week');
    }

    debugPrint('URL: $uri');
    debugPrint('========================================');

    final response = await http.get(uri, headers: authOnlyHeaders);

    debugPrint(
      'EXPORT STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'EXPORT CONTENT TYPE: '
      '${response.headers['content-type']}',
    );

    debugPrint(
      'EXPORT FILE SIZE: '
      '${response.bodyBytes.length} bytes',
    );

    debugPrint('========================================');

    if (response.statusCode != 200) {
      String message = 'Failed to export attendance.';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}

      throw Exception(message);
    }

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';

    if (!contentType.contains('spreadsheetml') &&
        !contentType.contains('excel')) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
      }

      throw Exception(
        'The attendance export API did not return an Excel file.',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('The exported attendance Excel file is empty.');
    }

    return response.bodyBytes;
  }

  // ============================================================
  // TEACHER RESULTS
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherResults({
    int? semesterId,
    int? grade,
    String? section,
    int? subjectId,
    String? search,
    int page = 1,
  }) async {
    if (page < 1) {
      page = 1;
    }

    final queryParameters = <String, String>{'page': page.toString()};

    if (semesterId != null && semesterId > 0) {
      queryParameters['semester_id'] = semesterId.toString();
    }

    if (grade != null && grade > 0) {
      queryParameters['grade'] = grade.toString();
    }

    if (section != null && section.trim().isNotEmpty) {
      queryParameters['section'] = section.trim().toUpperCase();
    }

    if (subjectId != null && subjectId > 0) {
      queryParameters['subject_id'] = subjectId.toString();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/teacher/teacher_result.php')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: authHeaders);

    final data = _decodeResponse(
      response,
      'The teacher result API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load teacher results.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> saveTeacherResults({
    required int semesterId,
    required int grade,
    required String section,
    required int subjectId,
    required Map<int, dynamic> marks,
  }) async {
    if (semesterId <= 0) {
      throw Exception('Semester is required.');
    }

    if (grade <= 0) {
      throw Exception('Grade is required.');
    }

    if (section.trim().isEmpty) {
      throw Exception('Section is required.');
    }

    if (subjectId <= 0) {
      throw Exception('Subject is required.');
    }

    if (marks.isEmpty) {
      throw Exception('No marks to save.');
    }

    final formattedMarks = <String, dynamic>{};

    for (final entry in marks.entries) {
      if (entry.key <= 0) {
        continue;
      }

      formattedMarks[entry.key.toString()] = entry.value;
    }

    if (formattedMarks.isEmpty) {
      throw Exception('No valid marks to save.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher_result.php'),
      headers: authHeaders,
      body: jsonEncode({
        'semester_id': semesterId,
        'grade': grade,
        'section': section.trim().toUpperCase(),
        'subject_id': subjectId,
        'marks': formattedMarks,
      }),
    );

    final data = _decodeResponse(
      response,
      'The teacher result API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save teacher results.');
    }

    return data;
  }

  // ============================================================
  // TEACHER HOMEWORK
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherHomework({
    int? grade,
    String? section,
    int? subjectId,
    String? fromDate,
    String? toDate,
    String? status,
    int page = 1,
  }) async {
    if (page < 1) {
      page = 1;
    }

    final queryParameters = <String, String>{'page': page.toString()};

    if (grade != null && grade > 0) {
      queryParameters['grade'] = grade.toString();
    }

    if (section != null && section.trim().isNotEmpty) {
      queryParameters['section'] = section.trim().toUpperCase();
    }

    if (subjectId != null && subjectId > 0) {
      queryParameters['subject_id'] = subjectId.toString();
    }

    if (fromDate != null && fromDate.trim().isNotEmpty) {
      queryParameters['from_date'] = fromDate.trim();
    }

    if (toDate != null && toDate.trim().isNotEmpty) {
      queryParameters['to_date'] = toDate.trim();
    }

    if (status != null && status.trim().isNotEmpty) {
      final normalizedStatus = status.trim();

      if (normalizedStatus == 'Active' || normalizedStatus == 'Closed') {
        queryParameters['status'] = normalizedStatus;
      }
    }

    final uri = Uri.parse('$baseUrl/teacher/homework.php')
        .replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: authHeaders);

    debugPrint('HOMEWORK URL: $uri');

    debugPrint(
      'HOMEWORK STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'HOMEWORK BODY: '
      '${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid JSON response: '
        '${response.body}',
      );
    }

    final data = decoded;

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load teacher homework.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> createTeacherHomework({
    required int assignmentId,
    required String title,
    String? description,
    required int assignedYear,
    required int assignedMonth,
    required int assignedDay,
    required int dueYear,
    required int dueMonth,
    required int dueDay,
    List<int>? teacherMaterialBytes,
    String? teacherMaterialFileName,
  }) async {
    if (assignmentId <= 0) {
      throw Exception('Subject assignment is required.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Homework title is required.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/teacher/homework.php'),
    );

    request.headers.addAll(authOnlyHeaders);

    request.fields['assignment_id'] = assignmentId.toString();

    request.fields['title'] = title.trim();

    request.fields['description'] = description?.trim() ?? '';

    request.fields['assigned_year'] = assignedYear.toString();

    request.fields['assigned_month'] = assignedMonth.toString();

    request.fields['assigned_day'] = assignedDay.toString();

    request.fields['due_year'] = dueYear.toString();

    request.fields['due_month'] = dueMonth.toString();

    request.fields['due_day'] = dueDay.toString();

    if (teacherMaterialBytes != null && teacherMaterialBytes.isNotEmpty) {
      if (teacherMaterialFileName == null ||
          teacherMaterialFileName.trim().isEmpty) {
        throw Exception('The selected file name is missing.');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'teacher_material',
          teacherMaterialBytes,
          filename: teacherMaterialFileName,
        ),
      );
    }

    debugPrint('========== HOMEWORK CREATE ==========');

    debugPrint('URL: ${request.url}');

    debugPrint(
      'FILE SELECTED: '
      '${teacherMaterialBytes != null}',
    );

    if (teacherMaterialBytes != null) {
      debugPrint(
        'FILE NAME: '
        '$teacherMaterialFileName',
      );

      debugPrint(
        'FILE SIZE: '
        '${teacherMaterialBytes.length} bytes',
      );
    }

    debugPrint(
      'REQUEST FIELD COUNT: '
      '${request.fields.length}',
    );

    debugPrint(
      'REQUEST FILE COUNT: '
      '${request.files.length}',
    );

    debugPrint('====================================');

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(
      response,
      'The teacher homework API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to create homework.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getTeacherHomeworkEdit({
    required int homeworkId,
  }) async {
    if (homeworkId <= 0) {
      throw Exception('Homework ID is required.');
    }

    final uri = Uri.parse('$baseUrl/teacher/homework-edit.php')
        .replace(queryParameters: {'id': homeworkId.toString()});

    final response = await http.get(uri, headers: authHeaders);

    final data = _decodeResponse(
      response,
      'The teacher homework edit API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to load homework for editing.',
      );
    }

    return data;
  }

  static Future<Map<String, dynamic>> updateTeacherHomework({
    required int homeworkId,
    required String title,
    String? description,
    required int dueYear,
    required int dueMonth,
    required int dueDay,
    List<int>? teacherMaterialBytes,
    String? teacherMaterialFileName,
  }) async {
    if (homeworkId <= 0) {
      throw Exception('Homework ID is required.');
    }

    if (title.trim().isEmpty) {
      throw Exception('Homework title is required.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/teacher/homework-edit.php'),
    );

    request.headers.addAll(authOnlyHeaders);

    request.fields['homework_id'] = homeworkId.toString();

    request.fields['title'] = title.trim();

    request.fields['description'] = description?.trim() ?? '';

    request.fields['due_year'] = dueYear.toString();

    request.fields['due_month'] = dueMonth.toString();

    request.fields['due_day'] = dueDay.toString();

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========== HOMEWORK UPDATE API =========');

    debugPrint('========================================');

    debugPrint('URL: ${request.url}');

    debugPrint('HOMEWORK ID: $homeworkId');

    debugPrint('TITLE: ${request.fields['title']}');

    debugPrint(
      'DUE DATE: '
      '$dueYear-$dueMonth-$dueDay',
    );

    if (teacherMaterialBytes != null && teacherMaterialBytes.isNotEmpty) {
      debugPrint('FILE SELECTED: YES');

      debugPrint(
        'FILE NAME: '
        '$teacherMaterialFileName',
      );

      debugPrint(
        'FILE SIZE: '
        '${teacherMaterialBytes.length} bytes',
      );

      if (teacherMaterialFileName == null ||
          teacherMaterialFileName.trim().isEmpty) {
        throw Exception('The selected file name is missing.');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'teacher_material',
          teacherMaterialBytes,
          filename: teacherMaterialFileName,
        ),
      );

      debugPrint(
        'MULTIPART FILE NAME: '
        '${request.files.first.filename}',
      );

      debugPrint(
        'MULTIPART FIELD NAME: '
        '${request.files.first.field}',
      );

      debugPrint(
        'MULTIPART FILE LENGTH: '
        '${request.files.first.length}',
      );
    } else {
      debugPrint('FILE SELECTED: NO');

      debugPrint('Existing material will be preserved.');
    }

    debugPrint(
      'REQUEST FIELD COUNT: '
      '${request.fields.length}',
    );

    debugPrint(
      'REQUEST FILE COUNT: '
      '${request.files.length}',
    );

    debugPrint('========================================');

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========== PHP RESPONSE ================');

    debugPrint('========================================');

    debugPrint(
      'STATUS CODE: '
      '${response.statusCode}',
    );

    debugPrint(
      'RESPONSE BODY: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The teacher homework update API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update homework.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> deleteTeacherHomeworkMaterial({
    required int homeworkId,
  }) async {
    if (homeworkId <= 0) {
      throw Exception('Homework ID is required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher/homework-delete-material.php'),
      headers: authHeaders,
      body: jsonEncode({'homework_id': homeworkId}),
    );

    final data = _decodeResponse(
      response,
      'The teacher homework material API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete teacher material.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getTeacherHomeworkView({
    required int homeworkId,
  }) async {
    if (homeworkId <= 0) {
      throw Exception('Homework ID is required.');
    }

    final uri = Uri.parse('$baseUrl/teacher/homework-view.php')
        .replace(queryParameters: {'id': homeworkId.toString()});

    final response = await http.get(uri, headers: authHeaders);

    final data = _decodeResponse(
      response,
      'The teacher homework view API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load homework details.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> updateTeacherHomeworkStatus({
    required int homeworkId,
    required int studentId,
    required String status,
  }) async {
    if (homeworkId <= 0) {
      throw Exception('Homework ID is required.');
    }

    if (studentId <= 0) {
      throw Exception('Student ID is required.');
    }

    if (status.trim().isEmpty) {
      throw Exception('Homework status is required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher/homework-status.php'),
      headers: authHeaders,
      body: jsonEncode({
        'homework_id': homeworkId,
        'student_id': studentId,
        'status': status.trim(),
      }),
    );

    final data = _decodeResponse(
      response,
      'The teacher homework status API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update homework status.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> markAllTeacherHomeworkDone({
    required int homeworkId,
  }) async {
    if (homeworkId <= 0) {
      throw Exception('Homework ID is required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/teacher/homework-status.php'),
      headers: authHeaders,
      body: jsonEncode({'homework_id': homeworkId, 'action': 'all_done'}),
    );

    final data = _decodeResponse(
      response,
      'The teacher homework status API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to mark all students as Done.',
      );
    }

    return data;
  }

  // ============================================================
  // TEACHER ROSTER
  // ============================================================

  static Future<Map<String, dynamic>> getTeacherRoster({
    String rosterType = 'first',
  }) async {
    final normalizedRosterType = rosterType.trim().toLowerCase();

    if (!['first', 'second', 'annual'].contains(normalizedRosterType)) {
      throw Exception('Invalid roster type.');
    }

    final uri = Uri.parse('$baseUrl/teacher/roster.php')
        .replace(queryParameters: {'roster_type': normalizedRosterType});

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========== TEACHER ROSTER ==============');

    debugPrint('========================================');

    debugPrint(
      'ROSTER TYPE: '
      '$normalizedRosterType',
    );

    debugPrint('URL: $uri');

    debugPrint('========================================');

    try {
      final response = await http.get(uri, headers: authHeaders);

      debugPrint(
        'STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'BODY: '
        '${response.body}',
      );

      debugPrint('========================================');

      final data = _decodeResponse(
        response,
        'The teacher roster API returned an invalid response.',
      );

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to load teacher roster.');
      }

      return data;
    } catch (e) {
      debugPrint('ROSTER ERROR: $e');

      rethrow;
    }
  }

  static Future<List<int>> downloadTeacherRosterExport({
    String rosterType = 'first',
  }) async {
    final normalizedRosterType = rosterType.trim().toLowerCase();

    if (!['first', 'second', 'annual'].contains(normalizedRosterType)) {
      throw Exception('Invalid roster type.');
    }

    final uri = Uri.parse('$baseUrl/teacher/roster.php').replace(
      queryParameters: {'roster_type': normalizedRosterType, 'export': 'xlsx'},
    );

    debugPrint('');

    debugPrint('========================================');

    debugPrint('====== TEACHER ROSTER EXPORT ===========');

    debugPrint('========================================');

    debugPrint(
      'ROSTER TYPE: '
      '$normalizedRosterType',
    );

    debugPrint('URL: $uri');

    debugPrint('========================================');

    try {
      final response = await http.get(uri, headers: authOnlyHeaders);

      debugPrint(
        'STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'CONTENT TYPE: '
        '${response.headers['content-type']}',
      );

      debugPrint(
        'FILE SIZE: '
        '${response.bodyBytes.length} bytes',
      );

      debugPrint('========================================');

      if (response.statusCode != 200) {
        String message = 'Failed to export teacher roster.';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      if (!contentType.contains('spreadsheetml') &&
          !contentType.contains('excel')) {
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded['message'] != null) {
            throw Exception(decoded['message'].toString());
          }
        } catch (e) {
          if (e is Exception) {
            rethrow;
          }
        }

        throw Exception(
          'The teacher roster export API did not return an Excel file.',
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('The exported teacher roster Excel file is empty.');
      }

      return response.bodyBytes;
    } catch (e) {
      debugPrint('ROSTER EXPORT ERROR: $e');

      rethrow;
    }
  }

  // ============================================================
  // JSON RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
    String invalidMessage,
  ) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception();
    } catch (_) {
      throw Exception(invalidMessage);
    }
  }
}
