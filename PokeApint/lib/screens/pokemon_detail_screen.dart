import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:PokeCenter/models/pokemon_detail_response.dart';
import 'package:PokeCenter/models/pokemon_species_response.dart';
import 'package:PokeCenter/providers/poke_api_provider.dart';

const _dark = Color(0xFF1E2240);
const _surface = Color(0xFFB8BDD5);
const _primary = Color(0xFF5345AB);
const _secondary = Color(0xFFE5D36D);

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;
  final String pokemonName;
  const PokemonDetailScreen({
    super.key,
    required this.pokemonId,
    required this.pokemonName,
  });
  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  late Future<PokemonDetailResponse> _pokemon;
  @override
  void initState() {
    super.initState();
    _pokemon = _load();
  }

  @override
  void didUpdateWidget(covariant PokemonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokemonId != widget.pokemonId) _pokemon = _load();
  }

  Future<PokemonDetailResponse> _load() async {
    final response = await context.read<PokeApiProvider>().getPokemonDetail(
      widget.pokemonId,
    );
    return PokemonDetailResponse.fromRawJson(response.body);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _surface,
      colorScheme: const ColorScheme.light(
        primary: _primary,
        onPrimary: Colors.white,
        secondary: _secondary,
        onSecondary: _dark,
        surface: _surface,
        onSurface: _dark,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: _dark,
        displayColor: _dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
    ),
    child: Scaffold(
      appBar: AppBar(
        title: Text(_displayName(widget.pokemonName)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                'N.º ${widget.pokemonId.toString().padLeft(3, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<PokemonDetailResponse>(
          future: _pokemon,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Cargando Pokémon',
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: _Retry(
                  message: 'No pudimos cargar este Pokémon.',
                  onRetry: () => setState(() {
                    _pokemon = _load();
                  }),
                ),
              );
            }
            return _PokemonDetails(
              key: ValueKey(snapshot.data!.id),
              pokemon: snapshot.data!,
            );
          },
        ),
      ),
    ),
  );
}

String _displayName(String name) => name
    .split('-')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
const _typeNames = {
  'normal': 'Normal',
  'fire': 'Fuego',
  'water': 'Agua',
  'electric': 'Eléctrico',
  'grass': 'Planta',
  'ice': 'Hielo',
  'fighting': 'Lucha',
  'poison': 'Veneno',
  'ground': 'Tierra',
  'flying': 'Volador',
  'psychic': 'Psíquico',
  'bug': 'Bicho',
  'rock': 'Roca',
  'ghost': 'Fantasma',
  'dragon': 'Dragón',
  'dark': 'Siniestro',
  'steel': 'Acero',
  'fairy': 'Hada',
};
const _statNames = {
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'Ataque especial',
  'special-defense': 'Defensa especial',
  'speed': 'Velocidad',
};

class _PokemonDetails extends StatefulWidget {
  final PokemonDetailResponse pokemon;
  const _PokemonDetails({super.key, required this.pokemon});
  @override
  State<_PokemonDetails> createState() => _PokemonDetailsState();
}

class _PokemonDetailsState extends State<_PokemonDetails> {
  int _tab = 0;
  late Future<PokemonSpeciesResponse>? _species;
  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  void _loadSpecies() {
    final url = widget.pokemon.speciesUrl;
    _species = url == null
        ? null
        : context
              .read<PokeApiProvider>()
              .getResource(url)
              .then(
                (response) =>
                    PokemonSpeciesResponse.fromJson(jsonDecode(response.body)),
              );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pokemon;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 380);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'POKÉDEX',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _displayName(p.name),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.catching_pokemon,
                              size: 220,
                              color: _secondary,
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: duration,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: Hero(
                              tag: 'pokemon-art-${p.id}',
                              child: _Artwork(
                                url: p.sprites.imageUrl,
                                name: p.name,
                                size: 235,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: p.types
                          .map(
                            (type) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _typeNames[type.name] ??
                                    _displayName(type.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 20,
                  children: [
                    _Measurement(
                      label: 'Altura',
                      value: '${(p.height / 10).toStringAsFixed(1)} m',
                    ),
                    _Measurement(
                      label: 'Peso',
                      value: '${(p.weight / 10).toStringAsFixed(1)} kg',
                    ),
                    _Measurement(
                      label: 'Experiencia base',
                      value: p.baseExperience?.toString() ?? '—',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Semantics(
                          selected: _tab == i,
                          child: InkWell(
                            onTap: () => setState(() {
                              _tab = i;
                            }),
                            child: AnimatedContainer(
                              duration: duration,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _tab == i
                                    ? _secondary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tab == i
                                        ? _primary
                                        : Colors.transparent,
                                    width: _tab == i ? 3 : 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                ['Ficha', 'Estadísticas', 'Evolución'][i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _tab == i ? _primary : _dark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSize(
                  duration: duration,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: duration,
                    child: _tab == 1
                        ? _Stats(
                            key: const ValueKey('stats'),
                            pokemon: p,
                            duration: duration,
                          )
                        : FutureBuilder<PokemonSpeciesResponse>(
                            future: _species,
                            builder: (context, snapshot) {
                              if (_tab == 0) {
                                return Column(
                                  key: const ValueKey('info'),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (snapshot.hasData) ...[
                                      _Heading(
                                        snapshot.data!.genus.isEmpty
                                            ? 'Acerca de este Pokémon'
                                            : snapshot.data!.genus,
                                      ),
                                      if (snapshot.data!.description.isNotEmpty)
                                        Text(
                                          snapshot.data!.description,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.6,
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                      Wrap(
                                        spacing: 28,
                                        runSpacing: 20,
                                        children: [
                                          _Measurement(
                                            label: 'Índice de captura / 255',
                                            value:
                                                snapshot.data!.captureRate
                                                    ?.toString() ??
                                                '—',
                                          ),
                                          _Measurement(
                                            label: 'Amistad base',
                                            value:
                                                snapshot.data!.happiness
                                                    ?.toString() ??
                                                '—',
                                          ),
                                          _Measurement(
                                            label: 'Categoría',
                                            value: snapshot.data!.mythical
                                                ? 'Singular'
                                                : snapshot.data!.legendary
                                                ? 'Legendario'
                                                : 'Normal',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ] else if (snapshot.hasError)
                                      _Retry(
                                        message:
                                            'No se pudo cargar la información de especie.',
                                        onRetry: () => setState(_loadSpecies),
                                      )
                                    else if (_species != null)
                                      const LinearProgressIndicator(
                                        semanticsLabel: 'Cargando especie',
                                      ),
                                    const _Heading('Habilidades'),
                                    if (p.abilities.isEmpty)
                                      const Text(
                                        'Sin habilidades disponibles.',
                                      ),
                                    for (final ability in p.abilities) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.bolt_outlined,
                                              color: _primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _displayName(ability.name),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (ability.isHidden)
                                              const Text(
                                                'Oculta',
                                                style: TextStyle(
                                                  color: _primary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                    ],
                                  ],
                                );
                              }
                              if (snapshot.hasError) {
                                return _Retry(
                                  message:
                                      'No se pudo cargar la información de especie.',
                                  onRetry: () => setState(_loadSpecies),
                                );
                              }
                              if (_species == null) {
                                return const Text(
                                  'Cadena evolutiva no disponible.',
                                );
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return _EvolutionSection(
                                key: ValueKey(snapshot.data!.id),
                                species: snapshot.data!,
                              );
                            },
                          ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'DATOS DE POKÉAPI',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: _dark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionSection extends StatefulWidget {
  final PokemonSpeciesResponse species;
  const _EvolutionSection({super.key, required this.species});
  @override
  State<_EvolutionSection> createState() => _EvolutionSectionState();
}

class _EvolutionSectionState extends State<_EvolutionSection> {
  Future<PokemonEvolution>? _chain;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final url = widget.species.evolutionUrl;
    _chain = url == null
        ? null
        : context
              .read<PokeApiProvider>()
              .getResource(url)
              .then(
                (response) => PokemonEvolution.fromJson(
                  jsonDecode(response.body)['chain'],
                ),
              );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PokemonEvolution>(
    future: _chain,
    builder: (context, snapshot) {
      if (_chain == null) return const Text('Cadena evolutiva no disponible.');
      if (snapshot.hasError) {
        return _Retry(
          message: 'No pudimos cargar las evoluciones.',
          onRetry: () => setState(_load),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final root = snapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Línea evolutiva'),
          Text(
            root.children.isEmpty
                ? 'Esta especie no tiene evoluciones registradas.'
                : 'Explora cada especie. Los requisitos pueden variar entre juegos.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          ..._nodes(root),
        ],
      );
    },
  );
  List<Widget> _nodes(PokemonEvolution node, [String? parent]) => [
    if (parent != null)
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          'Desde ${_displayName(parent)}\n${node.conditions.isEmpty ? 'Condición no disponible' : node.conditions.join('\nO bien: ')}',
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
    Material(
      color: node.speciesId == widget.species.id ? _secondary : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _Artwork(
          url:
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${node.speciesId}.png',
          name: node.name,
          size: 56,
        ),
        title: Text(
          _displayName(node.name),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          node.speciesId == widget.species.id
              ? 'Especie actual'
              : 'N.º ${node.speciesId.toString().padLeft(3, '0')}',
        ),
        trailing: node.speciesId == widget.species.id
            ? const Icon(Icons.check_circle_outline, color: _primary)
            : const Icon(Icons.arrow_forward_rounded),
        onTap: node.speciesId == widget.species.id
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PokemonDetailScreen(
                    pokemonId: node.speciesId,
                    pokemonName: node.name,
                  ),
                ),
              ),
      ),
    ),
    for (final child in node.children) ..._nodes(child, node.name),
  ];
}

class _Stats extends StatelessWidget {
  final PokemonDetailResponse pokemon;
  final Duration duration;
  const _Stats({super.key, required this.pokemon, required this.duration});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Heading('Estadísticas base'),
      const Text(
        'Valores base de la especie, antes del entrenamiento.',
        style: TextStyle(height: 1.5),
      ),
      const SizedBox(height: 24),
      if (pokemon.stats.isEmpty) const Text('Sin estadísticas disponibles.'),
      for (final stat in pokemon.stats)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _statNames[stat.name] ?? _displayName(stat.name),
                    ),
                  ),
                  Text(
                    '${stat.baseStat}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (stat.baseStat / 255).clamp(0, 1)),
                duration: duration,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(3),
                  color: _primary,
                  backgroundColor: Colors.white,
                  semanticsLabel: _statNames[stat.name] ?? stat.name,
                  semanticsValue: '${stat.baseStat}',
                ),
              ),
            ],
          ),
        ),
      const Divider(),
      const SizedBox(height: 12),
      Text(
        'Total: ${pokemon.stats.fold<int>(0, (sum, stat) => sum + stat.baseStat)}',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    ),
  );
}

class _Measurement extends StatelessWidget {
  final String label;
  final String value;
  const _Measurement({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _Artwork extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const _Artwork({required this.url, required this.name, required this.size});
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.catching_pokemon,
      size: size * .6,
      color: _dark,
      semanticLabel: 'Imagen no disponible',
    );
    return SizedBox(
      width: size,
      height: size,
      child: url == null
          ? fallback
          : Image.network(
              url!,
              fit: BoxFit.contain,
              semanticLabel: _displayName(name),
              errorBuilder: (_, error, stack) => fallback,
            ),
    );
  }
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Retry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 36),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    ),
  );
}
