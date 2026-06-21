import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'engine/ffi_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEI Realtime',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BeiPage(),
    );
  }
}

class BeiPage extends StatefulWidget {
  const BeiPage({super.key});
  @override
  State<BeiPage> createState() => _BeiPageState();
}

class _BeiPageState extends State<BeiPage> {
  final engine = BeiEngine();
  Timer? timer;
  bool isMarketOpen = false;
  Map<String, String> prices = {}; // {"BBCA": "10250",...}

  bool checkMarketHours() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday; // 1 = Senin, 7 = Minggu
    if (weekday == 6 || weekday == 7) return false;
    bool sesi1 = (hour > 9 || (hour == 9 && minute >= 0)) &&
        (hour < 11 || (hour == 11 && minute <= 30));
    bool sesi2 = false;
    if (weekday >= 1 && weekday <= 4) {
      sesi2 = (hour == 13 && minute >= 30) || (hour == 14);
    } else if (weekday == 5) {
      sesi2 = (hour == 14);
    }
    return sesi1 || sesi2;
  }

  void _startFeed() {
    engine.startFeed();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        isMarketOpen = checkMarketHours();
        prices = engine.getAllTicks(); // ambil semua saham 1x panggil
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startFeed();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codes = prices.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text('BEI Realtime'),
        backgroundColor: isMarketOpen? Colors.green : Colors.red,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(Icons.circle, color: isMarketOpen? Colors.greenAccent : Colors.redAccent, size: 12),
          )
        ],
      ),
      body: codes.isEmpty
         ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, i) {
                final code = codes[i];
                final price = prices[code]?? "0";
                return ListTile(
                  dense: true,
                  title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMarketOpen? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
    );
  }
}