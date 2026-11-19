import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  // Sambungan ke Firebase Realtime Database
  final DatabaseReference _myDatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://lab-safety-monitoring-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  StreamSubscription<DatabaseEvent>? _gasSubscription;

  // null bermaksud bacaan belum diterima
  int? gas;

  // Pastikan sama dengan gasLimit dalam Arduino
  int gasLimit = 200;

  String databaseStatus = 'Waiting for  Firebase reading';

  // Baca nilai gas daripada Firebase
  void _readGas() {
    _gasSubscription = _myDatabase.child('gas').onValue.listen(
          (DatabaseEvent event) {
        final data = event.snapshot.value;

        if (!mounted) return;

        setState(() {
          if (data is num) {
            gas = data.toInt();
            databaseStatus = 'gas reaidng accepted';
          } else {
            gas = null;
            databaseStatus = 'No gas reading';
          }
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          gas = null;
          databaseStatus = 'Failed to read Firebase';
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _readGas();
  }

  @override
  void dispose() {
    _gasSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Alert Status'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.black,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            databaseStatus,
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Paparan status amaran gas
          Card(
            color: gas == null
                ? Colors.grey.shade200
                : gas! >= gasLimit
                ? Colors.red.shade100
                : Colors.green.shade100,
            child: ListTile(
              leading: Icon(
                gas == null
                    ? Icons.help_outline
                    : gas! >= gasLimit
                    ? Icons.warning
                    : Icons.check_circle,
                color: gas == null
                    ? Colors.grey
                    : gas! >= gasLimit
                    ? Colors.red
                    : Colors.green,
              ),
              title: Text(
                gas == null
                    ? 'wait for reading'
                    : gas! >= gasLimit
                    ? 'Gas Alert'
                    : 'Normal',
              ),
              subtitle: Text(
                gas == null
                    ? 'No gas reading '
                    : gas! >= gasLimit
                    ? 'Gas reading achieve value warning test'
                    : 'Gas reading under value warning test',
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Paparan nilai bacaan gas
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('MQ-2 reader'),
              subtitle: const Text(' ADC value'),
              trailing: Text(
                gas == null ? '--' : '$gas',
              ),
            ),
          ),

          // Paparan nilai yang digunakan untuk ujian
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Alert Value'),
              subtitle: const Text('Test Value'),
              trailing: Text('$gasLimit'),
            ),
          ),
        ],
      ),
    );
  }
}