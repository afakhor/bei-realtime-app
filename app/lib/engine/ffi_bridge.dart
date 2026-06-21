import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

typedef StartFeedC = Void Function();
typedef StartFeedDart = void Function();
typedef GetAllDataC = Pointer<Utf8> Function();
typedef GetAllDataDart = Pointer<Utf8> Function();
typedef GetCandlesC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetCandlesDart = Pointer<Utf8> Function(Pointer<Utf8>);

class BeiEngine {
  late final DynamicLibrary _lib;
  late final StartFeedDart startFeed;
  late final GetAllDataDart _getAllData;
  late final GetCandlesDart _getCandles;

  BeiEngine() {
    _lib = Platform.isAndroid? DynamicLibrary.open('libbei_engine.so') : DynamicLibrary.process();
    startFeed = _lib.lookupFunction<StartFeedC, StartFeedDart>('start_feed');
    _getAllData = _lib.lookupFunction<GetAllDataC, GetAllDataDart>('get_all_data');
    _getCandles = _lib.lookupFunction<GetCandlesC, GetCandlesDart>('get_candles');
  }

  Map<String, dynamic> getAllData() {
    final ptr = _getAllData();
    final jsonStr = ptr.toDartString();
    return jsonDecode(jsonStr);
  }

  List<dynamic> getCandles(String code) {
    final codePtr = code.toNativeUtf8();
    final ptr = _getCandles(codePtr);
    final jsonStr = ptr.toDartString();
    malloc.free(codePtr);
    return jsonDecode(jsonStr);
  }
}