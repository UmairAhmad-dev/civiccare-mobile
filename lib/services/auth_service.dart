import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for Android Studio Emulator host routing
  final String baseUrl = "http://127.0.0.1:5000/api/auth";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', data['token'].toString());

      final userId = data['user']?['id']?.toString() ?? data['userId']?.toString() ?? '';
      await prefs.setString('userId', userId);
      await prefs.setString('user', json.encode(data['user']));

      return {
        'isProfileComplete': data['isProfileComplete'] ?? false,
      };
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Login failed');
    }
  }

  Future<void> register(String fullName, String email, String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'fullName': fullName, 'email': email, 'phone': phone, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token'].toString());

      final userId = data['user']?['id']?.toString() ?? data['userId']?.toString() ?? '';
      await prefs.setString('userId', userId);
      await prefs.setString('user', json.encode(data['user']));
    } else {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? 'Failed to send PIN');
    }
  }

  Future<void> resetPassword(String tokenPin, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': tokenPin, 'newPassword': password}),
    );
    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? 'Reset failed');
    }
  }
}