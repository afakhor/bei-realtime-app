import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'engine/ffi_bridge.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RTI Clone', theme: ThemeData.dark(), home: const WatchlistPage());
  }
}

class StockData {
  final String code;
  final int o, h, l, c, v;
  StockData.fromJson(this.code, Map j) : o=j['o'], h=j['h'], l=j['l'], c=j['c'], v=j['v'];
  double get change => (c - o).toDouble();
  double get percent => o == 0? 0 : change / o * 100;
}

class Trade {
  final int price, lot;
  final DateTime time;
  Trade.fromJson(Map j) : price=j['p'], lot=j['l'], time=DateTime.fromMillisecondsSinceEpoch(j['t'] * 1000);
}

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final engine = BeiEngine();
  Timer? timer;
  bool isMarketOpen = false;
  Map<String, StockData> stocks = {};
  List<Trade> trades = [];

  void _startFeed() {
    engine.startFeed();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final data = engine.getAllData();
      final Map<String, dynamic> stockMap = data['stocks'];
      final List<dynamic> tradeList = data['trades'];
      setState(() {
        isMarketOpen = data['market_open'];
        stocks = stockMap.map((k, v) => MapEntry(k, StockData.fromJson(k, v)));
        trades = tradeList.map((e) => Trade.fromJson(e)).toList();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startFeed();
  }

  @override
  Widget build(BuildContext context) {
    final list = stocks.values.toList()..sort((a, b) => a.code.compareTo(b.code));
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[800]),
        itemBuilder: (context, i) {
          final s = list[i];
          final color = s.change >= 0? Colors.greenAccent : Colors.redAccent;
          return ListTile(
            title: Text(s.code, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Vol: ${NumberFormat.compact().format(s.v)}'),
            trailing: Text('${s.c}', style: TextStyle(fontSize: 16, color: color)),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DetailPage(code: s.code, engine: engine),
            )),
          );
        },
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final String code;
  final BeiEngine engine;
  const DetailPage({super.key, required this.code, required this.engine});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  List<FlSpot> lineSpots = [];
  List<OhlcCandle> candles = [];

  @override
  void initState() {
    super.initState();
    loadCandles();
  }

  void loadCandles() {
    final raw = widget.engine.getCandles(widget.code);
    setState(() {
      candles = raw.map((e) => OhlcCandle.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.code),
          bottom: const TabBar(tabs: [Tab(text: 'Chart'), Tab(text: 'Running Trade')]),
        ),
        body: TabBarView(
          children: [
            // 1. Chart Candlestick
            candles.isEmpty
              ? const Center(child: Text('No Data'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: CandleChart(candles: candles),
                  ),
            // 2. Running Trade
            RunningTradeList(engine: widget.engine),
          ],
        ),
      ),
    );
  }
}

class OhlcCandle {
  final double t, o, h, l, c, v;
  OhlcCandle.fromJson(Map j)
      : t = j['t'].toDouble(),
        o = j['o'].toDouble(),
        h = j['h'].toDouble(),
        l = j['l'].toDouble(),
        c = j['c'].toDouble(),
        v = j['v'].toDouble();
}

class CandleChart extends StatelessWidget {
  final List<OhlcCandle> candles;
  const CandleChart({super.key, required this.candles});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: candles.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          final isUp = c.c >= c.o;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: c.h,
                fromY: c.l,
                color: isUp? Colors.green : Colors.red,
                width: 1,
              ),
              BarChartRodData(
                toY: c.c,
                fromY: c.o,
                color: isUp? Colors.green : Colors.red,
                width: 6,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }).toList(),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class RunningTradeList extends StatefulWidget {
  final BeiEngine engine;
  const RunningTradeList({super.key, required this.engine});
  @override
  State<RunningTradeList> createState() => _RunningTradeListState();
}

class _RunningTradeListState extends State<RunningTradeList> {
  Timer? timer;
  List<Trade> trades = [];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final data = widget.engine.getAllData();
      setState(() => trades = (data['trades'] as List).map((e) => Trade.fromJson(e)).toList());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: trades.length,
      itemBuilder: (_, i) {
        final t = trades[i];
        return ListTile(
          dense: true,
          title: Text('${t.price}', style: const TextStyle(color: Colors.greenAccent)),
          trailing: Text('${t.lot} Lot ${DateFormat.Hms().format(t.time)}'),
        );
      },
    );
  }
}