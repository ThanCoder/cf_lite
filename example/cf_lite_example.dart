import 'package:cf_lite/src/cf_lite_base.dart';

void main() async {
  final db = CFLite.getInstance();
  await db.init(dbPath: 'test.db.json');

  db.event.listen((data) {
    print('event type: ${data.type.name} key:${data.key} - val:${data.value}');
  });
}
