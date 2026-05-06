import 'package:flutter/material.dart';

import 'package:front_end/models/document_models.dart';

class DocumentListHeaderCard extends StatelessWidget {
  final int total;
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;
  final List<String> availableTypes;

  const DocumentListHeaderCard({
    super.key,
    required this.total,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableTypes,
  });

  

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents de l’obra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '$total document(s) disponibles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (availableTypes.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Filtrar per tipus',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tots els tipus'),
                  ),
                  ...availableTypes.map(
                    (type) => DropdownMenuItem<String?>(
                      value: type,
                      child: Text(type),
                    ),
                  ),
                ],
                onChanged: onTypeChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DocumentObraCard extends StatelessWidget {
  final DocumentObraItem document;
  final VoidCallback onDownload;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isBusy;

  const DocumentObraCard({
    super.key,
    required this.document,
    required this.onDownload,
    this.onEdit,
    this.onDelete,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBusy ? null : onDownload,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(_iconForFormat(document.format)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.displayName,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.fileName,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DocumentChip(label: document.formatLabel),
                        _DocumentChip(label: document.tipus),
                        _DocumentChip(label: document.midaLabel),
                        _DocumentChip(label: document.dataLabel),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !isBusy,
                onSelected: (value) {
                  if (value == 'download') onDownload();
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Baixar / obrir'),
                  ),
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar metadades'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForFormat(String format) {
    final value = format.toLowerCase();

    if (value.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (value.contains('jpg') ||
        value.contains('jpeg') ||
        value.contains('png') ||
        value.contains('webp')) {
      return Icons.image_rounded;
    }
    if (value.contains('doc')) return Icons.description_rounded;
    if (value.contains('xls')) return Icons.table_chart_rounded;

    return Icons.insert_drive_file_rounded;
  }
}

class DocumentUploadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DocumentUploadButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file_rounded),
      label: const Text('Pujar document'),
    );
  }
}

class DocumentEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onAction;

  const DocumentEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 42,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Pujar document'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DocumentErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const DocumentErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tornar-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentLoadingCard extends StatelessWidget {
  const DocumentLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final String label;

  const _DocumentChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.trim().isEmpty ? 'General' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}