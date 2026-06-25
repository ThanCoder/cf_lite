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

  /// All Data
  Map<String, dynamic> get data => _data;

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

    await saveAll();
  }

  ///
  /// ### Add Without Save
  ///
  /// ### You Need To Call `saveAll` Function !!!!
  ///
  void putWithoutSave<T>(String key, T value) {
    _data[key] = value;
    // event
    _eventController.add(
      CFEvent(key: key, value: value, type: CFEventType.put),
    );
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

    await saveAll();
  }

  ///
  /// ### Clear All Config Data
  ///
  Future<void> clearAll() async {
    _data.clear();

    await saveAll();
  }

  ///
  /// Save Data
  ///
  Future<void> saveAll() async {
    try {
      if (_setData != null) {
        await _setData!(_data);
        return;
      }
      // file
      final contents = jsonEncode(_data);
      await dbFile.writeAsString(contents);
    } catch (e) {
      print('[CFLite:saveAll]: $e');
    }
  }

  ///
  /// ### Get String Type
  ///
  String getString(
    String key, {
    String def = '',
    OnGetValueErrorCallback? onError,
  }) {
    return getValue<String>(key, def: def, onError: onError);
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
    return getValue<double>(key, def: def, onError: onError);
  }

  ///
  /// ### Get bool Type
  ///
  bool getBool(
    String key, {
    bool def = false,
    OnGetValueErrorCallback? onError,
  }) {
    return getValue<bool>(key, def: def, onError: onError);
  }

  ///
  /// ### Get List Type
  /// List<[item type]> getList<[item type]>
  ///
  List<T> getList<T>(
    String key, {
    required List<T> def,
    OnGetValueErrorCallback? onError,
  }) {
    return getValue<List<T>>(key, def: def, onError: onError);
  }

  ///
  /// ### Get getMap Type
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

    if (value == null) return def;

    try {
      // ===== INT =====
      if (T == int) {
        if (value is int) return value as T;
        return (int.tryParse(value.toString()) ?? def) as T;
      }

      // ===== BOOL =====
      if (T == bool) {
        if (value is bool) return value as T;
        if (value is int) return (value == 1) as T;
        if (value.toString().toLowerCase() == 'true') return true as T;
        if (value.toString().toLowerCase() == 'false') return false as T;
        return def;
      }

      // ===== DOUBLE =====
      if (T == double) {
        if (value is double) return value as T;
        if (value is int) return value.toDouble() as T;
        return (double.tryParse(value.toString()) ?? def) as T;
      }

      // ===== STRING =====
      if (T == String) {
        return value.toString() as T;
      }

      // ===== MAPS =====
      // value က Map ဖြစ်နေရင် အပြင်က တောင်းတဲ့ Type (T) အတိုင်း တိုက်ရိုက် Cast လုပ်ပေးခြင်း
      if (value is Map) {
        return Map.from(value) as T;
      }

      // ===== LISTS =====
      // value က List ဖြစ်နေရင် အပြင်က တောင်းတဲ့ Type (T) အတိုင်း dynamic cast လုပ်ပေးခြင်း
      if (value is List) {
        return List.from(value) as T;
      }
    } catch (e) {
      onError?.call(e.toString());
      return def;
    }

    // ဘယ် Type နဲ့မှ မကိုက်ညီရင်လည်း တိုက်ရိုက် Cast လုပ်ကြည့်မယ် (ဥပမာ Custom Object Type များအတွက်)
    try {
      return value as T;
    } catch (_) {
      return def;
    }
  }

  ///
  /// ### Get Map List
  ///
  List<Map<String, dynamic>> getMapList(String key) {
    final value = _data[key];
    if (value == null) return [];
    if (value is List<dynamic>) {
      try {
        return List<Map<String, dynamic>>.from(value);
      } catch (e) {
        print('[getMapList]: $e');
      }
    }
    // print(value.runtimeType);
    return [];
  }

  Future<void> putMapList(String key, List<Map<String, dynamic>> value) async {
    _data[key] = value;
    // event
    _eventController.add(
      CFEvent(key: key, value: value, type: CFEventType.put),
    );

    await saveAll();
  }
}
