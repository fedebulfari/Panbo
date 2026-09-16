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
      scaffoldBackgroundColor: const Color(0xfff4f0ea), // Un beige "carta"
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      useMaterial3: true,
      fontFamily: 'Courier', // Opzionale: un font monospace o molto netto aiuta molto lo stile!
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

  // Memorizza quale scheda della barra di navigazione è attiva (0 = Risorse)
  int _currentIndex = 0;

 @override
  Widget build(BuildContext context) {
    // Liste degli elementi
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
            backgroundColor: const Color(0xfff4f0ea), 
            title: const Text(
              'PANBO',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black),
            ),
            actions: [
              IconButton(
                tooltip: 'Nuova partita',
                onPressed: game.reset,
                icon: const Icon(Icons.restart_alt, color: Colors.black, size: 28),
              ),
            ],
          ),
          
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  _turnHeader(),
                  const SizedBox(height: 16),
                  _phaseRail(),
                  const SizedBox(height: 16),
                  
                  if (_currentIndex == 0) _section('RISORSE', Icons.inventory_2_outlined, _resourceGrid(resources)),
                  if (_currentIndex == 1) ...[
                    _section('TERRITORI', Icons.map_outlined, _territoryGrid(territories)),
                    const SizedBox(height: 16),
                    _section('STRUTTURE', Icons.construction_outlined, _buildingGrid(buildings)),
                  ],
                  if (_currentIndex == 2) ...[
                    _section('TRUPPE', Icons.shield_outlined, _troopGrid(troops)),
                    const SizedBox(height: 16),
                    _section('IMBARCAZIONI', Icons.sailing_outlined, _boatGrid(boats)),
                  ],
                ],
              ),
            ),
          ),
          
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Risorse'),
              NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'Espansioni'),
              NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Esercito'),
            ],
          ),
          
          floatingActionButton: GestureDetector(
            onTap: () {
              if (game.phase == TurnPhase.weather) {
                if (game.turn == 1) {
                  _showInitialFieldsDialog(context); // Setup iniziale al Turno 1
                } else {
                  _showWeatherDialog(context); // Meteo nei turni successivi
                }
              } else if (game.phase == TurnPhase.gather) {
                game.collectResources();
                game.nextPhase();
              } else if (game.phase == TurnPhase.payup) {
                if (game.hasDeficit) {
                  _showDeficitDialog(context);
                } else {
                  game.nextPhase();
                }
              } else if (game.phase == TurnPhase.expand) {
                game.nextPhase();
              } else if (game.phase == TurnPhase.cleanup) {
                if (game.hasExcess) {
                  _showCleanupDialog(context);
                } else {
                  game.nextPhase();
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, right: 16),
              decoration: _neoDecoration(
                ((game.phase == TurnPhase.payup && game.hasDeficit) || (game.phase == TurnPhase.cleanup && game.hasExcess))
                    ? const Color(0xffff90e8)
                    : const Color(0xffa7f3d0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    switch (game.phase) {
                      TurnPhase.weather => game.turn == 1 ? 'SETUP INIZIALE' : 'INIZIA TURNO',
                      TurnPhase.gather => 'INIZIA RACCOLTA',
                      TurnPhase.payup => game.hasDeficit ? 'PAGA DEBITO!' : 'PAGA E CONTINUA',
                      TurnPhase.expand => 'FINE AZIONI',
                      TurnPhase.cleanup => game.hasExcess ? 'SCARTA ECCESSO!' : 'FINE TURNO',
                    },
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    ((game.phase == TurnPhase.payup && game.hasDeficit) || (game.phase == TurnPhase.cleanup && game.hasExcess))
                        ? Icons.warning_amber_rounded
                        : Icons.arrow_forward,
                    color: Colors.black,
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

  // ==========================================
  // WIDGET HELPER (Sotto-componenti visivi)
  // ==========================================
  BoxDecoration _neoDecoration(Color color) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: Colors.black, width: 3),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
      ],
    );
  }

  Widget _turnHeader() => Container(
    margin: const EdgeInsets.only(bottom: 8, right: 8), 
    decoration: _neoDecoration(const Color(0xffffd500)),
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            shape: BoxShape.circle,
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
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            game.phase.label.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _phaseRail() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: TurnPhase.values
        .map(
          (item) => Chip(
            avatar: Icon(
              item == game.phase
                  ? Icons.radio_button_checked
                  : Icons.circle_outlined,
              size: 16,
            ),
            label: Text(item.label),
            backgroundColor: item == game.phase
                ? const Color(0xffc9dfb6)
                : null,
          ),
        )
        .toList(),
  );

  Widget _section(String title, IconData icon, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      child,
    ],
  );

  Widget _resourceGrid(List<GameItem> items) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    childAspectRatio: 2.3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    children: items
        .map((item) => _simpleCard(item, game.resources[item] ?? 0))
        .toList(),
  );

  Widget _troopGrid(List<GameItem> items) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 2.8,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    children: items
        .map((item) => _interactiveCard(item, game.troops[item] ?? 0))
        .toList(),
  );

  Widget _territoryGrid(List<GameItem> items) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 2.8,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    children: items
        .map((item) => _interactiveCard(item, game.territories[item] ?? 0))
        .toList(),
  );

  Widget _buildingGrid(List<GameItem> items) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 2.8,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    children: items
        .map((item) => _interactiveCard(item, game.buildings[item] ?? 0))
        .toList(),
  );

  Widget _boatGrid(List<GameItem> items) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    childAspectRatio: 2.8,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    children: items
        .map((item) => _interactiveCard(item, game.boats[item] ?? 0))
        .toList(),
  );

  Widget _simpleCard(GameItem item, int value) => Container(
    margin: const EdgeInsets.only(bottom: 6, right: 6),
    decoration: _neoDecoration(Colors.white),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Text(item.icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _interactiveCard(GameItem item, int count) {
    bool isActionPhase = game.phase == TurnPhase.expand;
    bool canAfford = game.canAction(item);

    return Opacity(
      opacity: isActionPhase ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 6),
        decoration: _neoDecoration(Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.remove_circle,
                    color: (isActionPhase && count > 0)
                        ? const Color(0xffff5252)
                        : Colors.grey,
                  ),
                  onPressed: (isActionPhase && count > 0)
                      ? () => game.kill(item)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.add_circle,
                    color: (isActionPhase && canAfford)
                        ? const Color(0xff69f0ae)
                        : Colors.grey,
                  ),
                  onPressed: (isActionPhase && canAfford)
                      ? () {
                          // Apertura della modale specifica per Campi e Fiumi!
                          if (item == Territories.field.item) {
                            _showRiverCountDialog(context, isField: true);
                          } else if (item == Buildings.river.item) {
                            _showRiverCountDialog(context, isField: false);
                          } else {
                            game.action(item);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeficitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xfff4f0ea),
          shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'DEBITO DI GRANO!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
          ),
          content: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              if (game.disposableItems.isEmpty && game.hasDeficit) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Non hai più nulla da poter sacrificare... Bancarotta!"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        game.currentDeficit = 0; 
                        Navigator.pop(context);
                        game.nextPhase();
                      },
                      child: const Text("Continua (Bancarotta)"),
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
                      int count = game.territories[item] ?? game.troops[item] ?? game.buildings[item] ?? 0;

                      return ListTile(
                        leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
                        title: Text(item.name),
                        subtitle: Text('Posseduti: $count'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            game.sacrificeItem(item); 
                            if (!game.hasDeficit) {
                              Navigator.pop(context);
                              game.nextPhase(); 
                            }
                          },
                          child: Text('Distruggi (+$saving)'),
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

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xfff4f0ea),
          shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'MAGAZZINI PIENI!',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900),
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
                        leading: Text(resource.icon, style: const TextStyle(fontSize: 24)),
                        title: Text(resource.name),
                        subtitle: Text('Possedute: $count'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            game.discardResource(resource);
                            if (!game.hasExcess) {
                              Navigator.pop(context);
                              game.nextPhase(); 
                            }
                          },
                          child: const Text('Scarta 1'),
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
          backgroundColor: const Color(0xfff4f0ea), 
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text(
            'CHE TEMPO FA?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black),
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

              GestureDetector(
                onTap: () {
                  game.setWeather(false); 
                  Navigator.pop(context); 
                  game.nextPhase(); 
                },
                child: Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.only(bottom: 16, right: 6),
                  decoration: _neoDecoration(Colors.orange), 
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.red, size: 32),
                      SizedBox(width: 12),
                      Text('SOLEGGIATO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                    ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  game.setWeather(true); 
                  Navigator.pop(context); 
                  game.nextPhase(); 
                },
                child: Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.only(bottom: 6, right: 6),
                  decoration: _neoDecoration(const Color(0xff93c5fd)), 
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue, size: 32),
                      SizedBox(width: 12),
                      Text('PIOVOSO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                    ],
                  ),
                ),
              ),
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
              backgroundColor: const Color(0xfff4f0ea),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
              title: const Text('SETUP INIZIALE: CAMPI E FIUMI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('I tuoi primi 3 campi da quanti fiumi sono bagnati? (0 a 6)'),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Fiumi Campo 1 (0-6)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => f1 = int.tryParse(val) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Fiumi Campo 2 (0-6)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => f2 = int.tryParse(val) ?? 0,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Fiumi Campo 3 (0-6)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => f3 = int.tryParse(val) ?? 0,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      game.addFieldWithRivers(f1);
                      game.addFieldWithRivers(f2);
                      game.addFieldWithRivers(f3);
                      Navigator.pop(context);
                      game.nextPhase(); 
                    },
                    child: Container(
                      decoration: _neoDecoration(const Color.fromARGB(255, 105, 240, 174)),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      child: const Text('CONFERMA SETUP', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRiverCountDialog(BuildContext context, {required bool isField}) {
    int count = 0;
    int maxLimit = isField ? 6 : 2;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xfff4f0ea),
          shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black, width: 3), borderRadius: BorderRadius.circular(8)),
          title: Text(isField ? 'CONFIGURA CAMPO' : 'CONFIGURA FIUME', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isField ? 'Da quanti fiumi è bagnato? (Min 0, Max 6)' : 'Quanti campi irriga? (Min 0, Max 2)'),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: isField ? 'Numero Fiumi (0-6)' : 'Campi Irrigati (0-2)'),
                keyboardType: TextInputType.number,
                onChanged: (val) => count = int.tryParse(val) ?? 0,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (count < 0) count = 0;
                  if (count > maxLimit) count = maxLimit;

                  if (isField) {
                    if (game.canAction(Territories.field.item)) {
                      game.action(Territories.field.item); 
                      game.addFieldWithRivers(count);      
                    }
                  } else {
                    if (game.canAction(Buildings.river.item)) {
                      game.action(Buildings.river.item);
                      game.addRiverWithFields(count);
                    }
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: _neoDecoration(const Color.fromARGB(255, 255, 128, 0)),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  child: const Text('COSTRUISCI', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}