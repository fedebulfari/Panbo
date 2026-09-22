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
    Map<Resources, int>? turnCost, 
    this.constructionCost = const {},
    this.capacity = 0,
    this.gain = const {},
    this.reqTerritory = const {},
    this.reqBuilding= const {},
  // ignore: prefer_initializing_formals
  }) : _turnCost = turnCost; 

  final String name;
  final String icon;
  
  final Map<Resources, int>? _turnCost; 
  
  Map<Resources, int> get turnCost => _turnCost ?? const {Resources.wheat: 1};

  final Map<Resources, int> constructionCost;
  final int capacity;
  final Map<Resources, int> gain;
  final Map<Territories, bool> reqTerritory;
  final Map<Buildings, bool> reqBuilding;
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
    boats.forEach((item, count) => cap += item.capacity * count);
    troops.forEach((item, count) => cap += item.capacity * count);
    return cap;
  }

  int get totalResourcesAmount {
    return resources.values.fold(0, (sum, amount) => sum + amount);
  }

  void _applyRainDamage() {
    int openCapacity = (buildings[Buildings.storageArea.item] ?? 0) * Buildings.storageArea.item.capacity;
    
    int safeCapacity = totalCapacity - openCapacity;

    int wheat = resources[Resources.wheat.item] ?? 0;
    int wood = resources[Resources.wood.item] ?? 0;

    int remainingSafe = safeCapacity;

    int safeWheat = (wheat < remainingSafe) ? wheat : remainingSafe;
    remainingSafe -= safeWheat;

    int safeWood = (wood < remainingSafe) ? wood : remainingSafe;
    remainingSafe -= safeWood;

    int exposedWheat = wheat - safeWheat;
    int exposedWood = wood - safeWood;

    if (exposedWheat > 0 || exposedWood > 0) {
      resources[Resources.wheat.item] = safeWheat;
      resources[Resources.wood.item] = safeWood + (exposedWood ~/ 2); 
      
      if (kDebugMode) {
        print('Pioggia! Perso $exposedWheat grano e ${exposedWood - (exposedWood ~/ 2)} legno rimasti all\'aperto.');
      }
    }
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
    int wheatGain = 0;
    
    for (final key in territories.keys) {
      int territoryCount = territories[key] ?? 0;
      if (territoryCount <= 0) continue;
      int activeCount = territoryCount;
      Map<GameItem, int> operationalCosts = {};
      
      for (var cost in key.turnCost.entries) {
        if (cost.key != Resources.wheat) {
          operationalCosts[cost.key.item] = cost.value;
        }
      }

      if (operationalCosts.isNotEmpty) {
        for (var opCost in operationalCosts.entries) {
          int available = resources[opCost.key] ?? 0;
          int maxAffordable = available ~/ opCost.value;
          if (maxAffordable < activeCount) {
            activeCount = maxAffordable;
          }
        }
        for (var opCost in operationalCosts.entries) {
          resources[opCost.key] = (resources[opCost.key] ?? 0) - (opCost.value * activeCount);
        }
      }

      for (final resource in key.gain.entries) {
        if(resource.key != Resources.wheat){
          int currentResourceAmount = resources[resource.key.item] ?? 0;
          resources[resource.key.item] = currentResourceAmount + (resource.value * activeCount);
        }
      }
    } 

    wheatGain += irrigatedfields * Territories.field.item.gain[Resources.wheat]!;
    if (currentWeather == WeatherType.stormy) {
      wheatGain = wheatGain ~/ 2;
    }
    resources[Resources.wheat.item] = (resources[Resources.wheat.item] ?? 0) + wheatGain;
    notifyListeners();
  }
  
  int getItemUpkeep(GameItem item) {
    int total = 0;
    for (var cost in item.turnCost.entries) {
      // Il grano è l'unico costo di "sopravvivenza" che genera debito/distruzione
      if (cost.key == Resources.wheat) {
        int multiplier = (isCold && troops.containsKey(item) && cost.key == Resources.wheat) ? 2 : 1;
        total += cost.value * multiplier;
      }
    }
    return total;
  }

  void _processPayUp() {
    Map<GameItem, int> requiredResources = {};

    // Calcola SOLO i costi in Grano (Sopravvivenza). I costi operativi sono già stati pagati nella Raccolta.
    for (final key in buildings.keys) {
      for (final res in key.turnCost.entries) {
        if (res.key == Resources.wheat) {
          requiredResources[res.key.item] = (requiredResources[res.key.item] ?? 0) + (res.value * buildings[key]!);
        }
      }
    }
    for (final key in troops.keys) {
      for (final res in key.turnCost.entries) {
        if (res.key == Resources.wheat) {
          int multiplier = (isCold && res.key == Resources.wheat) ? 2 : 1;
          requiredResources[res.key.item] = (requiredResources[res.key.item] ?? 0) + (res.value * multiplier * troops[key]!);
        }
      }
    }
    for (final key in territories.keys) {
      for (final res in key.turnCost.entries) {
        if (res.key == Resources.wheat) {
          requiredResources[res.key.item] = (requiredResources[res.key.item] ?? 0) + (res.value * territories[key]!);
        }
      }
    }

    int totalMissing = 0;

    requiredResources.forEach((resItem, amountRequired) {
      int currentAmount = resources[resItem] ?? 0;
      if (currentAmount >= amountRequired) {
        resources[resItem] = currentAmount - amountRequired;
      } else {
        totalMissing += (amountRequired - currentAmount);
        resources[resItem] = 0;
      }
    });

    currentDeficit = totalMissing;
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

  void addFieldWithRivers(int rivers) {
    if (rivers < 0) rivers = 0;
    if (rivers > 6) rivers = 6;
    
    irrigatedfields = irrigatedfields + rivers;
    notifyListeners();
  }

  void addRiverWithFields(int fieldsConnected, int fieldIndex) {
    if (fieldsConnected < 0) fieldsConnected = 0;
    if (fieldsConnected > 2) fieldsConnected = 2;
    irrigatedfields = irrigatedfields + fieldsConnected;
    notifyListeners();
  }

  void removeIrrigation(int amount) {
    irrigatedfields -= amount;
    if (irrigatedfields < 0) irrigatedfields = 0;
    notifyListeners();
  }

  void action(GameItem item) {
    if (canAction(item)) {
      for(final cost in item.constructionCost.entries) {
        resources[cost.key.item] = (resources[cost.key.item] ?? 0) - cost.value;
      }
      
      for(final ter in item.reqTerritory.entries) {
        if(ter.value) {
          territories[ter.key.item] = (territories[ter.key.item] ?? 0) - 1;
        }
      }
      
      for(final build in item.reqBuilding.entries) {
        if(build.value) {
          buildings[build.key.item] = (buildings[build.key.item] ?? 0) - 1;
        }
      }
      
      if (Troops.values.any((troop) => troop.item == item)) {
        troops[item] = (troops[item] ?? 0) + 1;
      } else if (Buildings.values.any((building) => building.item == item)) {
        buildings[item] = (buildings[item] ?? 0) + 1;
      } else if (Boats.values.any((boat) => boat.item == item)) {
        boats[item] = (boats[item] ?? 0) + 1;
      } else if (Territories.values.any((territory) => territory.item == item)) {
        territories[item] = (territories[item] ?? 0) + 1;
      }
      notifyListeners();
    }
  }

  bool canAction(GameItem item) {
    for(final req in item.reqBuilding.entries) {
      if (req.value) {
        int reqCount = (buildings[req.key.item] ?? 0);     
        if (reqCount < 1) return false;
      }
    }
    for(final req in item.reqTerritory.entries) {
      if (req.value) {
        int reqCount = (territories[req.key.item] ?? 0);
        if (reqCount < 1) return false;
      }
    }
    for(final cost in item.constructionCost.entries) {
      int resCount = (resources[cost.key.item] ?? 0);
      if (resCount < cost.value) return false;
    }
    return true;
  }

  bool canRemove(GameItem item) {
    int currentCount = (buildings[item] ?? 0) + 
                       (troops[item] ?? 0) + 
                       (boats[item] ?? 0) + 
                       (territories[item] ?? 0) + 
                       (resources[item] ?? 0);

    return currentCount > 0;
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
        break;
      }
    }
    notifyListeners();
  }

  void setWeather(WeatherType weather) {
    currentWeather = weather;
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
    if (isRainy) {
      _applyRainDamage();
    }
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