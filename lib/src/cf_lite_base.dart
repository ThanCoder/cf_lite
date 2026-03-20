import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cf_lite/src/cf_event.dart';

typedef SetDataCallback = Future<void> Function(Map<String, dynamic> map);
typedef GetDataCallback = Map<String, dynamic> Function();
typedef OnGetValueErrorCallback = void Function(String message);

class CFLite {
  static CFLite? _instance;

  ///
  /// ### SingleTon
  ///
  static CFLite getInstance() {
    _instance ??= CFLite();
    return _instance!;
  }

  final Map<String, dynamic> _data = {};
  late File dbFile;
  SetDataCallback? _setData;
  final _eventController = StreamController<CFEvent>.broadcast();

  Stream<CFEvent> get event => _eventController.stream;

  Future<void> init({
    required String? dbPath,
    GetDataCallback? getData,
    SetDataCallback? setData,
  }) async {
    if (dbPath == null && getData == null) {
      throw Exception('You Should Set `getData` Callback ');
    }
    // set
    _setData = setData;
    _data.clear();

    if (dbPath != null) {
      dbFile = File(dbPath);
      if (!dbFile.existsSync()) return;
      final json = jsonDecode(await dbFile.readAsString());
      _data.addAll(Map<String, dynamic>.from(json));
      return;
    }
    // get data
    _data.addAll(Map<String, dynamic>.from(getData!()));

    print(_data);
  }

  ///
  /// ### Add Config Data
  ///
  Future<void> put<T>(String key, T value) async {
    _data[key] = value;
    // event
    _eventController.add(
      CFEvent(key: key, value: value, type: CFEventType.put),
    );

    _save();
  }

  ///
  /// ### Remove Config Data
  ///
  Future<void> remove(String key) async {
    _data.remove(key);
    // event
    _eventController.add(
      CFEvent(key: key, value: null, type: CFEventType.remove),
    );

    _save();
  }

  ///
  /// ### Clear All Config Data
  ///
  Future<void> clearAll() async {
    _data.clear();

    _save();
  }

  ///
  /// Save Data
  ///
  Future<void> _save() async {
    if (_setData != null) {
      await _setData!(_data);
      return;
    }
    // file
    final contents = jsonEncode(_data);
    await dbFile.writeAsString(contents);
  }

  ///
  /// ### Get String Type
  ///
  String getString(
    String key, {
    String def = '',
    OnGetValueErrorCallback? onError,
  }) {
    return getValue(key, def: def, onError: onError);
  }

  ///
  /// ### Get int Type
  ///
  int getInt(String key, {int def = 0, OnGetValueErrorCallback? onError}) {
    return getValue<int>(key, def: def, onError: onError);
  }

  ///
  /// ### Get double Type
  ///
  double getDouble(
    String key, {
    double def = 0.0,
    OnGetValueErrorCallback? onError,
  }) {
    return getValue(key, def: def, onError: onError);
  }

  ///
  /// ### Get bool Type
  ///
  bool getBool(
    String key, {
    bool def = false,
    OnGetValueErrorCallback? onError,
  }) {
    return getValue(key, def: def, onError: onError);
  }

  ///
  /// ### Get bool Type
  ///
  List<T> getList<T>(
    String key, {
    List<T> def = const [],
    OnGetValueErrorCallback? onError,
  }) {
    return getValue(key, def: def, onError: onError);
  }

  ///
  /// ### Get bool Type
  ///
  Map<K, V> getMap<K, V>(
    String key, {
    Map<K, V> def = const {},
    OnGetValueErrorCallback? onError,
  }) {
    return getValue<Map<K, V>>(key, def: def, onError: onError);
  }

  ///
  /// ### Get Type Value
  ///
  /// Supported -> `String`,`int`,`double`,`bool`,`List<T>`,`List<Map<[String|dynamic],dynamic>>`
  ///
  T getValue<T>(
    String key, {
    required T def,
    OnGetValueErrorCallback? onError,
  }) {
    final value = _data[key];
    // print(
    //   'type: $T - defType: ${def.runtimeType} - value: ${value.runtimeType}',
    // );
    try {
      if (T == int) {
        return (int.tryParse(value) ?? def) as T;
      }
      if (T == bool) {
        return (bool.tryParse(value) ?? def) as T;
      }
      if (T == double) {
        return (double.tryParse(value) ?? def) as T;
      }
      if (T == String) {
        final val = value ?? def;
        return val.toString() as T;
      }

      // map
      if (T == Map<dynamic, dynamic>) {
        return Map<dynamic, dynamic>.from(value as Map<dynamic, dynamic>) as T;
      }
      if (T == Map<String, dynamic>) {
        return Map<String, dynamic>.from(value as Map<String, dynamic>) as T;
      }

      if (value is List) {
        if (T == List<String>) {
          return List<String>.from(value) as T;
        }
        if (T == List<int>) {
          return List<int>.from(value) as T;
        }
        if (T == List<Map<String, dynamic>>) {
          return List<Map<String, dynamic>>.from(value) as T;
        }
        if (T == List<Map<dynamic, dynamic>>) {
          return List<Map<dynamic, dynamic>>.from(value) as T;
        }
      }
    } catch (e) {
      // print('error: $e');
      onError?.call(e.toString());
      return def;
    }
    return def;
  }
}
