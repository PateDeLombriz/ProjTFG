import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> openDownloadedDocument({
  required List<int> bytes,
  required String filename,
  required String contentType,
}) async {
  final directory = await getTemporaryDirectory();
  final safeName = _safeFileName(filename);
  final file = File('${directory.path}/$safeName');

  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(file.path);

  if (result.type != ResultType.done) {
    throw Exception(
      result.message.isNotEmpty
          ? result.message
          : 'No s’ha pogut obrir el document.',
    );
  }
}

String _safeFileName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'document';

  return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}