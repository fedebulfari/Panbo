import 'package:flutter/material.dart';

import 'boats/brigade.dart';
import 'boats/galleon.dart';
import 'boats/raft.dart';
import 'game_model.dart';
import 'population/horse.dart';
import 'resouces/iron.dart';
import 'resouces/rock.dart';
import 'population/sheep.dart';
import 'resouces/wheat.dart';
import 'resouces/wood.dart';
import 'troops/batteringram.dart';
import 'troops/brigands.dart';
import 'troops/caravan.dart';
import 'troops/knights.dart';
import 'troops/soldiers.dart';
import 'troops/trebuchet.dart';

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

  @override
  void initState() {
    super.initState();
    game.addListener(_refresh);
  }

  @override
  void dispose() {
    game.removeListener(_refresh);
    game.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final resources = [Wheat.item, Wood.item, Rock.item, Iron.item, Horse.item, Sheep.item];
    final troops = [Brigands.item, Knights.item, Soldiers.item, BatteringRam.item, Trebuchet.item, Caravan.item];
    final boats = [Raft.item, Brigade.item, Galleon.item];
    return Scaffold(
      appBar: AppBar(
        title: const Text('PANBO', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
        actions: [IconButton(tooltip: 'Nuova partita', onPressed: game.reset, icon: const Icon(Icons.restart_alt))],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _turnHeader(), const SizedBox(height: 16), _phaseRail(), const SizedBox(height: 16),
              _section('Risorse', Icons.inventory_2_outlined, _resourceGrid(resources)),
              const SizedBox(height: 16), _section('Truppe', Icons.shield_outlined, _troopGrid(troops)),
              const SizedBox(height: 16), _section('Imbarcazioni', Icons.sailing_outlined, _boatGrid(boats)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (game.phase == TurnPhase.resources) game.collectResources();
          game.nextPhase();
        },
        icon: const Icon(Icons.arrow_forward),
        label: Text(game.phase == TurnPhase.resources ? 'Raccogli e continua' : 'Continua'),
      ),
    );
  }

  Widget _turnHeader() => Card(
        elevation: 0,
        color: const Color(0xff173f3a),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(child: Text('Turno ${game.turn}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(game.phase.label, style: const TextStyle(color: Color(0xffd5e9c8), fontWeight: FontWeight.bold)),
              Text(game.weather, style: const TextStyle(color: Colors.white70)),
            ]),
          ]),
        ),
      );

  Widget _phaseRail() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: TurnPhase.values.map((item) => Chip(
          avatar: Icon(item == game.phase ? Icons.radio_button_checked : Icons.circle_outlined, size: 16),
          label: Text(item.label),
          backgroundColor: item == game.phase ? const Color(0xffc9dfb6) : null,
        )).toList(),
      );

  Widget _section(String title, IconData icon, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
        child,
      ]);

  Widget _resourceGrid(List<GameItem> items) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, childAspectRatio: 2.3, crossAxisSpacing: 8, mainAxisSpacing: 8, children: items.map((item) => _counterCard(item, game.resources[item.name] ?? 0)).toList());

  Widget _troopGrid(List<GameItem> items) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 8, mainAxisSpacing: 8, children: items.map(_troopCard).toList());

  Widget _boatGrid(List<GameItem> items) => Wrap(spacing: 8, runSpacing: 8, children: items.map((item) => Chip(avatar: Text(item.icon), label: Text(item.name))).toList());

  Widget _counterCard(GameItem item, int value) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Text(item.icon, style: const TextStyle(fontSize: 22)), const SizedBox(width: 8), Expanded(child: Text(item.name)), Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])));

  Widget _troopCard(GameItem item) => Card(elevation: 0, child: ListTile(leading: Text(item.icon, style: const TextStyle(fontSize: 22)), title: Text(item.name), subtitle: Text('Costo: ${item.cost} grano'), trailing: IconButton(tooltip: 'Recluta', onPressed: () => game.recruit(item.name), icon: const Icon(Icons.add_circle_outline))));
}
