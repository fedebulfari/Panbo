import 'package:panbo/buildings.dart';
import 'package:panbo/resources.dart';
import 'package:panbo/territories.dart';

import 'game_model.dart';

enum Troops {
  brigands(GameItem(name: 'Briganti', icon: '🗡️', turnCost: {Resources.wheat:1}, constructionCost:{Resources.wheat:1, Resources.wood:3, Resources.stone:1}, reqBuilding: {Buildings.barracks: false})),
  knights(GameItem( name: 'Cavalieri', icon: '🐴', turnCost: {Resources.wheat:3}, constructionCost:{Resources.wheat:1, Resources.wood:3},reqTerritory:  {Territories.horse: true}, reqBuilding: {Buildings.barracks: false})),
  soldiers(GameItem(name: 'Soldati', icon: '⚔️', turnCost: {Resources.wheat:1}, constructionCost:{Resources.wheat:1, Resources.wood:3, Resources.iron:1}, reqBuilding: {Buildings.barracks: false})),
  batteringRam(GameItem(name: 'Arieti', icon: '🔨', turnCost: {Resources.wheat:3}, constructionCost:{Resources.wheat:3, Resources.wood:5, Resources.stone:3}, reqBuilding: {Buildings.barracks: false})),
  batteringRam2(GameItem(name: 'Arieti Pesanti', icon: '🔨', turnCost: {Resources.wheat:3}, constructionCost:{Resources.wheat:3, Resources.wood:5, Resources.iron:1}, reqBuilding: {Buildings.barracks: false})),
  trebuchet(GameItem(name: 'Trabucchi', icon: '🎯', turnCost: {Resources.wheat:3}, constructionCost:{Resources.wheat:3, Resources.wood:10}, reqBuilding: {Buildings.barracks: false})),
  trebuchet2(GameItem(name: 'Sfonda Muro', icon: '🎯', turnCost: {Resources.wheat:3}, constructionCost:{Resources.wheat:3, Resources.wood:20, Resources.iron:1}, reqBuilding: {Buildings.barracks: false})),
  caravan(GameItem(name: 'Carovane', icon: '🐫', turnCost: {Resources.wheat:3}, constructionCost:{Resources.wood:10}, reqTerritory: {Territories.horse: true}, reqBuilding: {Buildings.barracks: false},capacity: 50)),
  caravan2(GameItem(name: 'Carovane Blindate', icon: '🐫', turnCost: {Resources.wheat:5}, constructionCost:{Resources.wood:20, Resources.iron:1}, reqTerritory: {Territories.horse: true}, reqBuilding: {Buildings.barracks: false},capacity: 250));

  final GameItem item;

  const Troops(this.item);
}
