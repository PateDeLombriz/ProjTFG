import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/obra.dart'; // Importamos la clase Obra


Future<List<Obra>> getObres() async {
  final String baseUrl = kIsWeb
      ? 'http://localhost:8000/api/obres/'    // 🌐 Navegador del host
      : 'http://10.0.2.2:8000/api/obres/'; 
  // Hacemos la solicitud GET a la API
  final response = await http.get(
    Uri.parse(baseUrl), //  Nom del servei
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
