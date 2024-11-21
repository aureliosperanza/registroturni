import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StraordinarioPage extends StatefulWidget {
  const StraordinarioPage({super.key});

  @override
  _StraordinarioPageState createState() => _StraordinarioPageState();
}

class _StraordinarioPageState extends State<StraordinarioPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;
  late CollectionReference straordinarioCollection;
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _oreController = TextEditingController();

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  // Funzione per inizializzare l'ID dell'utente e la collezione 'straordinario'
  Future<void> _initUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid; // Ottieni l'ID dell'utente loggato
        straordinarioCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(
                'straordinario'); // Imposta la collezione specifica dell'utente
      });
    } else {
      setState(() {
        userId = ''; // Gestisci il caso in cui l'utente non è autenticato
      });
    }
  }

  Future<void> _showCreateStraordinarioDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Crea Straordinario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dataController,
                decoration: const InputDecoration(labelText: "Data"),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dataController.text = dateFormat.format(pickedDate);
                    });
                  }
                },
              ),
              TextField(
                controller: _oreController,
                decoration: const InputDecoration(labelText: "Numero di Ore"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () async {
                if (_dataController.text.isNotEmpty &&
                    _oreController.text.isNotEmpty) {
                  await straordinarioCollection.add({
                    'data': _dataController.text,
                    'ore': int.parse(_oreController.text),
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancellaStraordinario(String straordinarioId) async {
    await straordinarioCollection.doc(straordinarioId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Straordinario"),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/homepage');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: straordinarioCollection.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final straordinari = snapshot.data!.docs;
                if (straordinari.isEmpty) {
                  return const Center(
                    child: Text(
                      "Non ci sono straordinari",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text("Data",
                                  style: TextStyle(color: Colors.blue)))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text("Ore",
                                  style: TextStyle(color: Colors.blue)))),
                      DataColumn(
                          label: SizedBox(
                              width: 60,
                              child: Text("Elimina",
                                  style: TextStyle(color: Colors.blue)))),
                    ],
                    rows: straordinari.map((straordinario) {
                      String data = straordinario['data'];
                      int ore = straordinario['ore'];
                      return DataRow(cells: [
                        DataCell(Text(data,
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(Text('$ore h',
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _cancellaStraordinario(straordinario.id),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateStraordinarioDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Inserisci Straordinario",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
