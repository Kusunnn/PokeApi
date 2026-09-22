import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PokeCenter/screens/pokemon_center_screen.dart';
import 'package:PokeCenter/screens/pokemon_selection_screen.dart';
import 'package:PokeCenter/screens/pokemon_trade_screen.dart';

void main() {
  testWidgets(
    'Selects exactly six before trade and preserves selection on return',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: PokemonCenterScreen()));
      await tester.tap(find.text('IR A LA MAQUINA DE INTERCAMBIO'));
      await tester.pumpAndSettle();
      expect(find.byType(PokemonSelectionScreen), findsOneWidget);
      final proceed = find.byKey(const Key('continue-to-trade'));
      expect(tester.widget<ElevatedButton>(proceed).onPressed, isNull);
      for (var id = 1; id <= 6; id++) {
        await tester.tap(find.byKey(ValueKey('pokemon-$id')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('pokemon-7')));
      await tester.pumpAndSettle();
      expect(find.text('6 / 6 seleccionados'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pokemon-6')));
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(proceed).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('pokemon-7')));
      await tester.pumpAndSettle();
      await tester.tap(proceed);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PokemonTradeScreen>(find.byType(PokemonTradeScreen))
            .selectedPokemonIds,
        [1, 2, 3, 4, 5, 7],
      );
      await tester.tap(find.byTooltip('Abrir menu'));
      await tester.pumpAndSettle();
      expect(find.text('6 / 6 seleccionados'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('captured-pokemon-grid')),
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pokemon-36')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
