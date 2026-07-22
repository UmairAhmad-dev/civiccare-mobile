import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintService {
  // 10.0.2.2 points to host machine localhost in Android Emulator
  static const String baseUrl = "http://127.0.0.1:5000/api/citizen";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch Dashboard Stats (Total, In Progress, Resolved, AI Accuracy)
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/dashboard/stats'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to load stats');
    }
  }

  // Fetch User Complaints List
  Future<List<dynamic>> fetchUserComplaints() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/complaints'), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to fetch complaints');
    }
  }

  // Create Multi-Modal Complaint
  Future<Map<String, dynamic>> createComplaint({
    required String category,
    required String description,
    required String address,
    String? imageUrl,
    String? audioUrl,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/complaints'),
      headers: headers,
      body: json.encode({
        'category': category,
        'description': description,
        'address': address,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Failed to submit complaint');
    }
  }

  // Delete Complaint
  Future<bool> deleteComplaint(int complaintId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/complaints/$complaintId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete complaint');
    }
  }

  // Rate Resolved Complaint
  Future<bool> rateComplaint(int complaintId, int rating, String review) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/complaints/$complaintId/rate'),
      headers: headers,
      body: json.encode({'rating': rating, 'review': review}),
    );

    return response.statusCode == 200;
  }
}