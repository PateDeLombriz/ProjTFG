String formatDate(DateTime? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String formatDateTime(DateTime? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatDate(local)} $hour:$minute';
}

// Variant per a valors dinàmics (Map<String,dynamic>) que poden ser String ISO o DateTime
String formatDateDynamic(dynamic value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final raw = value.toString().trim();
  if (raw.isEmpty) return fallback;
  if (value is DateTime) return formatDate(value, fallback: fallback);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return formatDate(parsed, fallback: fallback);
}
