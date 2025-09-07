import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.67:8080/api";
  String? token;

  ApiService() {
    _loadToken();
  }

  // Carrega o token salvo localmente
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  Future<Map<String, String>> get headers async {
    if (token == null) {
      await _loadToken();
      if (token == null) throw Exception("Token não definido");
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Salva o token localmente
  Future<void> _saveToken(String t) async {
    final prefs = await SharedPreferences.getInstance();
    token = t;
    await prefs.setString('token', t);
  }

  Future<bool> register(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );
    return res.statusCode == 201;
  }

  Future<bool> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (res.statusCode == 200) {
      final t = jsonDecode(res.body)['token'];
      if (t != null) {
        await _saveToken(t.toString());
        return true;
      }
    }
    return false;
  }

  Future<String?> startGame() async {
    final h = await headers;
    final res = await http.post(
      Uri.parse('$baseUrl/game/new'),
      headers: h,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['fen'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> makeMove(String move) async {
    final h = await headers;
    final res = await http.post(
      Uri.parse('$baseUrl/game/move'),
      headers: h,
      body: jsonEncode({'move': move}),
    );

    print(res.body);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // Método para limpar o token (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    token = null;
  }
}
