import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openDownloadedDocument({
  required List<int> bytes,
  required String filename,
  required String contentType,
}) async {
  final blob = html.Blob(
    [Uint8List.fromList(bytes)],
    contentType.isEmpty ? 'application/octet-stream' : contentType,
  );

  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = filename.trim().isEmpty ? 'document' : filename
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}
