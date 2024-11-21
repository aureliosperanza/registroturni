import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'register.dart';
import 'homepage.dart';
import 'package:registroturni/presenze.dart';
import 'package:registroturni/assenze.dart';
import 'package:registroturni/straordinario.dart';
import 'package:registroturni/recoverpassword.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inizializza Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro Turni',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/recover': (context) => const RecoverPage(),
        '/homepage': (context) => const HomePage(),
        '/presenze': (context) => const PresenzePage(),
        '/assenze': (context) => const AssenzePage(),
        '/straordinario': (context) => const StraordinarioPage(),
      },
      builder: (context, child) {
        // Blocca il back fisico in tutta l'app
        SystemChannels.navigation.setMethodCallHandler((call) async {
          if (call.method == 'popRoute') {
            return null; // Blocca l'azione del tasto back
          }
          return null;
        });
        return child!;
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Istanza di FirebaseAuth

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Verifica se i campi sono vuoti
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compilare i campi"), // Messaggio per campi vuoti
        ),
      );
      return; // Esci dalla funzione se i campi sono vuoti
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Login riuscito, naviga verso la home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) =>
                const HomePage()), // Usa HomePage da homepage.dart
      );
    } catch (e) {
      // Errore nel login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di login: $e")),
      );
    }
  }

  void _register() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              const RegisterPage()), // Naviga alla RegisterPage
    );
  }

  void _recover() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const RecoverPage()), // Naviga alla RecoverPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Sfondo bianco
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg', // Percorso del logo
              height: 100, // Altezza dell'immagine
            ),
            const SizedBox(height: 32.0), // Spazio sotto l'immagine
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.blue), // Testo bianco
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle:
                    TextStyle(color: Colors.blue), // Testo del label bianco
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.blue), // Testo bianco
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle:
                    TextStyle(color: Colors.blue), // Testo del label bianco
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _recover,
                child: const Text(
                  "Hai dimenticato la password?",
                  style: TextStyle(color: Colors.blue), // Testo blu
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _login, // Testo blu
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Sfondo bianco
                minimumSize:
                    const Size(double.infinity, 50), // Larghezza massima
              ),
              child: const Text("Login", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16.0),
            OutlinedButton(
              onPressed: _register, // Testo bianco
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue), // Contorno bianco
                minimumSize:
                    const Size(double.infinity, 50), // Larghezza massima
              ), // Naviga alla pagina di registrazione
              child: const Text("Registrati",
                  style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
