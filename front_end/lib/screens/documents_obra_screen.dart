import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:front_end/models/document_models.dart';
import 'package:front_end/services/document_services.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/widgets/documents_widgets.dart';

class DocumentsObraScreen extends StatefulWidget {
  final int obraId;

  const DocumentsObraScreen({
    super.key,
    required this.obraId,
  });

  @override
  State<DocumentsObraScreen> createState() => _DocumentsObraScreenState();
}

class _DocumentsObraScreenState extends State<DocumentsObraScreen> {
  static final String _baseUrl = ApiConstants.baseUrl;

  late final DocumentService _service;
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery = '';
  DocumentSessionContext? _sessionContext;
  Future<DocumentObraListData>? _future;

  String? _selectedType;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = DocumentService(baseUrl: _baseUrl);
    _future = _loadDocuments();
    _loadSessionContext();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<DocumentObraListData> _loadDocuments() {
    return _service.fetchDocumentsObraData(widget.obraId);
  }

  Future<void> _loadSessionContext() async {
    try {
      final contextData = await _service.requireSessionContext();

      if (!mounted) return;
      setState(() {
        _sessionContext = contextData;
      });
    } catch (_) {
      // Si falla, deixam que el backend sigui qui controli permisos.
    }
  }

  Future<void> _reload() async {
    final nextFuture = _loadDocuments();

    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<DocumentObraItem> _applyFilter(DocumentObraListData data) {
    final selected = _selectedType?.trim().toLowerCase();
    final query = _searchQuery?.trim().toLowerCase();

    return data.documents.where((doc) {
      final matchesType = selected == null ||
          selected.isEmpty ||
          doc.tipus.trim().toLowerCase() == selected;

      final searchableText = [
        doc.displayName,
        doc.fileName,
        doc.tipus,
        doc.format,
        doc.comentari ?? '',
        doc.pathDoc,
      ].join(' ').toLowerCase();

      final matchesSearch = query!.isEmpty || searchableText.contains(query);

      return matchesType && matchesSearch;
    }).toList();
  }

  Future<void> _uploadDocument() async {
    final result = await _showUploadDialog();

    if (result == null) return;

    setState(() => _busy = true);

    try {
      await _service.uploadDocument(
        request: DocumentObraUploadRequest(
          obraId: widget.obraId,
          tipus: result.tipus,
          comentari: result.comentari,
        ),
        file: result.file,
      );

      await _reload();

      if (!mounted) return;
      _showMessage('Document pujat correctament.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadMultipleDocuments() async {
    final tipus = await _askTypeForMultipleUpload();
    if (tipus == null) return;

    const typeGroup = XTypeGroup(
      label: 'documents',
      extensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
    );

    final files = await openFiles(
      acceptedTypeGroups: [typeGroup],
    );

    if (files.isEmpty) return;

    setState(() => _busy = true);

    var successCount = 0;

    try {
      for (final file in files) {
        await _service.uploadDocument(
          request: DocumentObraUploadRequest(
            obraId: widget.obraId,
            tipus: tipus,
            comentari: file.name,
          ),
          file: file,
        );

        successCount++;
      }

      await _reload();

      if (!mounted) return;
      _showMessage('$successCount document(s) pujats correctament.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'S’han pujat $successCount document(s), però hi ha hagut un error: $error',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askTypeForMultipleUpload() async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'general');

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pujar diversos documents'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Tipus comú *',
                hintText: 'Ex: Pla, Informe, Certificat...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Has d’indicar el tipus.';
                }
                if (value.trim().length > 40) {
                  return 'Màxim 40 caràcters.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    // No dispose aquí si al teu Flutter Web t’ha donat problemes amb dialogs.
    return result;
  }

  Future<_DocumentUploadDialogResult?> _showUploadDialog() {
    return showDialog<_DocumentUploadDialogResult>(
      context: context,
      builder: (_) => const _DocumentUploadDialog(),
    );
  }

  Future<void> _downloadDocument(DocumentObraItem document) async {
    setState(() => _busy = true);

    try {
      await _service.downloadAndOpenDocument(document);

      if (!mounted) return;
      _showMessage('Document baixat correctament.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDocument(DocumentObraItem document) async {
    final result = await _showEditDialog(document);
    if (result == null) return;

    setState(() => _busy = true);

    try {
      await _service.updateDocumentMetadata(
        documentId: document.id,
        tipus: result.tipus,
        comentari: result.comentari,
      );

      await _reload();

      if (!mounted) return;
      _showMessage('Document actualitzat correctament.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_DocumentEditDialogResult?> _showEditDialog(
    DocumentObraItem document,
  ) {
    return showDialog<_DocumentEditDialogResult>(
      context: context,
      builder: (_) => _DocumentEditDialog(document: document),
    );
  }

  Future<void> _confirmDelete(DocumentObraItem document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar document'),
          content: Text(
            'Vols eliminar "${document.displayName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _busy = true);

    try {
      await _service.deleteDocument(document.id);
      await _reload();

      if (!mounted) return;
      _showMessage('Document eliminat correctament.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Documents de l’obra'),
        actions: [
          IconButton(
            tooltip: 'Pujar diversos documents',
            onPressed: _busy ? null : _uploadMultipleDocuments,
            icon: const Icon(Icons.drive_folder_upload_rounded),
          ),
        ],
      ),
      floatingActionButton: DocumentUploadButton(
        onPressed: _busy ? () {} : _uploadDocument,
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentObraListData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: const [
                    DocumentLoadingCard(),
                    SizedBox(height: 12),
                    DocumentLoadingCard(),
                    SizedBox(height: 12),
                    DocumentLoadingCard(),
                  ],
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    DocumentErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    ),
                  ],
                );
              }

              final data = snapshot.data;

              if (data == null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    DocumentErrorState(
                      message: 'No s’han rebut documents.',
                      onRetry: _reload,
                    ),
                  ],
                );
              }

              final filtered = _applyFilter(data);

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    DocumentListHeaderCard(
                      total: data.total,
                      selectedType: _selectedType,
                      availableTypes: data.tipusDisponibles,
                      onTypeChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Cercar document',
                        hintText: 'Nom, tipus, format...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery?.isEmpty ?? true
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (data.documents.isEmpty)
                      DocumentEmptyState(
                        title: 'Encara no hi ha documents',
                        message:
                            'Puja el primer document de l’obra per començar.',
                        onAction: _uploadDocument,
                      )
                    else if (filtered.isEmpty)
                      const DocumentEmptyState(
                        title: 'Cap document per aquest tipus',
                        message: 'Canvia el filtre per veure altres documents.',
                      )
                    else ...[
                      for (final document in filtered)
                        DocumentObraCard(
                          document: document,
                          isBusy: _busy,
                          onDownload: () => _downloadDocument(document),
                          onEdit:
                              (_sessionContext?.canModify(document) ?? false)
                                  ? () => _editDocument(document)
                                  : null,
                          onDelete:
                              (_sessionContext?.canModify(document) ?? false)
                                  ? () => _confirmDelete(document)
                                  : null,
                        ),
                    ]
                  ],
                ),
              );
            },
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              child: const AppLoadingIndicator(),
            ),
        ],
      ),
    );
  }
}

class _DocumentUploadDialog extends StatefulWidget {
  const _DocumentUploadDialog();

  @override
  State<_DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<_DocumentUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tipusController = TextEditingController(text: 'general');
  final _comentariController = TextEditingController();

  XFile? _selectedFile;

  @override
  void dispose() {
    _tipusController.dispose();
    _comentariController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'documents',
      extensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
    );

    final file = await openFile(
      acceptedTypeGroups: [typeGroup],
    );

    if (file == null) return;

    setState(() {
      _selectedFile = file;

      if (_comentariController.text.trim().isEmpty) {
        _comentariController.text = file.name;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final file = _selectedFile;

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has de seleccionar un fitxer.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      _DocumentUploadDialogResult(
        file: file,
        tipus: _tipusController.text.trim(),
        comentari: _comentariController.text.trim().isEmpty
            ? null
            : _comentariController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pujar document'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file_rounded),
                title: Text(
                  _selectedFile?.name ?? 'Selecciona un fitxer',
                ),
                subtitle: _selectedFile == null
                    ? const Text('PDF, imatge, Word o Excel')
                    : null,
                onTap: _pickFile,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipusController,
                decoration: const InputDecoration(
                  labelText: 'Tipus *',
                  hintText: 'Ex: Pla, Informe, Certificat...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Has d’indicar el tipus.';
                  }
                  if (value.trim().length > 40) {
                    return 'Màxim 40 caràcters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comentariController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comentari',
                  hintText: 'Ex: Plànol fonaments',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·lar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Pujar'),
        ),
      ],
    );
  }
}

class _DocumentEditDialog extends StatefulWidget {
  final DocumentObraItem document;

  const _DocumentEditDialog({
    required this.document,
  });

  @override
  State<_DocumentEditDialog> createState() => _DocumentEditDialogState();
}

class _DocumentEditDialogState extends State<_DocumentEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tipusController;
  late final TextEditingController _comentariController;

  @override
  void initState() {
    super.initState();

    _tipusController = TextEditingController(
      text: widget.document.tipus,
    );

    _comentariController = TextEditingController(
      text: widget.document.comentari ?? '',
    );
  }

  @override
  void dispose() {
    _tipusController.dispose();
    _comentariController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _DocumentEditDialogResult(
        tipus: _tipusController.text.trim(),
        comentari: _comentariController.text.trim().isEmpty
            ? null
            : _comentariController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;

    return AlertDialog(
      title: const Text('Editar document'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                document.fileName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipusController,
                decoration: const InputDecoration(
                  labelText: 'Tipus *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Has d’indicar el tipus.';
                  }
                  if (value.trim().length > 40) {
                    return 'Màxim 40 caràcters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comentariController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comentari',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·lar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _DocumentUploadDialogResult {
  final XFile file;
  final String tipus;
  final String? comentari;

  const _DocumentUploadDialogResult({
    required this.file,
    required this.tipus,
    this.comentari,
  });
}

class _DocumentEditDialogResult {
  final String tipus;
  final String? comentari;

  const _DocumentEditDialogResult({
    required this.tipus,
    this.comentari,
  });
}
