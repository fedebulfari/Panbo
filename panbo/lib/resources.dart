import 'package:panbo/buildings.dart';

import 'game_model.dart';

enum Resources{
	iron(GameItem(name: 'Ferro', icon: '⚙️', constructionCost: {Resources.rawIron:1, Resources.wood:10}, reqBuilding:{Buildings.forge: true}, turnCost: {})),
	wood(GameItem(name: 'Legno', icon: '🪵', turnCost: {})),
	wool(GameItem(name: 'Lana', icon: '🐑', turnCost: {})),
	stone(GameItem(name: 'Pietra', icon: '🪨', turnCost: {})),
	rawIron(GameItem(name: 'Ferro Grezzo', icon: '🔶', turnCost: {})),
	wheat(GameItem(name: 'Grano', icon: '🌾', turnCost: {}));

	final GameItem item;

	Resources(this.item);
}
