import 'dart:convert';

class PokemonDetailResponse {
  final String? speciesUrl;
  final int id;
  final String name;
  final int height;
  final int weight;
  final int? baseExperience;
  final PokemonSprites sprites;
  final List<PokemonTypeItem> types;
  final List<PokemonAbilityItem> abilities;
  final List<PokemonStatItem> stats;

  PokemonDetailResponse({
    this.speciesUrl,
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    this.baseExperience,
    required this.sprites,
    required this.types,
    required this.abilities,
    required this.stats,
  });

  factory PokemonDetailResponse.fromRawJson(String str) =>
      PokemonDetailResponse.fromJson(json.decode(str));

  factory PokemonDetailResponse.fromJson(Map<String, dynamic> json) {
    var typeList = json['types'] as List? ?? [];
    var abilityList = json['abilities'] as List? ?? [];
    var statList = json['stats'] as List? ?? [];

    return PokemonDetailResponse(
      speciesUrl: json['species']?['url'],
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      height: json['height'] ?? 0,
      weight: json['weight'] ?? 0,
      baseExperience: json['base_experience'],
      sprites: PokemonSprites.fromJson(json['sprites'] ?? {}),
      types: typeList.map((i) => PokemonTypeItem.fromJson(i)).toList(),
      abilities: abilityList
          .map((i) => PokemonAbilityItem.fromJson(i))
          .toList(),
      stats: statList.map((i) => PokemonStatItem.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'species': {'url': speciesUrl},
    'id': id,
    'name': name,
    'height': height,
    'weight': weight,
    'base_experience': baseExperience,
    'sprites': sprites.toJson(),
    'types': types.map((x) => x.toJson()).toList(),
    'abilities': abilities.map((x) => x.toJson()).toList(),
    'stats': stats.map((x) => x.toJson()).toList(),
  };
}

class PokemonSprites {
  final String? frontDefault;
  final String? officialArtwork;

  PokemonSprites({this.frontDefault, this.officialArtwork});

  factory PokemonSprites.fromRawJson(String str) =>
      PokemonSprites.fromJson(json.decode(str));

  factory PokemonSprites.fromJson(Map<String, dynamic> json) => PokemonSprites(
    frontDefault: json['front_default'],
    officialArtwork: json['other']?['official-artwork']?['front_default'],
  );

  Map<String, dynamic> toJson() => {
    'front_default': frontDefault,
    'other': {
      'official-artwork': {'front_default': officialArtwork},
    },
  };

  String? get imageUrl => officialArtwork ?? frontDefault;
}

class PokemonTypeItem {
  final int slot;
  final String name;

  PokemonTypeItem({required this.slot, required this.name});

  factory PokemonTypeItem.fromRawJson(String str) =>
      PokemonTypeItem.fromJson(json.decode(str));

  factory PokemonTypeItem.fromJson(Map<String, dynamic> json) =>
      PokemonTypeItem(
        slot: json['slot'] ?? 0,
        name: json['type']?['name'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'type': {'name': name},
  };
}

class PokemonAbilityItem {
  final String name;
  final bool isHidden;
  final int slot;

  PokemonAbilityItem({
    required this.name,
    required this.isHidden,
    required this.slot,
  });

  factory PokemonAbilityItem.fromRawJson(String str) =>
      PokemonAbilityItem.fromJson(json.decode(str));

  factory PokemonAbilityItem.fromJson(Map<String, dynamic> json) =>
      PokemonAbilityItem(
        name: json['ability']?['name'] ?? '',
        isHidden: json['is_hidden'] ?? false,
        slot: json['slot'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'ability': {'name': name},
    'is_hidden': isHidden,
    'slot': slot,
  };
}

class PokemonStatItem {
  final String name;
  final int baseStat;
  final int effort;

  PokemonStatItem({
    required this.name,
    required this.baseStat,
    required this.effort,
  });

  factory PokemonStatItem.fromRawJson(String str) =>
      PokemonStatItem.fromJson(json.decode(str));

  factory PokemonStatItem.fromJson(Map<String, dynamic> json) =>
      PokemonStatItem(
        name: json['stat']?['name'] ?? '',
        baseStat: json['base_stat'] ?? 0,
        effort: json['effort'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'stat': {'name': name},
    'base_stat': baseStat,
    'effort': effort,
  };
}
