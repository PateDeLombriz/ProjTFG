import 'package:flutter/material.dart';

/// Ombres subtils per mantenir un aspecte professional.
///
/// Evitam ombres massa fortes per no donar un look antic o carregat.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0D102A43),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x12102A43),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}