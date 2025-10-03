import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://154.38.182.36:7061/api";
  // final String baseUrl = "http://192.168.1.67:8080/api";
  String? token;


  Future<Map<String, String>> get headers async {
    return {
      'Content-Type': 'application/json',
    };
  }


  Future<Map?> startGame() async {
    final h = await headers;
    final res = await http.post(Uri.parse('$baseUrl/game/new'), headers: h);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> makeMove(int game_id, String move) async {
    final h = await headers;
    final res = await http.post(
      Uri.parse('$baseUrl/game/move'),
      headers: h,
      body: jsonEncode({'move': move, "game_id": game_id}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> soloMove(int game_id, String move) async {
    final url = Uri.parse("$baseUrl/game/solo");
    final h = await headers;
    final response = await http.post(
      url,
      headers: h,
      body: jsonEncode({"move": move, "game_id": game_id}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchPuzzle() async {
    final nextUrl = Uri.parse("https://lichess.org/api/puzzle/next");
    final nextResponse = await http.get(nextUrl);

    if (nextResponse.statusCode == 200) {
      final nextData = jsonDecode(nextResponse.body) as Map<String, dynamic>;
      final puzzleId = nextData['puzzle']['id'];
      final puzzleUrl = Uri.parse("https://lichess.org/api/puzzle/$puzzleId");
      final puzzleResponse = await http.get(puzzleUrl);

      if (puzzleResponse.statusCode == 200) {
        return jsonDecode(puzzleResponse.body) as Map<String, dynamic>;
      }
    }
    return null;
  }
}
