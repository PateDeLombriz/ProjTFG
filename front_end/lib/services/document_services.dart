import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:front_end/utils/document_download_opener_web.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/models/document_models.dart';

class DocumentServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const DocumentServiceException(
    this.message, {
    this.statusCode,
    this.body,
  });

  @override
  String toString() {
    final buffer = StringBuffer(message);

    if (statusCode != null) {
      buffer.write(' [$statusCode]');
    }

    if (body != null && body!.trim().isNotEmpty) {
      buffer.write(' ${body!.trim()}');
    }

    return buffer.toString();
  }
}

class DocumentService {
  final String baseUrl;
  final http.Client _client;

  String? _validatedToken;

  DocumentService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void dispose() {
    _client.close();
  }

  Future<DocumentObraListData> fetchDocumentsObraData(int obraId) async {
    final raw = await fetchDocumentsObraRaw(obraId);
    return DocumentObraListData.fromList(raw);
  }
  
  Future<DocumentSessionContext> requireSessionContext() async {
  await _requireAuthenticatedSession();

  final prefs = await SharedPreferences.getInstance();

  final tipus = prefs.getString('tipus')?.trim().toLowerCase();
  if (tipus != 'empresa' && tipus != 'treballador') {
    throw const DocumentServiceException(
      'No s’ha trobat el tipus d’usuari a la sessió.',
    );
  }

  final rawSubjectId = prefs.getString('subject_id')?.trim();
  final subjectId = int.tryParse(rawSubjectId ?? '');

  if (subjectId == null) {
    throw const DocumentServiceException(
      'No s’ha trobat l’identificador del subjecte a la sessió.',
    );
  }

  return DocumentSessionContext(
    tipus: tipus!,
    subjectId: subjectId,
  );
}

  Future<List<Map<String, dynamic>>> fetchDocumentsObraRaw(int obraId) async {
    final token = await _requireAuthenticatedSession();

    final uri = Uri.parse('$baseUrl/document_obra/').replace(
      queryParameters: {
        'id_obra': obraId.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw DocumentServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant els documents.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const DocumentServiceException(
        'La resposta dels documents no és vàlida.',
      );
    }

    return decoded.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  Future<DocumentObraItem> uploadDocument({
    required DocumentObraUploadRequest request,
    required XFile file,
  }) async {
    final token = await _requireAuthenticatedSession();

    final uploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/document_obra/'),
    );

    uploadRequest.headers['Authorization'] = 'Bearer $token';

    uploadRequest.fields['id_obra'] = request.obraId.toString();
    uploadRequest.fields['tipus'] = request.tipus.trim();

    final comentari = request.comentari?.trim();
    if (comentari != null && comentari.isNotEmpty) {
      uploadRequest.fields['comentari'] = comentari;
    }

    final bytes = await file.readAsBytes();

    uploadRequest.files.add(
      http.MultipartFile.fromBytes(
        'path_doc',
        bytes,
        filename: file.name,
      ),
    );

    final streamedResponse = await _client.send(uploadRequest);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw DocumentServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error pujant el document.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const DocumentServiceException(
        'La resposta de pujada del document no és vàlida.',
      );
    }

    return DocumentObraItem.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<DocumentObraItem> updateDocumentMetadata({
    required int documentId,
    String? tipus,
    String? comentari,
  }) async {
    final token = await _requireAuthenticatedSession();

    final payload = <String, dynamic>{
      if (tipus != null) 'tipus': tipus.trim(),
      if (comentari != null) 'comentari': comentari.trim().isEmpty
          ? null
          : comentari.trim(),
    };

    final response = await _client.patch(
      Uri.parse('$baseUrl/document_obra/$documentId/'),
      headers: _authHeaders(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw DocumentServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error actualitzant el document.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const DocumentServiceException(
        'La resposta d’actualització del document no és vàlida.',
      );
    }

    return DocumentObraItem.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<void> deleteDocument(int documentId) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.delete(
      Uri.parse('$baseUrl/document_obra/$documentId/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw DocumentServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error eliminant el document.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  Future<void> downloadAndOpenDocument(DocumentObraItem document) async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.get(
      Uri.parse('$baseUrl/document_obra/${document.id}/download/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw DocumentServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error baixant el document.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    final filename = _extractFilename(response) ?? document.fileName;

    await openDownloadedDocument(
      bytes: response.bodyBytes,
      filename: filename,
      contentType: contentType,
    );
  }

  Future<void> ensureAuthenticatedSession() async {
    await _requireAuthenticatedSession();
  }

  Future<String> requireUserType() async {
    await _requireAuthenticatedSession();

    final prefs = await SharedPreferences.getInstance();
    final tipus = prefs.getString('tipus')?.trim().toLowerCase();

    if (tipus == 'empresa' || tipus == 'treballador') {
      return tipus!;
    }

    throw const DocumentServiceException(
      'No s’ha trobat el tipus d’usuari a la sessió.',
    );
  }

  Future<String> _requireAuthenticatedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _readStoredToken(prefs);

    if (token == null || token.isEmpty) {
      throw const DocumentServiceException('No hi ha sessió guardada.');
    }

    if (_validatedToken == token) {
      return token;
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/me/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      await _storeSessionContext(prefs, token, response.body);
      _validatedToken = token;
      return token;
    }

    _validatedToken = null;

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _clearStoredSession();
      throw DocumentServiceException(
        _extractErrorMessage(
          response,
          fallback: 'La sessió ha caducat o no és vàlida. Torna a fer login.',
        ),
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    throw DocumentServiceException(
      _extractErrorMessage(
        response,
        fallback: 'Error al validar la sessió.',
      ),
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  String? _readStoredToken(SharedPreferences prefs) {
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) return token;

    final access = prefs.getString('access')?.trim();
    if (access != null && access.isNotEmpty) return access;

    final legacyToken = prefs.getString('session_token')?.trim();
    if (legacyToken != null && legacyToken.isNotEmpty) return legacyToken;

    return null;
  }

  Future<void> _storeSessionContext(
    SharedPreferences prefs,
    String token,
    String body,
  ) async {
    await prefs.setString('token', token);

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final tipus = decoded['tipus']?.toString();
        if (tipus != null && tipus.isNotEmpty) {
          await prefs.setString('tipus', tipus);
        }

        final subjectId = decoded['subject_id'];
        if (subjectId != null) {
          await prefs.setString('subject_id', subjectId.toString());
        }

        final idEmpresa = decoded['id_empresa'];
        if (idEmpresa != null) {
          await prefs.setString('id_empresa', idEmpresa.toString());
        }

        final idTreballador = decoded['id_treballador'];
        if (idTreballador != null) {
          await prefs.setString('id_treballador', idTreballador.toString());
        }
      }
    } catch (_) {
      // Si /me/ canvia format, mantenim token igualment.
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('access');
    await prefs.remove('session_token');
    await prefs.remove('tipus');
    await prefs.remove('subject_id');
    await prefs.remove('id_empresa');
    await prefs.remove('id_treballador');
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _handleUnauthorizedIfNeeded(int statusCode) async {
    if (statusCode == 401 || statusCode == 403) {
      _validatedToken = null;
    }
  }

  String? _extractFilename(http.Response response) {
    final disposition = response.headers['content-disposition'];
    if (disposition == null || disposition.trim().isEmpty) return null;

    final utf8Match = RegExp("filename\\*=UTF-8''([^;]+)").firstMatch(
      disposition,
    );

    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!);
    }

    final normalMatch = RegExp('filename="?([^";]+)"?').firstMatch(
      disposition,
    );

    return normalMatch?.group(1);
  }

  String _extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail != null && detail.toString().trim().isNotEmpty) {
          return detail.toString();
        }

        final errors = decoded.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');

        if (errors.trim().isNotEmpty) return errors;
      }

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.join(', ');
      }
    } catch (_) {
      // Ignorem respostes no JSON.
    }

    return fallback;
  }
}