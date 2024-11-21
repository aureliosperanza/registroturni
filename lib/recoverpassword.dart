import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecoverPage extends StatefulWidget {
  const RecoverPage({super.key});

  @override
  State<RecoverPage> createState() => _RecoverPageState();
}

class _RecoverPageState extends State<RecoverPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showMessage('Inserisci un indirizzo email valido.');
      return;
    }

    try {
      // Invia l'email di recupero password direttamente
      await _auth.sendPasswordResetEmail(email: email);

      // Mostra il messaggio di successo
      _showMessage('Email per il recupero inviata a $email.');

      // Torna alla pagina di login dopo un breve delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Torna alla pagina precedente (login)
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Si è verificato un errore.';

      if (e.code == 'user-not-found') {
        errorMessage = 'Nessun utente trovato con questa email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Indirizzo email non valido.';
      }

      _showMessage(errorMessage);
    } catch (e) {
      _showMessage('Errore imprevisto: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recupera Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Inserisci il tuo indirizzo email. Riceverai un link per reimpostare la password.',
              style: TextStyle(color: Colors.blue), // Testo blu
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _resetPassword,
                  child: const Text("Recupera Password"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
