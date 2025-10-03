import 'package:flutter/material.dart';
import '../screens/chess_screen.dart';
import '../screens/solo_game_screen.dart';

class BottomMenu extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) async {
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
        }
        onTap(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.bolt),
          label: "Difícil",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Solo",
        ),
      ],
    );
  }
}
