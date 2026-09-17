import 'package:flutter/material.dart';
import 'package:panbo/boats.dart';
import 'package:panbo/buildings.dart';
import 'package:panbo/resources.dart';
import 'package:panbo/territories.dart';
import 'package:panbo/troops.dart';

import 'game_model.dart';

void main() => runApp(const PanboApp());

class PanboApp extends StatelessWidget {
  const PanboApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Panbo',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF3E5AB),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
          useMaterial3: true,
          fontFamily: 'Courier', 
        ),
        home: const GamePage(),
      );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final game = GameState();
  
  int _currentIndex = 0;
  final Set<GameItem> _doubledProductionResources = {};
  
  final Map<GameItem, int> _stagedChanges = {};
  final List<int> _stagedFieldConfigs = [];
  final List<int> _stagedRiverConfigs = [];
  final Map<GameItem, int> _stagedConqueredAnimals = {}; 

  // Funzione Suprema: Simula il carrello in tempo reale e interroga game_model.dart
  bool _simulateAndCheck(bool Function(GameState) checkFn) {
    final backupResources = Map<GameItem, int>.from(game.resources);
    final backupBuildings = Map<GameItem, int>.from(game.buildings);
    final backupTerritories = Map<GameItem, int>.from(game.territories);
    final backupTroops = Map<GameItem, int>.from(game.troops);
    final backupBoats = Map<GameItem, int>.from(game.boats);
    final int backupIrrigated = game.irrigatedfields;

    _stagedChanges.forEach((stagedItem, count) {
      if (count > 0) {
        int conquered = _stagedConqueredAnimals[stagedItem] ?? 0;
        game.resources[Resources.wheat.item] = (game.resources[Resources.wheat.item] ?? 0) + (stagedItem.wheatCost * conquered);

        for (int i = 0; i < count; i++) {
          game.action(stagedItem);
          // Permette l'aggiunta di risorse craftate
          if (Resources.values.any((r) => r.item == stagedItem)) {
            game.resources[stagedItem] = (game.resources[stagedItem] ?? 0) + 1;
          }
        }
      } else if (count < 0) {
        if (Resources.values.any((r) => r.item == stagedItem)) {
          game.resources[stagedItem] = (game.resources[stagedItem] ?? 0) - (-count);
        } else {
          game.kill(stagedItem, amount: -count);
        }
      }
    });

    bool result = checkFn(game);

    game.resources.clear(); game.resources.addAll(backupResources);
    game.buildings.clear(); game.buildings.addAll(backupBuildings);
    game.territories.clear(); game.territories.addAll(backupTerritories);
    game.troops.clear(); game.troops.addAll(backupTroops);
    game.boats.clear(); game.boats.addAll(backupBoats);
    game.irrigatedfields = backupIrrigated;

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final resources = Resources.values.map((resource) => resource.item).toList();
    final troops = Troops.values.map((troop) => troop.item).toList();
    final boats = Boats.values.map((boat) => boat.item).toList();
    final territories = Territories.values.map((territory) => territory.item).toList();
    final buildings = Buildings.values.map((building) => building.item).toList();

    return ListenableBuilder(
      listenable: game,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFE7D0A7), 
            elevation: 4,
            shadowColor: Colors.black45,
            centerTitle: true,
            title: const Text(
              'PANBO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFF3E2723),
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Nuova partita',
                onPressed: () {
                  _doubledProductionResources.clear();
                  _stagedChanges.clear();
                  _stagedFieldConfigs.clear();
                  _stagedRiverConfigs.clear();
                  _stagedConqueredAnimals.clear();
                  game.reset();
                },
                icon: const Icon(
                  Icons.restart_alt,
                  color: Color(0xFF3E2723),
                  size: 28,
                ),
              ),
            ],
          ),

          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _turnHeader(),
                  const SizedBox(height: 16),
                  
                  _turnSummaryBoard(),
                  const SizedBox(height: 24),

                  if (_currentIndex == 0)
                    _section(
                      'RISORSE',
                      Icons.inventory_2_outlined,
                      _resourceGrid(resources),
                    ),
                  if (_currentIndex == 1) ...[
                    _section(
                      'TERRITORI',
                      Icons.map_outlined,
                      _interactiveGrid(territories),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      'STRUTTURE',
                      Icons.construction_outlined,
                      _interactiveGrid(buildings),
                    ),
                  ],
                  if (_currentIndex == 2) ...[
                    _section(
                      'TRUPPE',
                      Icons.shield_outlined,
                      _interactiveGrid(troops),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      'IMBARCAZIONI',
                      Icons.sailing_outlined,
                      _interactiveGrid(boats),
                    ),
                  ],
                ],
              ),
            ),
          ),

          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFFE7D0A7),
            indicatorColor: const Color(0xFF8D6E63).withValues(alpha: 0.4),
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined, color: Color(0xFF4E342E)),
                selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF3E2723)),
                label: 'Risorse',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_outlined, color: Color(0xFF4E342E)),
                selectedIcon: Icon(Icons.account_balance, color: Color(0xFF3E2723)),
                label: 'Espansioni',
              ),
              NavigationDestination(
                icon: Icon(Icons.shield_outlined, color: Color(0xFF4E342E)),
                selectedIcon: Icon(Icons.shield, color: Color(0xFF3E2723)),
                label: 'Esercito',
              ),
            ],
          ),

          floatingActionButton: GestureDetector(
            onTap: () {
              if (game.phase == TurnPhase.weather) {
                if (game.turn == 1) {
                  _showInitialFieldsDialog(context);
                } else {
                  _showWeatherDialog(context);
                }
              } else if (game.phase == TurnPhase.gather) {
                final beforeGather = Map<GameItem, int>.from(game.resources);
                
                game.collectResources();
                
                for (var item in _doubledProductionResources) {
                  final amountBefore = beforeGather[item] ?? 0;
                  final amountAfter = game.resources[item] ?? 0;
                  final producedAmount = amountAfter - amountBefore;
                  
                  if (producedAmount > 0) {
                    game.resources[item] = amountAfter + producedAmount;
                  }
                }
                
                setState(() {
                  _doubledProductionResources.clear();
                });
                
                game.nextPhase();
                
                if (game.phase == TurnPhase.payup && !game.hasDeficit) {
                  game.nextPhase();
                }
                
              } else if (game.phase == TurnPhase.payup) {
                if (game.hasDeficit) {
                  _showDeficitDialog(context);
                } else {
                  game.nextPhase();
                }
              } else if (game.phase == TurnPhase.expand) {
                Map<GameItem, int> conqueredAnimalsCopy = Map.from(_stagedConqueredAnimals);

                _stagedChanges.forEach((item, count) {
                  if (count > 0) {
                    int fieldIdx = 0;
                    int riverIdx = 0;
                    for (int i = 0; i < count; i++) {
                      int conqueredToProcess = conqueredAnimalsCopy[item] ?? 0;
                      
                      if (conqueredToProcess > 0) {
                         game.resources[Resources.wheat.item] = (game.resources[Resources.wheat.item] ?? 0) + item.wheatCost;
                         game.action(item);
                         conqueredAnimalsCopy[item] = conqueredToProcess - 1;
                      } else {
                         game.action(item);
                      }
                      
                      if (Resources.values.any((r) => r.item == item)) {
                        game.resources[item] = (game.resources[item] ?? 0) + 1;
                      }

                      if (item == Territories.field.item && fieldIdx < _stagedFieldConfigs.length) {
                        game.addFieldWithRivers(_stagedFieldConfigs[fieldIdx++]);
                      } else if (item == Buildings.river.item && riverIdx < _stagedRiverConfigs.length) {
                        game.addRiverWithFields(_stagedRiverConfigs[riverIdx++], 1);
                      }
                    }
                  } else if (count < 0) {
                    if (Resources.values.any((r) => r.item == item)) {
                      game.resources[item] = (game.resources[item] ?? 0) - (-count);
                    } else {
                      game.kill(item, amount: -count);
                    }
                  }
                });
                
                _stagedChanges.clear();
                _stagedFieldConfigs.clear();
                _stagedRiverConfigs.clear();
                _stagedConqueredAnimals.clear();
                
                game.nextPhase();
                
                if (game.phase == TurnPhase.cleanup && !game.hasExcess) {
                  game.nextPhase();
                }
                
              } else if (game.phase == TurnPhase.cleanup) {
                if (game.hasExcess) {
                  _showCleanupDialog(context);
                } else {
                  game.nextPhase();
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, right: 8),
              decoration: _boardGameDecoration(
                ((game.phase == TurnPhase.payup && game.hasDeficit) ||
                        (game.phase == TurnPhase.cleanup && game.hasExcess))
                    ? const Color(0xFFEF9A9A) 
                    : const Color(0xFFA5D6A7), 
                isInteractive: true,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    switch (game.phase) {
                      TurnPhase.weather => game.turn == 1 ? 'SETUP INIZIALE' : 'INIZIA TURNO',
                      TurnPhase.gather => 'INIZIA RACCOLTA',
                      TurnPhase.payup => 'PAGA DEBITO!',
                      TurnPhase.expand => 'FINE TURNO', 
                      TurnPhase.cleanup => 'SCARTA ECCESSO!',
                    },
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    ((game.phase == TurnPhase.payup && game.hasDeficit) ||
                            (game.phase == TurnPhase.cleanup && game.hasExcess))
                        ? Icons.warning_amber_rounded
                        : Icons.arrow_forward,
                    color: const Color(0xFF212121),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Decoration _boardGameDecoration(Color color, {bool isInteractive = false}) {
    return ShapeDecoration(
      color: color,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: const BorderSide(color: Color(0xFF4E342E), width: 2),
      ),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          offset: isInteractive ? const Offset(2, 6) : const Offset(2, 4),
          blurRadius: isInteractive ? 8 : 4,
        ),
        if (isInteractive)
          const BoxShadow(
            color: Colors.white70,
            offset: Offset(-1, -1),
            blurRadius: 2,
          ),
      ],
    );
  }

  Widget _turnHeader() => Container(
        decoration: _boardGameDecoration(const Color(0xFFFFCC80)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const ShapeDecoration(
                shape: CircleBorder(side: BorderSide(color: Color(0xFF4E342E), width: 2)),
                color: Colors.white,
              ),
              child: Icon(
                game.isCold ? Icons.ac_unit : Icons.wb_sunny,
                color: game.isCold ? Colors.blue : Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'TURNO ${game.turn}',
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF4E342E), width: 2),
                ),
              ),
              child: Text(
                game.phase.label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _turnSummaryBoard() {
    int totalUpkeep = 0;
    
    game.buildings.forEach((k, v) => totalUpkeep += game.getItemUpkeep(k) * (v + (_stagedChanges[k] ?? 0)));
    game.troops.forEach((k, v) => totalUpkeep += game.getItemUpkeep(k) * (v + (_stagedChanges[k] ?? 0)));
    game.territories.forEach((k, v) => totalUpkeep += game.getItemUpkeep(k) * (v + (_stagedChanges[k] ?? 0)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boardGameDecoration(const Color(0xFFBCAAA4)), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.analytics_outlined, color: Color(0xFF3E2723)),
              SizedBox(width: 8),
              Text(
                'RIEPILOGO TURNO',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF3E2723)),
              ),
            ],
          ),
          const Divider(color: Color(0xFF4E342E), thickness: 2, height: 24),
          
          Text(
            'Costo Mantenimento Proiettato: $totalUpkeep Grano',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFB71C1C),
            ),
          ),
          
          const SizedBox(height: 16),
          const Text(
            'Produzione Prevista:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: game.resources.keys.map((res) {
              int expectedProd = 0;
              
              if (res == Resources.wheat.item) {
                int projectedFields = game.irrigatedfields;
                for (int rivers in _stagedFieldConfigs) {
                  projectedFields += rivers;
                }
                for (int fields in _stagedRiverConfigs) {
                  projectedFields += fields;
                }
                expectedProd = Territories.field.item.gain * projectedFields;
                
                if (game.currentWeather == WeatherType.stormy) {
                   expectedProd = expectedProd ~/ 2;
                }
              } else if (res.territory != null) {
                int territoryGain = res.territory!.item.gain;
                int territoryCount = (game.territories[res.territory!.item] ?? 0) + (_stagedChanges[res.territory!.item] ?? 0);
                expectedProd = territoryGain * territoryCount;
              }

              if (_doubledProductionResources.contains(res)) {
                expectedProd *= 2;
              }
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(res.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text(
                    '+$expectedProd',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: expectedProd > 0 ? const Color(0xFF1B5E20) : const Color(0xFF3E2723),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 8),
            child: Row(
              children: [
                Icon(icon, size: 24, color: const Color(0xFF5D4037)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4E342E),
                    letterSpacing: 1.2
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      );

  Widget _resourceGrid(List<GameItem> items) => GridView.extent(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        maxCrossAxisExtent: 350, 
        childAspectRatio: 1.8, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items.map((item) {
          int baseCount = game.resources[item] ?? 0;
          int stagedCount = _stagedChanges[item] ?? 0;
          return _resourceCard(item, baseCount + stagedCount, stagedCount);
        }).toList(),
      );

  Widget _interactiveGrid(List<GameItem> items) => GridView.extent(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        maxCrossAxisExtent: 350,
        childAspectRatio: 3.5, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items.map((item) {
          int baseCount = game.troops[item] ?? game.territories[item] ?? game.buildings[item] ?? game.boats[item] ?? 0;
          int stagedCount = _stagedChanges[item] ?? 0;
          return _interactiveCard(item, baseCount + stagedCount, stagedCount);
        }).toList(),
      );

  Widget _resourceCard(GameItem item, int displayCount, int stagedCount) {
    bool isBeforeGatherAction = game.phase == TurnPhase.weather || game.phase == TurnPhase.gather;
    bool isExpandPhase = game.phase == TurnPhase.expand;
    bool isDoubled = _doubledProductionResources.contains(item);
    
    bool isCraftable = item.woodCost > 0 || item.stoneCost > 0 || item.ironCost > 0 || item.rawIronCost > 0 || item.wheatCost > 0 || item.requirement != null;
    
    // Controlla i costi per la risorsa (se craftabile) simulando lo stato attuale del carrello.
    bool canAffordCrafting = (isExpandPhase && isCraftable) ? _simulateAndCheck((g) => g.canAction(item)) : true;

    Color countColor = const Color(0xFF212121);
    if (stagedCount > 0) countColor = const Color(0xFF2E7D32);
    if (stagedCount < 0) countColor = const Color(0xFFC62828);

    return Container(
      decoration: _boardGameDecoration(const Color(0xFFFFF8E1), isInteractive: true),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF3E2723)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Color(0xFF8D6E63), width: 1.5),
                  ),
                ),
                child: Text(
                  '$displayCount',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: countColor),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isBeforeGatherAction) ...[
                IconButton(
                  iconSize: 32,
                  color: const Color(0xFFD32F2F),
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () {
                    setState(() {
                      if (isExpandPhase && isCraftable) {
                         if (stagedCount > 0) {
                            _stagedChanges[item] = stagedCount - 1;
                         } else if (displayCount > 0) {
                            _stagedChanges[item] = stagedCount - 1;
                         }
                      } else {
                         if (displayCount > 0) game.resources[item] = displayCount - 1;
                      }
                    });
                  },
                ),
                IconButton(
                  iconSize: 32,
                  color: canAffordCrafting ? const Color(0xFF388E3C) : Colors.grey.shade400,
                  icon: const Icon(Icons.add_circle),
                  onPressed: canAffordCrafting ? () {
                    setState(() {
                      if (isExpandPhase && isCraftable) {
                         _stagedChanges[item] = stagedCount + 1;
                      } else {
                         game.resources[item] = displayCount + 1;
                      }
                    });
                  } : null,
                ),
              ] else ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      game.resources[item] = (displayCount / 2).floor();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFBBDEFB),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFF1976D2), width: 2),
                      ),
                    ),
                    child: const Text(
                      '½',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF0D47A1)),
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 28,
                  color: const Color(0xFF616161),
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    setState(() {
                      game.resources[item] = 0;
                    });
                  },
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isDoubled) {
                        _doubledProductionResources.remove(item);
                      } else {
                        _doubledProductionResources.add(item);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: ShapeDecoration(
                      color: isDoubled ? const Color(0xFFFFD54F) : Colors.grey.shade200,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: isDoubled ? const Color(0xFFF57F17) : Colors.grey, width: 2),
                      ),
                    ),
                    child: Text(
                      'x2',
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 16,
                        color: isDoubled ? const Color(0xFFE65100) : Colors.grey.shade600
                      ),
                    ),
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _interactiveCard(GameItem item, int displayCount, int stagedCount) {
    bool isExpandPhase = game.phase == TurnPhase.expand;
    
    // Controlla se possiamo comprarlo, chiedendo dinamicamente a game_model se il costo + requirement è rispettato
    bool canAfford = isExpandPhase ? _simulateAndCheck((g) => g.canAction(item)) : false;
    
    // Controlla se possiamo eliminarlo (es. nessun altro pezzo si appoggia in modo critico a questo)
    bool canRemove = (displayCount > 0 && isExpandPhase) ? _simulateAndCheck((g) => g.canRemove(item)) : false;
    
    if (isExpandPhase && (item == Territories.horse.item || item == Territories.sheep.item)) {
        canAfford = true;
    }
    
    Color countColor = const Color(0xFF212121);
    if (stagedCount > 0) countColor = const Color(0xFF2E7D32);
    if (stagedCount < 0) countColor = const Color(0xFFC62828);

    return Container(
      decoration: _boardGameDecoration(const Color(0xFFFFF8E1), isInteractive: true),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF3E2723)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.remove_circle,
                  color: canRemove ? const Color(0xFFD32F2F) : Colors.grey.shade400,
                ),
                onPressed: canRemove ? () {
                  setState(() {
                    if (stagedCount > 0) {
                      _stagedChanges[item] = stagedCount - 1;
                      if (item == Territories.field.item && _stagedFieldConfigs.isNotEmpty) _stagedFieldConfigs.removeLast();
                      if (item == Buildings.river.item && _stagedRiverConfigs.isNotEmpty) _stagedRiverConfigs.removeLast();
                      
                      if (item == Territories.horse.item || item == Territories.sheep.item) {
                         int conquered = _stagedConqueredAnimals[item] ?? 0;
                         if (stagedCount - 1 < conquered) {
                             _stagedConqueredAnimals[item] = conquered - 1;
                         }
                      }
                    } else {
                      _stagedChanges[item] = stagedCount - 1;
                    }
                  });
                } : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: const BorderSide(color: Color(0xFF8D6E63), width: 1.5),
                  ),
                ),
                child: Text(
                  '$displayCount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: countColor,
                  ),
                ),
              ),
              IconButton(
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.add_circle,
                  color: canAfford ? const Color(0xFF388E3C) : Colors.grey.shade400,
                ),
                onPressed: canAfford
                    ? () {
                        if (item == Territories.field.item) {
                          _showRiverCountDialog(context, isField: true, isStaging: true);
                        } else if (item == Buildings.river.item) {
                          _showRiverCountDialog(context, isField: false, isStaging: true);
                        } else if (item == Territories.horse.item || item == Territories.sheep.item) {
                          _showAnimalActionDialog(context, item, stagedCount);
                        } else {
                          setState(() {
                            _stagedChanges[item] = stagedCount + 1;
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnimalActionDialog(BuildContext context, GameItem item, int stagedCount) {
    bool canReproduce = _simulateAndCheck((g) => g.canAction(item));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3E5AB),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4E342E), width: 3),
          ),
          title: Text(
            'NUOVO ${item.name.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Come vuoi ottenere questo animale?',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5D6A7),
                side: const BorderSide(color: Color(0xFF4E342E), width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                setState(() {
                  _stagedChanges[item] = stagedCount + 1;
                  _stagedConqueredAnimals[item] = (_stagedConqueredAnimals[item] ?? 0) + 1;
                });
                Navigator.pop(context);
              },
              child: const Text('Conquista\n(Gratis)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canReproduce ? const Color(0xFFFFCC80) : Colors.grey.shade400,
                side: const BorderSide(color: Color(0xFF4E342E), width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: canReproduce ? () {
                setState(() {
                  _stagedChanges[item] = stagedCount + 1;
                });
                Navigator.pop(context);
              } : null,
              child: Text('Riproduci\n(-${item.wheatCost} Grano)', textAlign: TextAlign.center, style: TextStyle(color: canReproduce ? const Color(0xFFE65100) : Colors.grey.shade700, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDeficitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3E5AB),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4E342E), width: 3),
          ),
          title: const Text(
            'DEBITO DI GRANO!',
            style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w900),
          ),
          content: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              if (game.disposableItems.isEmpty && game.hasDeficit) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Non hai più nulla da poter sacrificare... Bancarotta!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                      onPressed: () {
                        game.currentDeficit = 0;
                        Navigator.pop(context);
                        game.nextPhase();
                      },
                      child: const Text("Continua (Bancarotta)", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Devi ancora ripagare ${game.currentDeficit} grano.\nScegli cosa sacrificare per pareggiare i conti:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...game.disposableItems.map((item) {
                      int saving = game.getItemUpkeep(item);
                      int count = game.territories[item] ??
                          game.troops[item] ??
                          game.buildings[item] ??
                          0;

                      return ListTile(
                        leading: Text(
                          item.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Posseduti: $count'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF8E1),
                            side: const BorderSide(color: Color(0xFF4E342E)),
                          ),
                          onPressed: () {
                            game.sacrificeItem(item);
                            if (!game.hasDeficit) {
                              Navigator.pop(context);
                              game.nextPhase();
                            }
                          },
                          child: Text('Distruggi (+$saving)', style: const TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showDiscardAmountDialog(BuildContext context, GameItem resource, int maxAmount) async {
    int selectedAmount = 1;
    TextEditingController textController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            
            void updateAmount(int newAmount) {
              setStateModal(() {
                if (newAmount < 1) newAmount = 1;
                if (newAmount > maxAmount) newAmount = maxAmount;
                selectedAmount = newAmount;
                textController.text = selectedAmount.toString();
                textController.selection = TextSelection.fromPosition(TextPosition(offset: textController.text.length));
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFF3E5AB),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF4E342E), width: 3),
              ),
              title: Text('Scarta ${resource.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Quante unità vuoi scartare? (Max $maxAmount)'),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        color: const Color(0xFFD32F2F),
                        icon: const Icon(Icons.remove_circle),
                        onPressed: selectedAmount > 1
                            ? () => updateAmount(selectedAmount - 1)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF4E342E), width: 2),
                          ),
                        ),
                        child: TextField(
                          controller: textController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            int? parsed = int.tryParse(val);
                            if (parsed != null) {
                              if (parsed > maxAmount) {
                                updateAmount(maxAmount);
                              } else {
                                selectedAmount = parsed;
                              }
                            } else {
                              selectedAmount = 0; 
                            }
                          },
                          onEditingComplete: () {
                            if (selectedAmount < 1) updateAmount(1);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 40,
                        color: const Color(0xFF388E3C),
                        icon: const Icon(Icons.add_circle),
                        onPressed: selectedAmount < maxAmount
                            ? () => updateAmount(selectedAmount + 1)
                            : null,
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedAmount < 1) selectedAmount = 1;
                    if (selectedAmount > maxAmount) selectedAmount = maxAmount;
                    
                    for (int i = 0; i < selectedAmount; i++) {
                      game.discardResource(resource);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF57F17),
                    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Conferma', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3E5AB),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4E342E), width: 3),
          ),
          title: const Text(
            'MAGAZZINI PIENI!',
            style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w900),
          ),
          content: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              var ownedResources = game.resources.entries
                  .where((e) => e.value > 0)
                  .toList();

              return SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'La tua capacità massima è ${game.totalCapacity}.\nDevi scartare ancora ${game.currentExcess} risorse.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...ownedResources.map((entry) {
                      GameItem resource = entry.key;
                      int count = entry.value;

                      return ListTile(
                        leading: Text(
                          resource.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(resource.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Possedute: $count'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF8E1),
                            side: const BorderSide(color: Color(0xFF4E342E)),
                          ),
                          onPressed: () async {
                            await _showDiscardAmountDialog(context, resource, count);
                            if (!game.hasExcess) {
                              if (context.mounted) Navigator.pop(context);
                              game.nextPhase();
                            }
                          },
                          child: const Text('Scarta...', style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showWeatherDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3E5AB),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4E342E), width: 3),
          ),
          title: const Text(
            'CHE TEMPO FA?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Color(0xFF3E2723),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleziona le condizioni climatiche per questo turno:',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              ...WeatherType.values.map((weatherType) {
                String label;
                IconData icon;
                Color bgColor;
                Color iconColor;

                switch (weatherType) {
                  case WeatherType.cold:
                    label = 'BUFERA GELIDA';
                    icon = Icons.ac_unit;
                    bgColor = const Color(0xFF81D4FA);
                    iconColor = Colors.white;
                    break;
                  case WeatherType.warm:
                    label = 'CALDO TORRIDO';
                    icon = Icons.heat_pump;
                    bgColor = const Color(0xFFEF5350);
                    iconColor = Colors.yellow;
                    break;
                  case WeatherType.sunny:
                    label = 'SOLEGGIATO';
                    icon = Icons.wb_sunny;
                    bgColor = const Color(0xFFFFB74D);
                    iconColor = Colors.red;
                    break;
                  case WeatherType.rainy:
                    label = 'PIOVOSO';
                    icon = Icons.water_drop;
                    bgColor = const Color(0xFF90CAF9);
                    iconColor = const Color(0xFF0D47A1);
                    break;
                  case WeatherType.stormy:
                    label = 'TEMPORALE';
                    icon = Icons.thunderstorm;
                    bgColor = const Color(0xFF7E57C2);
                    iconColor = Colors.yellowAccent;
                    break;
                }

                return GestureDetector(
                  onTap: () {
                    game.setWeather(weatherType); 
                    Navigator.pop(context);
                    game.nextPhase();
                  },
                  child: Container(
                    width: double.maxFinite,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: _boardGameDecoration(bgColor, isInteractive: true),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: iconColor, size: 32),
                        const SizedBox(width: 16),
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showInitialFieldsDialog(BuildContext context) {
    int f1 = 0, f2 = 0, f3 = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF3E5AB),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF4E342E), width: 3),
              ),
              title: const Text(
                'SETUP INIZIALE: CAMPI E FIUMI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'I tuoi primi 3 campi da quanti fiumi sono bagnati? (0 a 6)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Fiumi Campo 1 (0-6)',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => f1 = int.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Fiumi Campo 2 (0-6)',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => f2 = int.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Fiumi Campo 3 (0-6)',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => f3 = int.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      game.addFieldWithRivers(f1);
                      game.addFieldWithRivers(f2);
                      game.addFieldWithRivers(f3);
                      Navigator.pop(context);
                      game.nextPhase();
                    },
                    child: Container(
                      decoration: _boardGameDecoration(const Color(0xFFA5D6A7), isInteractive: true),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: const Text(
                        'CONFERMA SETUP',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B5E20),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRiverCountDialog(BuildContext context, {required bool isField, bool isStaging = false}) {
    int count = 0;
    int maxLimit = isField ? 6 : 2;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF3E5AB),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4E342E), width: 3),
          ),
          title: Text(
            isField ? 'CONFIGURA CAMPO' : 'CONFIGURA FIUME',
            style: const TextStyle(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isField
                    ? 'Da quanti fiumi è bagnato? (Min 0, Max 6)'
                    : 'Quanti campi irriga? (Min 0, Max 2)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: isField ? 'Numero Fiumi (0-6)' : 'Campi Irrigati (0-2)',
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) => count = int.tryParse(val) ?? 0,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  if (count < 0) count = 0;
                  if (count > maxLimit) count = maxLimit;

                  if (isStaging) {
                    setState(() {
                      if (isField) {
                        _stagedChanges[Territories.field.item] = (_stagedChanges[Territories.field.item] ?? 0) + 1;
                        _stagedFieldConfigs.add(count);
                      } else {
                        _stagedChanges[Buildings.river.item] = (_stagedChanges[Buildings.river.item] ?? 0) + 1;
                        _stagedRiverConfigs.add(count);
                      }
                    });
                  } else {
                    if (isField) {
                      if (game.canAction(Territories.field.item)) {
                        game.action(Territories.field.item);
                        game.addFieldWithRivers(count);
                      }
                    } else {
                      if (game.canAction(Buildings.river.item)) {
                        int i = 1;
                        game.action(Buildings.river.item);
                        game.addRiverWithFields(count, i);
                      }
                    }
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: _boardGameDecoration(const Color(0xFFFFCC80), isInteractive: true),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const Text(
                    'COSTRUISCI',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE65100),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}