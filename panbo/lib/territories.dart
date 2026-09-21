import 'package:panbo/resources.dart';

import 'game_model.dart';

enum Territories {
  field(GameItem(name: 'Campo', icon: '🌾', gain: {Resources.wheat: 3})),
	territory(GameItem(name: 'Territorio', icon: '🌄')),
	mine(GameItem(name: 'Montagna', icon: '🏔️', gain: {Resources.stone: 1})),
  mine2(GameItem(name: 'Miniera', icon: '🏔️', gain: {Resources.stone: 5}, reqTerritory: {mine: true}, constructionCost:{Resources.wood:20,Resources.iron:2})),
	ironMine(GameItem(name: 'Montagna di Ferro', icon: '⛏️', gain: {Resources.rawIron: 1})),
  ironMine2(GameItem(name: 'Miniera di Ferro', icon: '⛏️', gain: {Resources.rawIron: 5}, reqTerritory: {ironMine: true}, constructionCost:{Resources.wood:20,Resources.iron:2})),
	horse(GameItem(name: 'Cavalli', icon: '🐎', constructionCost: {Resources.wheat:6})),
  sheep(GameItem(name: 'Pecore', icon: '🐑', gain: {Resources.wool: 1}, constructionCost: {Resources.wheat:4})),
	forest(GameItem(name: 'Foresta', icon: '🪓', gain: {Resources.wood: 1})),
  carpentry(GameItem(name: 'Falegnameria', icon: '🪓', gain: {Resources.wood: 5}, reqTerritory: {forest:true}, constructionCost:{Resources.wood:10,Resources.iron:2})),
  ;
	final GameItem item;

	const Territories(this.item);
}