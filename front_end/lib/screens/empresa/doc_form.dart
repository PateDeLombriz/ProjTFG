//fet pero no inclos, no sé com se guarden Document

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';

/// Gestió de **Documents de l'Obra (DocumentObra)**
/// ------------------------------------------------
/// - Llista de documents d'una obra
/// - Alta / edició de metadades + selecció de fitxer (amb file_selector)
/// - Mode multi-càrrega (batch) opcional amb openFiles()
/// - Confirmacions, validacions, overlay de càrrega, _dirty guard
/// - Suport tema clar/fosc i separació en seccions (ExpansionTile / Divider)
///
/// Endpoints (adapta'ls als teus):
///   GET    /document_obra/?id_obra=XX
///   POST   /document_obra/
///   PUT    /document_obra/{id}/
///   DELETE /document_obra/{id}/
///
/// *NOTA*: aquest exemple envia només metadades del document. Si vols pujar el binari,
/// hauràs de fer servir multipart/form-data amb http.MultipartRequest.
class DocumentObraScreen extends StatefulWidget {
  final int obraId;
  const DocumentObraScreen({super.key, required this.obraId});

  @override
  State<DocumentObraScreen> createState() => _DocumentObraScreenState();
}

class _DocumentObraScreenState extends State<DocumentObraScreen> {
  static const baseUrl = 'http://localhost:8000/api';

  bool _loading = true;
  bool _saving = false;

  List<DocumentDTO> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/document_obra/?id_obra=${widget.obraId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        _documents = data.map((e) => DocumentDTO.fromJson(e)).toList();
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) _snack('Error carregant documents: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteDocument(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar document'),
        content: const Text('Segur que vols eliminar aquest document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel·la')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      final res = await http.delete(Uri.parse('$baseUrl/document_obra/$id/'));
      if (res.statusCode == 204) {
        _documents.removeWhere((d) => d.id == id);
        if (mounted) setState(() {});
        _snack('🗑️ Eliminat correctament', success: true);
      } else {
        throw Exception('Error ${res.statusCode}');
      }
    } catch (e) {
      _snack('❌ Error eliminant: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCreateDialog({bool multi = false}) async {
    if (multi) {
      final xfiles = await openFiles();
      if (xfiles.isEmpty) return;

      final drafts = <DocumentDraft>[];
      for (final xf in xfiles) {
        final bytes = await xf.length();
        drafts.add(DocumentDraft(
          nom: xf.name,
          format: _extOrBin(xf.name),
          midaMb: bytes / (1024 * 1024),
          tipus: 'general',
          fitxer: xf,
        ));
      }
      if (drafts.isEmpty) return;
      await _saveDrafts(drafts);
    } else {
      final draft = await showDialog<DocumentDraft>(
        context: context,
        builder: (ctx) => DocumentDialog(),
      );
      if (draft == null) return;
      await _saveDrafts([draft]);
    }
  }

  Future<void> _openEditDialog(DocumentDTO doc) async {
    final updated = await showDialog<DocumentDraft>(
      context: context,
      builder: (ctx) => DocumentDialog(
        initial: doc.toDraft(),
        allowChangeFile: false,
      ),
    );
    if (updated == null) return;
    await _updateDocument(doc.id, updated);
  }

  Future<void> _saveDrafts(List<DocumentDraft> drafts) async {
    setState(() => _saving = true);
    try {
      for (final d in drafts) {
        await _createDocument(d);
      }
      await _fetchDocuments();
      _snack('✅ Document(s) creat(s)!', success: true);
    } catch (e) {
      _snack('❌ Error desant documents: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createDocument(DocumentDraft d) async {
    // Només metadades. Si vols enviar el binari, canvia a MultipartRequest.
    final payload = {
      'id_obra': widget.obraId,
      'id_creador': d.idCreador ?? 1, // TODO: usuari loguejat
      'nom': d.nom,
      'format': d.format,
      'mida': double.parse(d.midaMb.toStringAsFixed(2)),
      'comentari': d.comentari,
      'data_pujada': DateTime.now().toIso8601String(),
      'tipus': d.tipus ?? 'general',
    };

    final res = await http.post(
      Uri.parse('$baseUrl/document_obra/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _updateDocument(int id, DocumentDraft d) async {
    final payload = {
      'nom': d.nom,
      'format': d.format,
      'mida': double.parse(d.midaMb.toStringAsFixed(2)),
      'comentari': d.comentari,
      'tipus': d.tipus ?? 'general',
    };

    final res = await http.put(
      Uri.parse('$baseUrl/document_obra/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      final idx = _documents.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _documents[idx] = _documents[idx].copyWith(
          nom: d.nom,
          format: d.format,
          mida: d.midaMb,
          comentari: d.comentari,
          tipus: d.tipus ?? 'general',
        );
        setState(() {});
      }
      _snack('✅ Document actualitzat!', success: true);
    } else {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents de l\'obra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDocuments,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'multi') {
                _openCreateDialog(multi: true);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'multi', child: Text('Afegir diversos fitxers...')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_documents.isEmpty)
            Center(
              child: TextButton.icon(
                onPressed: () => _openCreateDialog(multi: false),
                icon: const Icon(Icons.upload_file),
                label: const Text('Afegeix el primer document'),
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final d = _documents[i];
                return _docTile(d);
              },
            ),

          if (_saving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(multi: false),
        icon: const Icon(Icons.add),
        label: const Text('Nou document'),
      ),
    );
  }

  Widget _docTile(DocumentDTO d) {
    final icon = _iconForExt(d.format);
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(d.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Tipus: ${d.tipus ?? '—'} · ${d.mida.toStringAsFixed(2)} MB\nPujat: ${_fmtDateTime(d.dataPujada)}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') {
              _openEditDialog(d);
            } else if (v == 'delete') {
              _deleteDocument(d.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? Colors.green : null),
    );
  }

  String _fmtDateTime(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _extOrBin(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return 'bin';
    return name.substring(dot + 1).toLowerCase();
  }

  IconData _iconForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}

//==================== DIALOG ====================
class DocumentDialog extends StatefulWidget {
  final DocumentDraft? initial;
  final bool allowChangeFile;
  const DocumentDialog({super.key, this.initial, this.allowChangeFile = true});

  @override
  State<DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<DocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _comentCtrl = TextEditingController();
  final _tipusCtrl = TextEditingController();

  XFile? _file;
  double _midaMb = 0;
  String _format = 'bin';

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final i = widget.initial!;
      _nomCtrl.text = i.nom;
      _comentCtrl.text = i.comentari ?? '';
      _tipusCtrl.text = i.tipus ?? '';
      _midaMb = i.midaMb;
      _format = i.format;
      // no carreguem fitxer, ja que allowChangeFile pot ser false
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _comentCtrl.dispose();
    _tipusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nou document' : 'Editar document'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obligatori' : null,
              ),
              const SizedBox(height: 8),
              if (widget.allowChangeFile)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: Text(_file?.name ?? 'Selecciona un fitxer'),
                  subtitle: _file == null ? null : Text('${_midaMb.toStringAsFixed(2)} MB · $_format'),
                  onTap: _pickFile,
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock),
                  title: const Text('Fitxer original mantingut'),
                  subtitle: Text('Mida: ${_midaMb.toStringAsFixed(2)} MB · $_format'),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tipusCtrl,
                decoration: const InputDecoration(labelText: 'Tipus'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _comentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Comentari'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel·la')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (widget.initial == null && _file == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecciona un fitxer')),
              );
              return;
            }
            Navigator.pop(
              context,
              DocumentDraft(
                nom: _nomCtrl.text.trim(),
                format: _format,
                midaMb: _midaMb,
                comentari: _comentCtrl.text.isEmpty ? null : _comentCtrl.text,
                tipus: _tipusCtrl.text.isEmpty ? null : _tipusCtrl.text,
                fitxer: _file,
              ),
            );
          },
          child: const Text('Desa'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final x = await openFile();
    if (x == null) return;
    final sizeBytes = await x.length();
    setState(() {
      _file = x;
      _midaMb = sizeBytes / (1024 * 1024);
      _format = _extOrBin(x.name);
      if (_nomCtrl.text.trim().isEmpty) {
        _nomCtrl.text = x.name;
      }
    });
  }

  String _extOrBin(String name) {
    final i = name.lastIndexOf('.');
    if (i == -1) return 'bin';
    return name.substring(i + 1).toLowerCase();
  }
}

//==================== DTO & Draft ====================
class DocumentDTO {
  final int id;
  final int idObra;
  final int idCreador;
  final String nom;
  final String format;
  final double mida; // MB
  final String? comentari;
  final DateTime dataPujada;
  final String? tipus;

  DocumentDTO({
    required this.id,
    required this.idObra,
    required this.idCreador,
    required this.nom,
    required this.format,
    required this.mida,
    required this.dataPujada,
    this.comentari,
    this.tipus,
  });

  factory DocumentDTO.fromJson(Map<String, dynamic> json) {
    return DocumentDTO(
      id: json['id'],
      idObra: json['id_obra'],
      idCreador: json['id_creador'],
      nom: json['nom'] ?? '',
      format: json['format'] ?? 'bin',
      mida: (json['mida'] as num?)?.toDouble() ?? 0.0,
      comentari: json['comentari'],
      dataPujada: DateTime.parse(json['data_pujada']),
      tipus: json['tipus'],
    );
  }

  DocumentDTO copyWith({
    String? nom,
    String? format,
    double? mida,
    String? comentari,
    String? tipus,
  }) {
    return DocumentDTO(
      id: id,
      idObra: idObra,
      idCreador: idCreador,
      nom: nom ?? this.nom,
      format: format ?? this.format,
      mida: mida ?? this.mida,
      dataPujada: dataPujada,
      comentari: comentari ?? this.comentari,
      tipus: tipus ?? this.tipus,
    );
  }

  DocumentDraft toDraft() => DocumentDraft(
        nom: nom,
        format: format,
        midaMb: mida,
        comentari: comentari,
        tipus: tipus,
        idCreador: idCreador,
        fitxer: null, // No tenim el binari
      );
}

class DocumentDraft {
  final String nom;
  final String format;
  final double midaMb;
  final String? comentari;
  final String? tipus;
  final int? idCreador;
  final XFile? fitxer; // local

  DocumentDraft({
    required this.nom,
    required this.format,
    required this.midaMb,
    this.comentari,
    this.tipus,
    this.idCreador,
    this.fitxer,
  });
}
