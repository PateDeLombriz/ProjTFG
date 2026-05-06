import 'package:flutter/material.dart';

import 'package:front_end/services/treballador_service.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/shared/themes/app_spacing.dart';
import 'package:front_end/shared/themes/app_text_styles.dart';
import 'package:front_end/shared/widgets/app_empty_state.dart';
import 'package:front_end/shared/widgets/app_error_state.dart';
import 'package:front_end/shared/widgets/app_loading_indicator.dart';

class TreballadorObraDocumentsScreen extends StatefulWidget {
  final int obraId;
  final String nomObra;

  const TreballadorObraDocumentsScreen({
    super.key,
    required this.obraId,
    required this.nomObra,
  });

  @override
  State<TreballadorObraDocumentsScreen> createState() =>
      _TreballadorObraDocumentsScreenState();
}

class _TreballadorObraDocumentsScreenState
    extends State<TreballadorObraDocumentsScreen> {
  late final TreballadorService _service;
  late Future<List<Map<String, dynamic>>> _future;

  String _tipusFilter = 'tots';
  String _formatFilter = 'tots';

  @override
  void initState() {
    super.initState();
    _service = TreballadorService(baseUrl: ApiConstants.baseUrl);
    _future = _service.fetchObraDocuments(widget.obraId);
  }

  Future<void> _reload() async {
    final nextFuture = _service.fetchObraDocuments(widget.obraId);

    setState(() {
      _future = nextFuture;
    });

    await nextFuture;
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> docs) {
    return docs.where((doc) {
      final tipus = _normalizeValue(_asString(doc['tipus']));
      final format = _normalizeValue(_asString(doc['format']));

      final matchesTipus = _tipusFilter == 'tots' || tipus == _tipusFilter;
      final matchesFormat = _formatFilter == 'tots' || format == _formatFilter;

      return matchesTipus && matchesFormat;
    }).toList();
  }

  List<(String, String)> _buildOptions(
    List<Map<String, dynamic>> docs,
    String key,
  ) {
    final values = <String, String>{};

    for (final doc in docs) {
      final raw = _asString(doc[key]);
      final normalized = _normalizeValue(raw);
      if (normalized == null || normalized.isEmpty) continue;

      values[normalized] = _prettyLabel(raw ?? normalized);
    }

    final sorted = values.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return [
      const ('tots', 'Tots'),
      ...sorted.map((entry) => (entry.key, entry.value)),
    ];
  }

  void _handleDownload(BuildContext context, Map<String, dynamic> doc) {
    final downloadUrl = _downloadUrl(doc);
    final nom = _documentName(doc);

    if (downloadUrl == null) {
      _showDownloadPendingSnack(context, nom);
      return;
    }

    _showDownloadReadySnack(context, nom);
  }

  void _showDownloadPendingSnack(BuildContext context, String nom) {
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        content: Text(
          '“$nom” encara no es pot descarregar. Falta exposar un endpoint segur de descàrrega.',
        ),
      ),
    );
  }

  void _showDownloadReadySnack(BuildContext context, String nom) {
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        content: Text(
          '“$nom” ja té URL de descàrrega. Només falta connectar l’obertura del fitxer.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualitza',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingIndicator(message: 'Carregant documents...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final allDocs = snapshot.data ?? [];
          final filteredDocs = _applyFilters(allDocs);

          final tipusOptions = _buildOptions(allDocs, 'tipus');
          final formatOptions = _buildOptions(allDocs, 'format');

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.md,
                AppSpacing.screenHorizontal,
                AppSpacing.xxxl,
              ),
              children: [
                _DocumentsHeaderCard(
                  nomObra: widget.nomObra,
                  documents: allDocs,
                ),
                const SizedBox(height: AppSpacing.md),
                if (allDocs.isNotEmpty) ...[
                  _DocumentsFilterPanel(
                    selectedTipus: _tipusFilter,
                    selectedFormat: _formatFilter,
                    tipusOptions: tipusOptions,
                    formatOptions: formatOptions,
                    onTipusChanged: (value) {
                      setState(() {
                        _tipusFilter = value;
                      });
                    },
                    onFormatChanged: (value) {
                      setState(() {
                        _formatFilter = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (allDocs.isEmpty)
                  const AppEmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'Sense documents',
                    message: 'Aquesta obra no té documents adjunts.',
                  )
                else if (filteredDocs.isEmpty)
                  const AppEmptyState(
                    icon: Icons.filter_list_off_rounded,
                    title: 'Sense resultats',
                    message:
                        'No hi ha documents que coincideixin amb els filtres seleccionats.',
                  )
                else
                  ...List.generate(filteredDocs.length, (index) {
                    final doc = filteredDocs[index];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == filteredDocs.length - 1
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: _DocumentCard(
                        doc: doc,
                        onDownload: () => _handleDownload(context, doc),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DocumentsHeaderCard extends StatelessWidget {
  final String nomObra;
  final List<Map<String, dynamic>> documents;

  const _DocumentsHeaderCard({
    required this.nomObra,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _DocumentsSummary.from(documents);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.folder_copy_outlined,
            color: scheme.onPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Documents de l’obra',
            style: AppTextStyles.headlineMedium.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              height: 1.10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            nomObra,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onPrimary.withOpacity(0.80),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'Total',
                  value: summary.total.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'PDF',
                  value: summary.pdfCount.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeaderMetric(
                  label: 'Descarregables',
                  value: summary.downloadReady.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.onPrimary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onPrimary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.78),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsFilterPanel extends StatelessWidget {
  final String selectedTipus;
  final String selectedFormat;
  final List<(String, String)> tipusOptions;
  final List<(String, String)> formatOptions;
  final ValueChanged<String> onTipusChanged;
  final ValueChanged<String> onFormatChanged;

  const _DocumentsFilterPanel({
    required this.selectedTipus,
    required this.selectedFormat,
    required this.tipusOptions,
    required this.formatOptions,
    required this.onTipusChanged,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterGroup(
            title: 'Tipus',
            selected: selectedTipus,
            options: tipusOptions,
            onChanged: onTipusChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterGroup(
            title: 'Format',
            selected: selectedFormat,
            options: formatOptions,
            onChanged: onFormatChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final String selected;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _FilterGroup({
    required this.title,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final key = option.$1;
              final label = option.$2;
              final isSelected = selected == key;

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(key),
                  selectedColor: scheme.primaryContainer,
                  backgroundColor: scheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final VoidCallback onDownload;

  const _DocumentCard({
    required this.doc,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final nom = _documentName(doc);
    final format = _asString(doc['format']);
    final tipus = _asString(doc['tipus']);
    final mida = _formatFileSize(doc['mida']);
    final dataPujada = _formatDate(doc['data_pujada']);
    final comentari = _asString(doc['comentari']);
    final downloadReady = _downloadUrl(doc) != null;

    final accent = _formatColor(context, format);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.75),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.045),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DocumentIcon(
                    format: format,
                    accent: accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (tipus != null) _prettyLabel(tipus),
                            if (format != null) format.toUpperCase(),
                            if (mida != '—') mida,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _DownloadStatusPill(downloadReady: downloadReady),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _DocumentTag(
                    icon: Icons.category_outlined,
                    label: tipus == null ? 'Sense tipus' : _prettyLabel(tipus),
                    color: scheme.primary,
                  ),
                  _DocumentTag(
                    icon: Icons.insert_drive_file_outlined,
                    label: format == null ? 'Sense format' : format.toUpperCase(),
                    color: accent,
                  ),
                  _DocumentTag(
                    icon: Icons.calendar_today_outlined,
                    label: dataPujada,
                    color: scheme.tertiary,
                  ),
                ],
              ),

              if (comentari != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    comentari,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.32,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        downloadReady
                            ? 'Descarrega'
                            : 'Descarrega pendent',
                      ),
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

class _DocumentIcon extends StatelessWidget {
  final String? format;
  final Color accent;

  const _DocumentIcon({
    required this.format,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        _iconForFormat(format),
        color: accent,
        size: 24,
      ),
    );
  }
}

class _DownloadStatusPill extends StatelessWidget {
  final bool downloadReady;

  const _DownloadStatusPill({
    required this.downloadReady,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final background = downloadReady
        ? scheme.primaryContainer.withOpacity(0.75)
        : scheme.surfaceContainerHighest.withOpacity(0.85);

    final foreground = downloadReady
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        downloadReady ? 'Disponible' : 'Preparat',
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DocumentTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DocumentTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSummary {
  final int total;
  final int pdfCount;
  final int downloadReady;

  const _DocumentsSummary({
    required this.total,
    required this.pdfCount,
    required this.downloadReady,
  });

  factory _DocumentsSummary.from(List<Map<String, dynamic>> docs) {
    var pdf = 0;
    var ready = 0;

    for (final doc in docs) {
      final format = _normalizeValue(_asString(doc['format']));
      if (format == 'pdf') pdf++;

      if (_downloadUrl(doc) != null) ready++;
    }

    return _DocumentsSummary(
      total: docs.length,
      pdfCount: pdf,
      downloadReady: ready,
    );
  }
}

/* ───────────────────────── Helpers ───────────────────────── */

String _documentName(Map<String, dynamic> doc) {
  return _asString(doc['nom']) ??
      _asString(doc['nom_document']) ??
      _asString(doc['title']) ??
      'Document sense nom';
}

String? _downloadUrl(Map<String, dynamic> doc) {
  return _asString(doc['download_url']) ??
      _asString(doc['url']) ??
      _asString(doc['file_url']);
}

String? _asString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _normalizeValue(String? value) {
  if (value == null) return null;

  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  return normalized.replaceAll(' ', '_');
}

String _prettyLabel(String value) {
  final text = value
      .trim()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase();

  if (text.isEmpty) return '—';

  return text
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) return part;
        return '${part[0].toUpperCase()}${part.substring(1)}';
      })
      .join(' ');
}

String _formatDate(dynamic value) {
  if (value == null) return '—';

  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return value.toString();

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();

  return '$day/$month/$year';
}

String _formatFileSize(dynamic value) {
  if (value == null) return '—';

  final parsed = double.tryParse(value.toString());
  if (parsed == null) return value.toString();

  return '${parsed.toStringAsFixed(2)} MB';
}

IconData _iconForFormat(String? format) {
  switch ((format ?? '').toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'webp':
      return Icons.image_outlined;
    case 'xlsx':
    case 'xls':
      return Icons.table_chart_outlined;
    case 'docx':
    case 'doc':
      return Icons.description_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Color _formatColor(BuildContext context, String? format) {
  final scheme = Theme.of(context).colorScheme;

  switch ((format ?? '').toLowerCase()) {
    case 'pdf':
      return scheme.error;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'webp':
      return scheme.tertiary;
    case 'xlsx':
    case 'xls':
      return Colors.green.shade700;
    case 'docx':
    case 'doc':
      return scheme.primary;
    default:
      return scheme.onSurfaceVariant;
  }
}