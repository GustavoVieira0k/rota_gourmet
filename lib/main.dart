import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rota_gourmet/authentication/login_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var options = const FirebaseOptions(
      apiKey: "AIzaSyBXRxSkyFNWI3jryI3F1XlfEmPzIdyCqpU",
      authDomain: "consultas-8cb04.firebaseapp.com",
      projectId: "consultas-8cb04",
      storageBucket: "consultas-8cb04.appspot.com",
      messagingSenderId: "1078828821937",
      appId: "1:1078828821937:web:3a6891e9cff11558706190");
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: options,
    );
  } else {
    await Firebase.initializeApp();
  }
  Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a faixa de debug
      title: 'Rota Gourmet', // Nome do app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
