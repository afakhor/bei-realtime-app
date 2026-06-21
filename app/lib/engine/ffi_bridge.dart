import 'dart:ffi';
import 'dart:io';

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

  BeiEngine() {
    final lib = DynamicLibrary.open('libbei_engine.so');
    nativeAdd = lib.lookupFunction<NativeAddC, NativeAddDart>('native_add');
    startFeed = lib.lookupFunction<StartFeedC, StartFeedDart>('start_feed');
    _getLastTick = lib.lookupFunction<GetLastTickC, GetLastTickDart>('get_last_tick');
  }

  String getLastTick() {
    final ptr = _getLastTick();
    return ptr.toDartString();
  }
}

// Helper buat convert Pointer<Utf8>
class Utf8 extends Struct {}
extension Utf8Pointer on Pointer<Utf8> {
  String toDartString() {
    final codeUnits = <int>[];
    var i = 0;
    while (true) {
      final char = cast<Uint8>().elementAt(i).value;
      if (char == 0) break;
      codeUnits.add(char);
      i++;
    }
    return String.fromCharCodes(codeUnits);
  }
}
