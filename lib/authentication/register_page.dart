import 'package:flutter/material.dart';
import 'package:rota_gourmet/services/users_services.dart';
import 'package:rota_gourmet/authentication/login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final UsersServices _usersServices = UsersServices();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    bool result = await _usersServices.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _usernameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro bem-sucedido!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao registrar. Verifique seus dados.')),
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
                'assets/images/rotagourmetlogo.png',
                height: 120,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text(
                "Registre-se!",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.green,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Text(
              'Encontre o restaurante ideal para você',
              style: TextStyle(
                  fontSize: 14, color: Color.fromARGB(255, 111, 111, 111)),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                labelText: "Nome de usuário",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email),
                labelText: "E-Mail",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                labelText: "Senha",
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                elevation: 1.5,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Registrar',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem uma conta?'),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text(
                    'Login',
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
