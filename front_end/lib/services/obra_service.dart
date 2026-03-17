import 'package:http/http.dart' as http;

import 'package:front_end/models/obra_models.dart';

class ObraService {
  static const String _baseUrl = 'http://localhost:8000/api';

  Future<ObraProfileData> fetchObraProfile(int obraId) async {
    final response = await http.get(Uri.parse('$_baseUrl/obres/$obraId/'));

    if (response.statusCode != 200) {
      throw Exception('Error carregant l\'obra (${response.statusCode})');
    }

    return ObraProfileData.fromJson(response.body);
  }

  Future<void> deleteObra(int obraId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/obres/$obraId/'));

    if (response.statusCode != 204) {
      throw Exception('Error eliminant l\'obra (${response.statusCode})');
    }
  }
}