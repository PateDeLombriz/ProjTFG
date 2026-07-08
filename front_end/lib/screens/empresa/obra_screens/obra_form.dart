import 'package:flutter/material.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/services/obra_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/shared/widgets/app_expandable_section.dart';
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
    'En curs',
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
      _showMessage('Has de seleccionar les dues dates.', isError: true);
      return;
    }

    if (_dataPrevFi!.isBefore(_dataInici!)) {
      _showMessage(
        'La data prevista de fi no pot ser anterior a la d’inici.',
        isError: true,
      );
      return;
    }

    if (_ubicacio == null) {
      _showMessage('Selecciona una ubicació.', isError: true);
      return;
    }

    final pressupost = _parsePressupost(_pressupostCtrl.text);
    if (pressupost == null) {
      _showMessage('El pressupost ha de ser un enter vàlid.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final request = ObraCreateRequest(
        nom: _nomCtrl.text.trim(),
        ubicacioId: _ubicacio!.idUbicacio,
        dataInici: _dataInici!,
        dataPrevFi: _dataPrevFi!,
        pressupost: pressupost,
        descripcio: _descripcioCtrl.text.trim(),
        estat: _estat,
      );

      await _service.createObraAmbUbicacio(
        request: request,
        ubicacio: _ubicacio!,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
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
          title: const Text('Nova obra'),
        ),
        body: const SafeArea(
          child: AppLoadingIndicator(),
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
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                children: [
                  ObraCreateHeaderCard(
                    title: 'Alta mínima d’obra',
                    subtitle:
                        'Defineix les dades imprescindibles i completa la resta des del detall de l’obra.',
                    nom: _nomCtrl.text,
                    estat: _estat,
                    pressupostText: _pressupostCtrl.text,
                    ubicacio: _ubicacio,
                    dataInici: _dataInici,
                    dataPrevFi: _dataPrevFi,
                  ),
                  const SizedBox(height: 14),
                  _buildDadesGeneralsSection(context),
                  const SizedBox(height: 14),
                  _buildUbicacioSection(context),
                  const SizedBox(height: 14),
                  _buildPlanificacioSection(context),
                  const SizedBox(height: 14),
                  _buildConfiguracioSection(context),
                  const SizedBox(height: 14),
                  ObraCreateSummaryCard(
                    nom: _nomCtrl.text,
                    pressupostText: _pressupostCtrl.text,
                    estat: _estat,
                    ubicacio: _ubicacio,
                    dataInici: _dataInici,
                    dataPrevFi: _dataPrevFi,
                  ),
                ],
              ),
            ),
            if (_saving)
              Container(
                color: Colors.black45,
                child: const AppLoadingIndicator(),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving || _loading ? null : _submit,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Creant obra...' : 'Crear obra'),
      ),
    );
  }

  Widget _buildDadesGeneralsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(
      title: 'Dades generals',
      subtitle: 'Nom i descripció inicial de l’obra.',
      icon: Icons.description_outlined,
      accent: scheme.primary,
      initiallyExpanded: true,
      child: Column(
        children: [
          _textField(
            controller: _nomCtrl,
            label: 'Nom *',
            icon: Icons.apartment_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Introdueix el nom de l’obra';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          _gap(),
          _textField(
            controller: _descripcioCtrl,
            label: 'Descripció inicial',
            icon: Icons.notes_outlined,
            minLines: 3,
            maxLines: 5,
            alignLabelWithHint: true,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacioSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(
      title: 'Ubicació',
      subtitle: 'Selecciona o ajusta la ubicació de l’obra.',
      icon: Icons.location_on_outlined,
      accent: scheme.tertiary,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasAvailableLocations)
            DropdownButtonFormField<ObraUbicacioInfo>(
              value: _ubicacions.any(
                (item) => item.idUbicacio == _ubicacio?.idUbicacio,
              )
                  ? _ubicacio
                  : null,
              decoration: _inputDecoration(
                'Ubicació existent',
                icon: Icons.location_city_outlined,
              ),
              items: _ubicacions
                  .map(
                    (item) => DropdownMenuItem<ObraUbicacioInfo>(
                      value: item,
                      child: Text(
                        item.displayLabel.isNotEmpty
                            ? item.displayLabel
                            : 'Ubicació #${item.idUbicacio}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _ubicacio = value);
              },
            )
          else
            const ObraFormEmptyState(
              icon: Icons.location_off_outlined,
              text:
                  'No hi ha ubicacions disponibles. Amb el backend actual aquesta pantalla només pot carregar ubicacions si rep ids coneguts o si s’afegeix un endpoint de llistat.',
            ),
          _gap(),
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
    );
  }

  Widget _buildPlanificacioSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(
      title: 'Planificació',
      subtitle: 'Dates bàsiques per iniciar el seguiment.',
      icon: Icons.event_note_outlined,
      accent: scheme.secondary,
      initiallyExpanded: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;

          if (!isWide) {
            return Column(
              children: [
                ObraDateField(
                  label: 'Data inici *',
                  value: _dataInici,
                  isRequired: true,
                  onTap: _pickDataInici,
                ),
                _gap(),
                ObraDateField(
                  label: 'Data prevista fi *',
                  value: _dataPrevFi,
                  isRequired: true,
                  accent: scheme.secondary,
                  onTap: _pickDataPrevFi,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: ObraDateField(
                  label: 'Data inici *',
                  value: _dataInici,
                  isRequired: true,
                  onTap: _pickDataInici,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ObraDateField(
                  label: 'Data prevista fi *',
                  value: _dataPrevFi,
                  isRequired: true,
                  accent: scheme.secondary,
                  onTap: _pickDataPrevFi,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfiguracioSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(
      title: 'Configuració inicial',
      subtitle: 'Estat i pressupost amb què es donarà d’alta l’obra.',
      icon: Icons.tune_rounded,
      accent: scheme.primary,
      initiallyExpanded: true,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _estat,
            decoration: _inputDecoration(
              'Estat inicial *',
              icon: Icons.flag_outlined,
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
          _gap(),
          _textField(
            controller: _pressupostCtrl,
            label: 'Pressupost inicial *',
            icon: Icons.euro_rounded,
            keyboardType: TextInputType.number,
            suffixText: '€',
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
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? suffixText,
    int? minLines,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      decoration: _inputDecoration(
        label,
        icon: icon,
        suffixText: suffixText,
        alignLabelWithHint: alignLabelWithHint,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? icon,
    String? suffixText,
    bool alignLabelWithHint = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixText: suffixText,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withOpacity(0.26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 14);
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.error.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.error_outline, color: scheme.error, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                'No s’han pogut carregar les dades inicials.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
      ),
    );
  }
}
