import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:front_end/screens/incidencia/incidenciaDetail_screen.dart';
import 'package:front_end/screens/tasca_screens/tasca_profile_screen.dart';
import 'package:front_end/screens/treballador/perfil_treb.dart';
import 'package:front_end/screens/treballador/treballador_detail_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:front_end/shared/constants/api_constants.dart';
import 'package:front_end/models/document_models.dart';
import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/responsable_models.dart';
import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/models/tasca_models.dart';

class ObraFabMenu extends StatelessWidget {
  final Future<void> Function(String value) onSelected;

  const ObraFabMenu({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final selected = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(1000, 1000, 16, 100),
          items: const [
            PopupMenuItem(
              value: 'inc',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.warning_amber_rounded),
                title: Text('Nova incidència'),
              ),
            ),
            PopupMenuItem(
              value: 'tasca',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.task_alt),
                title: Text('Nova tasca'),
              ),
            ),
            PopupMenuItem(
              value: 'doc',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.description_outlined),
                title: Text('Afegir document'),
              ),
            ),
            PopupMenuItem(
              value: 'rec',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Sol·licitar recurs'),
              ),
            ),
          ],
        );

        if (selected != null) {
          await onSelected(selected);
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class ObraHeaderCard extends StatelessWidget {
  final Obra obra;
  const ObraHeaderCard({
    super.key,
    required this.obra,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: scheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obra.nom,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (obra.hasDescription) ...[
                  const SizedBox(height: 8),
                  Text(
                    obra.descripcio!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ObraTag(
                      icon: Icons.flag_outlined,
                      label: _textOrFallback(obra.estat),
                    ),
                    _ObraTag(
                      icon: Icons.location_on_outlined,
                      label: obra.locationLabel,
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

class ObraCompactInfoPanel extends StatelessWidget {
  final Obra obra;
  final int responsablesCount;

  const ObraCompactInfoPanel({
    super.key,
    required this.obra,
    required this.responsablesCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
            'Informació general',
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
              _ObraInfoPill(
                label: 'Inici',
                value: _formatDate(obra.dataInici),
              ),
              _ObraInfoPill(
                label: 'Fi prevista',
                value: _formatDate(obra.dataPrevFi),
              ),
              _ObraInfoPill(
                label: 'Fi real',
                value: _formatDate(obra.dataFi),
              ),
              _ObraInfoPill(
                label: 'Pressupost',
                value: _formatMoney(obra.pressupost),
              ),
              _ObraInfoPill(
                label: 'Responsables',
                value: responsablesCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ObraSectionContent<T> extends StatelessWidget {
  final List<T> items;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  const ObraSectionContent({
    super.key,
    required this.items,
    required this.emptyText,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceContainerHighest.withOpacity(0.35),
        ),
        child: Text(
          emptyText,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          itemBuilder(items[i]),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class ObraLocationSectionBody extends StatelessWidget {
  final Obra obra;
  //Constructor que rep l'obra, i mostra la ubicació resumida i el mapa si hi ha coordenades. Si no hi ha coordenades però si dades d'ubicació, mostra un missatge indicant que no es poden mostrar les coordenades. Si no hi ha dades d'ubicació, mostra un missatge indicant que no hi ha dades d'ubicació.
  const ObraLocationSectionBody({
    super.key,
    required this.obra,
  });

  @override
  Widget build(BuildContext context) {
    if (!obra.hasLocationData) {
      final scheme = Theme.of(context).colorScheme;

      return Container(
        width: double.infinity,
        height: 50,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceContainerHighest.withOpacity(0.35),
        ),
        child: Text(
          'No hi ha dades d’ubicació disponibles.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ObraMapPanel(obra: obra);
  }
}

//Es el bloc base de cada secció, amb el titol i el cos que es pot expandir o contraure. El cos es passa com a widget, i pot ser un mapa, una llista d'incidencies, etc.
class ObraSectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Widget child;
  final bool initiallyExpanded;

  const ObraSectionBlock({
    super.key,
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
          children: [
            child,
          ],
        ),
      ),
    );
  }
}

class ObraMapPanel extends StatelessWidget {
  final Obra obra;

  const ObraMapPanel({
    super.key,
    required this.obra,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = obra.ubicacioInfo;
    final hasMap = obra.hasMapCoordinates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ObraDataCard(
          accent: scheme.primary,
          icon: Icons.location_on_outlined,
          title: obra.locationLabel,
          lines: _locationLines(info),
        ),
        if (hasMap) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(info!.latitud!, info.longitud!),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.front_end',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(info.latitud!, info.longitud!),
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.location_pin,
                          size: 42,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ] else if (obra.hasLocationData) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No hi ha coordenades per mostrar el mapa.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class ObraIncidenciaCard extends StatelessWidget {
  final Incidencia incidencia;

  const ObraIncidenciaCard({
    super.key,
    required this.incidencia,
  });

  @override
  Widget build(BuildContext context) {
    final accent = incidencia.criticitat >= 7
        ? Colors.red
        : incidencia.criticitat >= 4
            ? Colors.orange
            : Colors.green;

    return _ObraDataCard(
        accent: accent,
        icon: Icons.warning_amber_rounded,
        title: incidencia.descripcio,
        lines: [
          'Estat: ${_textOrFallback(incidencia.estat)}',
          'Inici: ${_formatDate(incidencia.dataInici)}',
          'Fi: ${_formatDate(incidencia.dataFi)}',
          'Criticitat: ${incidencia.criticitat}',
          'Prioritat: ${incidencia.prioritat}',
        ],
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => IncidenciaProfileScreen(
                      incidenciaId: incidencia.id,
                      baseUrl: ApiConstants.baseUrl)),
      )
    );
  }
}

class ObraTascaCard extends StatelessWidget {
  final Tasca tasca;
  final String baseUrl = ApiConstants.baseUrl;
  const ObraTascaCard({
    super.key,
    required this.tasca,
  });

  @override
  Widget build(BuildContext context) {
    return _ObraDataCard(
      accent: tasca.visibilitatTasca ? Colors.green : Colors.grey,
      icon: tasca.visibilitatTasca ? Icons.visibility : Icons.visibility_off,
      title: tasca.descripcio,
      lines: [
        'Prioritat: ${tasca.prioritat}',
        'Inici: ${_formatDate(tasca.dataInici)}',
        'Fi: ${_formatDate(tasca.dataFi)}',
        'Visible: ${tasca.visibilitatTasca ? 'Sí' : 'No'}',
      ],
      onTap: () => Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TascaProfileScreen(
            tascaId: tasca.id,
            baseUrl: baseUrl,
          ),
        ),
      ),
    );
  }
}

class ObraDocumentCard extends StatelessWidget {
  final DocumentObraItem document;

  const ObraDocumentCard({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return _ObraDataCard(
      accent: Colors.blueGrey,
      icon: Icons.description_outlined,
      title: document.nom,
      lines: [
        'Format: ${_textOrFallback(document.format)}',
        'Mida: ${_formatFileSizeMb(document.mida)}',
        'Tipus: ${_textOrFallback(document.tipus)}',
        'Pujada: ${_formatDate(document.dataPujada)}',
      ],
      onTap: () =>
          Navigator.pushNamed(context, '/documentView', arguments: document.id),
    );
  }
}

class ObraSolRecursCard extends StatelessWidget {
  final SolRecurs item;

  const ObraSolRecursCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return _ObraDataCard(
      accent: Colors.deepPurple,
      icon: Icons.inventory_2_outlined,
      title: 'Quantitat: ${item.quantitat}',
      lines: [
        'Recurs ID: ${item.idRecurs}',
        'Data necessitat: ${_formatDate(item.dataNecessitat)}',
        'Entrega: ${_formatDate(item.dataEntrega)}',
        'Proveïdor: ${_textOrFallback(item.proveidor)}',
      ],
      onTap: () => Navigator.pushNamed(context, '/recursProfile',
          arguments: item.idRecurs),
    );
  }
}

class ObraResponsableCard extends StatelessWidget {
  final ResponsableObra responsable;

  const ObraResponsableCard({
    super.key,
    required this.responsable,
  });

  @override
  Widget build(BuildContext context) {
    return _ObraDataCard(
        accent: Colors.indigo,
        icon: Icons.badge_outlined,
        title: 'Treballador ID: ${responsable.idTreballador}',
        lines: [
          'Inici: ${_formatDate(responsable.dataInici)}',
          'Fi: ${_formatDate(responsable.dataFi)}',
        ],
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TreballadorDetailScreen(treballadorId: this.responsable.idTreballador),
              ),
            ),
    );
  }
}

class _ObraDataCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback? onTap;

  const _ObraDataCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.lines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outline.withOpacity(0.08),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                constraints: const BoxConstraints(minHeight: 108),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...lines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObraInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _ObraInfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObraTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ObraTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

List<String> _locationLines(ObraUbicacioInfo? info) {
  if (info == null) {
    return const ['Sense dades d’ubicació disponibles'];
  }

  final lines = <String>[];

  final adreca = _textOrNull(info.adreca);
  if (adreca != null) {
    lines.add('Adreça: $adreca');
  }

  final ciutat = _textOrNull(info.ciutat);
  if (ciutat != null) {
    lines.add('Ciutat: $ciutat');
  }

  final provincia = _textOrNull(info.provincia);
  if (provincia != null) {
    lines.add('Província: $provincia');
  }

  final cp = _textOrNull(info.codiPostal);
  if (cp != null) {
    lines.add('Codi postal: $cp');
  }

  final pais = _textOrNull(info.pais);
  if (pais != null) {
    lines.add('País: $pais');
  }

  if (info.latitud != null && info.longitud != null) {
    lines.add(
      'Coordenades: ${info.latitud!.toStringAsFixed(6)}, ${info.longitud!.toStringAsFixed(6)}',
    );
  }

  return lines.isEmpty ? const ['Sense dades d’ubicació disponibles'] : lines;
}

String _textOrFallback(String? value, {String fallback = '—'}) {
  final parsed = _textOrNull(value);
  return parsed ?? fallback;
}

String? _textOrNull(String? value) {
  if (value == null) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _formatDate(DateTime? value, {String fallback = '—'}) {
  if (value == null) return fallback;

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}

String _formatMoney(num? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  return '€${value.toString()}';
}

String _formatFileSizeMb(double value) {
  return '${value.toStringAsFixed(2)} MB';
}
