import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import '../services/api_service.dart';
import '../screens/chess_screen.dart';
import '../screens/solo_game_screen.dart';
import '../widgets/bottom_menu_widget.dart';

class ProblemsScreen extends StatefulWidget {
  const ProblemsScreen({super.key});

  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  late ChessBoardController controller;
  bool loading = true;
  late chess.Chess game;
  final ApiService api = ApiService();
  int _selectedIndex = 2;
  List<Map<String, dynamic>> puzzles = [];
  int currentPuzzleIndex = 0;
  List<String> solutionMoves = [];
  int currentMoveIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    game = chess.Chess();
    fetchPuzzles();
  }

  Future<void> fetchPuzzles() async {
    setState(() => loading = true);
    final data = await api.fetchPuzzles(10);
    if (data != null && data.isNotEmpty) {
      puzzles = data;
      loadPuzzle(0);
    }
    setState(() => loading = false);
  }

  void loadPuzzle(int index) {
    if (index >= puzzles.length) return;
    final puzzle = puzzles[index];
    final fen = puzzle['fen'];
    controller.loadFen(fen);
    game.load(fen);
    solutionMoves = puzzle['moves'].split(' ');
    currentMoveIndex = 0;
    setState(() {});
  }

  Future<void> handleMove(String playerMove) async {
    if (currentMoveIndex >= solutionMoves.length) return;

    final expectedMove = solutionMoves[currentMoveIndex];
    if (playerMove == expectedMove) {
      // Make the move
      final from = playerMove.substring(0, 2);
      final to = playerMove.substring(2, 4);
      controller.makeMove(from: from, to: to);
      game.move({'from': from, 'to': to});
      currentMoveIndex++;

      if (currentMoveIndex >= solutionMoves.length) {
        // Puzzle solved
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Puzzle resolvido!")),
        );
        // Load next puzzle
        currentPuzzleIndex = (currentPuzzleIndex + 1) % puzzles.length;
        loadPuzzle(currentPuzzleIndex);
      }
    } else {
      // Invalid move
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jogada incorreta!")),
      );
    }
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

  void nextPuzzle() {
    currentPuzzleIndex = (currentPuzzleIndex + 1) % puzzles.length;
    loadPuzzle(currentPuzzleIndex);
  }

  void _onMenuTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChessScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SoloGameScreen()),
      );
    } else if (index == 2) {
      // Already here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Problemas"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : puzzles.isEmpty
              ? const Center(child: Text("Erro ao carregar problemas"))
              : Column(
                  children: [
                    ChessBoard(
                      controller: controller,
                      boardColor: BoardColor.brown,
                      boardOrientation: PlayerColor.white,
                      onMove: onPlayerMove,
                    ),
                    const SizedBox(height: 20),
                    Text("Puzzle ${currentPuzzleIndex + 1} de ${puzzles.length}"),
                    Text("Movimentos restantes: ${solutionMoves.length - currentMoveIndex}"),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: nextPuzzle,
                      icon: const Icon(Icons.skip_next),
                      label: const Text("Próximo Puzzle"),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomMenu(
        currentIndex: _selectedIndex,
        onTap: _onMenuTap,
      ),
    );
  }
}
