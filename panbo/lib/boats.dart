import 'game_model.dart';

enum Boats {
  brigade(GameItem(name: 'Brigata',icon: '⛵', woodCost: 50,woolCost: 30, ironCost: 3,capacity: 200)),
  galleon(GameItem(name: 'Galeone',icon: '🚢', woodCost: 20,woolCost: 15,capacity: 50)),
  raft(GameItem(name: 'Zattera', icon: '🛶', woodCost: 10, capacity: 20));

  final GameItem item;
  
  const Boats(this.item);
}
