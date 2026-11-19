import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseReference _myDatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://lab-safety-monitoring-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  StreamSubscription<DatabaseEvent>? _historySubscription;

  List<Map<String, dynamic>> history = [];

  String historyStatus = 'Menunggu sensor history';

  // Baca 20 rekod terkini daripada Firebase
  void _readHistory() {
    _historySubscription = _myDatabase
        .child('zz_history')
        .orderByKey()
        .limitToLast(20)
        .onValue
        .listen(
          (DatabaseEvent event) {
        if (!mounted) return;

        final data = event.snapshot.value;
        List<Map<String, dynamic>> records = [];

        if (data is Map) {
          for (final value in data.values) {
            if (value is Map) {
              records.add(Map<String, dynamic>.from(value));
            }
          }
        }

        // Susun rekod terbaru di bahagian atas
        records.sort((a, b) {
          int timeA = 0;
          int timeB = 0;

          if (a['timestamp'] is num) {
            timeA = (a['timestamp'] as num).toInt();
          }

          if (b['timestamp'] is num) {
            timeB = (b['timestamp'] as num).toInt();
          }

          return timeB.compareTo(timeA);
        });

        setState(() {
          history = records;

          if (history.isEmpty) {
            historyStatus = 'Belum ada rekod sensor';
          } else {
            historyStatus = 'Memaparkan rekod terkini';
          }
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          history = [];
          historyStatus = 'Gagal membaca sensor history';
        });
      },
    );
  }

  // Tukar masa Firebase kepada tarikh dan masa
  String _formatTime(dynamic value) {
    if (value is! num) {
      return 'Masa tidak tersedia';
    }

    DateTime time = DateTime.fromMillisecondsSinceEpoch(
      value.toInt(),
    ).toLocal();

    String day = time.day.toString().padLeft(2, '0');
    String month = time.month.toString().padLeft(2, '0');
    String year = time.year.toString();

    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    String second = time.second.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute:$second';
  }

  // Papar -- jika bacaan tiada
  String _formatValue(dynamic value, String unit) {
    if (value is! num) {
      return '--';
    }

    return '$value$unit';
  }

  @override
  void initState() {
    super.initState();
    _readHistory();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sensor History'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.black,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            historyStatus,
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Paparkan setiap rekod sensor
          ...history.map((record) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.history),

                title: Text(
                  _formatTime(record['timestamp']),
                ),

                subtitle: Text(
                  'Temperature: '
                      '${_formatValue(record['temperature'], ' °C')}\n'
                      'Humidity: '
                      '${_formatValue(record['humidity'], ' %')}\n'
                      'Gas: '
                      '${_formatValue(record['gas'], '')}\n'
                      'Distance: '
                      '${_formatValue(record['distance'], ' cm')}',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}