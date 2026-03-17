// ObraEditScreen — Edició amb estètica unificada i càrrega de dades actuals
// ---------------------------------------------------------------------------------
// • UI alineada amb HomeEmpresa: ColorScheme, inputs arrodonits, ListTiles de dates,
//   Dropdown per a l'estat, SnackBars i ombres suaus.
// • Rep una `obra` (Map) però refresca les dades des del servidor per assegurar
//   que l'usuari edita la versió més recent.
// • Mostra una capçalera compacta amb informació actual mentre es carrega/prepara.
// • En desa, fa PUT a /obres/{id}/ (canviable a PATCH si ho prefereixes).
// • Sense dependències noves. Si vols formatar moneda/dates amb `intl`, m'ho dius.
// ---------------------------------------------------------------------------------

import 'dart:convert';
import 'package:front_end/dialogs/seleccionar_ubicacio_dialog.dart';

import 'package:flutter/material.dart';
import 'package:front_end/models/ubicacio.dart';
import 'package:http/http.dart' as http;

class ObraEditScreen extends StatefulWidget {
  const ObraEditScreen({super.key, required this.obra});
  final Map<String, dynamic> obra; // ha d'incloure com a mínim 'id'

  @override
  State<ObraEditScreen> createState() => _ObraEditScreenState();
}

class _ObraEditScreenState extends State<ObraEditScreen> {
  static const String baseUrl = 'http://localhost:8000/api';

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomCtrl;
  late TextEditingController _ubicacioCtrl;
  late TextEditingController _pressupostCtrl;
  late TextEditingController _descripcioCtrl;
  final List<String> _estats = ['Res Firmat', 'En execució', 'Finalitzada'];
  String? _estat;

  DateTime? _dataInici;
  DateTime? _dataPrevFi;
  Ubicacio? _ubicacioTemporal;
  int?
      _ubicacioId; // per guardar l'id de la ubicació seleccionada al mapa, si es canvia des d'allà
  double? _latitud;
  double? _longitud;

  bool _loading = true; // mentre refresquem del servidor
  bool _saving = false;
  DateTime? _lastFetch;

  int get _id => widget.obra['id'] as int;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController();
    _ubicacioCtrl = TextEditingController();
    _pressupostCtrl = TextEditingController();
    _descripcioCtrl = TextEditingController();

    _prefill(widget.obra); // pre-omple ràpid
    _refreshFromServer(); // i després actualitza amb dades recents
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _ubicacioCtrl.dispose();
    _pressupostCtrl.dispose();
    _descripcioCtrl.dispose();
    super.dispose();
  }

  void _prefill(Map<String, dynamic> o) {
    _nomCtrl.text = (o['nom'] ?? o['Nom'] ?? '').toString();

    // 1) Guardam la FK real de la ubicació
    final ubicacioRaw = o['ubicacio'] ?? o['Ubicacio'];
    if (ubicacioRaw is int) {
      _ubicacioId = ubicacioRaw;
    } else {
      _ubicacioId = int.tryParse('${ubicacioRaw ?? ''}');
    }

    // 2) Si el backend ja ens envia la informació ampliada, la usam per mostrar text
    final ubicacioInfo = o['ubicacio_info'];
    if (ubicacioInfo is Map<String, dynamic>) {
      final adreca = (ubicacioInfo['adreca'] ?? '').toString().trim();
      final ciutat = (ubicacioInfo['ciutat'] ?? '').toString().trim();
      final provincia = (ubicacioInfo['provincia'] ?? '').toString().trim();

      _ubicacioCtrl.text = [
        adreca,
        ciutat,
        provincia,
      ].where((e) => e.isNotEmpty).join(', ');

      _latitud = double.tryParse('${ubicacioInfo['latitud'] ?? ''}');
      _longitud = double.tryParse('${ubicacioInfo['longitud'] ?? ''}');
    } else {
      // Si no hi ha ubicacio_info, deixam un text provisional
      _ubicacioCtrl.text =
          _ubicacioId == null ? '' : 'Ubicació seleccionada (#$_ubicacioId)';
    }

    final pr = o['pressupost'];
    _pressupostCtrl.text = pr == null ? '' : '$pr';

    _descripcioCtrl.text =
        (o['descripcio'] ?? o['Descripcio'] ?? '').toString();

    _dataInici = _parseDate(o['data_inici'] ?? o['DataInici']);
    _dataPrevFi = _parseDate(o['data_prev_fi'] ?? o['DataPrevFi']);

    final incoming = (o['estat'] ?? o['Estat'])?.toString().trim();

    if (incoming == null || incoming.isEmpty) {
      _estat = _estats.first;
    } else {
      if (!_estats.contains(incoming)) {
        _estats.insert(0, incoming);
      }
      _estat = incoming;
    }
  }

  Future<void> _refreshFromServer() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$baseUrl/obres/$_id/');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final o = jsonDecode(res.body) as Map<String, dynamic>;
        _prefill(o);
        _lastFetch = DateTime.now();
      } else {
        _snack('No s\'ha pogut actualitzar l\'obra (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      _snack('Error de connexió: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarUbicacioMapa() async {
    // Obrim el popup (dialog) en lloc de la pantalla completa
    final Ubicacio? resultat = await mostrarSelectorUbicacio(context);

    if (resultat == null || !mounted) return;

    setState(() {
      // Guardam l'objecte complet
      _ubicacioTemporal = resultat;

      // Encara no hi ha id definitiu si no s'ha guardat a backend
      _ubicacioId = null; // aquí pots assignar si tens id backend

      _latitud = resultat.latitud;
      _longitud = resultat.longitud;

      // Actualitzam el text visible
      _ubicacioCtrl.text = resultat.displayName.isNotEmpty
          ? resultat.displayName
          : resultat.adreca.isNotEmpty
              ? resultat.adreca
              : 'Ubicació seleccionada';
    });
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) {
      try {
        if (RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(v)) {
          final p = v.split('-');
          return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int?> _guardarUbicacioTemporalSiCal() async {
    if (_ubicacioTemporal == null) return _ubicacioId;

    final url = Uri.parse('$baseUrl/ubicacio/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_ubicacioTemporal),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final nouId = data['id_ubicacio'] ?? data['id'];
      _ubicacioId = nouId is int ? nouId : int.tryParse('$nouId');

      // Ja s'ha convertit en ubicació definitiva
      _ubicacioTemporal = null;

      return _ubicacioId;
    } else {
      _showError('No s\'ha pogut guardar la ubicació: ${response.body}');
      return null;
    }
  }

  // --------------------- SUBMIT ---------------------
  Future<void> _guardarCanvis() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInici == null || _dataPrevFi == null) {
      _snack('Selecciona les dates obligatòries.');
      return;
    }
    if (_ubicacioId == null && _ubicacioTemporal == null) {
      _snack('Selecciona una ubicació al mapa.');
      return;
    }
    final ubicacioFinalId = await _guardarUbicacioTemporalSiCal();
    if (ubicacioFinalId == null) return;

    final ok = await _confirm();
    if (ok != true) return;

    setState(() => _saving = true);
    final url = Uri.parse('$baseUrl/obres/$_id/');
    final payload = {
      'nom': _nomCtrl.text.trim(),
      'ubicacio': _ubicacioId,
      'data_inici': _fmtDate(_dataInici!),
      'data_prev_fi': _fmtDate(_dataPrevFi!),
      'pressupost': double.tryParse(_pressupostCtrl.text.replaceAll(',', '.')),
      'estat': _estat,
      'descripcio': _descripcioCtrl.text.trim(),
    };

    try {
      // Mantinc PUT per coherència amb el teu codi actual. Si prefereixes PATCH, m'ho dius.
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _snack('Obra actualitzada correctament!', success: true);
        Navigator.pop(context, jsonDecode(response.body));
      } else if (response.statusCode == 204) {
        _snack('Obra actualitzada (sense cos de resposta).', success: true);
        Navigator.pop(context, true);
      } else {
        _showError('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showError('Error de connexió: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirm() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmació'),
        content: const Text('Vols desar els canvis d\'aquesta obra?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·la'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desa'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tancar'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  Future<void> _pickDate({required bool inici}) async {
    final init = inici ? _dataInici : _dataPrevFi;
    final d = await showDatePicker(
      context: context,
      initialDate: init ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => inici ? _dataInici = d : _dataPrevFi = d);
  }

  InputDecoration _dec(BuildContext context, String label, {IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Obra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresca',
            onPressed: _refreshFromServer,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _guardarCanvis,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                nom: _nomCtrl.text,
                ubicacio: _ubicacioCtrl.text,
                estat: _estat.toString(),
                dataInici: _dataInici,
                dataPrevFi: _dataPrevFi,
                lastFetch: _lastFetch,
              ),
              const SizedBox(height: 16),

              // ---- Formulari ----
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dades generals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _nomCtrl,
                      decoration: _dec(context, 'Nom *', icon: Icons.title),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Camp obligatori'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _ubicacioCtrl,
                      readOnly: true,
                      onTap: _seleccionarUbicacioMapa,
                      decoration: _dec(
                        context,
                        'Ubicació',
                        icon: Icons.location_on_outlined,
                      ).copyWith(
                        hintText: 'Toca per seleccionar al mapa',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map_outlined),
                          onPressed: _seleccionarUbicacioMapa,
                        ),
                      ),
                      validator: (_) {
                        if (_ubicacioId == null && _ubicacioTemporal == null)
                          return 'Selecciona una ubicació al mapa';
                        return null;
                      },
                    ),

                    //const SizedBox(height: 12),
                    TextFormField(
                      controller: _pressupostCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(
                        context,
                        'Pressupost (€)',
                        icon: Icons.euro,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final val = double.tryParse(v.replaceAll(',', '.'));
                        if (val == null) return 'Introdueix un número vàlid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descripcioCtrl,
                      maxLines: 3,
                      decoration: _dec(
                        context,
                        'Descripció',
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value:
                          _estat, // pot ser null si encara no s'ha assignat; no passa res
                      decoration: _dec(
                        context,
                        'Estat *',
                        icon: Icons.flag_outlined,
                      ),
                      items: _estats
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _estat = v),
                    ),

                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data inici *'),
                      subtitle: Text(
                        _dataInici == null
                            ? 'Selecciona una data'
                            : '${_dataInici!.year}-${_dataInici!.month.toString().padLeft(2, '0')}-${_dataInici!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(inici: true),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data prevista fi *'),
                      subtitle: Text(
                        _dataPrevFi == null
                            ? 'Selecciona una data'
                            : '${_dataPrevFi!.year}-${_dataPrevFi!.month.toString().padLeft(2, '0')}-${_dataPrevFi!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(inici: false),
                    ),

                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _guardarCanvis,
                      icon: const Icon(Icons.save),
                      label: const Text('Desa canvis'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_loading || _saving)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _saving ? 'Desant canvis...' : 'Carregant dades...',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.nom,
    required this.ubicacio,
    required this.estat,
    required this.dataInici,
    required this.dataPrevFi,
    required this.lastFetch,
  });

  final String nom;
  final String ubicacio;
  final String estat;
  final DateTime? dataInici;
  final DateTime? dataPrevFi;
  final DateTime? lastFetch;

  Color _estatColor(String s, ColorScheme scheme) {
    switch (s) {
      case 'En execució':
        return Colors.orange;
      case 'Finalitzada':
        return Colors.green;
      case 'Res Firmat':
        return Colors.grey;
      default:
        return scheme.primary;
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = _estatColor(estat, scheme);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.house_siding_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom.isEmpty ? '—' : nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ubicacio.isEmpty ? 'Sense ubicació' : ubicacio,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          estat,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallTile(
                    context,
                    icon: Icons.event_available,
                    label: 'Inici',
                    value: dataInici == null ? '—' : _fmt(dataInici!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallTile(
                    context,
                    icon: Icons.event_busy,
                    label: 'Prev. fi',
                    value: dataPrevFi == null ? '—' : _fmt(dataPrevFi!),
                  ),
                ),
              ],
            ),
            if (lastFetch != null) ...[
              const SizedBox(height: 8),
              Text(
                'Darrera actualització: ${_fmt(lastFetch!)}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _smallTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
