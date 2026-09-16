import 'package:panbo/territories.dart';

import 'game_model.dart';

enum Resources{
	iron(GameItem(name: 'Ferro', icon: '⚙️',)),
	wood(GameItem(name: 'Legno', icon: '🪵', territory: Territories.forest)),
	wool(GameItem(name: 'Lana', icon: '🐑', territory: Territories.sheep)),
	stone(GameItem(name: 'Pietra', icon: '🪨', territory: Territories.mine)),
	rawIron(GameItem(name: 'Ferro Grezzo', icon: '🔶', territory: Territories.ironMine)),
	wheat(GameItem(name: 'Grano', icon: '🌾', territory: Territories.field));

	final GameItem item;

	const Resources(this.item);
}
