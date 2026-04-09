import 'package:flutter/material.dart';
import 'package:front_end/models/treballador_models.dart';

class TreballadorHeaderCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorHeaderCard({
    super.key,
    required this.profile,
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
          _TreballadorAvatar(
            imageUrl: profile.fotoUrl,
            fullName: profile.nomComplet,
            size: 78,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.nomComplet,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if ((profile.nickname ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@${profile.nickname!.trim()}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TreballadorTag(
                      icon: Icons.badge_outlined,
                      label: profile.carrecLabel,
                    ),
                    _TreballadorTag(
                      icon: Icons.business_outlined,
                      label: profile.empresaLabel,
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

class TreballadorContactCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorContactCard({
    super.key,
    required this.profile,
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
            'Contacte',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (!profile.hasContactInfo)
            _TreballadorEmptyInline(
              text: 'No hi ha dades de contacte disponibles.',
            )
          else ...[
            if ((profile.telefon ?? '').trim().isNotEmpty)
              _TreballadorContactRow(
                icon: Icons.phone_outlined,
                label: 'Telèfon',
                value: profile.telefon!,
              ),
            if ((profile.telefon ?? '').trim().isNotEmpty &&
                (profile.email ?? '').trim().isNotEmpty)
              const SizedBox(height: 12),
            if ((profile.email ?? '').trim().isNotEmpty)
              _TreballadorContactRow(
                icon: Icons.mail_outline,
                label: 'Correu',
                value: profile.email!,
              ),
          ],
        ],
      ),
    );
  }
}

class TreballadorSummaryCard extends StatelessWidget {
  final TreballadorProfileData profile;

  const TreballadorSummaryCard({
    super.key,
    required this.profile,
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
            'Resum',
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
                label: 'Estat',
                value: profile.estatLabel,
              ),
              _TreballadorInfoPill(
                label: 'Tasques',
                value: profile.tasquesCount.toString(),
              ),
              _TreballadorInfoPill(
                label: 'Obres',
                value: profile.obresCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TreballadorLoadingCard extends StatelessWidget {
  const TreballadorLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withOpacity(0.08)),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class TreballadorErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TreballadorErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.error.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: scheme.error),
              const SizedBox(width: 10),
              Text(
                'No s’ha pogut carregar el perfil',
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Torna-ho a provar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TreballadorAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullName;
  final double size;

  const _TreballadorAvatar({
    required this.imageUrl,
    required this.fullName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initialsFromName(fullName);
    final url = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarFallback(
                initials: initials,
              ),
            )
          : _AvatarFallback(
              initials: initials,
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (initials.isEmpty) {
      return Icon(
        Icons.person,
        color: scheme.primary,
        size: 34,
      );
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _TreballadorTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TreballadorTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreballadorContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TreballadorContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
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

class _TreballadorEmptyInline extends StatelessWidget {
  final String text;

  const _TreballadorEmptyInline({
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

String _initialsFromName(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.isEmpty) return '';
  if (parts.length == 1) {
    return parts.first.characters.take(1).toString().toUpperCase();
  }

  final first = parts.first.characters.take(1).toString();
  final second = parts[1].characters.take(1).toString();
  return '$first$second'.toUpperCase();
}