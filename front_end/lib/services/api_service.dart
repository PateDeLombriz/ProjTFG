import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/obra.dart'; // Importamos la clase Obra

Future<List<Obra>> getObres() async {
  // Hacemos la solicitud GET a la API
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/obres/'), // ✅ Nom del servei
  );
  print('STATUS CODE: ${response.statusCode}');
  print('BODY: ${response.body}');
  
  if (response.statusCode == 200) {
    // Si la respuesta es exitosa, decodificamos el JSON
    List<dynamic> apidata = jsonDecode(response.body);
    List<Obra> obras = apidata.map((json) => Obra.fromJson(json)).toList();
    return obras;
  } else {
    // Si hay algún error, lanzamos una excepción
    throw Exception('Failed to load obras');
  }
}
