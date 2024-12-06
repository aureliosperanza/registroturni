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
    _initUser();
    // Imposta valori iniziali di mese e anno
    final now = DateTime.now();
    _meseSelezionato = _mesi[now.month - 1];
    _annoSelezionato = now.year.toString();
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
                      "Non ci sono assenze per il mese e anno selezionati",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: assenze.map((assenza) {
                      String dataInizio = assenza['dataInizio'];
                      String dataFine = assenza['dataFine'];
                      int giorni = assenza['giorni'];
                      String tipoAssenza = assenza['tipoAssenza'];

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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Colonna per le informazioni di assenza
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // RIGA 1: Data Inizio e Data Fine
                                    _buildRow(
                                        label1: "Data Inizio:",
                                        value1: dataInizio,
                                        label2: "Data Fine:",
                                        value2: dataFine),
                                    const SizedBox(
                                        height: 8), // Spazio tra le righe

                                    // RIGA 2: Tipo Assenza e Giorni
                                    _buildRow(
                                        label1: "Tipo Assenza:",
                                        value1: tipoAssenza,
                                        label2: "Giorni:",
                                        value2: "$giorni gg"),
                                  ],
                                ),
                              ),

                              // Icona di eliminazione centrata
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _cancellaAssenza(assenza.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _showCreateAssenzaDialog, // Funzione che viene eseguita al click
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ), // Icona che appare nel bottone
        backgroundColor: Colors.blue, // Colore di sfondo del bottone
      ),
    );
  }

  // Metodo per costruire le righe di testo (Data Inizio, Data Fine, Tipo Assenza, Giorni, ecc.)
  Widget _buildRow(
      {required String label1,
      required String value1,
      required String label2,
      required String value2}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildColumn(label: label1, value: value1),
        const SizedBox(width: 16), // Distanza tra le colonne
        _buildColumn(label: label2, value: value2),
      ],
    );
  }

// Metodo per costruire le colonne con label e valore
  Widget _buildColumn({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.normal)),
      ],
    );
  }
}
