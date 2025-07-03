import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl =
    "https://letscode.felixeladi.co.ke/api"; // Use LAN IP for real devices

class AuthService with ChangeNotifier {
  String? _token;
  bool _authenticated = false;

  bool get isAuthenticated => _authenticated;
  String? get token => _token;

  Future<bool> register(String name, String email, String password) async {
  final url = Uri.parse("$baseUrl/register");

  final response = await http.post(
    url,
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json", // important
    },
    body: jsonEncode({ // ✅ This fixes the error
      "name": name,
      "email": email,
      "password": password,
      "password_confirmation": password,
    }),
  );

  print("📥 Status: ${response.statusCode}");
  print("📥 Body: ${response.body}");

  final data = jsonDecode(response.body);

  if (response.statusCode == 201 && data['token'] != null) {
    _saveToken(data['token']);
    return true;
  } else {
    throw Exception(data['message'] ?? data.toString());
  }
}


  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json", // ✅ Important
      },
      body: {
        "email": email,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      _saveToken(data['token']);
      return true;
    } else {
      throw Exception(data['message'] ?? "Login failed");
    }
  }

  // Future<void> logout() async {
  //   _token = null;
  //   _authenticated = false;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('token');
  //   notifyListeners();
  // }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token');
      _authenticated = true;
      notifyListeners();
    }
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    _authenticated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    // await prefs.setInt('user_id', user['id']);
    notifyListeners();
  }

  // Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');

  //   if (token != null) {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/logout'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Accept': 'application/json',
  //       },
  //     );

  //     if (response.statusCode != 200) {
  //       debugPrint("Logout warning: ${response.statusCode} ${response.body}");
  //     }
  //   }

  //   // Clear local state regardless
  //   _token = null;
  //   _authenticated = false;
  //   await prefs.remove('token');
  //   notifyListeners();
  // }
  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    bool success = false;

    if (token != null) {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Logout successful: ${response.body}");
        success = true;
      } else {
        debugPrint("Logout failed: ${response.statusCode} ${response.body}");
      }
    } else {
      debugPrint("No token found for logout.");
    }

    _token = null;
    _authenticated = false;
    await prefs.remove('token');
    notifyListeners();

    return success;
  }
}
