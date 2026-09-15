// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panbo/game_model.dart';
import 'package:panbo/main.dart';

void main() {
  testWidgets('advances the game through its phases', (tester) async {
    await tester.pumpWidget(const PanboApp());

    expect(find.text('Turno 1'), findsOneWidget);
    expect(find.text('Dado evento'), findsWidgets);

    await tester.tap(find.text('Continua'));
    await tester.pump();

    expect(find.text('Dado meteo'), findsWidgets);
  });

  test('recruits a troop by spending grain', () {
    final game = GameState();

    expect(game.recruit('Briganti'), isTrue);
    expect(game.troops['Briganti'], 1);
    expect(game.resources['Grano'], 9);
  });
}
