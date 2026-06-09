import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // ── REGISTER ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse(Constants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'email', value: data['email']);
      await _storage.write(key: 'role', value: data['role']);
    }

    return {'statusCode': response.statusCode, 'data': data};
  }

  // ── LOGIN ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(Constants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'email', value: data['email']);
      await _storage.write(key: 'role', value: data['role']);
    }

    return {'statusCode': response.statusCode, 'data': data};
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.deleteAll();
  }


  // ── GET Email ────────────────────────────────────────────────
  Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }

  // ── GET TOKEN ────────────────────────────────────────────────
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // ── GET ROLE ─────────────────────────────────────────────────
  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  // ── IS LOGGED IN ─────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }
}