import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ParentApiService {
  final String baseUrl;

  ParentApiService({required this.baseUrl});

  // ============================================================
  // PARENT DASHBOARD
  // ============================================================

  Future<Map<String, dynamic>> getDashboard(String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final uri = Uri.parse('$baseUrl/parent/dashboard.php');

    debugPrint('');
    debugPrint('========================================');
    debugPrint('========= PARENT DASHBOARD =============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT DASHBOARD STATUS: ${response.statusCode}');
    debugPrint('PARENT DASHBOARD BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent dashboard API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load parent dashboard.');
    }

    return data;
  }

  // ============================================================
  // CHILD DETAILS
  // ============================================================

  Future<Map<String, dynamic>> getChild(String token, int studentId) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    if (studentId <= 0) {
      throw Exception('Invalid student ID.');
    }

    final uri = Uri.parse('$baseUrl/parent/child.php?student_id=$studentId');

    debugPrint('');
    debugPrint('========================================');
    debugPrint('=========== PARENT CHILD ===============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('STUDENT ID: $studentId');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT CHILD STATUS: ${response.statusCode}');
    debugPrint('PARENT CHILD BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent child API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load child information.');
    }

    return data;
  }

  // ============================================================
  // CHILD RESULTS
  // ============================================================

  Future<Map<String, dynamic>> getResults(String token, int studentId) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    if (studentId <= 0) {
      throw Exception('Invalid student ID.');
    }

    final uri = Uri.parse('$baseUrl/parent/result.php?student_id=$studentId');

    debugPrint('');
    debugPrint('========================================');
    debugPrint('=========== PARENT RESULTS =============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('STUDENT ID: $studentId');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT RESULTS STATUS: ${response.statusCode}');
    debugPrint('PARENT RESULTS BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent results API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load student results.');
    }

    return data;
  }

  // ============================================================
  // CHILD ATTENDANCE
  // ============================================================

  Future<Map<String, dynamic>> getAttendance(
    String token,
    int studentId, {
    int page = 1,
  }) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    if (studentId <= 0) {
      throw Exception('Invalid student ID.');
    }

    if (page <= 0) {
      throw Exception('Invalid page number.');
    }

    final uri = Uri.parse(
      '$baseUrl/parent/attendance.php'
      '?student_id=$studentId&page=$page',
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('========= PARENT ATTENDANCE ============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('STUDENT ID: $studentId');
    debugPrint('PAGE: $page');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT ATTENDANCE STATUS: ${response.statusCode}');
    debugPrint('PARENT ATTENDANCE BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception(
        'The parent attendance API returned an invalid response.',
      );
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load attendance.');
    }

    return data;
  }

  // ============================================================
  // CHILD ANNOUNCEMENTS
  // ============================================================

  Future<Map<String, dynamic>> getAnnouncements(
    String token,
    int studentId,
  ) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    if (studentId <= 0) {
      throw Exception('Invalid student ID.');
    }

    final uri = Uri.parse(
      '$baseUrl/parent/announcements.php?student_id=$studentId',
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('======== PARENT ANNOUNCEMENTS ===========');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('STUDENT ID: $studentId');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT ANNOUNCEMENTS STATUS: ${response.statusCode}');
    debugPrint('PARENT ANNOUNCEMENTS BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception(
        'The parent announcements API returned an invalid response.',
      );
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load announcements.');
    }

    return data;
  }

  // ============================================================
  // HOMEWORK
  // ============================================================

  Future<Map<String, dynamic>> getHomework(
    String token,
    int studentId, {
    int currentPage = 1,
    int historyPage = 1,
  }) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    if (studentId <= 0) {
      throw Exception('Invalid student ID.');
    }

    if (currentPage <= 0) {
      throw Exception('Invalid current homework page.');
    }

    if (historyPage <= 0) {
      throw Exception('Invalid homework history page.');
    }

    final uri = Uri.parse(
      '$baseUrl/parent/homework.php'
      '?student_id=$studentId'
      '&current_page=$currentPage'
      '&history_page=$historyPage',
    );

    debugPrint('');
    debugPrint('========================================');
    debugPrint('=========== PARENT HOMEWORK =============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('STUDENT ID: $studentId');
    debugPrint('CURRENT PAGE: $currentPage');
    debugPrint('HISTORY PAGE: $historyPage');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT HOMEWORK STATUS: ${response.statusCode}');
    debugPrint('PARENT HOMEWORK BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent homework API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load homework.');
    }

    return data;
  }

  // ============================================================
  // PARENT PROFILE
  // ============================================================

  Future<Map<String, dynamic>> getProfile(String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final uri = Uri.parse('$baseUrl/parent/profile.php');

    debugPrint('');
    debugPrint('========================================');
    debugPrint('========== PARENT PROFILE ==============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
    );

    debugPrint('PARENT PROFILE STATUS: ${response.statusCode}');
    debugPrint('PARENT PROFILE BODY: ${response.body}');
    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent profile API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load parent profile.');
    }

    return data;
  }

  // ============================================================
  // CHANGE PROFILE PHOTO
  // ============================================================

  Future<Map<String, dynamic>> changePhoto(String token, XFile photo) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final fileSize = await photo.length();

    const maxFileSize = 5 * 1024 * 1024;

    if (fileSize > maxFileSize) {
      throw Exception('Photo size must not exceed 5 MB.');
    }

    final photoBytes = await photo.readAsBytes();

    if (photoBytes.isEmpty) {
      throw Exception('Selected photo is empty.');
    }

    final filename = photo.name.isNotEmpty ? photo.name : 'profile_photo.jpg';

    final uri = Uri.parse('$baseUrl/parent/profile.php');

    debugPrint('');
    debugPrint('========================================');
    debugPrint('======= CHANGE PARENT PHOTO ============');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('PHOTO: $filename');
    debugPrint('SIZE: $fileSize');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer ${token.trim()}',
      'Accept': 'application/json',
    });

    request.fields['action'] = 'change_photo';

    request.files.add(
      http.MultipartFile.fromBytes('photo', photoBytes, filename: filename),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('CHANGE PHOTO STATUS: ${response.statusCode}');

    debugPrint('CHANGE PHOTO BODY: ${response.body}');

    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent photo API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update profile photo.');
    }

    return data;
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<Map<String, dynamic>> changePassword(
    String token,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    if (currentPassword.trim().isEmpty) {
      throw Exception('Current password is required.');
    }

    if (newPassword.trim().isEmpty) {
      throw Exception('New password is required.');
    }

    if (confirmPassword.trim().isEmpty) {
      throw Exception('Password confirmation is required.');
    }

    if (newPassword != confirmPassword) {
      throw Exception('New password and confirmation password do not match.');
    }

    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }

    final uri = Uri.parse('$baseUrl/parent/profile.php');

    debugPrint('');
    debugPrint('========================================');
    debugPrint('======= CHANGE PARENT PASSWORD ==========');
    debugPrint('========================================');
    debugPrint('URL: $uri');
    debugPrint('TOKEN EXISTS: ${token.isNotEmpty}');
    debugPrint('========================================');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${token.trim()}',
        'Accept': 'application/json',
      },
      body: {
        'action': 'change_password',
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );

    debugPrint('CHANGE PASSWORD STATUS: ${response.statusCode}');

    debugPrint('CHANGE PASSWORD BODY: ${response.body}');

    debugPrint('========================================');

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception();
      }

      data = decoded;
    } catch (_) {
      throw Exception('The parent password API returned an invalid response.');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to change password.');
    }

    return data;
  }
}
