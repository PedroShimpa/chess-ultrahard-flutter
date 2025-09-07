
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final api = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: "Username")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final success = await api.register(usernameController.text, passwordController.text);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registrado com sucesso")));
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Falha no registro")));
                }
              },
              child: Text("Registrar"),
            ),
          ],
        ),
      ),
    );
  }
}
