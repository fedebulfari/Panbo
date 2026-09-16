import 'game_model.dart';

enum Troops {
  brigands(
    GameItem(
      name: 'Briganti',
      icon: '🗡️',
      cost: 1,
      wheatCost: 1,
      woodCost: 3,
      stoneCost: 1,
    ),
  ),
  knights(
    GameItem(
      name: 'Cavalieri',
      icon: '🐴',
      cost: 2,
      wheatCost: 1,
      woodCost: 3,
      horseCost: 1,
    ),
  ),
  soldiers(
    GameItem(
      name: 'Soldati',
      icon: '⚔️',
      cost: 1,
      wheatCost: 1,
      woodCost: 3,
      ironCost: 1,
    ),
  ),
  batteringRam(
    GameItem(
      name: 'Arieti',
      icon: '🔨',
      cost: 3,
      wheatCost: 3,
      woodCost: 5,
      stoneCost: 3,
    ),
  ),
  trebuchet(
    GameItem(
      name: 'Trabucchi',
      icon: '🎯',
      cost: 3,
      wheatCost: 3,
      woodCost: 10,
    ),
  ),
  caravan(
    GameItem(name: 'Carovane', icon: '🐫', cost: 3, woodCost: 10, horseCost: 1),
  );

  final GameItem item;

  const Troops(this.item);
}
