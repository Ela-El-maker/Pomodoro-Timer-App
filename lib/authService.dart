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
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  Future<bool?> register(String name, String email, String password) async {
    final url = Uri.parse("$baseUrl/register");

    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": password,
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['token'] != null) {
        await _saveToken(data['token']);
        await fetchUser();
        debugPrint("✅ Final user (post-fetch): $_user");

        if (_user != null) {
          notifyListeners();
          return true;
        } else {
          throw Exception("User data was not set correctly.");
        }
      } else {
        if (response.statusCode == 422 && data['errors'] != null) {
          // Laravel validation errors
          String fullMessage = "";
          data['errors'].forEach((key, messages) {
            for (var msg in messages) {
              fullMessage += "$msg\n";
            }
          });
          throw Exception(fullMessage.trim());
        }

        throw Exception(data['message'] ?? "Registration failed.");
      }
    } catch (e) {
      throw Exception("Something went wrong: ${e.toString()}");
    }
  }

  Future<bool?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await _saveToken(data['token']);
        // await fetchUser();

        debugPrint("✅ Final user (post-fetch): $_user");

        await fetchUser();

        if (_user != null) {
          notifyListeners();
          return true;
        } else {
          throw Exception("User data was not set correctly.");
        }
      } else {
        if (response.statusCode == 422 && data['errors'] != null) {
          // Laravel validation errors
          String fullMessage = "";
          data['errors'].forEach((key, messages) {
            for (var msg in messages) {
              fullMessage += "$msg\n";
            }
          });
          throw Exception(fullMessage.trim());
        }
        debugPrint("📡 Register status: ${response.statusCode}");
        debugPrint("📡 Register response: ${response.body}");

        throw Exception(data['message'] ?? "Registration failed.");
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  // Future<void> logout() async {
  //   _token = null;
  //   _authenticated = false;
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('token');
  //   notifyListeners();
  // }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token');
      _authenticated = true;

      if (prefs.containsKey('user')) {
        _user = jsonDecode(
            prefs.getString('user')!); // 🌟 use cached user instantly
      }

      notifyListeners(); // immediately update UI with cached data

      await fetchUser(); // then update with fresh one from server
      return true;
    }
    return false;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    _authenticated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    // await prefs.setInt('user_id', user['id']);
    notifyListeners();
  }

  bool _fetchingUser = false;

  Future<void> fetchUser() async {
    if (_token == null || _fetchingUser) return;

    _fetchingUser = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user));
        debugPrint("✅ User fetched in AuthService: $_user");
      } else {
        debugPrint("❌ Failed to fetch user: ${response.statusCode}");
        _user = null;
      }
    } finally {
      _fetchingUser = false;
      notifyListeners();
    }
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
    _user = null;
    _authenticated = false;
    await prefs.remove('token');
    notifyListeners();

    return success;
  }
}
