import 'package:panbo/resources.dart';

import 'game_model.dart';

enum Buildings {
  arsenal(GameItem(name: 'Arsenale',icon: '🏰',constructionCost:{Resources.wood:10, Resources.stone:10, Resources.iron:1}, capacity: 250, reqBuilding:{warehouse: true})),
  barracks(GameItem(name: 'Caserma', icon: '🛡️', constructionCost:{Resources.wood:10, Resources.stone:10})),
  bifurcation(GameItem(name: 'Bivio', icon: '🛣️', constructionCost:{Resources.stone:5}, reqBuilding:{road: false}, turnCost: {})),
  bridge(GameItem(name: 'Ponte', icon: '🌉', constructionCost:{Resources.stone:5}, turnCost: {})),
  cityWall(GameItem(name: 'Mura della Città', icon: '城墙', constructionCost:{Resources.stone:20, Resources.iron:2}, reqBuilding:{wall: true}, turnCost: {})),
  forge(GameItem(name: 'Forgia', icon: '⚒️', constructionCost:{Resources.stone:50})),
  harbor(GameItem(name: 'Porto', icon: '⚓', constructionCost:{Resources.wood:30})),
  river(GameItem(name: 'Fiume', icon: '🌊', constructionCost:{Resources.wood:10, Resources.stone:5}, turnCost: {})),
  road(GameItem(name: 'Strada', icon: '🛣️', constructionCost:{Resources.stone:10}, turnCost: {})),
  storageArea( GameItem(name: 'Magazzini all\'aperto', icon: '📦', capacity: 10)),
  temple(GameItem(name: 'Tempio', icon: '⛪', constructionCost:{Resources.stone:50})),
  wall(GameItem(name: 'Muro', icon: '🧱', constructionCost:{Resources.stone:15}, turnCost: {})),
  warehouse(GameItem(name: 'Magazzino',icon: '🏭',constructionCost:{Resources.wood:10,Resources.stone:10},capacity: 50)),
  wharf(GameItem(name: 'Molo', icon: '🛳️', constructionCost:{Resources.wood:10},reqBuilding:{harbor: false}, turnCost: {}));

  final GameItem item;

  const Buildings(this.item);
}
