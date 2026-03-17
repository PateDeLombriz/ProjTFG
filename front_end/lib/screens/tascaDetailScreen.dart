import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Shared del projecte.
// Aquests imports assumeixen que els components compartits ja existeixen
// amb aquests noms dins shared/.
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/widgets/app_card.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';
import 'package:front_end/shared/widgets/app_section.dart';

////////////////////////////////////////////////////////////////////////////////
// FUTUR FITXER: models/tasca_models.dart
////////////////////////////////////////////////////////////////////////////////

/// Model principal del detall d'una tasca.
///
/// Aquest model evita treballar amb Map<String, dynamic> com a estructura final
/// dins la pantalla. El parseig es fa una sola vegada a fromJson().
class TascaDetail {
  final int id;
  final String descripcio;
  final String? dataInici;
  final String? dataFi;
  final int? prioritat;
  final bool visibilitatTasca;
  final TascaObraSummary? obra;
  final TascaParentSummary? tascaPare;
  final TascaTreballadorSummary? treballador;
  final List<TascaDescriptionItem> incidencies;
  final List<TascaDescriptionItem> solucions;

  const TascaDetail({
    required this.id,
    required this.descripcio,
    required this.dataInici,
    required this.dataFi,
    required this.prioritat,
    required this.visibilitatTasca,
    required this.obra,
    required this.tascaPare,
    required this.treballador,
    required this.incidencies,
    required this.solucions,
  });

  factory TascaDetail.fromJson(Map<String, dynamic> json) {
    return TascaDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      descripcio: (json['descripcio'] ?? '') as String,
      dataInici: json['data_inici'] as String?,
      dataFi: json['data_fi'] as String?,
      prioritat: (json['prioritat'] as num?)?.toInt(),
      visibilitatTasca: (json['visibilitat_tasca'] ?? false) as bool,
      obra: json['obra'] is Map<String, dynamic>
          ? TascaObraSummary.fromJson(json['obra'] as Map<String, dynamic>)
          : null,
      tascaPare: json['tasca_pare'] is Map<String, dynamic>
          ? TascaParentSummary.fromJson(
              json['tasca_pare'] as Map<String, dynamic>,
            )
          : null,
      treballador: json['treballador'] is Map<String, dynamic>
          ? TascaTreballadorSummary.fromJson(
              json['treballador'] as Map<String, dynamic>,
            )
          : null,
      incidencies: ((json['incidencies'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TascaDescriptionItem.fromJson)
          .toList(),
      solucions: ((json['solucions'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TascaDescriptionItem.fromJson)
          .toList(),
    );
  }
}

/// Resum mínim de l'obra associada a la tasca.
///
/// Es manté dins el domini tasca perquè només representa la informació que
/// aquesta vista necessita de l'obra, sense redefinir el model complet d'obra.
class TascaObraSummary {
  final String? nom;
  final String? ubicacio;

  const TascaObraSummary({
    required this.nom,
    required this.ubicacio,
  });

  factory TascaObraSummary.fromJson(Map<String, dynamic> json) {
    return TascaObraSummary(
      nom: json['nom'] as String?,
      ubicacio: json['ubicacio']?.toString(),
    );
  }
}

/// Resum mínim de la tasca pare.
class TascaParentSummary {
  final String? descripcio;

  const TascaParentSummary({
    required this.descripcio,
  });

  factory TascaParentSummary.fromJson(Map<String, dynamic> json) {
    return TascaParentSummary(
      descripcio: json['descripcio'] as String?,
    );
  }
}

/// Resum mínim del treballador assignat.
class TascaTreballadorSummary {
  final String? nom;
  final String? comentari;

  const TascaTreballadorSummary({
    required this.nom,
    required this.comentari,
  });

  factory TascaTreballadorSummary.fromJson(Map<String, dynamic> json) {
    return TascaTreballadorSummary(
      nom: json['nom'] as String?,
      comentari: json['comentari'] as String?,
    );
  }
}

/// Element simple basat en descripció, útil per incidències i solucions.
class TascaDescriptionItem {
  final String? descripcio;

  const TascaDescriptionItem({
    required this.descripcio,
  });

  factory TascaDescriptionItem.fromJson(Map<String, dynamic> json) {
    return TascaDescriptionItem(
      descripcio: json['descripcio'] as String?,
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// FUTUR FITXER: services/tasca_service.dart
////////////////////////////////////////////////////////////////////////////////

/// Servei del domini tasca encarregat de demanar el detall al backend.
///
/// La pantalla no ha de fer HTTP directament. Aquesta classe encapsula
/// la comunicació amb l'API i retorna un model Dart tipat.
class TascaService {
  const TascaService();

  Future<TascaDetail> fetchTascaDetail(int tascaId) async {
    final url = Uri.parse('http://localhost:8000/api/tasca/$tascaId/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      return TascaDetail.fromJson(jsonMap);
    }

    throw Exception(
      'No s\'ha pogut carregar la tasca (codi ${response.statusCode}).',
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// FUTUR FITXER: screens/tasca_detail_screen.dart
////////////////////////////////////////////////////////////////////////////////

/// Pantalla de detall d'una tasca.
///
/// Aquesta screen segueix el criteri del projecte:
/// - coordina estat i càrrega
/// - decideix loading / error / empty / content
/// - composa la UI amb shared widgets
/// - evita decorar manualment la pantalla si shared ja cobreix el cas
class TascaDetailScreen extends StatefulWidget {
  final int tascaId;

  const TascaDetailScreen({
    super.key,
    required this.tascaId,
  });

  @override
  State<TascaDetailScreen> createState() => _TascaDetailScreenState();
}

class _TascaDetailScreenState extends State<TascaDetailScreen> {
  final TascaService _tascaService = const TascaService();

  TascaDetail? _tasca;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasca();
  }

  // ===========================================================================
  // CÀRREGA DE DADES
  // Carrega la tasca des del servei i actualitza l'estat de la pantalla.
  // ===========================================================================
  Future<void> _loadTasca() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasca = await _tascaService.fetchTascaDetail(widget.tascaId);

      if (!mounted) return;

      setState(() {
        _tasca = tasca;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error carregant la tasca: $e';
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // HELPERS DE PRESENTACIÓ LOCALS
  // Es mantenen dins la screen perquè ara mateix són simples i no justifiquen
  // un fitxer de formatters separat.
  // ===========================================================================
  String _textOrFallback(String? value, {String fallback = 'No disponible'}) {
    if (value == null) return fallback;

    final normalized = value.trim();
    if (normalized.isEmpty) return fallback;

    return normalized;
  }

  String _intOrFallback(int? value, {String fallback = 'No disponible'}) {
    return value?.toString() ?? fallback;
  }

  String _boolToSiNo(bool value) {
    return value ? 'Sí' : 'No';
  }

  // ===========================================================================
  // CAMP INFORMATIU BÀSIC
  // Mostra una etiqueta i el seu valor reutilitzant el tema global.
  // Es deixa com a mètode privat perquè encara no justifica un widget de domini.
  // ===========================================================================
  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LLISTA SIMPLE DE DESCRIPCIONS
  // Resol incidències i solucions sense crear un widget addicional de domini.
  // ===========================================================================
  Widget _buildDescriptionList({
    required List<TascaDescriptionItem> items,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return AppCard(
        child: Text(emptyMessage),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text(
                        _textOrFallback(item.descripcio),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ===========================================================================
  // CONTINGUT PRINCIPAL
  // Composa la pantalla per seccions usant els shared widgets del projecte.
  // ===========================================================================
  Widget _buildContent(BuildContext context, TascaDetail tasca) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppSection(
          title: 'Informació bàsica',
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context: context,
                  label: 'Descripció',
                  value: _textOrFallback(tasca.descripcio),
                ),
                _buildInfoRow(
                  context: context,
                  label: 'Data inici',
                  value: _textOrFallback(tasca.dataInici),
                ),
                _buildInfoRow(
                  context: context,
                  label: 'Data final',
                  value: _textOrFallback(tasca.dataFi),
                ),
                _buildInfoRow(
                  context: context,
                  label: 'Prioritat',
                  value: _intOrFallback(tasca.prioritat),
                ),
                _buildInfoRow(
                  context: context,
                  label: 'Visible',
                  value: _boolToSiNo(tasca.visibilitatTasca),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppSection(
          title: 'Obra associada',
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context: context,
                  label: 'Nom obra',
                  value: _textOrFallback(tasca.obra?.nom),
                ),
                _buildInfoRow(
                  context: context,
                  label: 'Ubicació',
                  value: _textOrFallback(tasca.obra?.ubicacio),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppSection(
          title: 'Tasca pare',
          child: AppCard(
            child: _buildInfoRow(
              context: context,
              label: 'Descripció pare',
              value: _textOrFallback(tasca.tascaPare?.descripcio),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppSection(
          title: 'Treballador assignat',
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context: context,
                  label: 'Nom',
                  value: _textOrFallback(tasca.treballador?.nom),
                ),
                _buildInfoRow(
                  context: context,
                  label: 'Comentari',
                  value: _textOrFallback(tasca.treballador?.comentari),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppSection(
          title: 'Incidències relacionades',
          child: _buildDescriptionList(
            items: tasca.incidencies,
            emptyMessage: 'Aquesta tasca no té incidències relacionades.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppSection(
          title: 'Solucions proposades',
          child: _buildDescriptionList(
            items: tasca.solucions,
            emptyMessage: 'Aquesta tasca no té solucions proposades.',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detall de la tasca'),
      ),
      body: _isLoading
          ? const AppLoadingIndicator(
              message: 'Carregant detall de la tasca...',
            )
          : _errorMessage != null
              ? AppErrorState(
                  title: 'No s\'ha pogut carregar la tasca',
                  message: _errorMessage!,
                  onRetry: _loadTasca,
                )
              : _tasca == null
                  ? const AppEmptyState(
                     icon: Icons.info_outline,
                      title: 'Sense dades',
                      message: 'No s\'han trobat dades per a aquesta tasca.',
                    )
                  : _buildContent(context, _tasca!),
    );
  }
}