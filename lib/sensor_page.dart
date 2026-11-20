import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  // extend to Firebase Realtime Database
  final DatabaseReference _myDatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://lab-safety-monitoring-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  StreamSubscription<DatabaseEvent>? _sensorSubscription;

  // null means reading not accepted
  double? temperature;
  double? humidity;
  int? gas;
  double? distance;

  String databaseStatus = 'wait data from Firebase';

  // read data sensor from Firebase
  void _readSensor() {
    _sensorSubscription = _myDatabase.onValue.listen(
          (DatabaseEvent event) {
        final data = event.snapshot.value;

        if (!mounted) return;

        if (data is! Map) {
          setState(() {
            temperature = null;
            humidity = null;
            gas = null;
            distance = null;
            databaseStatus = 'No data sensor';
          });
          return;
        }

        setState(() {
          temperature = (data['temperature'] as num?)?.toDouble();
          humidity = (data['humidity'] as num?)?.toDouble();
          gas = (data['gas'] as num?)?.toInt();
          distance = (data['distance'] as num?)?.toDouble();

          databaseStatus = 'Data Firebase accepted';
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          temperature = null;
          humidity = null;
          gas = null;
          distance = null;
          databaseStatus = 'Failed reading from Firebase';
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _readSensor();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Sensor Monitoring'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.black,
      ),

      body: ListView(
        padding:EdgeInsets.all(16),

        children: [
          Text(
            databaseStatus,
            style:TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 16),


          Card(
            child: ListTile(
              leading: Icon(
                Icons.thermostat,
                color: Colors.red,
              ),
              title: Text('Temperature'),
              subtitle:Text('DHT22'),
              trailing: Text(
                temperature == null ? '-- °C' : '$temperature °C',
              ),
            ),
          ),


          Card(
            child: ListTile(
              leading: Icon(
                Icons.water_drop,
                color: Colors.blue,
              ),
              title: Text('Humidity'),
              subtitle:  Text('DHT22'),
              trailing: Text(
                humidity == null ? '-- %' : '$humidity %',
              ),
            ),
          ),


          Card(
            child: ListTile(
              leading:  Icon(
                Icons.cloud_outlined,
                color: Colors.orange,
              ),
              title: Text('Gas / Smoke'),
              subtitle:  Text('MQ-2 -  ADC'),
              trailing: Text(
                gas == null ? '--' : '$gas',
              ),
            ),
          ),


          Card(
            child: ListTile(
              leading: const Icon(
                Icons.social_distance,
                color: Colors.purple,
              ),
              title: const Text('Distance'),
              subtitle: const Text('Ultrasonic HC-SR04'),
              trailing: Text(
                distance == null ? '-- cm' : '$distance cm',
              ),
            ),
          ),
        ],
      ),
    );
  }
}