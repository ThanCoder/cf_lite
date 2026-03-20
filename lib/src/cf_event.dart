class CFEvent {
  final String key;
  final dynamic value;
  final CFEventType type;
  const CFEvent({required this.key, required this.value, required this.type});

  CFEvent copyWith({String? key, dynamic value, CFEventType? type}) {
    return CFEvent(
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
    );
  }
}

enum CFEventType { put, remove }
