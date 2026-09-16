import 'package:flutter/material.dart';
import 'package:panbo/boats.dart';
import 'package:panbo/buildings.dart';
import 'package:panbo/resources.dart';
import 'package:panbo/territories.dart';
import 'package:panbo/troops.dart';
import 'game_model.dart';
import 'population/sheep.dart';
import 'troops/brigands.dart';

void main() => runApp(const PanboApp());

class PanboApp extends StatelessWidget {
  const PanboApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Panbo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b61)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfff4f1e8),
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
    final resources = Resources.values.map((resource) => resource.item).toList();
    final troops = Troops.values.map((troop) => troop.item).toList();
    final boats = Boats.values.map((boat) => boat.item).toList();
    final territories = Territories.values.map((territory) => territory.item).toList();
    final buildings = Buildings.values.map((building) => building.item).toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PANBO',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            tooltip: 'Nuova partita',
            onPressed: game.reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      
      // Il body osserva i cambiamenti in GameState
      body: ListenableBuilder(
        listenable: game,
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _turnHeader(),
                  const SizedBox(height: 16),
                  _phaseRail(),
                  const SizedBox(height: 16),

                  // --- SCHEDA 0: RISORSE ---
                  if (_currentIndex == 0)
                    _section(
                      'Risorse',
                      Icons.inventory_2_outlined,
                      _resourceGrid(resources),
                    ),

                  // --- SCHEDA 1: ESPANSIONI ---
                  if (_currentIndex == 1) ...[
                    _section(
                      'Territori',
                      Icons.map_outlined,
                      _territoryGrid(territories),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      'Strutture',
                      Icons.construction_outlined,
                      _buildingGrid(buildings),
                    ),
                  ],

                  // --- SCHEDA 2: ESERCITO ---
                  if (_currentIndex == 2) ...[
                    _section(
                      'Truppe',
                      Icons.shield_outlined,
                      _troopGrid(troops),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      'Imbarcazioni',
                      Icons.sailing_outlined,
                      _boatGrid(boats),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      
      // Barra di navigazione inferiore
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Risorse',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Espansioni',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Esercito',
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (game.phase == TurnPhase.gather) {
            game.collectResources();
            game.nextPhase();
          } else if (game.phase == TurnPhase.payup) {
            if (game.hasDeficit) {
              // Apre la modale per scegliere i sacrifici
              _showDeficitDialog(context);
            } else {
              game.nextPhase();
            }
          } else if (game.phase == TurnPhase.expand) {
            game.nextPhase();
          } else if (game.phase == TurnPhase.cleanup) {
            game.nextPhase();
          }
        },
        icon: Icon(game.hasDeficit ? Icons.warning_amber_rounded : Icons.arrow_forward),
        backgroundColor: game.hasDeficit ? Colors.red.shade100 : null,
        label: Text(
          switch (game.phase) {
            TurnPhase.gather => 'Raccogli e continua',
            TurnPhase.payup => game.hasDeficit ? 'Paga Debito!' : 'Paga e continua',
            TurnPhase.expand => 'Fine Azioni',
            TurnPhase.cleanup => 'Fine Turno',
          },
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HELPER (Sotto-componenti visivi)
  // ==========================================

  Widget _turnHeader() => Card(
        elevation: 0,
        color: const Color(0xff173f3a),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Turno ${game.turn}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    game.phase.label, // Questo usa l'extension TurnPhaseLabel
                    style: const TextStyle(
                      color: Color(0xffd5e9c8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                backgroundColor:
                    item == game.phase ? const Color(0xffc9dfb6) : null,
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
            .map((item) => _counterCard(item, game.resources[item] ?? 0))
            .toList(),
      );

  Widget _troopGrid(List<GameItem> items) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: items.map(_troopCard).toList(),
      );

  Widget _territoryGrid(List<GameItem> items) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: items
            .map((item) => _counterCard(item, game.territories[item] ?? 0))
            .toList(),
      );

  Widget _buildingGrid(List<GameItem> items) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: items
            .map((item) => _counterCard(item, game.buildings[item] ?? 0))
            .toList(),
      );

  Widget _boatGrid(List<GameItem> items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => Chip(
                  avatar: Text(item.icon),
                  label: Text('${item.name} (${game.boats[item] ?? 0})'),
                ))
            .toList(),
      );

  Widget _counterCard(GameItem item, int value) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Text(item.name)),
              Text(
                '$value',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  Widget _troopCard(GameItem item) => Card(
        elevation: 0,
        child: ListTile(
          leading: Text(item.icon, style: const TextStyle(fontSize: 22)),
          title: Text(item.name),
          subtitle: Text('Costo: ${item.cost} grano'),
          trailing: IconButton(
            tooltip: 'Recluta',
            onPressed: () {
              // Qui potresti voler chiamare game.recruit(item) dipendentemente dalla tua logica
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ),
      );
  void _showDeficitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impedisce di chiudere la finestra cliccando fuori!
      builder: (context) {
        return AlertDialog(
          title: const Text('Debito di Grano!', style: TextStyle(color: Colors.red)),
          content: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              // Sicurezza: se non c'è più nulla da sacrificare ma il debito c'è ancora!
              if (game.disposableItems.isEmpty && game.hasDeficit) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Non hai più nulla da poter sacrificare... Bancarotta!"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () {
                            game.currentDeficit = 0; // Forziamo a 0 per sbloccare il gioco
                            Navigator.pop(context);
                            game.nextPhase();
                          },
                          child: const Text("Continua (Bancarotta)"),
                      )
                    ]
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
                    // Generiamo un bottone per ogni elemento sacrificabile!
                    ...game.disposableItems.map((item) {
                      int saving = game.getItemUpkeep(item);
                      int count = game.territories[item] ?? game.troops[item] ?? game.buildings[item] ?? 0;
                      
                      return ListTile(
                        leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
                        title: Text(item.name),
                        subtitle: Text('Posseduti: $count'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            game.sacrificeItem(item); // Sacrifica l'elemento
                            
                            if (!game.hasDeficit) {
                              // Il debito è saldato! Chiudiamo la modale
                              Navigator.pop(context);
                              game.nextPhase(); // Passiamo subito alla fase successiva (Expand)
                            }
                          },
                          child: Text('Distruggi (+$saving)'),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}