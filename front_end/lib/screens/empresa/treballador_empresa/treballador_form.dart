// lib/screens/treballador/treballador_form.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/shared/widgets/app_expandable_section.dart';
import 'package:front_end/widgets/treballador_widgets.dart';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────────
/// TreballadorForm
/// Pantalla per crear un Treballador, crear el seu Contracte lligat a l'empresa
/// loguejada (extreta del JWT) i (opcionalment) assignar permisos amb flags.
/// Estètica alineada amb la guia: Material 3, surfaceVariant, cards/xips, etc.
/// ─────────────────────────────────────────────────────────────────────────────
class TreballadorForm extends StatefulWidget {
  final int? treballadorId;
  final Map<String, dynamic>? initialData;

  const TreballadorForm({
    super.key,
    this.treballadorId,
    this.initialData,
  });

  bool get isEditing => treballadorId != null;

  @override
  State<TreballadorForm> createState() => _TreballadorFormState();
}

class _TreballadorFormState extends State<TreballadorForm> {
  //==================== CONFIG/API ====================
  late final String _baseApi = ApiConstants.baseUrl;
  late final TreballadorService _treballadorService =
      TreballadorService(baseUrl: ApiConstants.baseUrl);

  // TODO(auth): Obtenir el token real de login (p.ex. FlutterSecureStorage)
  Future<String?> _readToken() async {
    // return await storage.read(key: 'jwt');
    return null;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  //==================== FORM STATE ====================
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _cognomsCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _comentCtrl = TextEditingController();
  DateTime? _dataNaix;

  // ContracteTreballador
  DateTime? _dataContracte;
  DateTime? _dataFiContracte;
  final _carrecCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _nssCtrl = TextEditingController();
  final _salariCtrl = TextEditingController();
  String _estatTreballador = 'actiu'; // actiu | baixa | acomiadat

  bool _saving = false;

  //==================== PERMISOS (opcions + selecció) ====================
  List<_Permis> _permisos = [];
  final Map<int, _PermisSelection> _seleccioPermis = {}; // id_permis -> flags

  @override
  void initState() {
    super.initState();
    _hydrateInitialData();
    _loadPermisos();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _cognomsCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    _nickCtrl.dispose();
    _comentCtrl.dispose();

    _carrecCtrl.dispose();
    _categoriaCtrl.dispose();
    _nssCtrl.dispose();
    _salariCtrl.dispose();
    _treballadorService.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.isEditing;

  void _hydrateInitialData() {
    final data = widget.initialData;
    if (data == null) return;

    _nomCtrl.text = _stringValue(data['nom']);
    _cognomsCtrl.text = _stringValue(data['cognoms']);
    _dniCtrl.text = _stringValue(
      data['dni_nie_passaport'] ?? data['dni'] ?? data['document_identitat'],
    );
    _emailCtrl.text = _stringValue(data['email']);
    _telefonCtrl.text = _stringValue(data['telefon']);
    _nickCtrl.text = _stringValue(data['nickname']);
    _comentCtrl.text = _stringValue(data['comentaris']);
    _dataNaix = _parseDate(data['data_naixement']);

    final contracte = _firstContracte(data['contractes']);
    if (contracte != null) {
      _dataContracte = _parseDate(contracte['data_contracte']);
      _dataFiContracte = _parseDate(contracte['data_fi']);
      _carrecCtrl.text = _stringValue(contracte['carrec']);
      _categoriaCtrl.text = _stringValue(contracte['categoria_professional']);
      _nssCtrl.text = _stringValue(contracte['nss']);
      _salariCtrl.text = _stringValue(contracte['salari']);
      final estat = _stringValue(contracte['estat']).toLowerCase();
      if (estat == 'actiu' || estat == 'baixa' || estat == 'acomiadat') {
        _estatTreballador = estat;
      }
    } else {
      _carrecCtrl.text = _stringValue(data['carrec']);
      final estat = _stringValue(data['estat']).toLowerCase();
      if (estat == 'actiu' || estat == 'baixa' || estat == 'acomiadat') {
        _estatTreballador = estat;
      }
    }
  }

  Map<String, dynamic>? _firstContracte(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;

    final maps = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (maps.isEmpty) return null;

    for (final contracte in maps) {
      final estat = _stringValue(contracte['estat']).toLowerCase();
      if (estat == 'actiu') return contracte;
    }

    return maps.first;
  }

  DateTime? _parseDate(dynamic value) {
    final text = _stringValue(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  //==================== LOAD DATA ====================
  Future<void> _loadPermisos() async {
    try {
      final token = await _readToken();
      final res =
          await http.get(Uri.parse('$_baseApi/permis/'), headers: _headers(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _permisos = data.map((e) => _Permis.fromJson(e)).toList();
        });
      } else {
        _snack('No s\'han pogut carregar permisos (${res.statusCode})');
      }
    } catch (e) {
      _snack('Error carregant permisos: $e');
    }
  }

  //==================== JWT: extreure id d'empresa ====================
  Future<int?> _empresaIdFromToken() async {
    final token = await _readToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payloadB64 = parts[1]
          .replaceAll('-', '+')
          .replaceAll('_', '/')
          .padRight((parts[1].length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(payloadB64));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      if (map['tipus'] == 'empresa') {
        final sub = map['sub'];
        if (sub is int) return sub;
        if (sub is String) return int.tryParse(sub);
      }
    } catch (_) {}
    return null;
  }

  //==================== SUBMIT ====================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && _dataContracte == null) {
      _snack('⚠️ Selecciona la data de contracte');
      return;
    }

    if (_dataNaix == null) {
      final ok = await _confirmDialog(
        title: 'Sense data de naixement',
        text: 'Vols continuar sense indicar la data de naixement?',
      );
      if (ok != true) return;
    }

    setState(() => _saving = true);

    try {
      final token = await _readToken();

      if (_isEditing) {
        await _updateTreballador();

        if (mounted) {
          _snack('✅ Treballador actualitzat correctament', success: true);
          Navigator.pop(context, true);
        }
        return;
      }

      // 1) Crear Treballador
      final treId = await _createTreballador(token);

      // 2) Crear Contracte lligat a l'empresa del JWT
      final empresaId = await _empresaIdFromToken();
      if (empresaId == null) {
        throw Exception("No s'ha pogut identificar l'empresa del JWT");
      }
      await _createContracteTreballador(token, treId, empresaId);

      // 3) Assignar permisos seleccionats (opcional)
      if (_seleccioPermis.isNotEmpty) {
        await _assignarPermisos(token, treId);
      }

      if (mounted) {
        _snack('✅ Treballador creat correctament', success: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('❌ Error durant el desament: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateTreballador() async {
    final id = widget.treballadorId;
    if (id == null) {
      throw Exception('No s’ha rebut l’identificador del treballador.');
    }

    final payload = {
      'nom': _nomCtrl.text.trim(),
      'cognoms': _cognomsCtrl.text.trim(),
      'nickname': _nickCtrl.text.trim().isEmpty ? null : _nickCtrl.text.trim(),
      'dni_nie_passaport': _dniCtrl.text.trim().isEmpty
          ? null
          : _dniCtrl.text.trim(),
      'data_naixement': _dataNaix != null ? _fmtDate(_dataNaix!) : null,
      'telefon':
          _telefonCtrl.text.trim().isEmpty ? null : _telefonCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'comentaris':
          _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
    };

    await _treballadorService.updateTreballadorBasic(id, payload);
  }

  Future<int> _createTreballador(String? token) async {
    final payload = {
      'nom': _nomCtrl.text.trim(),
      'cognoms': _cognomsCtrl.text.trim(),
      'nickname': _nickCtrl.text.trim().isEmpty ? null : _nickCtrl.text.trim(),
      'dni_nie_passaport': _dniCtrl.text.trim(),
      'data_naixement': _dataNaix != null ? _fmtDate(_dataNaix!) : null,
      'telefon':
          _telefonCtrl.text.trim().isEmpty ? null : _telefonCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'comentaris':
          _comentCtrl.text.trim().isEmpty ? null : _comentCtrl.text.trim(),
      // 'foto': (si cal, via multipart)
    };

    final res = await http.post(
      Uri.parse('$_baseApi/treballadors/'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final id = (map['id'] ?? map['pk']) as int?;
      if (id == null) {
        throw Exception('Resposta sense id de treballador');
      }
      return id;
    } else {
      throw Exception('Crear Treballador -> ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _createContracteTreballador(
      String? token, int idTreballador, int idEmpresa) async {
    final payload = {
      'id_treballador': idTreballador,
      'id_empresa': idEmpresa,
      'data_contracte': _fmtDate(_dataContracte!),
      'data_fi':
          _dataFiContracte != null ? _fmtDate(_dataFiContracte!) : null,
      'salari': _salariCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_salariCtrl.text.replaceAll(',', '.')),
      'carrec':
          _carrecCtrl.text.trim().isEmpty ? null : _carrecCtrl.text.trim(),
      'categoria_professional': _categoriaCtrl.text.trim().isEmpty
          ? null
          : _categoriaCtrl.text.trim(),
      'nss': _nssCtrl.text.trim().isEmpty ? null : _nssCtrl.text.trim(),
      'estat': _estatTreballador, // 'actiu' | 'baixa' | 'acomiadat'
    };

    // TODO(backend): confirma el path exacte a urls.py (p.ex. contracte_treballador/)
    final res = await http.post(
      Uri.parse('$_baseApi/contracte_treballador/'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
          'Crear ContracteTreballador -> ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _assignarPermisos(String? token, int idTreballador) async {
    for (final entry in _seleccioPermis.entries) {
      final idPermis = entry.key;
      final sel = entry.value;

      final payload = {
        'id_treballador': idTreballador,
        'id_permis': idPermis,
        'lectura': sel.lectura,
        'escriptura': sel.escriptura,
        'edicio': sel.edicio,
      };

      final res = await http.post(
        Uri.parse('$_baseApi/permis_treballador/'),
        headers: _headers(token),
        body: jsonEncode(payload),
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception(
            'Assignar permís($idPermis) -> ${res.statusCode}: ${res.body}');
      }
    }
  }

  //==================== UI HELPERS ====================
  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<bool?> _confirmDialog({required String title, required String text}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel·la')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continua')),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2100),
    );
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outline.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: scheme.primary.withOpacity(0.55),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error.withOpacity(0.70)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.error, width: 1.4),
      ),
    );
  }

  Widget _gap([double h = 12]) => SizedBox(height: h);

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _dec(label, icon: icon),
      onChanged: (_) => setState(() {}),
    );
  }

  //==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primaryContainer.withOpacity(0.06),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar treballador' : 'Nou treballador'),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                TreballadorFormHeaderCard(
                  editing: _isEditing,
                  fullName: _fullNamePreview(),
                  documentLabel: _documentPreview(),
                  carrecLabel: _carrecPreview(),
                  estatLabel: _estatTreballadorLabel(),
                  contactLabel: _contactPreview(),
                ),
                const SizedBox(height: 14),
                _buildDadesBasiquesSection(context),
                const SizedBox(height: 14),
                _buildContacteSection(context),
                const SizedBox(height: 14),
                if (_isEditing)
                  _buildEditModeSection(context)
                else ...[
                  _buildContracteSection(context),
                  const SizedBox(height: 14),
                  _buildPermisosSection(context),
                ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _submit,
        icon: Icon(_isEditing ? Icons.edit_outlined : Icons.save_rounded),
        label: Text(_isEditing ? 'Desa canvis' : 'Desa'),
      ),
    );
  }

  Widget _buildDadesBasiquesSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(accentBorder: true,
      title: 'Dades bàsiques',
      icon: Icons.badge_outlined,
      accent: scheme.primary,
      initiallyExpanded: true,
      child: Column(
        children: [
          _textField(
            controller: _nomCtrl,
            label: 'Nom *',
            icon: Icons.person_outline,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Obligatori' : null,
          ),
          _gap(),
          _textField(
            controller: _cognomsCtrl,
            label: 'Cognoms *',
            icon: Icons.badge_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Obligatori' : null,
          ),
          _gap(),
          _textField(
            controller: _dniCtrl,
            label: _isEditing ? 'DNI/NIE/Passaport' : 'DNI/NIE/Passaport *',
            icon: Icons.credit_card,
            validator: (v) => !_isEditing &&
                    (v == null || v.trim().isEmpty)
                ? 'Obligatori'
                : null,
          ),
          _gap(),
          TreballadorFormDateTile(
            title: 'Data de naixement',
            date: _dataNaix,
            onTap: () async {
              final d = await _pickDate(_dataNaix);
              if (d != null) setState(() => _dataNaix = d);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContacteSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(accentBorder: true,
      title: 'Contacte i observacions',
      icon: Icons.contact_mail_outlined,
      accent: scheme.secondary,
      initiallyExpanded: true,
      child: Column(
        children: [
          _textField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          _gap(),
          _textField(
            controller: _telefonCtrl,
            label: 'Telèfon',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _gap(),
          _textField(
            controller: _nickCtrl,
            label: 'Àlies / nickname',
            icon: Icons.tag,
          ),
          _gap(),
          _textField(
            controller: _comentCtrl,
            label: 'Comentaris',
            icon: Icons.notes_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(accentBorder: true,
      title: 'Abast de l’edició',
      icon: Icons.info_outline_rounded,
      accent: scheme.tertiary,
      initiallyExpanded: true,
      child: TreballadorFormInfoNotice(
        accent: scheme.tertiary,
        text:
            'Aquesta edició actualitza les dades bàsiques del treballador. '
            'El contracte i els permisos es mantenen sense canvis.',
      ),
    );
  }

  Widget _buildContracteSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(accentBorder: true,
      title: 'Contracte amb l’empresa',
      icon: Icons.work_outline_rounded,
      accent: scheme.tertiary,
      initiallyExpanded: true,
      child: Column(
        children: [
          TreballadorFormDateTile(
            title: 'Data de contracte *',
            date: _dataContracte,
            isRequired: true,
            onTap: () async {
              final d = await _pickDate(_dataContracte);
              if (d != null) setState(() => _dataContracte = d);
            },
          ),
          _gap(),
          TreballadorFormDateTile(
            title: 'Data fi',
            date: _dataFiContracte,
            emptyText: 'Sense data fi',
            onTap: () async {
              final d = await _pickDate(_dataFiContracte);
              if (d != null) setState(() => _dataFiContracte = d);
            },
          ),
          _gap(),
          _textField(
            controller: _carrecCtrl,
            label: 'Càrrec',
            icon: Icons.work_outline,
          ),
          _gap(),
          _textField(
            controller: _categoriaCtrl,
            label: 'Categoria professional',
            icon: Icons.engineering_outlined,
          ),
          _gap(),
          _textField(
            controller: _nssCtrl,
            label: 'NSS',
            icon: Icons.numbers_rounded,
          ),
          _gap(),
          _textField(
            controller: _salariCtrl,
            label: 'Salari (€)',
            icon: Icons.euro_rounded,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null) return 'Número invàlid';
              return null;
            },
          ),
          _gap(),
          DropdownButtonFormField<String>(
            value: _estatTreballador,
            decoration: _dec(
              'Estat del treballador *',
              icon: Icons.flag_outlined,
            ),
            items: const [
              DropdownMenuItem(value: 'actiu', child: Text('Actiu')),
              DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
              DropdownMenuItem(value: 'acomiadat', child: Text('Acomiadat')),
            ],
            onChanged: (v) => setState(() => _estatTreballador = v ?? 'actiu'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermisosSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppExpandableSection(accentBorder: true,
      title: 'Permisos opcionals',
      icon: Icons.admin_panel_settings_outlined,
      accent: scheme.primary,
      count: _seleccioPermis.length,
      initiallyExpanded: false,
      child: _permisos.isEmpty
          ? const TreballadorFormEmptyState(
              text: 'Sense permisos disponibles.',
              icon: Icons.lock_outline_rounded,
            )
          : Column(
              children: [
                for (var i = 0; i < _permisos.length; i++) ...[
                  _permRow(_permisos[i], scheme),
                  if (i != _permisos.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  Widget _permRow(_Permis p, ColorScheme scheme) {
    final sel = _seleccioPermis[p.id];
    final selected = sel != null;

    return TreballadorFormPermissionCard(
      title: p.clauFuncional,
      description: p.descripcio,
      selected: selected,
      accent: scheme.primary,
      onSelectedChanged: (on) {
        setState(() {
          if (on) {
            _seleccioPermis[p.id] = _PermisSelection();
          } else {
            _seleccioPermis.remove(p.id);
          }
        });
      },
      child: selected
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _flagChip(
                  label: 'Lectura',
                  value: sel.lectura,
                  onChanged: (v) => setState(
                    () => _seleccioPermis[p.id] = sel.copyWith(lectura: v),
                  ),
                  color: scheme.primary,
                ),
                _flagChip(
                  label: 'Escriptura',
                  value: sel.escriptura,
                  onChanged: (v) => setState(
                    () => _seleccioPermis[p.id] = sel.copyWith(escriptura: v),
                  ),
                  color: scheme.tertiary,
                ),
                _flagChip(
                  label: 'Edició',
                  value: sel.edicio,
                  onChanged: (v) => setState(
                    () => _seleccioPermis[p.id] = sel.copyWith(edicio: v),
                  ),
                  color: Colors.green,
                ),
              ],
            )
          : null,
    );
  }

  Widget _flagChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return TreballadorFormPermissionFlagChip(
      label: label,
      value: value,
      onChanged: onChanged,
      color: color,
    );
  }

  String _fullNamePreview() {
    final nom = _nomCtrl.text.trim();
    final cognoms = _cognomsCtrl.text.trim();
    final fullName = [nom, cognoms]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    return fullName;
  }

  String _documentPreview() {
    final document = _dniCtrl.text.trim();
    return document.isEmpty ? '' : document;
  }

  String _carrecPreview() {
    final carrec = _carrecCtrl.text.trim();
    if (carrec.isNotEmpty) return carrec;
    final categoria = _categoriaCtrl.text.trim();
    if (categoria.isNotEmpty) return categoria;
    return '';
  }

  String _contactPreview() {
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) return email;
    final telefon = _telefonCtrl.text.trim();
    if (telefon.isNotEmpty) return telefon;
    final nick = _nickCtrl.text.trim();
    if (nick.isNotEmpty) return '@$nick';
    return '';
  }

  String _estatTreballadorLabel() {
    switch (_estatTreballador) {
      case 'actiu':
        return 'Actiu';
      case 'baixa':
        return 'Baixa';
      case 'acomiadat':
        return 'Acomiadat';
      default:
        return _estatTreballador;
    }
  }
}

//==================== MODELS/HELPERS (local) ====================
class _Permis {
  final int id;
  final String clauFuncional;
  final String? descripcio;

  _Permis({required this.id, required this.clauFuncional, this.descripcio});

  factory _Permis.fromJson(Map<String, dynamic> j) {
    return _Permis(
      id: j['id'] as int,
      clauFuncional:
          (j['clau_funcional'] ?? j['clauFuncional'] ?? '').toString(),
      descripcio:
          (j['descripcio'] ?? j['descripcion'] ?? j['description'])?.toString(),
    );
    }
}

class _PermisSelection {
  final bool lectura;
  final bool escriptura;
  final bool edicio;

  _PermisSelection(
      {this.lectura = false, this.escriptura = false, this.edicio = false});

  _PermisSelection copyWith({bool? lectura, bool? escriptura, bool? edicio}) {
    return _PermisSelection(
      lectura: lectura ?? this.lectura,
      escriptura: escriptura ?? this.escriptura,
      edicio: edicio ?? this.edicio,
    );
  }
}
