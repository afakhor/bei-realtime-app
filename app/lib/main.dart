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
      debugShowCheckedModeBanner: false,
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
  final List<FlSpot> spots = [];
  Timer? timer;
  double x = 0;
  String lastTick = '-';
  bool isRunning = false;

  void _startFeed() {
    if (isRunning) return;
    engine.startFeed();
    isRunning = true;

    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final tickStr = engine.getLastTick();
      final price = double.tryParse(tickStr)?? 0;

      if (tickStr.isNotEmpty) {
        setState(() {
          lastTick = tickStr;
          spots.add(FlSpot(x, price));
          if (spots.length > 60) spots.removeAt(0); // tahan 30 detik
          x += 0.5;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BEI Realtime Chart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Native Add Test: ${engine.nativeAdd(5, 7)}'),
            Text('Last Tick: $lastTick', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isRunning? null : _startFeed,
              child: Text(isRunning? 'Running...' : 'Start Feed'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: spots.isEmpty
                 ? const Center(child: Text('Klik Start Feed dulu'))
                  : LineChart(
                      LineChartData(
                        minY: spots.map((e) => e.y).reduce((a, b) => a < b? a : b) - 5,
                        maxY: spots.map((e) => e.y).reduce((a, b) => a > b? a : b) + 5,
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}