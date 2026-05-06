import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:front_end/models/document_models.dart';
import 'package:front_end/models/incidencia_models.dart';
import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/responsable_models.dart';
import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/screens/documents_obra_screen.dart';
import 'package:front_end/screens/empresa/incidencia/incidenciaDetail_screen.dart';
import 'package:front_end/screens/empresa/tasca_screens/tasca_detail_screen.dart';
import 'package:front_end/screens/empresa/treballador%20Empresa/treballador_detail_screen.dart';
import 'package:front_end/shared/screen/map_selector_screen.dart';
import 'package:front_end/utils/obra_feedback.dart';
import 'package:latlong2/latlong.dart';
import 'package:front_end/shared/services/geocoding_services.dart';

class ObraFabMenu extends StatelessWidget {
  final Future<void> Function(String value) onSelected;

  const ObraFabMenu({
    super.key,
    required this.onSelected,
  });

  Future<void> _openMenu(BuildContext context) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;

    final buttonRect = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(buttonRect, Offset.zero & overlay.size),
      items: const [
        PopupMenuItem<String>(
          value: 'inc',
          child: _ObraFabMenuItem(
            icon: Icons.warning_amber_rounded,
            label: 'Nova incidència',
          ),
        ),
        PopupMenuItem<String>(
          value: 'tasca',
          child: _ObraFabMenuItem(
            icon: Icons.task_alt,
            label: 'Nova tasca',
          ),
        ),
        PopupMenuItem<String>(
          value: 'doc',
          child: _ObraFabMenuItem(
            icon: Icons.description_outlined,
            label: 'Afegir document',
          ),
        ),
        PopupMenuItem<String>(
          value: 'rec',
          child: _ObraFabMenuItem(
            icon: Icons.inventory_2_outlined,
            label: 'Sol·licitar recurs',
          ),
        ),
      ],
    );

    if (selected != null) {
      await onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openMenu(context),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
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
            alignment: Alignment.center,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
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
                    style: theme.textTheme.bodyMedium?.copyWith(
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
                      label: _displayText(obra.estat),
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

class ObraCreateHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const ObraCreateHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObraFormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ObraFormSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class ObraDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const ObraDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(obraFormatDate(value)),
      ),
    );
  }
}

class ObraCreateSummaryCard extends StatelessWidget {
  final String nom;
  final String pressupostText;
  final String estat;
  final ObraUbicacioInfo? ubicacio;
  final DateTime? dataInici;
  final DateTime? dataPrevFi;

  const ObraCreateSummaryCard({
    super.key,
    required this.nom,
    required this.pressupostText,
    required this.estat,
    required this.ubicacio,
    required this.dataInici,
    required this.dataPrevFi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resum', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _ObraSummaryRow(
              label: 'Nom',
              value: nom.trim().isEmpty ? '—' : nom.trim(),
            ),
            _ObraSummaryRow(
              label: 'Ubicació',
              value: ubicacio?.adreca.toString() ?? '—',
            ),
            _ObraSummaryRow(label: 'Estat', value: estat),
            _ObraSummaryRow(label: 'Inici', value: obraFormatDate(dataInici)),
            _ObraSummaryRow(
              label: 'Fi prevista',
              value: obraFormatDate(dataPrevFi),
            ),
            _ObraSummaryRow(
              label: 'Pressupost',
              value: obraFormatMoneyPreview(pressupostText),
            ),
          ],
        ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                value: obraFormatDate(obra.dataInici),
              ),
              _ObraInfoPill(
                label: 'Fi prevista',
                value: obraFormatDate(obra.dataPrevFi),
              ),
              _ObraInfoPill(
                label: 'Fi real',
                value: obraFormatDate(obra.dataFi),
              ),
              _ObraInfoPill(
                label: 'Pressupost',
                value: _formatMoneyValue(obra.pressupost),
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
      return _ObraInfoMessage(message: emptyText);
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



class ObraSectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Widget child;
  final bool initiallyExpanded;
  final VoidCallback? onAdd;
  final String addTooltip;

  const ObraSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.count,
    required this.child,
    this.initiallyExpanded = false,
    this.onAdd,
    this.addTooltip = 'Afegir element',
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
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (onAdd != null)
                IconButton(
                  tooltip: addTooltip,
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
          subtitle: Text(
            count == 1 ? '1 element' : '$count elements',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          children: [child],
        ),
      ),
    );
  }
}
class ObraLocationSectionBody extends StatelessWidget {
  final Obra? obra;
  final ObraUbicacioInfo? ubicacio;
  final bool editable;
  final ValueChanged<ObraUbicacioInfo?>? onChanged;
  final String? title;
  final String emptyMessage;

  const ObraLocationSectionBody({
    super.key,
    required Obra this.obra,
  })  : ubicacio = null,
        editable = false,
        onChanged = null,
        title = null,
        emptyMessage = 'No hi ha dades d’ubicació disponibles.';

  const ObraLocationSectionBody.read({
    super.key,
    required this.ubicacio,
    this.title,
    this.emptyMessage = 'No hi ha dades d’ubicació disponibles.',
  })  : obra = null,
        editable = false,
        onChanged = null;

  const ObraLocationSectionBody.editable({
    super.key,
    required this.ubicacio,
    required this.onChanged,
    this.title,
    this.emptyMessage =
        'Encara no s’ha seleccionat cap ubicació. Obre el mapa per afegir-la.',
  })  : obra = null,
        editable = true;

  @override
  Widget build(BuildContext context) {
    final resolvedInfo = ubicacio ?? obra?.ubicacioInfo;

    if (!_hasAnyLocationData(resolvedInfo) && !editable) {
      return _ObraInfoMessage(message: emptyMessage);
    }

    return ObraMapPanel(
      obra: obra,
      ubicacio: resolvedInfo,
      editable: editable,
      onChanged: onChanged,
      customTitle: title,
      emptyMessage: emptyMessage,
    );
  }
}

class ObraMapPanel extends StatelessWidget {
  final Obra? obra;
  final ObraUbicacioInfo? ubicacio;
  final bool editable;
  final ValueChanged<ObraUbicacioInfo?>? onChanged;
  final String? customTitle;
  final String emptyMessage;

  const ObraMapPanel({
    super.key,
    required this.obra,
    this.ubicacio,
    this.editable = false,
    this.onChanged,
    this.customTitle,
    this.emptyMessage = 'No hi ha dades d’ubicació disponibles.',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = ubicacio ?? obra?.ubicacioInfo;
    final hasMap = info?.latitud != null && info?.longitud != null;

    final resolvedTitle = customTitle ??
        obra?.locationLabel ??
        info?.displayLabel ??
        'Ubicació';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ObraDataCard(
          accent: scheme.primary,
          icon: Icons.location_on_outlined,
          title: resolvedTitle,
          lines: _buildLocationLines(info),
        ),
        if (editable) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final selected = await mostrarSelectorUbicacio(
                  context,
                  ubicacioInicial: info,
                );
                if (selected != null) {
                  onChanged?.call(selected);
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: Text(info == null ? 'Seleccionar ubicació' : 'Editar ubicació'),
            ),
          ),
        ],
        if (hasMap && info != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(info.latitud!, info.longitud!),
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
        ] else if (info != null && GeocodingService.hasAddressData(info)) ...[
          const SizedBox(height: 12),
          _ObraResolvedMapPreview(info: info),
        ] else ...[
          const SizedBox(height: 12),
          _ObraInfoMessage(
            message: editable
                ? emptyMessage
                : 'No hi ha coordenades per mostrar el mapa.',
          ),
        ],
      ],
    );
  }
}

class _ObraResolvedMapPreview extends StatefulWidget {
  final ObraUbicacioInfo info;

  const _ObraResolvedMapPreview({
    required this.info,
  });

  @override
  State<_ObraResolvedMapPreview> createState() =>
      _ObraResolvedMapPreviewState();
}

class _ObraResolvedMapPreviewState extends State<_ObraResolvedMapPreview> {
  late final Future<LatLng?> _futurePoint;

  @override
  void initState() {
    super.initState();
    _futurePoint = GeocodingService.geocodeAddress(
      GeocodingService.buildAddressQuery(widget.info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<LatLng?>(
      future: _futurePoint,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.surfaceContainerHighest.withOpacity(0.35),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Cercant coordenades a partir de l’adreça...'),
                ),
              ],
            ),
          );
        }

        final point = snapshot.data;
        if (point == null) {
          return const _ObraInfoMessage(
            message:
                'No s’han pogut resoldre coordenades a partir de l’adreça.',
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
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
                      point: point,
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
        );
      },
    );
  }
}

class ObraIncidenciaCard extends StatelessWidget {
  final Incidencia incidencia;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ObraIncidenciaCard({
    super.key,
    required this.incidencia,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = incidencia.criticitat >= 7
        ? Colors.red
        : incidencia.criticitat >= 4
            ? Colors.orange
            : Colors.green;

    final open = onTap ??
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncidenciaProfileScreen(
                incidenciaId: incidencia.id,
              ),
            ),
          );
        };

    return _ObraDataCard(
      accent: accent,
      icon: Icons.warning_amber_rounded,
      title: incidencia.descripcio,
      lines: [
        'Estat: ${_displayText(incidencia.estat)}',
        'Inici: ${obraFormatDate(incidencia.dataInici)}',
        'Fi: ${obraFormatDate(incidencia.dataFi)}',
        'Criticitat: ${incidencia.criticitat}',
        'Prioritat: ${incidencia.prioritat}',
      ],
      onTap: open,
      onEdit: onEdit ?? open,
      onDelete: onDelete,
      editTooltip: 'Editar incidència',
      deleteTooltip: 'Eliminar incidència',
    );
  }
}

class ObraTascaCard extends StatelessWidget {
  final Tasca tasca;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ObraTascaCard({
    super.key,
    required this.tasca,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final open = onTap ??
        () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TascaDetailScreen(
                tascaId: tasca.id,
              ),
            ),
          );
        };

    return _ObraDataCard(
      accent: tasca.visibilitatTasca ? Colors.green : Colors.grey,
      icon: tasca.visibilitatTasca ? Icons.visibility : Icons.visibility_off,
      title: tasca.descripcio,
      lines: [
        'Prioritat: ${tasca.prioritat}',
        'Inici: ${obraFormatDate(tasca.dataInici)}',
        'Fi: ${obraFormatDate(tasca.dataFi)}',
        'Visible: ${tasca.visibilitatTasca ? 'Sí' : 'No'}',
      ],
      onTap: open,
      onEdit: onEdit ?? open,
      onDelete: onDelete,
      editTooltip: 'Editar tasca',
      deleteTooltip: 'Eliminar tasca',
    );
  }
}

class ObraDocumentCard extends StatelessWidget {
  final DocumentObraItem document;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ObraDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final open = onTap ??
        () {
          Navigator.push(
  context,
    MaterialPageRoute(
      builder: (_) => DocumentsObraScreen(
          obraId: document.idObra,
      ),
    ),
    );
        };
    return _ObraDataCard(
      accent: Colors.blueGrey,
      icon: Icons.description_outlined,
      title: document.pathDoc,
      lines: [
        'Format: ${_displayText(document.format)}',
        'Mida: ${_formatFileSizeMb(document.mida)}',
        'Tipus: ${_displayText(document.tipus)}',
        'Pujada: ${obraFormatDate(document.dataPujada)}',
      ],
      onTap: open,
      onEdit: onEdit ?? open,
      onDelete: onDelete,
      editTooltip: 'Editar document',
      deleteTooltip: 'Eliminar document',
    );
  }
}

class ObraSolRecursCard extends StatelessWidget {
  final SolRecurs item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ObraSolRecursCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final open = onTap ??
        () {
          Navigator.pushNamed(
            context,
            '/recursProfile',
            arguments: item.idRecurs,
          );
        };

    return _ObraDataCard(
      accent: Colors.deepPurple,
      icon: Icons.inventory_2_outlined,
      title: 'Quantitat: ${item.quantitat}',
      lines: [
        'Recurs ID: ${item.idRecurs}',
        'Data necessitat: ${obraFormatDate(item.dataNecessitat)}',
        'Entrega: ${obraFormatDate(item.dataEntrega)}',
        'Proveïdor: ${_displayText(item.proveidor)}',
      ],
      onTap: open,
      onEdit: onEdit ?? open,
      onDelete: onDelete,
      editTooltip: 'Editar recurs',
      deleteTooltip: 'Eliminar recurs',
    );
  }
}

class ObraResponsableCard extends StatelessWidget {
  final ResponsableObra responsable;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ObraResponsableCard({
    super.key,
    required this.responsable,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final open = onTap ??
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TreballadorDetailScreen(
                treballadorId: responsable.idTreballador,
              ),
            ),
          );
        };

    return _ObraDataCard(
      accent: Colors.indigo,
      icon: Icons.badge_outlined,
      title: 'Treballador ID: ${responsable.idTreballador}',
      lines: [
        'Inici: ${obraFormatDate(responsable.dataInici)}',
        'Fi: ${obraFormatDate(responsable.dataFi)}',
      ],
      onTap: open,
      onEdit: onEdit ?? open,
      onDelete: onDelete,
      editTooltip: 'Editar responsable',
      deleteTooltip: 'Eliminar responsable',
    );
  }
}

class _ObraFabMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ObraFabMenuItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _ObraSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _ObraSummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObraInfoMessage extends StatelessWidget {
  final String message;

  const _ObraInfoMessage({
    required this.message,
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
        message,
        style: TextStyle(color: scheme.onSurfaceVariant),
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editTooltip;
  final String deleteTooltip;

  const _ObraDataCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.lines,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.editTooltip = 'Editar',
    this.deleteTooltip = 'Eliminar',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleLines = lines.where((line) => line.trim().isNotEmpty).toList();
    final hasActions = onEdit != null || onDelete != null;

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
                constraints: const BoxConstraints(minHeight: 116),
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
                        alignment: Alignment.center,
                        child: Icon(icon, size: 20, color: accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (visibleLines.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...visibleLines.map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    line,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.30,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasActions) ...[
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              _ObraCardActionButton(
                                tooltip: editTooltip,
                                icon: Icons.edit_outlined,
                                onPressed: onEdit!,
                              ),
                            if (onEdit != null && onDelete != null)
                              const SizedBox(height: 6),
                            if (onDelete != null)
                              _ObraCardActionButton(
                                tooltip: deleteTooltip,
                                icon: Icons.delete_outline,
                                isDanger: true,
                                onPressed: onDelete!,
                              ),
                          ],
                        ),
                      ],
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

class _ObraCardActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDanger;

  const _ObraCardActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDanger ? scheme.error : scheme.primary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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


List<String> _buildLocationLines(ObraUbicacioInfo? info) {
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

  final codiPostal = _textOrNull(info.codiPostal);
  if (codiPostal != null) {
    lines.add('Codi postal: $codiPostal');
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

  return lines.isEmpty
      ? const ['Sense dades d’ubicació disponibles']
      : lines;
}

bool _hasAnyLocationData(ObraUbicacioInfo? info) {
  if (info == null) return false;

  return info.latitud != null ||
      info.longitud != null ||
      _hasAddressData(info);
}

bool _hasAddressData(ObraUbicacioInfo? info) {
  if (info == null) return false;

  return _textOrNull(info.adreca) != null ||
      _textOrNull(info.ciutat) != null ||
      _textOrNull(info.provincia) != null ||
      _textOrNull(info.codiPostal) != null ||
      _textOrNull(info.pais) != null;
}

String _buildLocationTitle(ObraUbicacioInfo? info) {
  if (info == null) return 'Ubicació';

  final adreca = _textOrNull(info.adreca);
  if (adreca != null) return adreca;

  final ciutat = _textOrNull(info.ciutat);
  if (ciutat != null) return ciutat;

  return 'Ubicació';
}

String _displayText(String? value, {String fallback = '—'}) {
  return _textOrNull(value) ?? fallback;
}

String? _textOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _formatMoneyValue(num? value, {String fallback = '—'}) {
  if (value == null) return fallback;
  return '€$value';
}

String _formatFileSizeMb(num value) {
  return '${value.toStringAsFixed(2)} MB';
}