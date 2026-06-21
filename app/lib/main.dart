import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'engine/ffi_bridge.dart';

class _BeiPageState extends State<BeiPage> {
  final engine = BeiEngine();
  final List<FlSpot> spots = [];
  Timer? timer;
  double x = 0;
  String lastTick = '-';
  bool isMarketOpen = false;

  bool checkMarketHours() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final weekday = now.weekday; // 1 = Senin, 7 = Minggu
    
    if (weekday == 6 || weekday == 7) return false; // Weekend
    // Sesi 1: 09:00-11:30
    if (hour > 9 && hour < 11) return true;
    if (hour == 9 && minute >= 0) return true;
    if (hour == 11 && minute <= 30) return true;
    // Sesi 2: 13:30-15:49
    if (hour == 13 && minute >= 30) return true;
    if (hour == 14) return true;
    if (hour == 15 && minute <= 49) return true;
    return false;
  }

  void _startFeed() {
    engine.startFeed();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        lastTick = engine.getLastTick();
        isMarketOpen = checkMarketHours();
        
        final price = double.tryParse(lastTick)?? 0;
        if (price > 0) {
          spots.add(FlSpot(x, price));
          if (spots.length > 120) spots.removeAt(0); // 2 menit data
          x += 1;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startFeed(); // auto start pas buka app
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
        backgroundColor: isMarketOpen? Colors.green : Colors.grey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: isMarketOpen? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 8),
                Text(
                  isMarketOpen? 'Market Open' : 'Market Closed - Last Price',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            Text('IHSG: $lastTick', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: spots.isEmpty
                 ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: isMarketOpen? Colors.green : Colors.orange,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
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