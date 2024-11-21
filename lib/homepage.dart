import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase per gestire il logout

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Funzione per il logout
  Future<void> _logout(BuildContext context) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;

      User? user = auth.currentUser;
      if (user != null) {
        // L'utente è loggato
        await auth.signOut(); // Esegui il logout da Firebase
        Navigator.pushReplacementNamed(
            context, '/login'); // Torna alla pagina di login (main.dart)
      } else {
        // L'utente non è loggato
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun utente loggato')),
        );
      }
    } catch (e) {
      // Gestisci eventuali errori
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisci un tema comune per i bottoni
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue,
      side: const BorderSide(color: Colors.blue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Arrotondamento degli angoli
      ),
      minimumSize: const Size.fromHeight(50), // Larghezza uniforme
    );
    return Scaffold(
      appBar: null, // Rimuovi l'AppBar
      body: Column(
        children: [
          const SizedBox(height: 50), // Spazio in alto alla pagina
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3), // Offset dell'ombra
                ),
              ],
            ),
            child: const Text(
              "Registro Turni è una semplice app dove puoi inserire le tue presenze settimanali, le tue assenze e i tuoi straordinari",
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 100), // Spazio tra la box e i bottoni

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20), // Padding di 20px ai lati
            child: ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/presenze');
              },
              child: const Text("Presenze"),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/assenze');
              },
              child: const Text("Assenze"),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: buttonStyle,
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/straordinario');
              },
              child: const Text("Straordinario"),
            ),
          ),
          const Spacer(), // Occupa lo spazio rimanente tra i bottoni e il bottone Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double
                  .infinity, // Adatta la larghezza del bottone alla larghezza dello schermo
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Colore blu del bottone
                ),
                onPressed: () {
                  _logout(context);
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white), // Testo bianco
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
