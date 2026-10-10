import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StudentApi {
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
  // STUDENT DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> getStudentDashboard() async {
    final uri = Uri.parse('$baseUrl/student/dashboard.php');

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========= STUDENT DASHBOARD ============');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT DASHBOARD STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT DASHBOARD RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student dashboard API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student dashboard.');
    }

    return data;
  }

  // ============================================================
  // STUDENT SUBJECTS
  // ============================================================

  static Future<Map<String, dynamic>> getStudentSubjects() async {
    final uri = Uri.parse('$baseUrl/student/subjects.php');

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========== STUDENT SUBJECTS ============');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT SUBJECTS STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT SUBJECTS RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student subjects API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student subjects.');
    }

    return data;
  }

  // ============================================================
  // STUDENT MATERIALS
  // ============================================================

  static Future<Map<String, dynamic>> getStudentMaterials({
    int page = 1,
    int subject = 0,
  }) async {
    final queryParameters = <String, String>{'page': page.toString()};

    if (subject > 0) {
      queryParameters['subject'] = subject.toString();
    }

    final uri = Uri.parse('$baseUrl/student/materials.php')
        .replace(queryParameters: queryParameters);

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========== STUDENT MATERIALS ===========');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT MATERIALS STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT MATERIALS RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student materials API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student materials.');
    }

    return data;
  }

  // ============================================================
  // STUDENT ANNOUNCEMENTS
  // ============================================================

  static Future<Map<String, dynamic>> getStudentAnnouncements({
    int page = 1,
    String search = '',
  }) async {
    final queryParameters = <String, String>{'page': page.toString()};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/student/announcements.php')
        .replace(queryParameters: queryParameters);

    debugPrint('');

    debugPrint('========================================');

    debugPrint('======= STUDENT ANNOUNCEMENTS ==========');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT ANNOUNCEMENTS STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT ANNOUNCEMENTS RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student announcements API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to load student announcements.',
      );
    }

    return data;
  }

  // ============================================================
  // STUDENT ATTENDANCE
  // ============================================================

  static Future<Map<String, dynamic>> getStudentAttendance({
    int page = 1,
  }) async {
    final queryParameters = <String, String>{'page': page.toString()};

    final uri = Uri.parse('$baseUrl/student/attendance.php')
        .replace(queryParameters: queryParameters);

    debugPrint('');

    debugPrint('========================================');

    debugPrint('========= STUDENT ATTENDANCE ===========');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT ATTENDANCE STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT ATTENDANCE RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student attendance API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student attendance.');
    }

    return data;
  }

  // ============================================================
  // STUDENT RESULTS
  // ============================================================

  static Future<Map<String, dynamic>> getStudentResults() async {
    final uri = Uri.parse('$baseUrl/student/results.php');

    debugPrint('');

    debugPrint('========================================');

    debugPrint('=========== STUDENT RESULTS ============');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT RESULTS STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT RESULTS RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student results API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student results.');
    }

    return data;
  }

  // ============================================================
  // STUDENT HOMEWORK
  // ============================================================

  static Future<Map<String, dynamic>> getStudentHomework() async {
    final uri = Uri.parse('$baseUrl/student/homework.php');

    debugPrint('');

    debugPrint('========================================');

    debugPrint('=========== STUDENT HOMEWORK ===========');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT HOMEWORK STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT HOMEWORK RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student homework API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student homework.');
    }

    return data;
  }

  // ============================================================
  // STUDENT HOMEWORK HISTORY
  // ============================================================

  static Future<Map<String, dynamic>> getStudentHomeworkHistory() async {
    final uri = Uri.parse('$baseUrl/student/homework-history.php');

    debugPrint('');

    debugPrint('========================================');

    debugPrint('====== STUDENT HOMEWORK HISTORY ========');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('========================================');

    final response = await http.get(uri, headers: authHeaders);

    debugPrint(
      'STUDENT HOMEWORK HISTORY STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'STUDENT HOMEWORK HISTORY RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student homework history API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to load student homework history.',
      );
    }

    return data;
  }

  // ============================================================
  // SUBMIT STUDENT HOMEWORK
  // ============================================================

  static Future<Map<String, dynamic>> submitStudentHomework({
    required int homeworkId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/student/homework-submit.php');

    debugPrint('');

    debugPrint('========================================');

    debugPrint('======= SUBMIT STUDENT HOMEWORK ========');

    debugPrint('========================================');

    debugPrint('URL: $uri');

    debugPrint('Homework ID: $homeworkId');

    debugPrint('File: $fileName');

    debugPrint('File Size: ${fileBytes.length} bytes');

    debugPrint('========================================');

    if (token == null || token!.isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['homework_id'] = homeworkId.toString();

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint(
      'SUBMIT STUDENT HOMEWORK STATUS: '
      '${response.statusCode}',
    );

    debugPrint(
      'SUBMIT STUDENT HOMEWORK RESPONSE: '
      '${response.body}',
    );

    debugPrint('========================================');

    final data = _decodeResponse(
      response,
      'The student homework submission API returned an invalid response.',
    );

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to submit homework.');
    }

    return data;
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
