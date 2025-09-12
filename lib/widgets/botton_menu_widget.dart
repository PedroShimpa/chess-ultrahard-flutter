import 'package:flutter/material.dart';
import '../screens/chess_screen.dart';
import '../screens/solo_game_screen.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

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
        } else if (index == 2) {
          final api = ApiService();
          await api.logout();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
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
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: "Sair",
        ),
      ],
    );
  }
}
