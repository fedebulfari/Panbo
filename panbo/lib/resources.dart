import 'package:panbo/buildings.dart';

import 'game_model.dart';

enum Resources{
	iron(GameItem(name: 'Ferro', icon: '⚙️', constructionCost: {Resources.rawIron:1, Resources.wood:10}, reqBuilding:{Buildings.forge: true})),
	wood(GameItem(name: 'Legno', icon: '🪵')),
	wool(GameItem(name: 'Lana', icon: '🐑')),
	stone(GameItem(name: 'Pietra', icon: '🪨')),
	rawIron(GameItem(name: 'Ferro Grezzo', icon: '🔶')),
	wheat(GameItem(name: 'Grano', icon: '🌾'));

	final GameItem item;

	Resources(this.item);
}
