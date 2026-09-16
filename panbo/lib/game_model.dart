import 'package:flutter/foundation.dart';
import 'package:panbo/boats.dart';
import 'package:panbo/buildings.dart';
import 'package:panbo/resources.dart';
import 'package:panbo/territories.dart';
import 'package:panbo/troops.dart';

enum TurnPhase { weather, gather, payup, expand, cleanup }

extension TurnPhaseLabel on TurnPhase {
  String get label => switch (this) {
    TurnPhase.weather => 'Meteo',
    TurnPhase.gather => 'Raccolta',
    TurnPhase.payup => 'Pagamento',
    TurnPhase.expand => 'Azioni',
    TurnPhase.cleanup => 'Pulizia',
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
    this.ironCost = 0,
    this.horseCost = 0,
    this.woolCost = 0,
    this.capacity = 0,
    this.gain = 0,
    this.territory,
  });
  final String name;
  final String icon;
  final int cost;
  final int wheatCost;
  final int woodCost;
  final int stoneCost;
  final int ironCost;
  final int horseCost;
  final int woolCost;
  final int capacity;
  final int gain;
  final Territories? territory;
}

class GameState extends ChangeNotifier {
  int turn = 1;
  TurnPhase phase = TurnPhase.weather;
  bool isCold = false; // Se true, l'inverno raddoppia i costi delle truppe
  int currentDeficit = 0;
  bool get hasDeficit => currentDeficit > 0;
  int currentExcess = 0;
  bool get hasExcess => currentExcess > 0;

  // Traccia quanti fiumi bagnano ciascun campo
  Map<int, int> fieldIrrigation = {}; 

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
    for (final key in resources.keys) {
      if (key == Resources.wheat.item) {
        int totalWheatGain = 0;
        // Calcola il guadagno di ogni campo in base ai fiumi collegati
        fieldIrrigation.forEach((fieldIndex, riversCount) {
          int baseGain = Territories.field.item.gain;
          totalWheatGain += baseGain * (riversCount > 0 ? riversCount : 1);
        });
        resources[key] = (resources[key] ?? 0) + totalWheatGain;
      } else {
        if (key.territory != null) {
          int currentResourceAmount = resources[key] ?? 0;
          int territoryGain = key.territory!.item.gain;
          int territoryCount = territories[key.territory!.item] ?? 0;

          resources[key] = currentResourceAmount + (territoryGain * territoryCount);
        }
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
    return 0; // Risorse o imbarcazioni non costano mantenimento qui
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
      resources[Resources.wheat.item] = 0; // Abbiamo speso tutto il grano possibile
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
      
      // Se si distrugge un campo, eliminiamo la sua irrigazione
      if (item == Territories.field.item && fieldIrrigation.isNotEmpty) {
        fieldIrrigation.remove(fieldIrrigation.keys.last);
      }
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

        if (territoryToRemove == Territories.field.item && fieldIrrigation.isNotEmpty) {
          fieldIrrigation.remove(fieldIrrigation.keys.last);
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
    int newIndex = fieldIrrigation.isNotEmpty ? fieldIrrigation.keys.last + 1 : 0;
    fieldIrrigation[newIndex] = rivers;
    notifyListeners();
  }

  void addRiverWithFields(int fieldsConnected) {
    if (fieldsConnected < 0) fieldsConnected = 0;
    if (fieldsConnected > 2) fieldsConnected = 2;

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
    return (resources[Resources.wheat.item] ?? 0) >= item.wheatCost &&
        (resources[Resources.wood.item] ?? 0) >= item.woodCost &&
        (resources[Resources.stone.item] ?? 0) >= item.stoneCost &&
        (resources[Resources.iron.item] ?? 0) >= item.ironCost &&
        (territories[Territories.horse.item] ?? 0) >= item.horseCost &&
        (resources[Resources.wool.item] ?? 0) >= item.woolCost;
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
        
        // Se eliminiamo un campo, dobbiamo rimuovere un'irrigazione
        if (item == Territories.field.item && newCount >= 0) {
          if (fieldIrrigation.isNotEmpty) {
             fieldIrrigation.remove(fieldIrrigation.keys.last);
          }
        }
        break;
      }
    }
    notifyListeners();
  }

  void setWeather(bool cold) {
    isCold = cold;
    notifyListeners();
  }

  void reset() {
    turn = 1;
    currentDeficit = 0;
    currentExcess = 0; 
    isCold = false;
    phase = TurnPhase.weather;
    fieldIrrigation.clear();
    
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