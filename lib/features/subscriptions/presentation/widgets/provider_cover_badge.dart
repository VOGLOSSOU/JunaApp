import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/provider_entity.dart';

/// Bandeau contraint à la largeur de la photo par son parent Positioned.
class ProviderCoverBadge extends StatelessWidget {
  final ProviderEntity provider;
  const ProviderCoverBadge({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: provider.name,
      child: Semantics(
        button: true,
        label: 'Voir le profil de ${provider.name}',
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.push('/providers/${provider.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Proposé par',
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.3,
                                color: Colors.white70)),
                        const SizedBox(height: 3),
                        Text(provider.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white54,
                                decorationThickness: 0.7,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  if (provider.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified,
                        color: Color(0xFF60A5FA),
                        size: 16,
                        semanticLabel: 'Prestataire vérifié'),
                  ],
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
