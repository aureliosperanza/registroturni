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

  String? _meseSelezionato;
  String? _annoSelezionato;
  final List<String> _mesi = DateFormat().dateSymbols.MONTHS.sublist(0, 12);
  final List<String> _anni = List.generate(
    5,
    (index) => (DateTime.now().year - 2 + index).toString(),
  );

  @override
  void initState() {
    super.initState();
    _initUser(); // Inizializza l'utente e le collezioni
    _aggiornaAssenzeEStraordinarioInTurno();

    // Imposta valori iniziali di mese e anno
    final now = DateTime.now();
    _meseSelezionato = _mesi[now.month - 1];
    _annoSelezionato = now.year.toString();
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

      int totaleMalattia = 0;
      int totaleFerie = 0;
      int totaleStraordinario = 0;

      // Calcolo delle assenze (Malattia e Ferie separati)
      for (var assenzaDoc in assenzeSnapshot.docs) {
        DateTime inizioAssenza =
            DateFormat('dd/MM/yyyy').parse(assenzaDoc['dataInizio']);
        DateTime fineAssenza =
            DateFormat('dd/MM/yyyy').parse(assenzaDoc['dataFine']);
        String tipoAssenza = assenzaDoc['tipoAssenza']; // Malattia o Ferie

        if (inizioAssenza.isBefore(dataFineTurno) &&
            fineAssenza.isAfter(dataInizioTurno)) {
          int giorniAssenza = assenzaDoc['giorni'] ?? 0;

          if (tipoAssenza == 'Malattia') {
            totaleMalattia += giorniAssenza;
          } else if (tipoAssenza == 'Ferie') {
            totaleFerie += giorniAssenza;
          }
        }
      }

      // Calcolo dello straordinario
      for (var straordinarioDoc in straordinarioSnapshot.docs) {
        DateTime dataStraordinario = DateFormat('dd/MM/yyyy').parse(
            straordinarioDoc['data']); // Solo una data per lo straordinario

        // Verifica se la data dello straordinario è compresa nell'intervallo del turno
        if (dataStraordinario.isAfter(dataInizioTurno) &&
            dataStraordinario.isBefore(dataFineTurno)) {
          int oreStraordinario = straordinarioDoc['ore'] ?? 0;
          totaleStraordinario += oreStraordinario;
        }
      }

      // Aggiorna il turno con i nuovi valori di malattia, ferie e straordinario
      await turniCollection.doc(turnoDoc.id).update({
        'malattia': totaleMalattia,
        'ferie': totaleFerie,
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
                  'malattia': 0,
                  'ferie': 0,
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

  DateTime? _convertiData(String dataString) {
    try {
      final parti = dataString.split('/'); // Divide la data in [DD, MM, YYYY]
      final giorno = int.parse(parti[0]);
      final mese = int.parse(parti[1]);
      final anno = int.parse(parti[2]);
      return DateTime(anno, mese, giorno);
    } catch (e) {
      print("Errore nel parsing della data: $e");
      return null; // Ritorna null se la data non è valida
    }
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
          // Filtri per mese e anno
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Allinea i widget a sinistra
              children: [
                // Dropdown per il mese
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Sfondo bianco
                    border:
                        Border.all(color: Colors.blue, width: 2), // Bordo blu
                    borderRadius:
                        BorderRadius.circular(8), // Angoli arrotondati
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8), // Spazio interno
                  child: DropdownButton<String>(
                    value: _meseSelezionato,
                    items: _mesi.map((mese) {
                      return DropdownMenuItem(
                        value: mese,
                        child: Text(
                          mese,
                          style:
                              const TextStyle(color: Colors.blue), // Testo blu
                        ),
                      );
                    }).toList(),
                    onChanged: (valore) {
                      setState(() {
                        _meseSelezionato = valore;
                      });
                    },
                    underline:
                        const SizedBox(), // Rimuove la linea sotto il dropdown
                  ),
                ),
                const SizedBox(width: 16), // Spazio tra mese e anno
                // Dropdown per l'anno
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Sfondo bianco
                    border:
                        Border.all(color: Colors.blue, width: 2), // Bordo blu
                    borderRadius:
                        BorderRadius.circular(8), // Angoli arrotondati
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8), // Spazio interno
                  child: DropdownButton<String>(
                    value: _annoSelezionato,
                    items: _anni.map((anno) {
                      return DropdownMenuItem(
                        value: anno,
                        child: Text(
                          anno,
                          style:
                              const TextStyle(color: Colors.blue), // Testo blu
                        ),
                      );
                    }).toList(),
                    onChanged: (valore) {
                      setState(() {
                        _annoSelezionato = valore;
                      });
                    },
                    underline:
                        const SizedBox(), // Rimuove la linea sotto il dropdown
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: turniCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Errore nel caricamento dei dati",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Non ci sono presenze",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  );
                }

                final turni = snapshot.data!.docs.where((documento) {
                  final dataInizioString =
                      documento['dataInizio']; // Esempio: "10/11/2024"

                  // Converte la data dal formato "DD/MM/YYYY" a DateTime
                  final dataInizio = _convertiData(dataInizioString);

                  if (dataInizio == null) {
                    return false; // Ignora le date non valide
                  }

                  final meseTurno = _mesi[dataInizio.month - 1];
                  final annoTurno = dataInizio.year.toString();

                  return meseTurno == _meseSelezionato &&
                      annoTurno == _annoSelezionato;
                }).toList();

                if (turni.isEmpty) {
                  return const Center(
                    child: Text(
                      "Non ci sono presenze per il mese e anno selezionati",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: turni.length,
                  itemBuilder: (context, index) {
                    final turno = turni[index];
                    return Card(
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                            color: Colors.blue, width: 2), // Bordo blu
                        borderRadius:
                            BorderRadius.circular(8), // Angoli arrotondati
                      ),
                      color: Colors.white, // Sfondo bianco
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // RIGA 1: Data Inizio, Data Fine e Turno sulla stessa riga
                            _buildRow(
                                label1: "Data Inizio:",
                                value1: turno['dataInizio'],
                                label2: "Data Fine:",
                                value2: turno['dataFine'],
                                label3: "Turno:",
                                value3: turno['turno']),
                            const SizedBox(
                                height:
                                    8), // Spazio tra la prima e la seconda riga

                            // RIGA 2: Malattia, Ferie e Straordinario sulla stessa riga
                            _buildRow(
                                label1: "Malattia:",
                                value1: "${turno['malattia']} gg",
                                label2: "Ferie:",
                                value2: "${turno['ferie']} gg",
                                label3: "Straordinario:",
                                value3: "${turno['straordinario']} h"),
                            const SizedBox(
                                height:
                                    8), // Spazio tra la seconda e la terza riga

                            // Centrare il bottone di cancellazione al centro della card
                            Center(
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _cancellaTurno(turno.id);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _mostraPopupCreaTurno, // Funzione che viene eseguita al click
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ), // Icona che appare nel bottone
        backgroundColor: Colors.blue, // Colore di sfondo del bottone
      ),
    );
  }

// Metodo per costruire le righe di testo (Data Inizio, Data Fine, Turno, ecc.)
  Widget _buildRow(
      {required String label1,
      required String value1,
      required String label2,
      required String value2,
      required String label3,
      required String value3}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildColumn(label: label1, value: value1),
        const SizedBox(width: 16), // Distanza tra le colonne
        _buildColumn(label: label2, value: value2),
        const SizedBox(width: 16), // Distanza tra le colonne
        _buildColumn(label: label3, value: value3),
      ],
    );
  }

// Metodo per costruire le colonne con label e valore
  Widget _buildColumn({required String label, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }
}
