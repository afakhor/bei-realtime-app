import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

typedef StartFeedC = Void Function();
typedef StartFeedDart = void Function();

typedef GetAllTicksC = Pointer<Utf8> Function();
typedef GetAllTicksDart = Pointer<Utf8> Function();

class BeiEngine {
  late final DynamicLibrary _lib;
  late final StartFeedDart startFeed;
  late final GetAllTicksDart _getAllTicks;

  BeiEngine() {
    _lib = Platform.isAndroid
       ? DynamicLibrary.open('libbei_engine.so')
        : DynamicLibrary.process();
    startFeed = _lib.lookupFunction<StartFeedC, StartFeedDart>('start_feed');
    _getAllTicks = _lib.lookupFunction<GetAllTicksC, GetAllTicksDart>('get_all_ticks');
  }

  Map<String, String> getAllTicks() {
    final resultPtr = _getAllTicks();
    final jsonStr = resultPtr.toDartString();
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }
}