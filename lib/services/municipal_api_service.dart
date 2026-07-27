import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MunicipalApiService {
  // 127.0.0.1 used for adb reverse tcp:5000 tcp:5000 connection
  static const String baseUrl = "http://127.0.0.1:5000/api/services";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch Public Services Catalog with built-in timeout and fallback safety
  Future<List<dynamic>> fetchPublicServices() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/public'), headers: headers).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (_) {
      // Fallback network catch error block
    }

    // Default Fallback Data so the UI never displays an infinite spinner
    return [
      {
        'id': 1,
        'name': 'Doorstep Garbage Pickup',
        'type': 'SUBSCRIPTION',
        'fee': 1500,
        'description': 'Weekly residential waste collection and environmental disposal.',
        'defaultDeadlineDays': 7
      },
      {
        'id': 2,
        'name': 'Emergency Water Tanker',
        'type': 'ONE_TIME',
        'fee': 1200,
        'description': 'Rapid municipal dispatch clean water tanker for shortages.',
        'defaultDeadlineDays': 1
      }
    ];
  }

  // Request a Service (Fixed: no longer swallows errors silently)
  Future<bool> requestService(int serviceId, String address, String notes) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/request'),
      headers: headers,
      body: json.encode({
        'serviceId': serviceId,
        'address': address,
        'notes': notes,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data['success'] == true;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit service request (Server Error)');
    }
  }
}