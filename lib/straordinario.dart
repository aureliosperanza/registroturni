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

  String? _meseSelezionato;
  String? _annoSelezionato;
  final List<String> _mesi = DateFormat().dateSymbols.MONTHS.sublist(0, 12);
  final List<String> _anni = List.generate(
    5,
    (index) => (DateTime.now().year - 2 + index).toString(),
  );
  String _tipoSelezionato = 'Diurno'; // Valore di default per il turno

  @override
  void initState() {
    super.initState();
    _initUser();
    // Imposta valori iniziali di mese e anno
    final now = DateTime.now();
    _meseSelezionato = _mesi[now.month - 1];
    _annoSelezionato = now.year.toString();
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
    // Resetta i campi di testo ogni volta che si apre il popup
    _dataController.clear();
    _oreController.clear();
    _tipoSelezionato = "Diurno";

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
              const SizedBox(height: 16), // Spazio tra i widget
              DropdownButtonFormField<String>(
                value: _tipoSelezionato,
                items: ['Diurno', 'Notturno']
                    .map((String tipoStraordinario) => DropdownMenuItem(
                          value: tipoStraordinario,
                          child: Text(tipoStraordinario),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _tipoSelezionato = newValue!;
                  });
                },
                decoration:
                    const InputDecoration(labelText: "Tipo Straordinario"),
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
                    _oreController.text.isNotEmpty &&
                    _tipoSelezionato.isNotEmpty) {
                  await straordinarioCollection.add({
                    'data': _dataController.text,
                    'ore': int.parse(_oreController.text),
                    'tipo': _tipoSelezionato, // Salva il tipo selezionato
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
          // Filtri per mese e anno
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
                const Spacer(), // Occupa tutto lo spazio disponibile tra i dropdown e il pulsante
              ],
            ),
          ),
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
                final turni = snapshot.data!.docs.where((documento) {
                  final dataString = documento['data']; // Campo 'data'
                  final data = _convertiData(dataString);

                  if (data == null) return false;

                  final meseTurno = _mesi[data.month - 1];
                  final annoTurno = data.year.toString();

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
                    children: turni.map((straordinario) {
                      String data = straordinario['data'];
                      int ore = straordinario['ore'];
                      String tipo = straordinario['tipo'];

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
                              // Riga con Data e Ore
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Data: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      Text(
                                        data,
                                        style:
                                            const TextStyle(color: Colors.blue),
                                      ),
                                      const SizedBox(
                                          width: 20), // Spazio tra Data e Ore
                                      const Text(
                                        "Ore: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      Text(
                                        "$ore",
                                        style:
                                            const TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Riga con Tipo e pulsante Cancella
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Tipo: ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      Text(
                                        tipo,
                                        style:
                                            const TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await _cancellaStraordinario(
                                          straordinario.id);
                                    },
                                  ),
                                ],
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
            _showCreateStraordinarioDialog, // Funzione che viene eseguita al click
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ), // Icona che appare nel bottone
        backgroundColor: Colors.blue, // Colore di sfondo del bottone
      ),
    );
  }
}
