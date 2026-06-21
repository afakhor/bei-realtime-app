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
  final List<FlSpot> spots = [];
  Timer? timer;
  double x = 0;
  String lastTick = '0';
  bool isMarketOpen = false;

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
        lastTick = engine.getLastTick();
        isMarketOpen = checkMarketHours();
        final price = double.tryParse(lastTick) ?? 0;
        if (price > 0) {
          spots.add(FlSpot(x, price));
          if (spots.length > 120) spots.removeAt(0);
          x += 1;
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('BEI Realtime'),
        backgroundColor: isMarketOpen ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: isMarketOpen ? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 8),
                Text(
                  isMarketOpen ? 'Market Open' : 'Market Closed - Last Price',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'IHSG: $lastTick',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: spots.isEmpty
                  ? const Center(child: Text('Menunggu data...'))
                  : LineChart(
                      LineChartData(
                        minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5,
                        maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: isMarketOpen ? Colors.green : Colors.orange,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (isMarketOpen ? Colors.green : Colors.orange).withOpacity(0.2),
                            ),
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