import 'package:flutter/foundation.dart';

enum TurnPhase { event, weather, card, resources, troops, buildings, animals }

extension TurnPhaseLabel on TurnPhase {
  String get label => switch (this) {
        TurnPhase.event => 'Dado evento',
        TurnPhase.weather => 'Dado meteo',
        TurnPhase.card => 'Carta divinazione',
        TurnPhase.resources => 'Raccolta risorse',
        TurnPhase.troops => 'Azioni di guerra',
        TurnPhase.buildings => 'Espansione popolazione',
        TurnPhase.animals => 'Costruzione strutture',
      };
}

class GameItem {
  const GameItem({required this.name, required this.icon, this.cost = 0});
  final String name;
  final String icon;
  final int cost;
}

class GameState extends ChangeNotifier {
  int turn = 1;
  TurnPhase phase = TurnPhase.event;
  String weather = 'Sereno';
  final Map<String, int> resources = {
    'Grano': 10, 'Legno': 10, 'Roccia': 10, 'Ferro': 0, 'Cavalli': 0, 'Pecore': 0,
  };
  final Map<String, int> troops = {
    'Briganti': 0, 'Cavalieri': 0, 'Soldati': 0, 'Arieti': 0, 'Trabucco': 0, 'Carovane': 0,
  };

  void nextPhase() {
    final nextIndex = phase.index + 1;
    if (nextIndex >= TurnPhase.values.length) {
      turn++;
      phase = TurnPhase.event;
      weather = const ['Sereno', 'Vento forte', 'Pioggia', 'Bufera gelida'][turn % 4];
    } else {
      phase = TurnPhase.values[nextIndex];
    }
    notifyListeners();
  }

  void collectResources() {
    for (final key in ['Grano', 'Legno', 'Roccia']) {
      resources[key] = resources[key]! + 1;
    }
    notifyListeners();
  }

  bool recruit(String troop) {
    if (resources['Grano']! < 1) return false;
    resources['Grano'] = resources['Grano']! - 1;
    troops[troop] = troops[troop]! + 1;
    notifyListeners();
    return true;
  }

  void reset() {
    turn = 1;
    phase = TurnPhase.event;
    weather = 'Sereno';
    for (final key in resources.keys) {
      resources[key] = key == 'Grano' || key == 'Legno' || key == 'Roccia' ? 10 : 0;
    }
    for (final key in troops.keys) {
      troops[key] = 0;
    }
    notifyListeners();
  }
}