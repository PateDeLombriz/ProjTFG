import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static String get login => '$baseUrl/login/';
  static String get me => '$baseUrl/me/';
  static String get registerEmpresa => '$baseUrl/register/empresa/';
}