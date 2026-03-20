# Config Box Lite (CFLite) 📦

A lightweight, JSON-based persistent key-value storage for Dart and Flutter. **CFLite** simplifies local data management with powerful type-casting, reactive event listeners, and zero boilerplate.

## ✨ Key Features

- **🚀 Easy Initialization:** Set up your database with a single line by specifying a JSON file path.
- **🛡️ Type-Safe Retrieval:** Specialized getters (`getString`, `getBool`, `getInt`, `getDouble`) ensure data integrity.
- **🧬 Advanced Generic Support:** Retrieve complex data types like `List<String>`, `List<int>`, or `List<Map>` with automatic casting using `getValue<T>`.
- **💡 Smart Fallbacks:** Every getter supports a `def` (default) parameter, returning a safe value if a key is missing or types mismatch.
- **🔔 Reactive Data:** Built-in Event Listener to track `put`, `delete`, or `update` actions in real-time.
- **🏗️ Zero Boilerplate:** No complex schemas, tables, or migrations required.

---

## 🚀 Getting Started

### 1. Initialization

Initialize the instance and link it to your JSON file.

```dart
final db = CFLite.getInstance();
await db.init(dbPath: 'test.db.json');
```

## Example Json Data

```json
{
  "test": "test one",
  "name": 12,
  "list": [1, 2, 3, 4, 5],
  "str_list": ["than", "coder"],
  "map": { "name": "thancoder" },
  "map_list": [{ "name": "thancoder" }]
}
```

## Example

```dart
///
final db = CFLite.getInstance();
await db.init(dbPath: 'test.db.json'); //important


await db.put('name', 12);
await db.put<String>('test', 'test one');
await db.put('list', [1,2,3,4,5]);

print(db.getString('name')); // 12
print(db.getBool('list', def: false)); //false
print(db.getInt('list', def: 1)); // 1
print(db.getDouble('list', def: 0.1)); // 0.1

// List
print(db.getList<int>('list')); //[1, 2, 3, 4, 5]
print(db.getList<String>('str_list')); //["than", "coder"]

//Map
print(db.getMap('map')); //{name: thancoder}
print(db.getMap<String,dynamic>('map')); //{name: thancoder}
print(db.getMap<dynamic,dynamic>('map')); //{name: thancoder}

// Value Cast

print(db.getValue<bool>('list', def: false)); //false
print(db.getValue<int>('list', def: 1)); // 1
print(db.getValue<double>('list', def: 0.1)); // 0.1
print(db.getValue<String>('list', def: 'i str')); //[1, 2, 3, 4, 5] but String Type

print(db.getValue<List<int>>('list', def: [])); //[1, 2, 3, 4, 5]
print(db.getValue<List<String>>('str_list', def: [])); //[than, coder]
print(db.getValue<Map<String, dynamic>>('map', def: {})); // {name: thancoder}
print(db.getValue<Map<dynamic, dynamic>>('map', def: {}),); // {name: thancoder}
print(db.getValue<List<Map<dynamic, dynamic>>>('map_list', def: []),); //[{name: thancoder}]
```

### Event Listener

```dart
db.event.listen((data) {
  print('event type: ${data.type.name} key:${data.key} - val:${data.value}');
});
```
