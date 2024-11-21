import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssenzePage extends StatefulWidget {
  const AssenzePage({super.key});

  @override
  _AssenzePageState createState() => _AssenzePageState();
}

class _AssenzePageState extends State<AssenzePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;
  late CollectionReference assenzeCollection;

  final TextEditingController _dataInizioController = TextEditingController();
  final TextEditingController _dataFineController = TextEditingController();
  String selectedAssenza = 'Malattia';

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  // Funzione per inizializzare l'ID dell'utente e la collezione 'assenze'
  Future<void> _initUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid; // Ottieni l'ID dell'utente loggato
        assenzeCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(
                'assenze'); // Imposta la collezione specifica dell'utente
      });
    } else {
      setState(() {
        userId = ''; // Gestisci il caso in cui l'utente non è autenticato
      });
    }
  }

  Future<void> _showCreateAssenzaDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Crea Assenza"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dataInizioController,
                decoration: const InputDecoration(labelText: "Data Inizio"),
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
                      _dataInizioController.text =
                          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
              ),
              TextField(
                controller: _dataFineController,
                decoration: const InputDecoration(labelText: "Data Fine"),
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
                      _dataFineController.text =
                          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedAssenza,
                items: ['Malattia', 'Ferie']
                    .map((String tipoAssenza) => DropdownMenuItem(
                          value: tipoAssenza,
                          child: Text(tipoAssenza),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedAssenza = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: "Tipo Assenza"),
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
                if (_dataInizioController.text.isNotEmpty &&
                    _dataFineController.text.isNotEmpty) {
                  int giorni = _calcolaNumeroGiorni(
                    _dataInizioController.text,
                    _dataFineController.text,
                  );

                  await assenzeCollection.add({
                    'dataInizio': _dataInizioController.text,
                    'dataFine': _dataFineController.text,
                    'tipoAssenza': selectedAssenza,
                    'giorni': giorni, // Salva il numero di giorni
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

  // Funzione per calcolare il numero di giorni tra due date
  int _calcolaNumeroGiorni(String dataInizio, String dataFine) {
    final DateFormat format = DateFormat('dd/MM/yyyy');

    try {
      DateTime inizio = format.parse(dataInizio);
      DateTime fine = format.parse(dataFine);
      return fine.difference(inizio).inDays + 1;
    } catch (e) {
      print("Errore nel parsing delle date: $e");
      return 0;
    }
  }

  Future<void> _cancellaAssenza(String assenzaId) async {
    await assenzeCollection.doc(assenzaId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assenze'),
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
              stream: assenzeCollection.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final assenze = snapshot.data!.docs;
                if (assenze.isEmpty) {
                  return const Center(
                    child: Text(
                      "Non ci sono assenze",
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
                              child: Text("Data Inizio",
                                  style: TextStyle(color: Colors.blue)))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text("Data Fine",
                                  style: TextStyle(color: Colors.blue)))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text("Tipo Assenza",
                                  style: TextStyle(color: Colors.blue)))),
                      DataColumn(
                          label: SizedBox(
                              width: 100,
                              child: Text("Giorni",
                                  style: TextStyle(color: Colors.blue)))),
                      DataColumn(
                          label: SizedBox(
                              width: 60,
                              child: Text("Elimina",
                                  style: TextStyle(color: Colors.blue)))),
                    ],
                    rows: assenze.map((assenza) {
                      String dataInizio = assenza['dataInizio'];
                      String dataFine = assenza['dataFine'];
                      int giorni = assenza['giorni'];
                      return DataRow(cells: [
                        DataCell(Text(dataInizio,
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(Text(dataFine,
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(Text(assenza['tipoAssenza'],
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(Text('$giorni gg',
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _cancellaAssenza(assenza.id),
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
        onPressed: _showCreateAssenzaDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Inserisci Assenza",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
