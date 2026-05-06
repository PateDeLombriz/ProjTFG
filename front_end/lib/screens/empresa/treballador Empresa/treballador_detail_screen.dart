//Aquesta pantalla es la uqe es mostra desde una sessio de empresa
//quant mira la informacio d'un treballador, es mostra el perfil del treballador, amb les seves dades i les seves obres associades
import 'package:flutter/material.dart';

import 'package:front_end/models/treballador_models.dart';
import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/Constants/api_constants.dart';
import 'package:front_end/widgets/treballador_widgets.dart';

class TreballadorDetailScreen extends StatefulWidget {
  final int treballadorId;

  const TreballadorDetailScreen({
    super.key,
    required this.treballadorId,
  });

  @override
  State<TreballadorDetailScreen> createState() =>
      _TreballadorDetailScreenState();
}

class _TreballadorDetailScreenState extends State<TreballadorDetailScreen> {
  late final TreballadorService _service;
  late Future<_TreballadorDetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _future = _loadData();
  }

  Future<_TreballadorDetailBundle> _loadData() async {
    final detailFuture = _service.fetchTreballadorDetail(widget.treballadorId);
    final tasquesFuture = _service.fetchTreballadorTasques(widget.treballadorId);
    final obresFuture =
        _service.fetchTreballadorObresParticipades(widget.treballadorId);

    final results = await Future.wait<dynamic>([
      detailFuture,
      tasquesFuture,
      obresFuture,
    ]);

    final detail = Map<String, dynamic>.from(
      results[0] as Map<String, dynamic>,
    );
    final tasques = (results[1] as List).cast<Map<String, dynamic>>();
    final obres = (results[2] as List).cast<Map<String, dynamic>>();

    return _TreballadorDetailBundle(
      profile: _buildProfileFromDetail(
        detail: detail,
        tasques: tasques,
        obres: obres,
      ),
      detail: detail,
      tasques: tasques,
      obres: obres,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Detall del treballador'),
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_TreballadorDetailBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _TreballadorDetailLoadingView();
          }

          if (snapshot.hasError) {
            return _TreballadorDetailErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _TreballadorDetailErrorView(
              message: 'No s’han rebut dades del detall del treballador.',
              onRetry: _reload,
            );
          }

          final detail = data.detail;
          final contractes = _asMapList(detail['contractes']);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                TreballadorHeaderCard(profile: data.profile),
                const SizedBox(height: 16),
                TreballadorContactCard(profile: data.profile),
                const SizedBox(height: 16),
                TreballadorSummaryCard(profile: data.profile),
                const SizedBox(height: 16),
                _TreballadorAdminInfoCard(detail: detail),
                const SizedBox(height: 16),
                _TreballadorSectionBlock(
                  title: 'Contractes',
                  icon: Icons.badge_outlined,
                  count: contractes.length,
                  initiallyExpanded: true,
                  child: contractes.isEmpty
                      ? const _TreballadorEmptyPanel(
                          text: 'No hi ha contractes disponibles.',
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < contractes.length; i++) ...[
                              _TreballadorContracteCard(
                                contracte: contractes[i],
                              ),
                              if (i != contractes.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _TreballadorSectionBlock(
                  title: 'Tasques assignades',
                  icon: Icons.task_alt_outlined,
                  count: data.tasques.length,
                  child: data.tasques.isEmpty
                      ? const _TreballadorEmptyPanel(
                          text: 'No hi ha tasques assignades.',
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < data.tasques.length; i++) ...[
                              _TreballadorTascaCard(tasca: data.tasques[i]),
                              if (i != data.tasques.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _TreballadorSectionBlock(
                  title: 'Obres participades',
                  icon: Icons.apartment_outlined,
                  count: data.obres.length,
                  child: data.obres.isEmpty
                      ? const _TreballadorEmptyPanel(
                          text: 'No hi ha obres participades.',
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < data.obres.length; i++) ...[
                              _TreballadorObraCard(obra: data.obres[i]),
                              if (i != data.obres.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TreballadorDetailBundle {
  final TreballadorProfileData profile;
  final Map<String, dynamic> detail;
  final List<Map<String, dynamic>> tasques;
  final List<Map<String, dynamic>> obres;

  const _TreballadorDetailBundle({
    required this.profile,
    required this.detail,
    required this.tasques,
    required this.obres,
  });
}

TreballadorProfileData _buildProfileFromDetail({
  required Map<String, dynamic> detail,
  required List<Map<String, dynamic>> tasques,
  required List<Map<String, dynamic>> obres,
}) {
  final contractes = _asMapList(detail['contractes']);
  final contracteActual = _selectContracteActual(contractes);

  final profileMap = <String, dynamic>{
    ...detail,
    'tasques_count': tasques.length,
    'obres_count': obres.length,
  };

  if (contracteActual != null) {
    profileMap['contracte_vigent'] = contracteActual;

    final empresaActual = _textOrNull(contracteActual['empresa']);
    if (empresaActual != null) {
      profileMap['empresa_actual'] = empresaActual;
    }
  }

  return TreballadorProfileData.fromMap(profileMap);
}

Map<String, dynamic>? _selectContracteActual(
  List<Map<String, dynamic>> contractes,
) {
  if (contractes.isEmpty) return null;

  for (final contracte in contractes) {
    final estat = _textOrNull(contracte['estat'])?.toLowerCase();
    if (estat == 'actiu' || estat == 'activa') {
      return contracte;
    }
  }

  return contractes.first;
}

class _TreballadorDetailLoadingView extends StatelessWidget {
  const _TreballadorDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        TreballadorLoadingCard(),
        SizedBox(height: 16),
        TreballadorLoadingCard(),
        SizedBox(height: 16),
        TreballadorLoadingCard(),
        SizedBox(height: 16),
        TreballadorLoadingCard(),
      ],
    );
  }
}

class _TreballadorDetailErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TreballadorDetailErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        TreballadorErrorCard(
          message: message,
          onRetry: () {
            onRetry();
          },
        ),
      ],
    );
  }
}

class _TreballadorAdminInfoCard extends StatelessWidget {
  final Map<String, dynamic> detail;

  const _TreballadorAdminInfoCard({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informació administrativa',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TreballadorInfoPill(
                label: 'DNI / NIE',
                value: _textOrFallback(detail['dni_nie_passaport']),
              ),
              _TreballadorInfoPill(
                label: 'Naixement',
                value: _formatDate(detail['data_naixement']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TreballadorDataCard(
            title: 'Comentaris',
            value: _textOrFallback(
              detail['comentaris'],
              fallback: 'Sense comentaris.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorContracteCard extends StatelessWidget {
  final Map<String, dynamic> contracte;

  const _TreballadorContracteCard({
    required this.contracte,
  });

  @override
  Widget build(BuildContext context) {
    return _TreballadorDataCard(
      title: _textOrFallback(
        contracte['empresa'],
        fallback: 'Empresa',
      ),
      subtitle: _textOrFallback(
        contracte['carrec'],
        fallback: 'Sense càrrec',
      ),
      pills: [
        _TreballadorPillData(
          label: 'Estat',
          value: _textOrFallback(contracte['estat']),
        ),
        _TreballadorPillData(
          label: 'Inici',
          value: _formatDate(contracte['data_contracte']),
        ),
        _TreballadorPillData(
          label: 'Fi',
          value: _formatDate(contracte['data_fi']),
        ),
        _TreballadorPillData(
          label: 'Salari',
          value: _formatMoney(contracte['salari']),
        ),
      ],
    );
  }
}

class _TreballadorTascaCard extends StatelessWidget {
  final Map<String, dynamic> tasca;

  const _TreballadorTascaCard({
    required this.tasca,
  });

  @override
  Widget build(BuildContext context) {
    final obra = _asMap(tasca['obra']);
    final incidencies = _asMapList(tasca['incidencies']);
    final solucions = _asMapList(tasca['solucions']);

    return _TreballadorDataCard(
      title: 'Tasca #${_textOrFallback(tasca['id'])}',
      subtitle: _textOrFallback(
        tasca['descripcio'],
        fallback: 'Sense descripció',
      ),
      pills: [
        _TreballadorPillData(
          label: 'Prioritat',
          value: _textOrFallback(
            tasca['prioritat'],
            fallback: '—',
          ),
        ),
        _TreballadorPillData(
          label: 'Inici',
          value: _formatDate(tasca['data_inici']),
        ),
        _TreballadorPillData(
          label: 'Fi',
          value: _formatDate(tasca['data_fi']),
        ),
        _TreballadorPillData(
          label: 'Incidències',
          value: incidencies.length.toString(),
        ),
        _TreballadorPillData(
          label: 'Solucions',
          value: solucions.length.toString(),
        ),
      ],
      footer: obra == null
          ? null
          : Text(
              'Obra: ${_textOrFallback(obra['nom'], fallback: 'Sense nom')}',
            ),
    );
  }
}

class _TreballadorObraCard extends StatelessWidget {
  final Map<String, dynamic> obra;

  const _TreballadorObraCard({
    required this.obra,
  });

  @override
  Widget build(BuildContext context) {
    final ubicacio = _asMap(obra['ubicacio_info']);

    return _TreballadorDataCard(
      title: _textOrFallback(
        obra['nom'],
        fallback: 'Obra',
      ),
      subtitle: _textOrFallback(
        obra['descripcio'],
        fallback: 'Sense descripció',
      ),
      pills: [
        _TreballadorPillData(
          label: 'Estat',
          value: _textOrFallback(
            obra['estat'],
            fallback: '—',
          ),
        ),
        _TreballadorPillData(
          label: 'Inici',
          value: _formatDate(obra['data_inici']),
        ),
        _TreballadorPillData(
          label: 'Fi prevista',
          value: _formatDate(obra['data_prev_fi']),
        ),
      ],
      footer: ubicacio == null
          ? null
          : Text(
              'Ubicació: ${_buildUbicacioLabel(ubicacio)}',
            ),
    );
  }
}

class _TreballadorSectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Widget child;
  final bool initiallyExpanded;

  const _TreballadorSectionBlock({
    required this.title,
    required this.icon,
    required this.count,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: scheme.primary),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            count == 1 ? '1 element' : '$count elements',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _TreballadorDataCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<_TreballadorPillData> pills;
  final Widget? footer;
  final String? value;

  const _TreballadorDataCard({
    required this.title,
    this.subtitle,
    this.pills = const [],
    this.footer,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (value != null && value!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              value!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (pills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final pill in pills)
                  _TreballadorInfoPill(
                    label: pill.label,
                    value: pill.value,
                  ),
              ],
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _TreballadorPillData {
  final String label;
  final String value;

  const _TreballadorPillData({
    required this.label,
    required this.value,
  });
}

class _TreballadorInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _TreballadorInfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorEmptyPanel extends StatelessWidget {
  final String text;

  const _TreballadorEmptyPanel({
    required this.text,
  });

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
        text,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) {
    if (item is Map<String, dynamic>) return item;
    return Map<String, dynamic>.from(item as Map);
  }).toList();
}

String _textOrFallback(dynamic value, {String fallback = '—'}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _formatDate(dynamic value) {
  if (value == null) return '—';

  final raw = value.toString().trim();
  if (raw.isEmpty) return '—';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();

  return '$day/$month/$year';
}

String _formatMoney(dynamic value) {
  if (value == null) return '—';
  final text = value.toString().trim();
  if (text.isEmpty) return '—';
  return '$text €';
}

String _buildUbicacioLabel(Map<String, dynamic> map) {
  final parts = <String>[
    if (_textOrNull(map['adreca']) != null) _textOrNull(map['adreca'])!,
    if (_textOrNull(map['adreça']) != null) _textOrNull(map['adreça'])!,
    if (_textOrNull(map['ciutat']) != null) _textOrNull(map['ciutat'])!,
    if (_textOrNull(map['provincia']) != null) _textOrNull(map['provincia'])!,
  ];

  if (parts.isEmpty) return 'Sense ubicació';
  return parts.join(', ');
}

String? _textOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}