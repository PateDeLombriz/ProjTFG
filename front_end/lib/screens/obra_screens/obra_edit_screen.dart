import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/shared/widgets/map_selector_widget.dart';
import 'package:front_end/widgets/obra_widgets.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ObraEditScreen extends StatefulWidget {
  final Map<String, dynamic> obra;
  final List<int> knownLocationIds;

  const ObraEditScreen({
    super.key,
    required this.obra,
    this.knownLocationIds = const [],
  });

  @override
  State<ObraEditScreen> createState() => _ObraEditScreenState();
}

class _ObraEditScreenState extends State<ObraEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _pressupostCtrl = TextEditingController();
  final _descripcioCtrl = TextEditingController();

  late final ObraService _service;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  late Obra _obraFallback;
  Obra? _obraActual;

  List<ObraUbicacioInfo> _ubicacions = const [];
  ObraUbicacioInfo? _ubicacioSeleccionada;

  DateTime? _dataInici;
  DateTime? _dataPrevFi;
  DateTime? _dataFi;
  String _estat = 'Planificació';

  final List<String> _estatOptions = [
    'Planificació',
    'En execució',
    'Aturada',
    'Finalitzada',
  ];

  int get _obraId => _extractObraId(widget.obra);

  int? get _currentUbicacioId =>
      _ubicacioSeleccionada?.idUbicacio ??
      _obraActual?.ubicacioInfo?.idUbicacio ??
      _obraActual?.ubicacio?.id;

  bool get _canEditLocation => _ubicacions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _service = ObraService(baseUrl: ApiConstants.baseUrl);

    _obraFallback = Obra.fromMap(widget.obra);
    _applyObra(_obraFallback);

    _loadCurrentData();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _pressupostCtrl.dispose();
    _descripcioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await _service.ensureAuthenticatedSession();

      final profile = await _service.fetchObraProfile(_obraId);

      List<ObraUbicacioInfo> ubicacions = const [];
      if (widget.knownLocationIds.isNotEmpty) {
        ubicacions = await _service.fetchUbicacions(
          knownIds: widget.knownLocationIds,
        );
      }

      if (!mounted) return;

      setState(() {
        _obraActual = profile.obra;
        _ubicacions = ubicacions;
        _applyObra(profile.obra, tryResolveLocation: true);
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

  void _applyObra(
    Obra obra, {
    bool tryResolveLocation = false,
  }) {
    _nomCtrl.text = obra.nom;
    _pressupostCtrl.text =
        obra.pressupost == null ? '' : obra.pressupost.toString();
    _descripcioCtrl.text = obra.descripcio ?? '';

    _dataInici = obra.dataInici;
    _dataPrevFi = obra.dataPrevFi;
    _dataFi = obra.dataFi;

    final incomingStatus = _cleanText(obra.estat);
    if (incomingStatus != null && !_estatOptions.contains(incomingStatus)) {
      _estatOptions.insert(0, incomingStatus);
    }
    _estat = incomingStatus ?? _estatOptions.first;

    if (tryResolveLocation && _ubicacions.isNotEmpty) {
      final locationId = obra.ubicacioInfo?.idUbicacio ?? obra.ubicacio?.id;
      if (locationId != null) {
        final match = _findLocationOptionById(locationId);
        if (match != null) {
          _ubicacioSeleccionada = match;
        }
      }
    }
  }

  ObraUbicacioInfo? _findLocationOptionById(int id) {
    for (final item in _ubicacions) {
      if (item.idUbicacio == id) return item;
    }
    return null;
  }

  Future<void> _pickDate({
    required _ObraEditDateField field,
  }) async {
    final now = DateTime.now();

    DateTime initialDate;
    DateTime firstDate;
    DateTime lastDate = DateTime(now.year + 10);

    switch (field) {
      case _ObraEditDateField.dataInici:
        initialDate = _dataInici ?? now;
        firstDate = DateTime(now.year - 1);
        break;
      case _ObraEditDateField.dataPrevFi:
        initialDate = _dataPrevFi ?? _dataInici ?? now;
        firstDate = _dataInici ?? DateTime(now.year - 1);
        break;
      case _ObraEditDateField.dataFi:
        initialDate = _dataFi ?? _dataPrevFi ?? _dataInici ?? now;
        firstDate = _dataInici ?? DateTime(now.year - 1);
        break;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null || !mounted) return;

    setState(() {
      switch (field) {
        case _ObraEditDateField.dataInici:
          _dataInici = picked;

          if (_dataPrevFi != null && _dataPrevFi!.isBefore(picked)) {
            _dataPrevFi = picked;
          }

          if (_dataFi != null && _dataFi!.isBefore(picked)) {
            _dataFi = picked;
          }
          break;

        case _ObraEditDateField.dataPrevFi:
          _dataPrevFi = picked;
          break;

        case _ObraEditDateField.dataFi:
          _dataFi = picked;
          break;
      }
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_dataInici == null || _dataPrevFi == null) {
      _showMessage('Has de seleccionar la data d’inici i la data prevista de fi.');
      return;
    }

    if (_dataPrevFi!.isBefore(_dataInici!)) {
      _showMessage(
        'La data prevista de fi no pot ser anterior a la d’inici.',
      );
      return;
    }

    if (_dataFi != null && _dataFi!.isBefore(_dataInici!)) {
      _showMessage(
        'La data de fi real no pot ser anterior a la data d’inici.',
      );
      return;
    }

    if (_estat == 'Finalitzada' && _dataFi == null) {
      _showMessage(
        'Si l’obra està finalitzada, has d’indicar la data de fi real.',
      );
      return;
    }

    if (_estat != 'Finalitzada' && _dataFi != null) {
      _showMessage(
        'La data de fi real només s’ha d’informar quan l’obra està finalitzada.',
      );
      return;
    }

    final pressupost = _parsePressupost(_pressupostCtrl.text);
    if (pressupost == null) {
      _showMessage('El pressupost ha de ser un enter vàlid.');
      return;
    }

    final ubicacioId = _currentUbicacioId;
    if (ubicacioId == null) {
      _showMessage(
        'Aquesta obra no té una ubicació vàlida associada.',
        isError: true,
      );
      return;
    }

    final token = await _readStoredToken();
    if (token == null || token.isEmpty) {
      _showMessage(
        'No hi ha sessió activa. Torna a iniciar sessió.',
        isError: true,
      );
      return;
    }

    final payload = <String, dynamic>{
      'nom': _nomCtrl.text.trim(),
      'ubicacio': ubicacioId,
      'data_inici': _formatApiDate(_dataInici!),
      'data_prev_fi': _formatApiDate(_dataPrevFi!),
      'data_fi': _dataFi == null ? null : _formatApiDate(_dataFi!),
      'pressupost': pressupost,
      'descripcio': _nullableTrim(_descripcioCtrl.text),
      'estat': _estat,
    };

    setState(() => _saving = true);

        setState(() => _saving = true);

    try {
      final result = await _service.updateObra(
        obraId: _obraId,
        payload: payload,
      );

      if (!mounted) return;

      _showMessage('Obra actualitzada correctament.', isError: false);
      Navigator.of(context).pop(result ?? true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<String?> _readStoredToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final legacyToken = prefs.getString('session_token')?.trim();
    if (legacyToken != null && legacyToken.isNotEmpty) {
      return legacyToken;
    }

    return null;
  }

  int? _parsePressupost(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(normalized);
  }

  String? _nullableTrim(String? value) {
    if (value == null) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _cleanText(String? value) {
    if (value == null) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _formatApiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  int _extractObraId(Map<String, dynamic> obra) {
    final raw = obra['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse('$raw');
    if (parsed == null) {
      throw ArgumentError('L’obra rebuda no conté un id vàlid.');
    }
    return parsed;
  }

  String _extractErrorMessage(
    String body, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } catch (_) {
      // Fallback si el cos no és JSON o no és usable.
    }

    return fallback;
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
    final obra = _obraActual ?? _obraFallback;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar obra'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _loading || _saving ? null : _loadCurrentData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? _ObraEditErrorView(
                        message: _loadError!,
                        onRetry: _loadCurrentData,
                      )
                    : Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ObraHeaderCard(obra: obra),
                            const SizedBox(height: 16),
                            const ObraCreateHeaderCard(
                              title: 'Edició essencial de l’obra',
                              subtitle:
                                  'Aquesta pantalla només permet canviar la informació important de l’obra. Les incidències, tasques, documents, responsables i recursos s’han d’editar des dels seus fluxos propis.',
                            ),
                            const SizedBox(height: 16),
                            ObraFormSection(
                              title: 'Informació principal',
                              subtitle:
                                  'Nom, estat, calendari, pressupost, descripció i ubicació associada.',
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
                                  ),
                                  const SizedBox(height: 14),
                                  if (_canEditLocation)
                                    UbicacioSelectorScreen(
                                      ubicacioInicial: _ubicacions.firstOrNull,
                                      
                                    )
                                  else
                                    _ObraEditReadonlyField(
                                      label: 'Ubicació',
                                      value: obra.locationLabel,
                                      helperText:
                                          'No es pot canviar des d’aquesta pantalla perquè no hi ha un llistat d’ubicacions disponible en aquest flux.',
                                    ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ObraDateField(
                                          label: 'Data inici *',
                                          value: _dataInici,
                                          onTap: () => _pickDate(
                                            field: _ObraEditDateField.dataInici,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ObraDateField(
                                          label: 'Data prevista fi *',
                                          value: _dataPrevFi,
                                          onTap: () => _pickDate(
                                            field:
                                                _ObraEditDateField.dataPrevFi,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ObraDateField(
                                    label: 'Data fi real',
                                    value: _dataFi,
                                    onTap: () => _pickDate(
                                      field: _ObraEditDateField.dataFi,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    value: _estat,
                                    decoration: InputDecoration(
                                      labelText: 'Estat *',
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
                                      setState(() {
                                        _estat = value;
                                        if (_estat != 'Finalitzada') {
                                          _dataFi = null;
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _pressupostCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Pressupost *',
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
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _descripcioCtrl,
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      labelText: 'Descripció',
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'Desant...' : 'Desar canvis',
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                              child: const Text('Cancel·lar'),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.08),
            ),
        ],
      ),
    );
  }
}

enum _ObraEditDateField {
  dataInici,
  dataPrevFi,
  dataFi,
}

class _ObraEditReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final String? helperText;

  const _ObraEditReadonlyField({
    required this.label,
    required this.value,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _ObraEditErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ObraEditErrorView({
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
              'No s’han pogut carregar les dades actuals de l’obra.',
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