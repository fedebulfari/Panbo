import 'package:flutter/foundation.dart';
import 'package:panbo/boats.dart';
import 'package:panbo/buildings.dart';
import 'package:panbo/resources.dart';
import 'package:panbo/territories.dart';
import 'package:panbo/troops.dart';

enum TurnPhase { weather, gather, payup, expand, cleanup }

extension TurnPhaseLabel on TurnPhase {
  String get label => switch (this) {
    TurnPhase.weather => 'Setup',
    TurnPhase.gather => 'Raccolta',
    TurnPhase.payup => 'Pagamento',
    TurnPhase.expand => 'Azioni',
    TurnPhase.cleanup => 'Pulizia',
  };
}
enum WeatherType { cold, warm, sunny, rainy, stormy }

extension WeatherTypeLabel on WeatherType {
  String get label => switch (this) {
    WeatherType.cold => 'Bufera Gelida',
    WeatherType.warm => 'Caldo Torrido',
    WeatherType.sunny => 'Soleggiato',
    WeatherType.rainy => 'Piovoso',
    WeatherType.stormy => 'Tempestoso',
  };
}

class GameItem {
  const GameItem({
    required this.name,
    required this.icon,
    this.cost = 1,
    this.wheatCost = 0,
    this.woodCost = 0,
    this.stoneCost = 0,
    this.rawIronCost=0,
    this.ironCost = 0,
    this.horseCost = 0,
    this.woolCost = 0,
    this.capacity = 0,
    this.gain = 0,
    this.territory,
    this.requirement,
  });
  final String name;
  final String icon;
  final int cost;
  final int wheatCost;
  final int woodCost;
  final int stoneCost;
  final int ironCost;
  final int rawIronCost;
  final int horseCost;
  final int woolCost;
  final int capacity;
  final int gain;
  final Territories? territory;
  final Buildings? requirement;
}

class GameState extends ChangeNotifier {
  int turn = 1;
  int irrigatedfields = 0; 
  TurnPhase phase = TurnPhase.weather;
  bool isRainy = false;
  bool isCold = false;
  WeatherType currentWeather = WeatherType.sunny;
  int currentDeficit = 0;
  bool get hasDeficit => currentDeficit > 0;
  int currentExcess = 0;
  bool get hasExcess => currentExcess > 0;

  final Map<GameItem, int> resources = {
    for (final territory in Resources.values) territory.item: 0,
  };
  final Map<GameItem, int> troops = {
    for (final troop in Troops.values) troop.item: 0,
  };
  final Map<GameItem, int> buildings = {
    for (final building in Buildings.values) building.item: 0,
  };
  final Map<GameItem, int> territories = {
    for (final territory in Territories.values) territory.item: 0,
  };
  final Map<GameItem, int> boats = {
    for (final boat in Boats.values) boat.item: 0,
  };

  void nextPhase() {
    final nextIndex = phase.index + 1;
    if (nextIndex >= TurnPhase.values.length) {
      turn++;
      phase = TurnPhase.weather;
    } else {
      phase = TurnPhase.values[nextIndex];
    }

    if (phase == TurnPhase.payup) {
      _processPayUp();
    } else if (phase == TurnPhase.cleanup) {
      _processCleanup();
    }
    notifyListeners();
  }

  int get totalCapacity {
    int cap = 0;
    buildings.forEach((item, count) => cap += item.capacity * count);
    return cap;
  }

  int get totalResourcesAmount {
    return resources.values.fold(0, (sum, amount) => sum + amount);
  }

  void _processCleanup() {
    int capacity = totalCapacity;
    if (capacity == 0) {
      for (final key in resources.keys) {
        resources[key] = 0;
      }
      currentExcess = 0;
    } else {
      int amount = totalResourcesAmount;
      if (amount > capacity) {
        currentExcess = amount - capacity;
      } else {
        currentExcess = 0;
      }
    }
  }

  void discardResource(GameItem resource) {
    if (currentExcess > 0 && (resources[resource] ?? 0) > 0) {
      resources[resource] = resources[resource]! - 1;
      currentExcess--;
      notifyListeners();
    }
  }

  void collectResources() {
    // 1. Calcola la produzione del grano
    int wheatGain = Territories.field.item.gain * irrigatedfields;
    
    // 2. Se c'è un temporale, la PRODUZIONE viene dimezzata (usando la divisione intera '~/')
    if (currentWeather == WeatherType.stormy) {
      wheatGain = wheatGain ~/ 2;
    }
    
    resources[Resources.wheat.item] = (resources[Resources.wheat.item] ?? 0) + wheatGain;

    for (final key in resources.keys) {
      if (key.territory != null && key != Resources.wheat.item) {
        int currentResourceAmount = resources[key] ?? 0;
        int territoryGain = key.territory!.item.gain;
        int territoryCount = territories[key.territory!.item] ?? 0;

        resources[key] = currentResourceAmount + (territoryGain * territoryCount);
      }
    }
    notifyListeners();
  }

  int getItemUpkeep(GameItem item) {
    int multiplier = isCold ? 2 : 1;
    if (buildings.containsKey(item)) return item.cost;
    if (troops.containsKey(item)) return item.cost * multiplier;
    if (territories.containsKey(item)) {
      return item.wheatCost > 0 ? item.wheatCost : item.cost;
    }
    return 0;
  }

  void _processPayUp() {
    int totalWheatRequired = 0;

    for (final key in buildings.keys) {
      totalWheatRequired += getItemUpkeep(key) * buildings[key]!;
    }
    for (final key in troops.keys) {
      totalWheatRequired += getItemUpkeep(key) * troops[key]!;
    }
    for (final key in territories.keys) {
      totalWheatRequired += getItemUpkeep(key) * territories[key]!;
    }

    int currentWheat = resources[Resources.wheat.item] ?? 0;
    if (currentWheat >= totalWheatRequired) {
      resources[Resources.wheat.item] = currentWheat - totalWheatRequired;
      currentDeficit = 0;
    } else {
      currentDeficit = totalWheatRequired - currentWheat;
      resources[Resources.wheat.item] = 0;
    }
  }

  void sacrificeItem(GameItem item) {
    if (currentDeficit <= 0) return;

    int upkeepSaved = getItemUpkeep(item);
    if (upkeepSaved == 0) return;

    if (buildings.containsKey(item) && buildings[item]! > 0) {
      buildings[item] = buildings[item]! - 1;
    } else if (troops.containsKey(item) && troops[item]! > 0) {
      troops[item] = troops[item]! - 1;
    } else if (territories.containsKey(item) && territories[item]! > 0) {
      territories[item] = territories[item]! - 1;
      if (item == Territories.field.item) irrigatedfields = irrigatedfields > 0 ? irrigatedfields - 1 : 0;
    } else {
      return;
    }

    currentDeficit -= upkeepSaved;
    if (currentDeficit < 0) currentDeficit = 0;
    notifyListeners();
  }

  List<GameItem> get disposableItems {
    List<GameItem> list = [];
    list.addAll(
      territories.entries
          .where((e) => e.value > 0 && getItemUpkeep(e.key) > 0)
          .map((e) => e.key),
    );
    list.addAll(
      troops.entries
          .where((e) => e.value > 0 && getItemUpkeep(e.key) > 0)
          .map((e) => e.key),
    );
    list.addAll(
      buildings.entries
          .where((e) => e.value > 0 && getItemUpkeep(e.key) > 0)
          .map((e) => e.key),
    );
    return list;
  }

  void payUp(bool isCold) {
    int multiplier = isCold ? 2 : 1;
    int currentWheat = resources[Resources.wheat.item] ?? 0;
    int totalWheatRequired = 0;

    for (final key in buildings.keys) {
      totalWheatRequired += key.cost * buildings[key]!;
    }
    for (final key in troops.keys) {
      totalWheatRequired += key.cost * multiplier * troops[key]!;
    }
    for (final key in territories.keys) {
      int terrCost = key.wheatCost > 0 ? key.wheatCost : key.cost;
      totalWheatRequired += terrCost * territories[key]!;
    }
    if (currentWheat >= totalWheatRequired) {
      resources[Resources.wheat.item] = currentWheat - totalWheatRequired;
    } else {
      int deficit = totalWheatRequired - currentWheat;
      resources[Resources.wheat.item] = 0; 
      while (deficit > 0) {
        var ownedTerritories = territories.entries
            .where((e) => e.value > 0)
            .toList();
        if (ownedTerritories.isEmpty) {
          break;
        }

        var territoryToRemove = ownedTerritories.last.key;
        territories[territoryToRemove] = territories[territoryToRemove]! - 1;
        if (territoryToRemove == Territories.field.item) {
          irrigatedfields = irrigatedfields > 0 ? irrigatedfields - 1 : 0;
        }
        int costSaved = territoryToRemove.wheatCost > 0
            ? territoryToRemove.wheatCost
            : territoryToRemove.cost;
        deficit -= costSaved;

        if (kDebugMode) {
          print(
            'Deficit! Perso 1 ${territoryToRemove.name} per ripagare $costSaved grano.',
          );
        }
      }
    }
    notifyListeners();
  }

  void addFieldWithRivers(int rivers) {
    if (rivers < 0) rivers = 0;
    if (rivers > 6) rivers = 6;
    
    territories[Territories.field.item] = (territories[Territories.field.item] ?? 0) + 1;
    irrigatedfields = irrigatedfields + rivers;
    notifyListeners();
  }

  void addRiverWithFields(int fieldsConnected, int fieldIndex) {
    if (fieldsConnected < 0) fieldsConnected = 0;
    if (fieldsConnected > 2) fieldsConnected = 2;
    irrigatedfields = irrigatedfields + fieldsConnected;
    buildings[Buildings.river.item] = (buildings[Buildings.river.item] ?? 0) + 1;
    notifyListeners();
  }

  void action(GameItem item) {
    if (canAction(item)) {
      resources[Resources.wheat.item] =
          (resources[Resources.wheat.item] ?? 0) - item.wheatCost;
      resources[Resources.wood.item] =
          (resources[Resources.wood.item] ?? 0) - item.woodCost;
      resources[Resources.stone.item] =
          (resources[Resources.stone.item] ?? 0) - item.stoneCost;
      resources[Resources.iron.item] =
          (resources[Resources.iron.item] ?? 0) - item.ironCost;
      territories[Territories.horse.item] =
          (territories[Territories.horse.item] ?? 0) - item.horseCost;
      resources[Resources.wool.item] =
          (resources[Resources.wool.item] ?? 0) - item.woolCost;
      resources[Resources.rawIron.item]=
          (resources[Resources.rawIron.item] ?? 0) - item.rawIronCost;
      if(item.requirement!=null && item.requirement!=Buildings.road && item.requirement!=Buildings.forge && item.requirement!=Buildings.barracks) {
        buildings[item.requirement!.item]=(buildings[item.requirement!.item]??0)-1;
      }
      if (Troops.values.any((troop) => troop.item == item)) {
        final troop = Troops.values.firstWhere((troop) => troop.item == item);
        troops[troop.item] = (troops[troop.item] ?? 0) + 1;
      } else if (Buildings.values.any((building) => building.item == item)) {
        final building = Buildings.values.firstWhere(
          (building) => building.item == item,
        );
        buildings[building.item] = (buildings[building.item] ?? 0) + 1;
      } else if (Boats.values.any((boat) => boat.item == item)) {
        final boat = Boats.values.firstWhere((boat) => boat.item == item);
        boats[boat.item] = (boats[boat.item] ?? 0) + 1;
      } else if (Territories.values.any(
        (territory) => territory.item == item,
      )) {
        final territory = Territories.values.firstWhere(
          (territory) => territory.item == item,
        );
        territories[territory.item] = (territories[territory.item] ?? 0) + 1;
      }
      notifyListeners();
    }
  }

  bool canAction(GameItem item) {
    if (item.requirement != null) {
      int reqCount = (buildings[item.requirement!.item] ?? 0) +
                     (territories[item.requirement!.item] ?? 0) +
                     (troops[item.requirement!.item] ?? 0) +
                     (boats[item.requirement!.item] ?? 0);
                     
      if (reqCount <= 0) return false;
    }

    return (resources[Resources.wheat.item] ?? 0) >= item.wheatCost &&
        (resources[Resources.wood.item] ?? 0) >= item.woodCost &&
        (resources[Resources.stone.item] ?? 0) >= item.stoneCost &&
        (resources[Resources.iron.item] ?? 0) >= item.ironCost &&
        (territories[Territories.horse.item] ?? 0) >= item.horseCost &&
        (resources[Resources.wool.item] ?? 0) >= item.woolCost &&
        (resources[Resources.rawIron.item] ?? 0) >= item.rawIronCost;
  }

  bool canRemove(GameItem item) {
    Buildings? targetBuilding;
    for (var b in Buildings.values) {
       if (b.item == item) {
          targetBuilding = b;
          break;
       }
    }
    if (targetBuilding == null) return true; 

    int itemCurrentCount = (buildings[item] ?? 0) + (troops[item] ?? 0) + (boats[item] ?? 0) + (territories[item] ?? 0) + (resources[item] ?? 0);
    if (itemCurrentCount > 1) return true; // Ne resterebbe almeno 1.

    final allItems = [
      ...Resources.values.map((e) => e.item),
      ...Troops.values.map((e) => e.item),
      ...Boats.values.map((e) => e.item),
      ...Territories.values.map((e) => e.item),
      ...Buildings.values.map((e) => e.item),
    ];

    for (var other in allItems) {
       if (other.requirement == targetBuilding) {
          bool isConsumedUpgrade = (other.requirement != Buildings.road && 
                                    other.requirement != Buildings.forge && 
                                    other.requirement != Buildings.barracks);
                             
          if (!isConsumedUpgrade) {
              int count = (resources[other] ?? 0) + (troops[other] ?? 0) + (boats[other] ?? 0) + (territories[other] ?? 0) + (buildings[other] ?? 0);
              if (count > 0) return false; // C'è un pezzo dipendente in gioco, non puoi distruggerlo!
          }
       }
    }
    return true;
  }

  void kill(GameItem item, {int amount = 1}) {
    final allMaps = [
      resources,
      troops,
      buildings,
      territories,
      boats,
    ];
    for (final map in allMaps) {
      if (map.containsKey(item)) {
        final currentCount = map[item] ?? 0;
        final newCount = currentCount - amount;
        map[item] = newCount > 0 ? newCount : 0;
        if (item == Territories.field.item && newCount >= 0) {
          irrigatedfields = irrigatedfields > 0 ? irrigatedfields - 1 : 0;
        }
        break;
      }
    }
    notifyListeners();
  }

  void setWeather(WeatherType weather) {
    currentWeather = weather; // <-- IL BUG ERA QUI!
    isCold = switch (weather) {
      WeatherType.cold => true,
      WeatherType.warm => false,
      _ => isCold,
    };
    isRainy = switch (weather) {
      WeatherType.rainy => true,
      WeatherType.stormy => true,
      _ => false,
    };
    notifyListeners();
  }

  void reset() {
    turn = 1;
    currentDeficit = 0;
    currentExcess = 0;
    isRainy = false; 
    isCold = false;
    currentWeather = WeatherType.sunny;
    phase = TurnPhase.weather;
    irrigatedfields = 0;
  
    for (final key in resources.keys) {
      resources[key] = 0;
    }
    for (final key in troops.keys) {
      troops[key] = 0;
    }
    for (final key in buildings.keys) {
      buildings[key] = 0;
    }
    for (final key in territories.keys) {
      territories[key] = 0;
    }
    for (final key in boats.keys) {
      boats[key] = 0;
    }
    notifyListeners();
  }
}