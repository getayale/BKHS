import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
}
