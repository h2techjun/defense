import 'dart:convert';
import 'dart:io';
void main() async {
  final f = File('e:/defense/assets/data/enemies.json');
  final txt = await f.readAsString();
  final list = json.decode(txt) as List;
  bool found = false;
  for(var item in list) {
    if(item['id'] == 'strawShoeSpirit') {
      found = true;
      print('FOUND strawShoeSpirit: ${item['id']} / HP: ${item['hp']}');
    }
  }
  print('Total enemies: ${list.length}. Found strawShoeSpirit: $found');
}
