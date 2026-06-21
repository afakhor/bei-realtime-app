import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart'; // ini yg penting

// C function signatures
typedef NativeAddC = Int32 Function(Int32 a, Int32 b);
typedef NativeAddDart = int Function(int a, int b);

typedef StartFeedC = Void Function();
typedef StartFeedDart = void Function();

typedef GetLastTickC = Pointer<Utf8> Function();
typedef GetLastTickDart = Pointer<Utf8> Function();

class BeiEngine {
  late NativeAddDart nativeAdd;
  late StartFeedDart startFeed;
  late GetLastTickDart _getLastTick;
  late DynamicLibrary _lib;

  BeiEngine() {
    if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libbei_engine.so');
    } else if (Platform.isIOS) {
      _lib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Platform not supported');
    }
    
    nativeAdd = _lib.lookupFunction<NativeAddC, NativeAddDart>('native_add');
    startFeed = _lib.lookupFunction<StartFeedC, StartFeedDart>('start_feed');
    _getLastTick = _lib.lookupFunction<GetLastTickC, GetLastTickDart>('get_last_tick');
  }

  String getLastTick() {
    final ptr = _getLastTick();
    if (ptr == nullptr) return '';
    final result = ptr.toDartString(); // toDartString() udah dari package:ffi
    // calloc.free(ptr); // HANYA kalau C++ kamu ga free sendiri. Hati2 double free
    return result;
  }
}