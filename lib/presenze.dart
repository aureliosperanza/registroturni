import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenzePage extends StatefulWidget {
  const PresenzePage({super.key});

  @override
  _PresenzePageState createState() => _PresenzePageState();
}

class _PresenzePageState extends State<PresenzePage> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // FirebaseAuth per ottenere l'ID utente
  late final String userId; // Variabile per l'ID dell'utente

  // Collezioni Firestore dinamiche basate sull'ID dell'utente
  late final CollectionReference turniCollection;
  late final CollectionReference assenzeCollection;
  late final CollectionReference straordinarioCollection;

  final TextEditingController _dataInizioController = TextEditingController();
  final TextEditingController _dataFineController = TextEditingController();
  String _turnoSelezionato = 'Mattino'; // Valore di default per il turno

  @override
  void initState() {
    super.initState();
    _initUser(); // Inizializza l'utente e le collezioni
    _aggiornaAssenzeEStraordinarioInTurno();
  }

  // Funzione per inizializzare l'ID dell'utente e le collezioni
  Future<void> _initUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        userId = currentUser.uid; // Ottieni l'ID dell'utente autenticato
        // Ora le collezioni sono basate sull'ID dell'utente
        turniCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('turni');
        assenzeCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('assenze');
        straordinarioCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('straordinario');
      });
    } else {
      setState(() {
        userId = ''; // Gestisci il caso in cui l'utente non è autenticato
      });
    }
  }

  Future<void> _aggiornaAssenzeEStraordinarioInTurno() async {
    QuerySnapshot turniSnapshot = await turniCollection.get();
    QuerySnapshot assenzeSnapshot = await assenzeCollection.get();
    QuerySnapshot straordinarioSnapshot = await straordinarioCollection.get();

    for (var turnoDoc in turniSnapshot.docs) {
      DateTime dataInizioTurno =
          DateFormat('dd/MM/yyyy').parse(turnoDoc['dataInizio']);
      DateTime dataFineTurno =
          DateFormat('dd/MM/yyyy').parse(turnoDoc['dataFine']);

      int totaleAssenze = 0;
      int totaleStraordinario = 0;

      // Calcolo delle assenze
      for (var assenzaDoc in assenzeSnapshot.docs) {
        DateTime inizioAssenza =
            DateFormat('dd/MM/yyyy').parse(assenzaDoc['dataInizio']);
        DateTime fineAssenza =
            DateFormat('dd/MM/yyyy').parse(assenzaDoc['dataFine']);

        if (inizioAssenza.isBefore(dataFineTurno) &&
            fineAssenza.isAfter(dataInizioTurno)) {
          int giorniAssenza = assenzaDoc['giorni'] ?? 0;
          totaleAssenze += giorniAssenza;
        }
      }

      // Calcolo dello straordinario
      for (var straordinarioDoc in straordinarioSnapshot.docs) {
        DateTime dataStraordinario = DateFormat('dd/MM/yyyy')
            .parse(straordinarioDoc['data']); // Usa solo la data

        // Verifica se la data dello straordinario rientra nel periodo del turno
        if (dataStraordinario
                .isAfter(dataInizioTurno.subtract(const Duration(days: 1))) &&
            dataStraordinario
                .isBefore(dataFineTurno.add(const Duration(days: 1)))) {
          int oreStraordinario = straordinarioDoc['ore'] ?? 0;
          totaleStraordinario += oreStraordinario;
        }
      }

      // Aggiorna il turno con i valori di assenze e straordinario calcolati
      await turnoDoc.reference.update({
        'assenze': totaleAssenze,
        'straordinario': totaleStraordinario,
      });
    }
  }

  void _mostraPopupCreaTurno() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Crea Presenza"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _dataInizioController,
                decoration: const InputDecoration(labelText: "Data Inizio"),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? dataSelezionata = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (dataSelezionata != null) {
                    _dataInizioController.text =
                        DateFormat('dd/MM/yyyy').format(dataSelezionata);
                  }
                },
              ),
              TextField(
                controller: _dataFineController,
                decoration: const InputDecoration(labelText: "Data Fine"),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? dataSelezionata = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (dataSelezionata != null) {
                    _dataFineController.text =
                        DateFormat('dd/MM/yyyy').format(dataSelezionata);
                  }
                },
              ),
              DropdownButton<String>(
                value: _turnoSelezionato,
                onChanged: (String? nuovoValore) {
                  setState(() {
                    _turnoSelezionato = nuovoValore!;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Mattino',
                    child: Text('Mattino'),
                  ),
                  DropdownMenuItem(
                    value: 'Pomeriggio',
                    child: Text('Pomeriggio'),
                  ),
                  DropdownMenuItem(
                    value: 'Notte',
                    child: Text('Notte'),
                  ),
                ],
                isExpanded: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () async {
                await turniCollection.add({
                  'dataInizio': _dataInizioController.text,
                  'dataFine': _dataFineController.text,
                  'turno': _turnoSelezionato,
                  'assenze': 0,
                  'straordinario': 0,
                });
                // Chiama la funzione di aggiornamento subito dopo aver creato il turno
                await _aggiornaAssenzeEStraordinarioInTurno();
                _dataInizioController.clear();
                _dataFineController.clear();
                setState(() {
                  _turnoSelezionato = 'Mattino';
                });
                Navigator.of(context).pop();
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancellaTurno(String turnoId) async {
    await turniCollection.doc(turnoId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presenze'),
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
              stream: turniCollection.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final turni = snapshot.data!.docs;
                if (turni.isEmpty) {
                  return const Center(
                    child: Text(
                      "Non ci sono presenze",
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
                                style: TextStyle(color: Colors.blue))),
                      ),
                      DataColumn(
                        label: SizedBox(
                            width: 100,
                            child: Text("Data Fine",
                                style: TextStyle(color: Colors.blue))),
                      ),
                      DataColumn(
                        label: SizedBox(
                            width: 100,
                            child: Text("Turno",
                                style: TextStyle(color: Colors.blue))),
                      ),
                      DataColumn(
                        label: SizedBox(
                            width: 100,
                            child: Text("Assenze",
                                style: TextStyle(color: Colors.blue))),
                      ),
                      DataColumn(
                        label: SizedBox(
                            width: 100,
                            child: Text("Straordinario",
                                style: TextStyle(color: Colors.blue))),
                      ),
                      DataColumn(
                        label: SizedBox(
                            width: 100,
                            child: Text("Elimina",
                                style: TextStyle(color: Colors.blue))),
                      ),
                    ],
                    rows: turni.map((turno) {
                      return DataRow(cells: [
                        DataCell(Text(turno['dataInizio'],
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(Text(turno['dataFine'],
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(Text(turno['turno'],
                            style: const TextStyle(color: Colors.blue))),
                        DataCell(
                          InkWell(
                            onTap: () {
                              // Naviga alla pagina delle assenze
                              Navigator.of(context).pushNamed('/assenze');
                            },
                            child: Text(
                              '${turno['assenze']} gg', // Aggiunge " gg" accanto al numero di assenze
                              style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        DataCell(
                          InkWell(
                            onTap: () {
                              // Naviga alla pagina delle assenze
                              Navigator.of(context).pushNamed('/straordinario');
                            },
                            child: Text(
                              '${turno['straordinario']} h', // Aggiunge " gg" accanto al numero di assenze
                              style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        DataCell(IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () async {
                            await _cancellaTurno(turno.id);
                          },
                        )),
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
        onPressed: _mostraPopupCreaTurno,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Inserisci Presenza",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
