import 'package:chess_bot_only_flutter/widgets/bottom_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import '../services/api_service.dart';
import 'chess_screen.dart';

class SoloGameScreen extends StatefulWidget {
  final bool playAsBlack;

  const SoloGameScreen({super.key, this.playAsBlack = false});

  @override
  State<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends State<SoloGameScreen> {
  late ChessBoardController controller;
  bool loading = true;
  late chess.Chess game;
  final ApiService api = ApiService();

  String evaluation = "";
  String bestMoveWhite = "";
  String bestMoveBlack = "";
  int _selectedIndex = 1;
  int game_id = 0;

  // Estado de orientação do tabuleiro
  late PlayerColor boardOrientation;

  // Controle do overlay da melhor jogada
  bool showBestMoveOverlay = true;

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    game = chess.Chess();
    boardOrientation =
        widget.playAsBlack ? PlayerColor.black : PlayerColor.white;
    startGame();
  }

  Future<void> startGame() async {
    setState(() => loading = true);
    final body = await api.startGame();
    if (body != null) {
      controller.loadFen(body['fen']);
      game.load(body['fen']);
      game_id = body['game_id'];
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> handleMove(String playerMove) async {
    final from = playerMove.substring(0, 2);
    final to = playerMove.substring(2, 4);

    final prevFen = game.fen;

    controller.makeMove(from: from, to: to);
    game.move({'from': from, 'to': to});

    final res = await api.soloMove(game_id, playerMove);
    if (!mounted) return;

    if (res == null) {
      controller.loadFen(prevFen);
      game.load(prevFen);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Jogada inválida!")));
      return;
    }

    if (mounted) {
      setState(() {
        evaluation = res["evaluation"] ?? "";
        bestMoveWhite = res["best_move_for_side"] ?? "";
        bestMoveBlack = res["best_move_opponent"] ?? "";
        showBestMoveOverlay = true; // mostrar overlay após a jogada
      });
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
      if (!mounted) return;
      setState(() {
        showBestMoveOverlay = false; // remove overlay ao clicar
      });
      Future.microtask(() async {
        await handleMove(playerMove);
      });
    }
  }

  void resetGame() async {
    controller.resetBoard();
    game.reset();
    await startGame();
    if (mounted) {
      setState(() {
        showBestMoveOverlay = true;
      });
    }
  }

  void _onMenuTap(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChessScreen()),
      );
    } else if (index == 1) {
      resetGame(); // já está na tela solo, só reinicia
    }
  }

  // Função para inverter o tabuleiro
  void invertBoard() {
    if (!mounted) return;
    setState(() {
      boardOrientation = boardOrientation == PlayerColor.white
          ? PlayerColor.black
          : PlayerColor.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Game Solo"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Stack(
                  children: [
                    ChessBoard(
                      controller: controller,
                      boardColor: BoardColor.brown,
                      boardOrientation: boardOrientation,
                      onMove: onPlayerMove,
                    ),
                    // Coordenadas horizontais (a-h)
                    Positioned(
                      bottom: 0,
                      left: 24,
                      right: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(8, (i) {
                          return Text(
                            String.fromCharCode(97 + i), // a-h
                            style: const TextStyle(color: Colors.white),
                          );
                        }),
                      ),
                    ),
                    // Coordenadas verticais (1-8)
                    Positioned(
                      top: 24,
                      bottom: 24,
                      left: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(8, (i) {
                          return Text(
                            '${8 - i}', // 8-1
                            style: const TextStyle(color: Colors.white),
                          );
                        }),
                      ),
                    ),
                    // Marcação da melhor jogada, só ativa quando showBestMoveOverlay = true
                    if (bestMoveWhite.isNotEmpty && showBestMoveOverlay)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: BestMovePainter(bestMoveWhite),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Avaliação: $evaluation"),
                Text("Melhor jogada lado da vez: $bestMoveWhite"),
                Text("Melhor jogada oponente: $bestMoveBlack"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: resetGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Resetar Jogo"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: invertBoard,
                      icon: const Icon(Icons.screen_rotation),
                      label: const Text("Inverter Tabuleiro"),
                    ),
                  ],
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

class BestMovePainter extends CustomPainter {
  final String bestMove;

  BestMovePainter(this.bestMove);

  @override
  void paint(Canvas canvas, Size size) {
    if (bestMove.length < 4) return;

    final fromFile = bestMove.codeUnitAt(0) - 97; // a-h => 0-7
    final fromRank = 8 - int.parse(bestMove[1]); // 1-8 => 7-0
    final toFile = bestMove.codeUnitAt(2) - 97;
    final toRank = 8 - int.parse(bestMove[3]);

    final squareSize = size.width / 8;

    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Destacar origem
    canvas.drawRect(
      Rect.fromLTWH(
        fromFile * squareSize,
        fromRank * squareSize,
        squareSize,
        squareSize,
      ),
      paint,
    );

    // Destacar destino
    canvas.drawRect(
      Rect.fromLTWH(
        toFile * squareSize,
        toRank * squareSize,
        squareSize,
        squareSize,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
