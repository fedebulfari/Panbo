import 'package:panbo/buildings.dart';

import 'game_model.dart';

enum Troops {
  brigands(GameItem(name: 'Briganti', icon: '🗡️', cost: 1, wheatCost: 1, woodCost: 3, stoneCost: 1, requirement: Buildings.barracks),),
  knights(GameItem( name: 'Cavalieri', icon: '🐴', cost: 2, wheatCost: 1, woodCost: 3, horseCost: 1, requirement: Buildings.barracks),),
  soldiers(GameItem(name: 'Soldati', icon: '⚔️', cost: 1, wheatCost: 1, woodCost: 3, ironCost: 1, requirement: Buildings.barracks),),
  batteringRam(GameItem(name: 'Arieti', icon: '🔨', cost: 3, wheatCost: 3, woodCost: 5, stoneCost: 3, requirement: Buildings.barracks),),
  trebuchet(GameItem(name: 'Trabucchi', icon: '🎯', cost: 3, wheatCost: 3, woodCost: 10, requirement: Buildings.barracks),),
  caravan(GameItem(name: 'Carovane', icon: '🐫', cost: 3, woodCost: 10, horseCost: 1, requirement: Buildings.barracks),);

  final GameItem item;

  const Troops(this.item);
}
