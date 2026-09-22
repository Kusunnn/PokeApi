import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:PokeCenter/providers/poke_api_provider.dart';
import 'package:PokeCenter/screens/generation_list_screen.dart';
import 'package:PokeCenter/screens/pokemon_center_screen.dart';
import 'package:PokeCenter/widgets/menu_button.dart';

class _FakeApi extends PokeApiProvider {
  @override
  Future<http.Response> getGenerations() async => http.Response(
    '{"count":0,"next":null,"previous":null,"results":[]}',
    200,
  );
}

void main() {
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PokeApiProvider>(
        create: (_) => _FakeApi(),
        child: const MaterialApp(home: Scaffold(body: MenuButton())),
      ),
    );
    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();
  }

  testWidgets('Menu uses NES font and dismisses outside without navigating', (
    tester,
  ) async {
    await mount(tester);
    for (final label in ['Inicio', 'Centro Pokemon', 'Salir']) {
      expect(
        tester.widget<Text>(find.text(label)).style?.fontFamily,
        'NESFont',
      );
    }
    await tester.tapAt(const Offset(790, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('navigation-menu')), findsNothing);
    expect(find.byType(MenuButton), findsOneWidget);
  });

  testWidgets('Inicio opens the home screen', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.byType(GenerationListScreen), findsOneWidget);
    expect(find.byKey(const Key('navigation-menu')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Centro Pokemon opens its screen and its menu works', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Centro Pokemon'));
    await tester.pumpAndSettle();
    expect(find.byType(PokemonCenterScreen), findsOneWidget);
    await tester.tap(find.byType(MenuButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('navigation-menu')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Salir requests native app exit', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await mount(tester);
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
    expect(find.byKey(const Key('navigation-menu')), findsNothing);
  });
}
