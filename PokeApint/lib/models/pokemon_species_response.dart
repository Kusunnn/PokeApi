/// Species information is separate from an individual Pokémon/form.
class PokemonSpeciesResponse {
  final int id;
  final String description;
  final String genus;
  final String? evolutionUrl;
  final int? captureRate;
  final int? happiness;
  final bool legendary;
  final bool mythical;
  final String growth;

  PokemonSpeciesResponse.fromJson(Map<String, dynamic> json)
    : id = json['id'] ?? 0,
      description = _localized(json['flavor_text_entries'], 'flavor_text'),
      genus = _localized(json['genera'], 'genus'),
      evolutionUrl = json['evolution_chain']?['url'],
      captureRate = json['capture_rate'],
      happiness = json['base_happiness'],
      legendary = json['is_legendary'] ?? false,
      mythical = json['is_mythical'] ?? false,
      growth = json['growth_rate']?['name'] ?? '';

  static String _localized(dynamic entries, String key) {
    final list = (entries as List? ?? []).cast<Map<String, dynamic>>();
    for (final language in ['es', 'en']) {
      for (final entry in list.reversed) {
        if (entry['language']?['name'] == language) {
          return (entry[key] as String).replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
    }
    return '';
  }
}

class PokemonEvolution {
  final int speciesId;
  final String name;
  final List<String> conditions;
  final List<PokemonEvolution> children;

  PokemonEvolution.fromJson(Map<String, dynamic> json)
    : speciesId =
          int.tryParse(
            Uri.parse(
              json['species']['url'],
            ).pathSegments.where((part) => part.isNotEmpty).last,
          ) ??
          0,
      name = json['species']['name'],
      conditions = (json['evolution_details'] as List? ?? [])
          .map(
            (detail) => evolutionCondition(Map<String, dynamic>.from(detail)),
          )
          .toList(),
      children = (json['evolves_to'] as List? ?? [])
          .map((child) => PokemonEvolution.fromJson(child))
          .toList();
}

/// Preserve every non-empty requirement; separate alternatives with OR in UI.
String evolutionCondition(Map<String, dynamic> detail) {
  const labels = {
    'min_level': 'Nivel',
    'min_happiness': 'Amistad mínima',
    'min_beauty': 'Belleza mínima',
    'min_affection': 'Afecto mínimo',
    'item': 'Objeto',
    'held_item': 'Objeto equipado',
    'known_move': 'Movimiento',
    'known_move_type': 'Tipo de movimiento',
    'location': 'Lugar',
    'party_species': 'En el equipo',
    'party_type': 'Tipo en el equipo',
    'trade_species': 'Intercambiar por',
    'time_of_day': 'Momento',
    'needs_overworld_rain': 'Lluvia en el mundo',
    'turn_upside_down': 'Consola invertida',
  };
  const names = {
    'level-up': 'Subir de nivel',
    'trade': 'Intercambio',
    'use-item': 'Usar objeto',
    'shed': 'Espacio libre y Poké Ball',
    'day': 'Día',
    'night': 'Noche',
    'dusk': 'Atardecer',
    'thunder-stone': 'Piedra trueno',
    'water-stone': 'Piedra agua',
    'fire-stone': 'Piedra fuego',
    'leaf-stone': 'Piedra hoja',
    'moon-stone': 'Piedra lunar',
    'sun-stone': 'Piedra solar',
  };
  final result = <String>[];
  final trigger = detail['trigger']?['name'];
  if (trigger != null) {
    result.add(names[trigger] ?? trigger.replaceAll('-', ' '));
  }
  for (final entry in detail.entries) {
    final value = entry.value;
    if (entry.key == 'trigger' ||
        value == null ||
        value == false ||
        value == '') {
      continue;
    }
    if (entry.key == 'gender') {
      result.add(
        value == 1
            ? 'Hembra'
            : value == 2
            ? 'Macho'
            : 'Sin género',
      );
    } else if (entry.key == 'relative_physical_stats') {
      result.add(
        value == 0
            ? 'Ataque = Defensa'
            : value == 1
            ? 'Ataque > Defensa'
            : 'Ataque < Defensa',
      );
    } else if (value == true) {
      result.add(labels[entry.key] ?? entry.key.replaceAll('_', ' '));
    } else {
      final raw = value is Map ? value['name'].toString() : value.toString();
      result.add(
        '${labels[entry.key] ?? entry.key.replaceAll('_', ' ')}: ${names[raw] ?? raw.replaceAll('-', ' ')}',
      );
    }
  }
  return result.isEmpty ? 'Condición no disponible' : result.join(' · ');
}
