import 'package:chess_bot_only_flutter/widgets/bottom_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import '../services/api_service.dart';
import 'solo_game_screen.dart';
import 'problems_screen.dart';

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
  int game_id = 0;
  int _selectedIndex = 0;
  List<String> moveHistory = [];

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    game = chess.Chess();
    startGame();
  }

  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Already here
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SoloGameScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProblemsScreen()),
      );
    }
  }

  Future<void> startGame() async {
    setState(() => loading = true);
    final body = await api.startGame();
    if (body != null) {
      controller.loadFen(body['fen']);
      game.load(body['fen']);
      game_id = body['game_id'];
    }
    if (!mounted) return;

    if (widget.playAsBlack) {
      final res = await api.makeMove(game_id, "0000"); 
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
    moveHistory.add(playerMove);

    final res = await api.makeMove(game_id, playerMove);
    if (!mounted) return;

    if (res == null || res['engine_move'] == null) {
      controller.loadFen(prevFen);
      game.load(prevFen);
      moveHistory.removeLast();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Jogada inválida!")));
      return;
    }

    final engineMove = res['engine_move'];
    final engineFrom = engineMove.substring(0, 2);
    final engineTo = engineMove.substring(2, 4);

    Future.delayed(const Duration(milliseconds: 50), () {
      controller.makeMove(from: engineFrom, to: engineTo);
    });
    game.move({'from': engineFrom, 'to': engineTo});
    moveHistory.add(engineMove);

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
    moveHistory.clear();
    await startGame();
  }

  void _showMoveHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Histórico de Jogadas"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: moveHistory.length,
            itemBuilder: (context, index) {
              final move = moveHistory[index];
              final moveNumber = (index ~/ 2) + 1;
              final isWhite = index % 2 == 0;
              return ListTile(
                title: Text("$moveNumber. ${isWhite ? 'Brancas' : 'Pretas'}: $move"),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fechar"),
          ),
        ],
      ),
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
                    boardOrientation: widget.playAsBlack
                        ? PlayerColor.black
                        : PlayerColor.white,
                    onMove: onPlayerMove,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: resetGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Resetar Jogo"),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _selectedIndex,
        onTap: _onMenuTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMoveHistory,
        child: const Icon(Icons.history),
      ),
    );
  }
}
