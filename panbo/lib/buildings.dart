import 'package:panbo/resources.dart';

import 'game_model.dart';

enum Buildings {
  barracks(GameItem(name: 'Caserma', icon: '🛡️', constructionCost:{Resources.wood:10, Resources.stone:10})),
  wall(GameItem(name: 'Muro', icon: '🧱', constructionCost:{Resources.stone:10}, turnCost: {})),
  cityWall(GameItem(name: 'Mura della Città', icon: '城墙', constructionCost:{Resources.stone:10, Resources.iron:1}, reqBuilding:{wall: true}, turnCost: {})),
  forge(GameItem(name: 'Forgia', icon: '⚒️', constructionCost:{Resources.stone:50})),
  harbor(GameItem(name: 'Porto', icon: '⚓', constructionCost:{Resources.wood:30})),
  wharf(GameItem(name: 'Molo', icon: '🛳️', constructionCost:{Resources.wood:10},reqBuilding:{harbor: false}, turnCost: {})),
  river(GameItem(name: 'Fiume', icon: '🌊', constructionCost:{Resources.wood:10, Resources.stone:5}, turnCost: {})),
  bridge(GameItem(name: 'Ponte', icon: '🌉', constructionCost:{Resources.stone:5}, turnCost: {})),
  road(GameItem(name: 'Strada', icon: '🛣️', constructionCost:{Resources.stone:10}, turnCost: {})),
  bifurcation(GameItem(name: 'Bivio', icon: '🛣️', constructionCost:{Resources.stone:5}, reqBuilding:{road: false}, turnCost: {})),
  temple(GameItem(name: 'Tempio', icon: '⛪', constructionCost:{Resources.stone:50})),
  storageArea( GameItem(name: 'Magazzini all\'aperto', icon: '📦', capacity: 10)),
  warehouse(GameItem(name: 'Magazzino',icon: '🏭',constructionCost:{Resources.wood:10,Resources.stone:10},capacity: 50)),
  arsenal(GameItem(name: 'Arsenale',icon: '🏰',constructionCost:{Resources.wood:10, Resources.stone:10, Resources.iron:1}, capacity: 250, reqBuilding:{warehouse: true})),
  ;
  final GameItem item;

  const Buildings(this.item);
}
