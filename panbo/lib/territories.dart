import 'game_model.dart';

enum Territories {
	mine(GameItem(name: 'Miniera', icon: '⛏️', gain: 1)),
	field(GameItem(name: 'Campo', icon: '🌾', gain: 3)),
	territory(GameItem(name: 'Territorio', icon: '🌄')),
	horse(GameItem(name: 'Cavalli', icon: '🐎', wheatCost: 6, cost: 0)),
	ironMine(GameItem(name: 'MinieraDiFerro', icon: '🧨', gain: 1)),
	sheep(GameItem(name: 'Pecore', icon: '🐑', gain: 1, wheatCost: 4, cost: 0)),
	forest(GameItem(name: 'Foresta', icon: '🪓', gain: 1));

	final GameItem item;

	const Territories(this.item);
}