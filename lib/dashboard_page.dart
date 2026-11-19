import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Loginpage.dart';
import 'sensor_page.dart';
import 'history_page.dart';
import 'alert_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // address Realtime Database
  final DatabaseReference _myDatabase = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://lab-safety-monitoring-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).ref();

  StreamSubscription<DatabaseEvent>? _databaseSubscription;

  bool led = false;
  bool buzzer = false;

  // null means reading not accept
  double? temperature;
  double? humidity;
  int? gas;
  double? distance;

  // to make sure same with gasLimit in Arduino
  int gasLimit = 200;

  String databaseStatus = 'waiting data from Firebase';

  // read data from Firebase
  void _readData() {
    _databaseSubscription = _myDatabase
        .orderByKey()
        .endAt('temperature')
        .onValue
        .listen(
          (DatabaseEvent event) {
        final data = event.snapshot.value;

        if (!mounted) return;

        if (data is! Map) {
          setState(() {
            databaseStatus = 'No data Firebase';
            gas = null;
          });
          return;
        }

        setState(() {
          temperature = (data['temperature'] as num?)?.toDouble();
          humidity = (data['humidity'] as num?)?.toDouble();
          gas = (data['gas'] as num?)?.toInt();
          distance = (data['distance'] as num?)?.toDouble();

          led = data['led'] == true;
          buzzer = data['buzzer'] == true;

          databaseStatus = 'Data Firebase accepted';
        });
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          databaseStatus = 'Failed read from Firebase';
          gas = null;
        });
      },
    );
  }

  // send instruction from LED to Firebase
  Future<void> _setLed(bool value) async {
    try {
      await _myDatabase.child('led').set(value);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed send instruction to LED'),
        ),
      );
    }
  }

  // send instruction from buzzer to Firebase
  Future<void> _setBuzzer(bool value) async {
    try {
      await _myDatabase.child('buzzer').set(value);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('failed to send instruction to buzzer'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _readData();
  }

  @override
  void dispose() {
    _databaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Smart Lab Dashboard'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.black,

        // Button back to  login
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Log out',
          onPressed: () async {
            try {
              // Log out from Firebase
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              // to open login and reject page before
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const Loginpage(),
                ),
                    (route) => false,
              );
            } catch (error) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to log out. Try again.'),
                ),
              );
            }
          },
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            databaseStatus,
            style: const TextStyle(
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 10),

          // Status that from  Firebase
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
              title: const Text('Gas Status'),
              subtitle: Text(
                gas == null
                    ? 'wait for read gas'
                    : gas! >= gasLimit
                    ? 'Gas Alert - reading above value testing'
                    : 'Normal - reading under value testing',
              ),
            ),
          ),

          const SizedBox(height: 20),

          // sensor page
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SensorPage(),
                ),
              );
            },
            child: const Text('View Sensor Details'),
          ),

          const SizedBox(height: 10),

          //  history page
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPage(),
                ),
              );
            },
            child: const Text('View Sensor History'),
          ),

          const SizedBox(height: 10),

          // alert page
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertPage(),
                ),
              );
            },
            child: const Text('View Alerts'),
          ),

          const SizedBox(height: 20),

          const Text(
            'Sensor Readings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // temperature
          Card(
            child: ListTile(
              leading: const Icon(Icons.thermostat),
              title: const Text('Temperature'),
              subtitle: const Text('DHT22'),
              trailing: Text(
                temperature == null ? '-- °C' : '$temperature °C',
              ),
            ),
          ),

          // Humidity
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop),
              title: const Text('Humidity'),
              subtitle: const Text('DHT22'),
              trailing: Text(
                humidity == null ? '-- %' : '$humidity %',
              ),
            ),
          ),

          // gas
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Gas / Smoke'),
              subtitle: const Text('MQ-2 - ADC'),
              trailing: Text(
                gas == null ? '--' : '$gas',
              ),
            ),
          ),

          // Distance
          Card(
            child: ListTile(
              leading: const Icon(Icons.social_distance),
              title: const Text('Distance'),
              subtitle: const Text('Ultrasonic'),
              trailing: Text(
                distance == null ? '-- cm' : '$distance cm',
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Actuator Control',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // LED
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Warning LED'),
              subtitle: Text(led ? ' ON' : 'OFF'),
              trailing: Switch(
                value: led,
                onChanged: (bool value) async {
                  await _setLed(value);
                },
              ),
            ),
          ),

          //  buzzer
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Buzzer'),
              subtitle: Text(buzzer ? ' ON' : ' OFF'),
              trailing: Switch(
                value: buzzer,
                onChanged: (bool value) async {
                  await _setBuzzer(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('ESP32'),
              subtitle: Text('Reading from Firebase'),
            ),
          ),
        ],
      ),
    );
  }
}