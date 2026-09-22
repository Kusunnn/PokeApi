import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PokeApiProvider extends ChangeNotifier {
  final Map<Uri, http.Response> _cache = {};

  Future<http.Response> getResource(String resource) async {
    final url = Uri.parse(resource);
    if (url.scheme != 'https' || url.host != 'pokeapi.co') {
      throw ArgumentError('Recurso de PokéAPI inválido');
    }
    if (_cache.containsKey(url)) return _cache[url]!;
    final response = await http.get(url).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el recurso (${response.statusCode})');
    }
    _cache[url] = response;
    return response;
  }

  final String _baseUrl = 'pokeapi.co';
  final String _apiPath = '/api/v2';

  Future<http.Response> getGenerations() async {
    final url = Uri.https(_baseUrl, '$_apiPath/generation');
    final response = await http.get(url);
    return response;
  }

  Future<http.Response> getGenerationDetail(int id) async {
    final url = Uri.https(_baseUrl, '$_apiPath/generation/$id');
    final response = await http.get(url);
    return response;
  }

  Future<http.Response> getPokemonDetail(int id) async {
    final url = Uri.https(_baseUrl, '$_apiPath/pokemon/$id');
    return getResource(url.toString());
  }
}
