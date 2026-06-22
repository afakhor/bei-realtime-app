import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

typedef StartFeedC = Void Function();
typedef GetDataC = Pointer<Utf8> Function();

class EngineBridge {
  late final DynamicLibrary _lib;
  late final void Function() _startFeed;
  late final Pointer<Utf8> Function() _getData;

  EngineBridge() {
    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libbei_engine.so');
      } else {
        _lib = DynamicLibrary.process();
      }
      debugPrint('FFI: libbei_engine.so berhasil di-load');
    } catch (e) {
      debugPrint('FFI ERROR: gagal load libbei_engine.so: $e');
      rethrow;
    }

    _startFeed = _lib.lookupFunction<StartFeedC, StartFeedC>('start_feed');
    _getData = _lib.lookupFunction<GetDataC, GetDataC>('get_all_data');
  }

  void startFeed() {
    debugPrint('FFI: panggil start_feed()');
    _startFeed();
  }

  Map<String, dynamic> getAllData() {
    final ptr = _getData();
    final str = ptr.toDartString();
    debugPrint('FFI: get_all_data() return: $str');
    return jsonDecode(str);
  }
}