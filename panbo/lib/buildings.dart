import 'game_model.dart';

enum Buildings {
  arsenal(GameItem(name: 'Arsenale',icon: '🏰',woodCost: 10,stoneCost: 10, ironCost: 1,capacity: 250, requirement: warehouse)),
  barracks(GameItem(name: 'Caserma', icon: '🛡️', woodCost: 10, stoneCost: 10)),
  bifurcation(GameItem(name: 'Bivio', icon: '🛣️', stoneCost: 5, requirement: road)),
  bridge(GameItem(name: 'Ponte', icon: '🌉', stoneCost: 5)),
  cityWall(GameItem(name: 'Mura della Città', icon: '城墙', stoneCost: 20, ironCost: 2, requirement: wall)),
  forge(GameItem(name: 'Forgia', icon: '⚒️', stoneCost: 50)),
  harbor(GameItem(name: 'Porto', icon: '⚓', woodCost: 30)),
  river(GameItem(name: 'Fiume', icon: '🌊', woodCost: 10, stoneCost: 5)),
  road(GameItem(name: 'Strada', icon: '🛣️', stoneCost: 10)),
  storageArea( GameItem(name: 'Magazzini all\'aperto', icon: '🏗️', capacity: 10)),
  temple(GameItem(name: 'Tempio', icon: '⛪', stoneCost: 50)),
  wall(GameItem(name: 'Muro', icon: '🧱', stoneCost: 15)),
  warehouse(GameItem(name: 'Magazzino',icon: '🏭',woodCost: 10,stoneCost: 10,capacity: 50)),
  wharf(GameItem(name: 'Molo', icon: '🛳️', woodCost: 10));

  final GameItem item;

  const Buildings(this.item);
}
