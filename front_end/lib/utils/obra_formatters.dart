import 'package:front_end/models/obra_models.dart';

String obraFormatText(String? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final text = value.trim();
  return text.isEmpty ? fallback : text;
}

String obraFormatDate(DateTime? value, {String fallback = '—'}) {
  if (value == null) return fallback;

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}

String obraFormatMoney(num? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  return '€${value.toString()}';
}

String obraFormatFileSizeMb(double value) {
  return '${value.toStringAsFixed(2)} MB';
}

String obraFormatUbicacio(ObraUbicacioRef? ubicacio, {String fallback = '—'}) {
  if (ubicacio == null) return fallback;
  if (ubicacio.etiqueta != null && ubicacio.etiqueta!.trim().isNotEmpty) {
    return ubicacio.etiqueta!;
  }
  if (ubicacio.id != null) return 'Ubicació #${ubicacio.id}';
  return fallback;
}

String obraFormatResponsableCount(int count) {
  if (count == 1) return '1 responsable';
  return '$count responsables';
}