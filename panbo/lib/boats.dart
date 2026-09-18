import 'package:panbo/buildings.dart';
import 'package:panbo/resources.dart';
import 'game_model.dart';

enum Boats {
  brigade(GameItem(name: 'Brigata',icon: '⛵', constructionCost:{Resources.wood:60, Resources.wool:30, Resources.iron:2}, capacity: 350, reqBuilding:{Buildings.harbor: true}, turnCost: {})),
  galleon(GameItem(name: 'Galeone',icon: '🚢', constructionCost:{Resources.wood:30, Resources.wool:15}, capacity: 100, reqBuilding:{Buildings.harbor: true}, turnCost: {})),
  raft(GameItem(name: 'Zattera', icon: '🛶', constructionCost:{Resources.wood:20}, capacity: 30, reqBuilding:{Buildings.harbor: true}, turnCost: {}));

  final GameItem item;
  
  const Boats(this.item);
}
