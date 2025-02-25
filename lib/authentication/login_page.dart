import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rota_gourmet/pages/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Controle da visibilidade da senha

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login bem-sucedido!')),
      );
      // Redirecionar para a página principal após login bem-sucedido
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(35.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 35),
            Center(
              child: Image.asset(
                'assets/images/rotagourmetlogo.png', // Certifique-se do caminho correto
                height: 120,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Bem-vindo de volta!",
              style: TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              'Encontre o restaurante ideal para você',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 111, 111, 111),
              ),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                labelText: "E-Mail",
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.fingerprint),
                labelText: "Senha",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 1),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 1.5),
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(top: 8),
              child: const Text(
                'Esqueceu a senha?',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                elevation: 1.5,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ainda não tem conta?'),
                const SizedBox(width: 5),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Registre-se',
                    style: TextStyle(color: Color.fromARGB(255, 52, 156, 56)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
