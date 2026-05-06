import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front_end/shared/constants/api_constants.dart';

class TreballadorSolRecursListScreen extends StatefulWidget {
  final String? baseUrl;

  const TreballadorSolRecursListScreen({
    super.key,
    this.baseUrl,
  });

  @override
  State<TreballadorSolRecursListScreen> createState() =>
      _TreballadorSolRecursListScreenState();
}

class _TreballadorSolRecursListScreenState
    extends State<TreballadorSolRecursListScreen> {
  late final TreballadorSolRecursService _service;
  final TextEditingController _searchController = TextEditingController();

  Future<TreballadorSolRecursListData>? _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service = TreballadorSolRecursService(
      baseUrl: widget.baseUrl ?? ApiConstants.baseUrl,
    );
    _future = _buildFuture();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<TreballadorSolRecursListData> _buildFuture() {
    return _service.fetchMySolRecursData();
  }

  Future<void> _reload() async {
    FocusScope.of(context).unfocus();

    final nextFuture = _buildFuture();
    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<TreballadorSolRecurs> _applyFilter(
    List<TreballadorSolRecurs> items,
  ) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      return item.searchableText.contains(query);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
    });
  }

  void _handleItemTap(TreballadorSolRecurs sollicitud) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _TreballadorSolRecursDetailSheet(sollicitud: sollicitud);
      },
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
        title: const Text('Les meves sol·licituds'),
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<TreballadorSolRecursListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                _TreballadorSolRecursLoadingCard(),
                SizedBox(height: 12),
                _TreballadorSolRecursLoadingCard(),
                SizedBox(height: 12),
                _TreballadorSolRecursLoadingCard(),
              ],
            );
          }

          if (snapshot.hasError) {
            return _TreballadorSolRecursErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _TreballadorSolRecursErrorState(
              message: 'No s’han rebut dades de sol·licituds.',
              onRetry: _reload,
            );
          }

          final filtered = _applyFilter(data.sollicituds);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _TreballadorSolRecursHeaderCard(
                  title: 'Les meves sol·licituds',
                  subtitle:
                      'Peticions de material i recursos que has creat amb la teva sessió.',
                  count: data.total,
                  pendentsCount: data.pendentsCount,
                  entregadesCount: data.entregadesCount,
                ),
                const SizedBox(height: 16),
                _TreballadorSolRecursSearchField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                  onClear: _clearSearch,
                ),
                const SizedBox(height: 16),
                if (data.sollicituds.isEmpty)
                  const _TreballadorSolRecursEmptyState(
                    title: 'Encara no has fet cap sol·licitud',
                    message:
                        'Quan sol·licitis recursos o material, apareixeran aquí.',
                  )
                else if (filtered.isEmpty)
                  const _TreballadorSolRecursEmptyState(
                    title: 'Cap resultat per aquesta cerca',
                    message:
                        'No s’ha trobat cap sol·licitud que coincideixi amb el text introduït.',
                  )
                else
                  ...[
                    for (int i = 0; i < filtered.length; i++) ...[
                      _TreballadorSolRecursItemCard(
                        sollicitud: filtered[i],
                        onTap: () => _handleItemTap(filtered[i]),
                      ),
                      if (i != filtered.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   SERVICE                                  */
/* -------------------------------------------------------------------------- */

class TreballadorSolRecursServiceException implements Exception {
  final String message;
  final int? statusCode;

  const TreballadorSolRecursServiceException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode == null) return message;
    return '$message [$statusCode]';
  }
}

class TreballadorSolRecursService {
  final String baseUrl;
  final http.Client _client;

  String? _validatedToken;

  TreballadorSolRecursService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void dispose() {
    _client.close();
  }

  Future<TreballadorSolRecursListData> fetchMySolRecursData() async {
    final raw = await fetchMySolRecursRaw();
    return TreballadorSolRecursListData.fromResponse(raw);
  }

  Future<dynamic> fetchMySolRecursRaw() async {
    final token = await _requireAuthenticatedSession();

    final response = await _client.get(
      Uri.parse('$baseUrl/treballadors/me/sol_recurs/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      await _handleUnauthorizedIfNeeded(response.statusCode);
      throw TreballadorSolRecursServiceException(
        _extractErrorMessage(
          response,
          fallback: 'Error carregant les teves sol·licituds de recursos.',
        ),
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }

  Future<String> _requireAuthenticatedSession() async {
    if (_validatedToken != null && _validatedToken!.isNotEmpty) {
      return _validatedToken!;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedToken = _readStoredToken(prefs);

    if (storedToken == null || storedToken.isEmpty) {
      throw const TreballadorSolRecursServiceException(
        'No hi ha cap sessió activa. Torna a iniciar sessió.',
      );
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/me/'),
      headers: _authHeaders(storedToken),
    );

    if (response.statusCode == 200) {
      await _storeSessionContext(prefs, storedToken, response.body);
      _validatedToken = storedToken;
      return storedToken;
    }

    await _handleUnauthorizedIfNeeded(response.statusCode);

    throw TreballadorSolRecursServiceException(
      _extractErrorMessage(
        response,
        fallback: 'La sessió ha caducat o no és vàlida. Torna a fer login.',
      ),
      statusCode: response.statusCode,
    );
  }

  String? _readStoredToken(SharedPreferences prefs) {
    final token = prefs.getString('token')?.trim();
    if (token != null && token.isNotEmpty) return token;

    final access = prefs.getString('access')?.trim();
    if (access != null && access.isNotEmpty) return access;

    final sessionToken = prefs.getString('session_token')?.trim();
    if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;

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
      if (decoded is! Map<String, dynamic>) return;

      final tipus = _asString(decoded['tipus'] ?? decoded['subject_type']);
      if (tipus != null) {
        await prefs.setString('tipus', tipus);
      }

      final subjectId = _asIntOrNull(
        decoded['subject_id'] ??
            decoded['id_treballador'] ??
            decoded['treballador_id'] ??
            decoded['id'],
      );

      if (subjectId != null) {
        await prefs.setString('subject_id', subjectId.toString());
        await prefs.setInt('subject_id', subjectId);
      }

      final idTreballador = _asIntOrNull(
        decoded['id_treballador'] ??
            decoded['treballador_id'] ??
            decoded['subject_id'],
      );

      if (idTreballador != null) {
        await prefs.setString('id_treballador', idTreballador.toString());
        await prefs.setInt('id_treballador', idTreballador);
      }
    } catch (_) {
      // Si /me/ retorna una resposta inesperada, no bloquejam la pantalla.
    }
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _handleUnauthorizedIfNeeded(int statusCode) async {
    if (statusCode != 401 && statusCode != 403) return;

    _validatedToken = null;
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('access');
    await prefs.remove('session_token');
    await prefs.remove('tipus');
    await prefs.remove('subject_id');
    await prefs.remove('id_treballador');
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

        final error = decoded['error'];
        if (error != null && error.toString().trim().isNotEmpty) {
          return error.toString();
        }

        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Ignoram parse errors i retornam fallback.
    }

    return fallback;
  }
}

/* -------------------------------------------------------------------------- */
/*                                    MODELS                                  */
/* -------------------------------------------------------------------------- */

class TreballadorSolRecursListData {
  final List<TreballadorSolRecurs> sollicituds;

  const TreballadorSolRecursListData({
    required this.sollicituds,
  });

  factory TreballadorSolRecursListData.fromResponse(dynamic response) {
    final list = _extractListFromResponse(response);

    final items = list
        .whereType<Map>()
        .map((item) => TreballadorSolRecurs.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList()
      ..sort((a, b) {
        final aDate = a.dataCreacio ?? a.dataNecessitat;
        final bDate = b.dataCreacio ?? b.dataNecessitat;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

    return TreballadorSolRecursListData(sollicituds: items);
  }

  int get total => sollicituds.length;

  int get pendentsCount {
    return sollicituds.where((item) => item.isPendent).length;
  }

  int get entregadesCount {
    return sollicituds.where((item) => item.isEntregada).length;
  }
}

class TreballadorSolRecurs {
  final int id;
  final int? idEmpresa;
  final int? idObra;
  final int? idRecurs;
  final String? obraNom;
  final String? recursNom;
  final String? recursTipus;
  final String? unitatsMesura;
  final double? quantitat;
  final DateTime? dataNecessitat;
  final DateTime? dataEntrega;
  final DateTime? dataCreacio;
  final String? comentari;
  final String? proveidor;
  final String? estatRaw;

  const TreballadorSolRecurs({
    required this.id,
    required this.idEmpresa,
    required this.idObra,
    required this.idRecurs,
    required this.obraNom,
    required this.recursNom,
    required this.recursTipus,
    required this.unitatsMesura,
    required this.quantitat,
    required this.dataNecessitat,
    required this.dataEntrega,
    required this.dataCreacio,
    required this.comentari,
    required this.proveidor,
    required this.estatRaw,
  });

  factory TreballadorSolRecurs.fromMap(Map<String, dynamic> map) {
    final obraMap = _firstMap([
      map['obra'],
      map['obra_info'],
      map['id_obra'],
      map['id_obra_info'],
    ]);

    final recursMap = _firstMap([
      map['recurs'],
      map['recurs_info'],
      map['id_recurs'],
      map['id_recurs_info'],
    ]);

    final idObra = _extractId(
      direct: map['id_obra'] ?? map['obra_id'],
      map: obraMap,
      keys: const ['id', 'id_obra'],
    );

    final idRecurs = _extractId(
      direct: map['id_recurs'] ?? map['recurs_id'],
      map: recursMap,
      keys: const ['id', 'id_recurs'],
    );

    return TreballadorSolRecurs(
      id: _asInt(
        map['id'] ?? map['id_sol_recurs'] ?? map['sol_recurs_id'],
      ),
      idEmpresa: _extractId(
        direct: map['id_empresa'] ?? map['empresa_id'],
        map: _asMap(map['empresa'] ?? map['empresa_info']),
        keys: const ['id', 'id_empresa'],
      ),
      idObra: idObra,
      idRecurs: idRecurs,
      obraNom: _firstNonEmptyString([
        map['obra_nom'],
        map['nom_obra'],
        obraMap?['nom'],
        obraMap?['nom_obra'],
        if (idObra != null) 'Obra #$idObra',
      ]),
      recursNom: _firstNonEmptyString([
        map['recurs_nom'],
        map['nom_recurs'],
        recursMap?['nom'],
        recursMap?['nom_recurs'],
        if (idRecurs != null) 'Recurs #$idRecurs',
      ]),
      recursTipus: _firstNonEmptyString([
        map['tipus_recurs'],
        map['recurs_tipus'],
        recursMap?['tipus_recurs'],
        recursMap?['tipus'],
      ]),
      unitatsMesura: _firstNonEmptyString([
        map['unitats_mesura'],
        map['unitat_mesura'],
        recursMap?['unitats_mesura'],
        recursMap?['unitat_mesura'],
      ]),
      quantitat: _asDoubleOrNull(
        map['quantitat'] ?? map['quantitat_sollicitada'],
      ),
      dataNecessitat: _asDateTime(
        map['data_necessitat'] ?? map['necessitat'],
      ),
      dataEntrega: _asDateTime(
        map['data_entrega'] ?? map['entrega'],
      ),
      dataCreacio: _asDateTime(
        map['data_creacio'] ?? map['created_at'] ?? map['created'],
      ),
      comentari: _asString(map['comentari'] ?? map['observacions']),
      proveidor: _asString(map['proveidor']),
      estatRaw: _asString(map['estat'] ?? map['status']),
    );
  }

  String get recursLabel {
    final value = recursNom?.trim();
    return value == null || value.isEmpty ? 'Recurs sense nom' : value;
  }

  String get obraLabel {
    final value = obraNom?.trim();
    return value == null || value.isEmpty ? 'Obra no indicada' : value;
  }

  String get proveidorLabel {
    final value = proveidor?.trim();
    return value == null || value.isEmpty ? 'Sense proveïdor' : value;
  }

  String get tipusLabel {
    final value = recursTipus?.trim();
    return value == null || value.isEmpty ? 'Sense tipus' : value;
  }

  String get quantitatLabel {
    if (quantitat == null) return 'Quantitat no indicada';

    final number = quantitat! % 1 == 0
        ? quantitat!.toInt().toString()
        : quantitat!.toStringAsFixed(2);

    final unitat = unitatsMesura?.trim();
    if (unitat == null || unitat.isEmpty) return number;

    return '$number $unitat';
  }

  String get dataNecessitatLabel {
    return _formatDate(dataNecessitat, fallback: 'Sense data de necessitat');
  }

  String get dataEntregaLabel {
    return _formatDate(dataEntrega, fallback: 'Pendent d’entrega');
  }

  String get dataCreacioLabel {
    return _formatDate(dataCreacio, fallback: 'Sense data de creació');
  }

  String get estatKey {
    final raw = estatRaw?.trim().toLowerCase();

    if (raw != null && raw.isNotEmpty) {
      if (raw == 'entregat' || raw == 'entregada' || raw == 'finalitzat') {
        return 'entregada';
      }
      if (raw == 'pendent' || raw == 'sollicitat' || raw == 'sol·licitat') {
        return 'pendent';
      }
      return raw;
    }

    if (dataEntrega != null) return 'entregada';
    return 'pendent';
  }

  String get estatLabel {
    switch (estatKey) {
      case 'entregada':
      case 'entregat':
        return 'Entregada';
      case 'pendent':
        return 'Pendent';
      case 'cancel·lada':
      case 'cancelada':
        return 'Cancel·lada';
      default:
        final raw = estatRaw?.trim();
        if (raw == null || raw.isEmpty) return 'Pendent';
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  bool get isPendent => estatKey == 'pendent';
  bool get isEntregada => estatKey == 'entregada' || estatKey == 'entregat';

  String get searchableText {
    return <String>[
      recursLabel,
      obraLabel,
      proveidorLabel,
      tipusLabel,
      quantitatLabel,
      estatLabel,
      dataNecessitatLabel,
      dataEntregaLabel,
      comentari ?? '',
    ].join(' ').toLowerCase();
  }
}

/* -------------------------------------------------------------------------- */
/*                                   WIDGETS                                  */
/* -------------------------------------------------------------------------- */

class _TreballadorSolRecursHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final int pendentsCount;
  final int entregadesCount;

  const _TreballadorSolRecursHeaderCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.pendentsCount,
    required this.entregadesCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TreballadorSolRecursTag(
                      icon: Icons.list_alt_rounded,
                      label: count == 1 ? '1 sol·licitud' : '$count sol·licituds',
                    ),
                    _TreballadorSolRecursTag(
                      icon: Icons.schedule_rounded,
                      label: pendentsCount == 1
                          ? '1 pendent'
                          : '$pendentsCount pendents',
                      accent: Colors.orange,
                    ),
                    _TreballadorSolRecursTag(
                      icon: Icons.check_circle_outline_rounded,
                      label: entregadesCount == 1
                          ? '1 entregada'
                          : '$entregadesCount entregades',
                      accent: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorSolRecursSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _TreballadorSolRecursSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = controller.text.trim().isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cerca per recurs, obra, estat o comentari',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasValue
            ? IconButton(
                tooltip: 'Neteja cerca',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),
    );
  }
}

class _TreballadorSolRecursItemCard extends StatelessWidget {
  final TreballadorSolRecurs sollicitud;
  final VoidCallback? onTap;

  const _TreballadorSolRecursItemCard({
    required this.sollicitud,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _statusColor(sollicitud.estatKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            context,
            borderColor: accent.withOpacity(0.35),
            borderWidth: 1.5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sollicitud.recursLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sollicitud.obraLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TreballadorSolRecursMiniInfo(
                          icon: Icons.inventory_outlined,
                          label: sollicitud.quantitatLabel,
                        ),
                        _TreballadorSolRecursMiniInfo(
                          icon: Icons.event_outlined,
                          label: sollicitud.dataNecessitatLabel,
                        ),
                      ],
                    ),
                    if (sollicitud.comentari?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        sollicitud.comentari!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TreballadorSolRecursStatusChip(
                    label: sollicitud.estatLabel,
                    color: accent,
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreballadorSolRecursDetailSheet extends StatelessWidget {
  final TreballadorSolRecurs sollicitud;

  const _TreballadorSolRecursDetailSheet({
    required this.sollicitud,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _statusColor(sollicitud.estatKey);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    sollicitud.recursLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                _TreballadorSolRecursStatusChip(
                  label: sollicitud.estatLabel,
                  color: accent,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TreballadorSolRecursDetailRow(
              icon: Icons.home_work_outlined,
              label: 'Obra',
              value: sollicitud.obraLabel,
            ),
            _TreballadorSolRecursDetailRow(
              icon: Icons.category_outlined,
              label: 'Tipus',
              value: sollicitud.tipusLabel,
            ),
            _TreballadorSolRecursDetailRow(
              icon: Icons.inventory_outlined,
              label: 'Quantitat',
              value: sollicitud.quantitatLabel,
            ),
            _TreballadorSolRecursDetailRow(
              icon: Icons.event_outlined,
              label: 'Data de necessitat',
              value: sollicitud.dataNecessitatLabel,
            ),
            _TreballadorSolRecursDetailRow(
              icon: Icons.local_shipping_outlined,
              label: 'Entrega',
              value: sollicitud.dataEntregaLabel,
            ),
            _TreballadorSolRecursDetailRow(
              icon: Icons.store_outlined,
              label: 'Proveïdor',
              value: sollicitud.proveidorLabel,
            ),
            _TreballadorSolRecursDetailRow(
              icon: Icons.schedule_outlined,
              label: 'Creada',
              value: sollicitud.dataCreacioLabel,
            ),
            if (sollicitud.comentari?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                'Comentari',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sollicitud.comentari!.trim(),
                style: const TextStyle(height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TreballadorSolRecursDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TreballadorSolRecursDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorSolRecursEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _TreballadorSolRecursEmptyState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TreballadorSolRecursLoadingCard extends StatelessWidget {
  const _TreballadorSolRecursLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(context),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _TreballadorSolRecursErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _TreballadorSolRecursErrorState({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(
            context,
            borderColor: scheme.error.withOpacity(0.30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: scheme.error,
                size: 34,
              ),
              const SizedBox(height: 12),
              const Text(
                'No s’han pogut carregar les sol·licituds',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Torna-ho a provar'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TreballadorSolRecursStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TreballadorSolRecursStatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TreballadorSolRecursTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _TreballadorSolRecursTag({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorSolRecursMiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TreballadorSolRecursMiniInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   HELPERS                                  */
/* -------------------------------------------------------------------------- */

BoxDecoration _cardDecoration(
  BuildContext context, {
  Color? borderColor,
  double borderWidth = 1,
}) {
  final scheme = Theme.of(context).colorScheme;

  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: borderColor ?? scheme.outline.withOpacity(0.10),
      width: borderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.035),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}

Color _statusColor(String key) {
  switch (key) {
    case 'entregada':
    case 'entregat':
      return Colors.green;
    case 'cancel·lada':
    case 'cancelada':
      return Colors.red;
    case 'pendent':
    default:
      return Colors.orange;
  }
}

List<dynamic> _extractListFromResponse(dynamic response) {
  if (response is List) return response;

  if (response is Map) {
    for (final key in [
      'results',
      'sollicituds',
      'sol_licituds',
      'sol_recurs',
      'items',
      'data',
    ]) {
      final value = response[key];
      if (value is List) return value;
    }

    return [response];
  }

  return const [];
}

Map<String, dynamic>? _firstMap(List<dynamic> values) {
  for (final value in values) {
    final map = _asMap(value);
    if (map != null) return map;
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _asInt(dynamic value) {
  return _asIntOrNull(value) ?? 0;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return int.tryParse(text);
}

double? _asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();

  final text = value.toString().trim().replaceAll(',', '.');
  if (text.isEmpty) return null;

  return double.tryParse(text);
}

String? _asString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;

  return text;
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final text = _asString(value);
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

int? _extractId({
  required dynamic direct,
  required Map<String, dynamic>? map,
  required List<String> keys,
}) {
  if (direct is Map) {
    final directMap = Map<String, dynamic>.from(direct);
    for (final key in keys) {
      final id = _asIntOrNull(directMap[key]);
      if (id != null) return id;
    }
  }

  final directId = _asIntOrNull(direct);
  if (directId != null) return directId;

  if (map == null) return null;

  for (final key in keys) {
    final id = _asIntOrNull(map[key]);
    if (id != null) return id;
  }

  return null;
}

DateTime? _asDateTime(dynamic value) {
  final text = _asString(value);
  if (text == null) return null;

  return DateTime.tryParse(text);
}

String _formatDate(
  DateTime? date, {
  required String fallback,
}) {
  if (date == null) return fallback;

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day/$month/$year';
}