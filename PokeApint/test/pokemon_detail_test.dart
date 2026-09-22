import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:PokeCenter/models/pokemon_detail_response.dart';
import 'package:PokeCenter/models/pokemon_species_response.dart';
import 'package:PokeCenter/providers/poke_api_provider.dart';
import 'package:PokeCenter/screens/pokemon_detail_screen.dart';

final fixture = {
  'id': 25,
  'name': 'pikachu',
  'height': 4,
  'weight': 60,
  'base_experience': null,
  'sprites': {
    'front_default': null,
    'other': {
      'official-artwork': {'front_default': null},
    },
  },
  'types': [
    {
      'slot': 1,
      'type': {'name': 'electric'},
    },
  ],
  'abilities': [
    {
      'slot': 3,
      'is_hidden': true,
      'ability': {'name': 'lightning-rod'},
    },
  ],
  'stats': [
    {
      'base_stat': 35,
      'effort': 0,
      'stat': {'name': 'hp'},
    },
  ],
};

class FakePokeApi extends PokeApiProvider {
  final List<int> requestedIds = [];
  bool fail = false;
  bool extended = false;
  bool failChain = false;
  @override
  Future<http.Response> getResource(String url) async {
    if (url.contains('pokemon-species'))
      return http.Response(
        jsonEncode({
          'id': 25,
          'genera': [],
          'flavor_text_entries': [],
          'evolution_chain': {
            'url': 'https://pokeapi.co/api/v2/evolution-chain/10/',
          },
        }),
        200,
      );
    if (failChain) throw Exception('Sin conexión');
    return http.Response(
      jsonEncode({
        'chain': {
          'species': {
            'name': 'pichu',
            'url': 'https://pokeapi.co/api/v2/pokemon-species/172/',
          },
          'evolution_details': [],
          'evolves_to': [
            {
              'species': {
                'name': 'pikachu',
                'url': 'https://pokeapi.co/api/v2/pokemon-species/25/',
              },
              'evolution_details': [
                {
                  'trigger': {'name': 'level-up'},
                  'min_happiness': 160,
                },
              ],
              'evolves_to': [],
            },
          ],
        },
      }),
      200,
    );
  }

  @override
  Future<http.Response> getPokemonDetail(int id) async {
    requestedIds.add(id);
    if (fail) throw Exception('Sin conexión');
    return http.Response(
      jsonEncode({
        ...fixture,
        if (extended)
          'species': {'url': 'https://pokeapi.co/api/v2/pokemon-species/25/'},
      }),
      200,
    );
  }
}

void main() {
  test('Mantiene requisitos conjuntos y ramas de evolución', () {
    Map<String, dynamic> node(
      int id,
      String name,
      List children,
      List details,
    ) => {
      'species': {
        'name': name,
        'url': 'https://pokeapi.co/api/v2/pokemon-species/$id/',
      },
      'evolves_to': children,
      'evolution_details': details,
    };
    final tree = PokemonEvolution.fromJson(
      node(133, 'eevee', [
        node(134, 'vaporeon', [], [
          {
            'trigger': {'name': 'use-item'},
            'item': {'name': 'water-stone'},
          },
        ]),
        node(196, 'espeon', [], [
          {
            'trigger': {'name': 'level-up'},
            'min_happiness': 160,
            'time_of_day': 'day',
          },
        ]),
      ], []),
    );
    expect(tree.children.length, 2);
    expect(tree.children.first.speciesId, 134);
    expect(tree.children.first.conditions.single, contains('Piedra agua'));
    expect(
      tree.children.last.conditions.single,
      contains('Amistad mínima: 160'),
    );
    expect(tree.children.last.conditions.single, contains('Día'));
    expect(
      evolutionCondition({'relative_physical_stats': 0}),
      'Ataque = Defensa',
    );
    final species = PokemonSpeciesResponse.fromJson({
      'flavor_text_entries': [
        {
          'language': {'name': 'en'},
          'flavor_text': 'English',
        },
        {
          'language': {'name': 'es'},
          'flavor_text': 'Texto\n español',
        },
      ],
    });
    expect(species.description, 'Texto español');
    expect(species.captureRate, isNull);
  });

  test(
    'Parsea campos anidados, valores nulos y conserva datos al serializar',
    () {
      final pokemon = PokemonDetailResponse.fromRawJson(jsonEncode(fixture));
      expect(pokemon.id, 25);
      expect(pokemon.types.single.name, 'electric');
      expect(pokemon.abilities.single.isHidden, isTrue);
      expect(pokemon.stats.single.baseStat, 35);
      expect(pokemon.baseExperience, isNull);
      expect(pokemon.sprites.imageUrl, isNull);
      expect(
        PokemonDetailResponse.fromJson(pokemon.toJson()).toJson(),
        pokemon.toJson(),
      );
      expect(PokemonDetailResponse.fromJson({}).stats, isEmpty);
      expect(
        PokemonSprites.fromJson({'front_default': 'sprite.png'}).imageUrl,
        'sprite.png',
      );
    },
  );

  Widget app(FakePokeApi api) => ChangeNotifierProvider<PokeApiProvider>.value(
    value: api,
    child: const MaterialApp(
      home: PokemonDetailScreen(pokemonId: 25, pokemonName: 'pikachu'),
    ),
  );

  testWidgets(
    'Consulta el ID seleccionado y muestra su ficha en pantalla estrecha',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakePokeApi();
      await tester.pumpWidget(app(api));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(api.requestedIds, [25]);
      expect(find.text('Eléctrico'), findsOneWidget);
      expect(find.text('0.4 m'), findsOneWidget);
      expect(find.text('6.0 kg'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Oculta'), 200);
      expect(find.text('Oculta'), findsOneWidget);
      await tester.ensureVisible(find.text('Estadísticas'));
      await tester.tap(find.text('Estadísticas'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Total: 35'), 200);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(api));
      expect(api.requestedIds, [25]);
    },
  );

  testWidgets('Permite recuperarse de un error con Reintentar', (tester) async {
    final api = FakePokeApi()..fail = true;
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar este Pokémon.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(api.requestedIds, [25, 25]);
    expect(find.text('Eléctrico'), findsOneWidget);
  });
  testWidgets('Reintenta la cadena y abre una preevolución', (tester) async {
    final api = FakePokeApi()
      ..extended = true
      ..failChain = true;
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Evolución'));
    await tester.tap(find.text('Evolución'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reintentar'), 150);
    api.failChain = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pichu'), 150);
    await tester.tap(find.text('Pichu'));
    await tester.pumpAndSettle();
    expect(api.requestedIds, [25, 172]);
    expect(tester.takeException(), isNull);
  });
}
