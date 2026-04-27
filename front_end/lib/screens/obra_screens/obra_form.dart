import 'package:flutter/material.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/widgets/obra_widgets.dart';

class ObraCreateScreen extends StatefulWidget {
  final List<int> knownLocationIds;

  const ObraCreateScreen({
    super.key,
    this.knownLocationIds = const [],
  });

  @override
  State<ObraCreateScreen> createState() => _ObraCreateScreenState();
}

class _ObraCreateScreenState extends State<ObraCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _pressupostCtrl = TextEditingController();
  final _descripcioCtrl = TextEditingController();

  late final ObraService _service;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  List<ObraUbicacioInfo> _ubicacions = const [];
  ObraUbicacioInfo? _ubicacio;
  DateTime? _dataInici;
  DateTime? _dataPrevFi;
  String _estat = 'Planificació';

  static const List<String> _estatOptions = [
    'Planificació',
    'En execució',
    'Aturada',
    'Finalitzada',
  ];

  bool get _hasAvailableLocations => _ubicacions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _service = ObraService(baseUrl: ApiConstants.baseUrl);
    _loadInitialData();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _pressupostCtrl.dispose();
    _descripcioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await _service.ensureAuthenticatedSession();

      final ubicacions = await _service.fetchUbicacions(
        knownIds: widget.knownLocationIds,
      );

      if (!mounted) return;

      setState(() {
        _ubicacions = ubicacions;
        if (ubicacions.length == 1) {
          _ubicacio = ubicacions.first;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDataInici() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInici ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) return;

    setState(() {
      _dataInici = picked;
      if (_dataPrevFi != null && _dataPrevFi!.isBefore(picked)) {
        _dataPrevFi = picked;
      }
    });
  }

  Future<void> _pickDataPrevFi() async {
    final baseDate = _dataInici ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _dataPrevFi ?? baseDate,
      firstDate: baseDate,
      lastDate: DateTime(baseDate.year + 10),
    );

    if (picked == null) return;

    setState(() {
      _dataPrevFi = picked;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_dataInici == null || _dataPrevFi == null) {
      _showMessage('Has de seleccionar les dues dates.');
      return;
    }

    if (_dataPrevFi!.isBefore(_dataInici!)) {
      _showMessage(
        'La data prevista de fi no pot ser anterior a la d’inici.',
      );
      return;
    }

    if (_ubicacio == null) {
      _showMessage('Selecciona una ubicació.', isError: true);
      return;
    }

    if (_ubicacio!.idUbicacio <= 0) {
      _showMessage(
        'La ubicació seleccionada al mapa encara no està registrada al backend. '
        'Amb el flux actual, només es pot crear l’obra amb una ubicació existent.',
        isError: true,
      );
      return;
    }
    final pressupost = _parsePressupost(_pressupostCtrl.text);
    if (pressupost == null) {
      _showMessage('El pressupost ha de ser un enter vàlid.');
      return;
    }

    final request = ObraCreateRequest(
      nom: _nomCtrl.text.trim(),
      ubicacioId: _ubicacio!.idUbicacio,
      dataInici: _dataInici!,
      dataPrevFi: _dataPrevFi!,
      pressupost: pressupost,
      descripcio: _descripcioCtrl.text.trim(),
      estat: _estat,
    );

    setState(() => _saving = true);

    try {
      await _service.createMinimalObra(request: request);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int? _parsePressupost(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(normalized);
  }

  void _showMessage(String message, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Nova obra'),
        ),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nova obra'),
        ),
        body: SafeArea(
          child: _ErrorView(
            message: _loadError!,
            onRetry: _loadInitialData,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova obra'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ObraCreateHeaderCard(
                title: 'Alta mínima d’obra',
                subtitle:
                    'Aquesta pantalla només demana les dades imprescindibles. La resta d’informació s’ha d’editar després des del detall de l’obra.',
              ),
              const SizedBox(height: 16),
              ObraFormSection(
                title: 'Dades principals',
                subtitle: 'Nom, ubicació, dates, estat i pressupost inicial.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introdueix el nom de l’obra';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasAvailableLocations)
                          DropdownButtonFormField<ObraUbicacioInfo>(
                            value: _ubicacions.any((item) =>
                                    item.idUbicacio == _ubicacio?.idUbicacio)
                                ? _ubicacio
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Ubicació existent',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            items: _ubicacions
                                .map(
                                  (item) => DropdownMenuItem<ObraUbicacioInfo>(
                                    value: item,
                                    child: Text(
                                      item.displayLabel.isNotEmpty
                                          ? item.displayLabel
                                          : 'Ubicació #${item.idUbicacio}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _ubicacio = value);
                            },
                          )
                        else
                          const _NoLocationsView(),
                        const SizedBox(height: 12),
                        ObraLocationSectionBody.editable(
                          ubicacio: _ubicacio,
                          onChanged: (value) {
                            setState(() => _ubicacio = value);
                          },
                          title: 'Ubicació de l’obra',
                          emptyMessage:
                              'Selecciona una ubicació existent o obre el mapa per afegir-ne una.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ObraDateField(
                            label: 'Data inici *',
                            value: _dataInici,
                            onTap: _pickDataInici,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ObraDateField(
                            label: 'Data prevista fi *',
                            value: _dataPrevFi,
                            onTap: _pickDataPrevFi,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _estat,
                      decoration: InputDecoration(
                        labelText: 'Estat inicial *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _estatOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _estat = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pressupostCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Pressupost inicial *',
                        suffixText: '€',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introdueix el pressupost';
                        }
                        if (_parsePressupost(value) == null) {
                          return 'Valor no vàlid';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descripcioCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Descripció inicial',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ObraCreateSummaryCard(
                nom: _nomCtrl.text,
                pressupostText: _pressupostCtrl.text,
                estat: _estat,
                ubicacio: _ubicacio,
                dataInici: _dataInici,
                dataPrevFi: _dataPrevFi,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Desant...' : 'Crear obra'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed:
                    _saving ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Cancel·lar'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(
              'No s’han pogut carregar les dades inicials.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoLocationsView extends StatelessWidget {
  const _NoLocationsView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: Text(
        'No hi ha ubicacions disponibles. Amb el backend actual aquesta pantalla només pot carregar ubicacions si rep ids coneguts o si s’afegeix un endpoint de llistat.',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
