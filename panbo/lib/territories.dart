import 'package:panbo/resources.dart';

import 'game_model.dart';

enum Territories {
  field(GameItem(name: 'Campo', icon: '🌾', gain: {Resources.wheat: 2})),
	territory(GameItem(name: 'Territorio', icon: '🌄')),
  mountain(GameItem(name: 'Montagna', icon: '🏔️', gain: {Resources.stone: 1}, turnCost:{Resources.wheat:5})),
	mine(GameItem(name: 'Miniera', icon: '🏔️', gain: {Resources.stone: 3}, constructionCost:{Resources.wood:10, Resources.stone:3}, reqTerritory: {mountain: true})),
  mine2(GameItem(name: 'Impianto Minierario', icon: '🏔️', gain: {Resources.stone: 10}, reqTerritory: {mine: true}, constructionCost:{Resources.iron:2})),
  ironMountain(GameItem(name: 'Montagna di ferro', icon: '⛏️', gain: {Resources.rawIron: 1}, turnCost:{Resources.wheat:5})),
	ironMine(GameItem(name: 'Miniera di Ferro', icon: '⛏️', gain: {Resources.rawIron: 3},reqTerritory: {ironMountain: true}, constructionCost:{Resources.wood:10, Resources.stone:3},)),
  ironMine2(GameItem(name: 'Impianto Minierario di Ferro', icon: '⛏️', gain: {Resources.rawIron: 10}, reqTerritory: {ironMine: true}, constructionCost:{Resources.iron:2})),
	horse(GameItem(name: 'Cavalli', icon: '🐎', constructionCost: {Resources.wool:6})),
  sheep(GameItem(name: 'Pecore', icon: '🐑', gain: {Resources.wool: 1}, constructionCost: {Resources.wool:4})),
	forest(GameItem(name: 'Foresta', icon: '🪓', gain: {Resources.wood: 1})),
  carpentry(GameItem(name: 'Carpenteria', icon: '🪓', constructionCost: {Resources.wood: 5, Resources.stone: 3}, reqTerritory: {forest:true}, gain: {Resources.wood: 3})),
  joinery(GameItem(name: 'Segheria', icon: '🪓', constructionCost: {Resources.iron: 2}, reqTerritory: {carpentry:true}, gain: {Resources.wood: 10})),
  ;
	final GameItem item;

	const Territories(this.item);
}