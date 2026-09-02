import 'package:flutter/material.dart';

// Estat d'un treballador (actiu / baixa / acomiadat)
Color colorForTreballadorEstat(String statusKey) {
  switch (statusKey.trim().toLowerCase()) {
    case 'actiu':
      return Colors.green;
    case 'baixa':
      return Colors.orange;
    case 'acomiadat':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Criticitat numèrica (0–10): >= 7 vermell, >= 4 taronja, < 4 verd
Color colorForCriticitat(int criticitat) {
  if (criticitat >= 7) return Colors.red;
  if (criticitat >= 4) return Colors.orange;
  return Colors.green;
}

// Prioritat dinàmica (int o String): rank >= 3 vermell, == 2 taronja, == 1 verd
Color colorForPriority(dynamic value) {
  final rank = _priorityRank(value);
  if (rank >= 3) return Colors.red;
  if (rank == 2) return Colors.orange;
  if (rank == 1) return Colors.green;
  return Colors.blueGrey;
}

Color colorByEstat(String? estat) {
  switch (estat?.trim().toLowerCase()) {
    case 'oberta':
      return Colors.orange;
      case 'gestionada':
      return Colors.green;
    case 'tancada':
      return Colors.blue;
    case 'cancel·lada':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

int _priorityRank(dynamic value) {
  if (value is num) return value.toInt();
  final text = value?.toString().trim().toLowerCase() ?? '';
  switch (text) {
    case 'urgent':
    case 'urgente':
    case 'alta':
    case 'high':
      return 3;
    case 'media':
    case 'medium':
      return 2;
    case 'baixa':
    case 'baja':
    case 'low':
      return 1;
    default:
      return int.tryParse(text) ?? 0;
  }
}
