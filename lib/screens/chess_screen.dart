import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import '../services/api_service.dart';
import 'login_screen.dart'; // tela de login

class ChessScreen extends StatefulWidget {
  final bool playAsBlack;
  const ChessScreen({super.key, this.playAsBlack = false});

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> {
  late ChessBoardController controller;
  bool loading = true;
  late chess.Chess game;
  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    game = chess.Chess();
    startGame();
  }

  Future<void> startGame() async {
    setState(() => loading = true);
    final fen = await api.startGame();
    if (fen != null) {
      controller.loadFen(fen);
      game.load(fen);
    }
    if (!mounted) return;

    if (widget.playAsBlack) {
      final res = await api.makeMove("0000"); // engine joga primeiro
      if (res != null && res['engine_move'] != null) {
        final move = res['engine_move'];
        final from = move.substring(0, 2);
        final to = move.substring(2, 4);
        controller.makeMove(from: from, to: to);
        game.move({'from': from, 'to': to});
      }
    }

    setState(() => loading = false);
  }

  Future<void> handleMove(String playerMove) async {
    final from = playerMove.substring(0, 2);
    final to = playerMove.substring(2, 4);

    final prevFen = game.fen;

    controller.makeMove(from: from, to: to);
    game.move({'from': from, 'to': to});

    final res = await api.makeMove(playerMove);
    if (!mounted) return;

    if (res == null || res['engine_move'] == null) {
      controller.loadFen(prevFen);
      game.load(prevFen);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jogada inválida!")),
      );
      return;
    }

    final engineMove = res['engine_move'];
    final engineFrom = engineMove.substring(0, 2);
    final engineTo = engineMove.substring(2, 4);

    Future.delayed(const Duration(milliseconds: 50), () {
      controller.makeMove(from: engineFrom, to: engineTo);
    });
    game.move({'from': engineFrom, 'to': engineTo});

    setState(() {});
  }

  String? detectPlayerMove() {
    final moves = game.moves({'verbose': true});
    final currentFen = controller.getFen();

    for (var m in moves) {
      game.move({'from': m['from'], 'to': m['to']});
      final newPieces = game.fen.split(' ')[0];
      final currentPieces = currentFen.split(' ')[0];

      if (newPieces == currentPieces) {
        game.undo();
        return m['from'] + m['to'];
      }
      game.undo();
    }
    return null;
  }

  void onPlayerMove() {
    final playerMove = detectPlayerMove();
    if (playerMove != null) {
      Future.microtask(() async {
        await handleMove(playerMove);
      });
    }
  }

  void resetGame() async {
    controller.resetBoard();
    game.reset();
    await startGame();
  }

  void logout() async {
    await api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xadrez Ultra Difícil"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChessBoard(
                    controller: controller,
                    boardColor: BoardColor.brown,
                    boardOrientation:
                        widget.playAsBlack ? PlayerColor.black : PlayerColor.white,
                    onMove: onPlayerMove,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: resetGame,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Resetar Jogo"),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Sair"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
