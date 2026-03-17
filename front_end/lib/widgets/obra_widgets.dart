import 'package:flutter/material.dart';
import 'package:front_end/models/document_models.dart';
import 'package:front_end/models/incidencia_models.dart';

import 'package:front_end/models/obra_models.dart';
import 'package:front_end/models/responsable_models.dart';
import 'package:front_end/models/sol_recurs_models.dart';
import 'package:front_end/models/tasca_models.dart';
import 'package:front_end/utils/obra_formatters.dart';

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
                title: Text('Nova Incidència'),
              ),
            ),
            PopupMenuItem(
              value: 'tasca',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.task_alt),
                title: Text('Nova Tasca'),
              ),
            ),
            PopupMenuItem(
              value: 'doc',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.description_outlined),
                title: Text('Afegir Document'),
              ),
            ),
            PopupMenuItem(
              value: 'rec',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Sol·licitar Recurs'),
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

class ObraHeroCard extends StatelessWidget {
  final Obra obra;
  final int incidenciesCount;
  final int tasquesCount;
  final int documentsCount;
  final int recursosCount;
  final int responsablesCount;

  const ObraHeroCard({
    super.key,
    required this.obra,
    required this.incidenciesCount,
    required this.tasquesCount,
    required this.documentsCount,
    required this.recursosCount,
    required this.responsablesCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withOpacity(0.10),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            obra.nom,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            obraFormatText(obra.descripcio),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ObraInfoChip(
                icon: Icons.location_on_outlined,
                label: obraFormatUbicacio(obra.ubicacio),
              ),
              ObraInfoChip(
                icon: Icons.event_outlined,
                label: 'Inici: ${obraFormatDate(obra.dataInici)}',
              ),
              ObraInfoChip(
                icon: Icons.schedule_outlined,
                label: 'Fi prev.: ${obraFormatDate(obra.dataPrevFi)}',
              ),
              ObraInfoChip(
                icon: Icons.payments_outlined,
                label: obraFormatMoney(obra.pressupost),
              ),
              ObraInfoChip(
                icon: Icons.flag_outlined,
                label: obraFormatText(obra.estat),
              ),
              ObraInfoChip(
                icon: Icons.badge_outlined,
                label: obraFormatResponsableCount(responsablesCount),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.35,
            children: [
              ObraStatTile(
                label: 'Incidències',
                value: incidenciesCount.toString(),
                icon: Icons.warning_amber_rounded,
              ),
              ObraStatTile(
                label: 'Tasques',
                value: tasquesCount.toString(),
                icon: Icons.task_alt,
              ),
              ObraStatTile(
                label: 'Documents',
                value: documentsCount.toString(),
                icon: Icons.description_outlined,
              ),
              ObraStatTile(
                label: 'Recursos',
                value: recursosCount.toString(),
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ObraSectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final List<Widget> children;
  final String emptyMessage;

  const ObraSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.count,
    required this.children,
    this.emptyMessage = 'No hi ha dades',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(icon, color: scheme.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        subtitle: Text('$count elements'),
        children: children.isEmpty
            ? [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ]
            : children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: child,
                  ),
                )
                .toList(growable: false),
      ),
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

    return ObraDataCard(
      accent: accent,
      icon: Icons.warning_amber_rounded,
      title: incidencia.descripcio,
      lines: [
        'Estat: ${obraFormatText(incidencia.estat)}',
        'Inici: ${obraFormatDate(incidencia.dataInici)}',
        'Fi: ${obraFormatDate(incidencia.dataFi)}',
        'Criticitat: ${incidencia.criticitat}',
        'Prioritat: ${incidencia.prioritat}',
      ],
    );
  }
}

class ObraTascaCard extends StatelessWidget {
  final Tasca tasca;

  const ObraTascaCard({
    super.key,
    required this.tasca,
  });

  @override
  Widget build(BuildContext context) {
    return ObraDataCard(
      accent: tasca.visibilitatTasca ? Colors.green : Colors.grey,
      icon: tasca.visibilitatTasca ? Icons.visibility : Icons.visibility_off,
      title: tasca.descripcio,
      lines: [
        'Prioritat: ${tasca.prioritat}',
        'Inici: ${obraFormatDate(tasca.dataInici)}',
        'Fi: ${obraFormatDate(tasca.dataFi)}',
        'Visible: ${tasca.visibilitatTasca ? 'Sí' : 'No'}',
      ],
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
    return ObraDataCard(
      accent: Colors.blueGrey,
      icon: Icons.description_outlined,
      title: document.nom,
      lines: [
        'Format: ${obraFormatText(document.format)}',
        'Mida: ${obraFormatFileSizeMb(document.mida)}',
        'Tipus: ${obraFormatText(document.tipus)}',
        'Pujada: ${obraFormatDate(document.dataPujada)}',
      ],
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
    return ObraDataCard(
      accent: Colors.deepPurple,
      icon: Icons.inventory_2_outlined,
      title: 'Quantitat: ${item.quantitat}',
      lines: [
        'Recurs ID: ${item.idRecurs}',
        'Data necessitat: ${obraFormatDate(item.dataNecessitat)}',
        'Entrega: ${obraFormatDate(item.dataEntrega)}',
        'Proveïdor: ${obraFormatText(item.proveidor)}',
      ],
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
    return ObraDataCard(
      accent: Colors.indigo,
      icon: Icons.badge_outlined,
      title: 'Treballador ID: ${responsable.idTreballador}',
      lines: [
        'Inici: ${obraFormatDate(responsable.dataInici)}',
        'Fi: ${obraFormatDate(responsable.dataFi)}',
      ],
    );
  }
}

class ObraDataCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final List<String> lines;

  const ObraDataCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 118,
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
                                height: 1.3,
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
    );
  }
}

class ObraInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const ObraInfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class ObraStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const ObraStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}