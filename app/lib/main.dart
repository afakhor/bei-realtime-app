import 'package:flutter/material.dart';
import 'engine/ffi_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = BeiEngine();
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('BEI Engine Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('5 + 7 = ${engine.nativeAdd(5, 7)}'),
              const SizedBox(height: 20),
              Text('Tick: ${engine.getLastTick()}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => engine.startFeed(),
                child: const Text('Start Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
