import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/active_subscription_entity.dart';

class SubscriberFlipCard extends StatefulWidget {
  final ActiveSubscriptionEntity sub;
  final String userName;
  final Widget front;

  const SubscriberFlipCard(
      {super.key,
      required this.sub,
      required this.userName,
      required this.front});

  @override
  State<SubscriberFlipCard> createState() => _SubscriberFlipCardState();
}

class _SubscriberFlipCardState extends State<SubscriberFlipCard> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: _flipped,
      label: _flipped
          ? 'Revenir au recto de la carte'
          : 'Retourner la carte pour lire les instructions',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _flipped = !_flipped),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _flipped ? math.pi : 0),
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, angle, _) {
              final showBack = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      excluding: showBack,
                      child: IgnorePointer(
                        ignoring: showBack,
                        child: Opacity(
                            opacity: showBack ? 0 : 1, child: widget.front),
                      ),
                    ),
                    Positioned.fill(
                      child: ExcludeSemantics(
                        excluding: !showBack,
                        child: IgnorePointer(
                          ignoring: !showBack,
                          child: Opacity(
                            opacity: showBack ? 1 : 0,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: _buildBack(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFullInstructions() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instructions de l’abonnement'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.sub.subscriptionName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(widget.sub.providerName),
            const SizedBox(height: 16),
            Text(widget.sub.instructions?.trim().isNotEmpty == true
                ? widget.sub.instructions!.trim()
                : 'Aucune instruction particulière pour cet abonnement.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'))
        ],
      ),
    );
  }

  Widget _buildBack() {
    final sub = widget.sub;
    final instructions = sub.instructions?.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x401A5C2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
                child: Text('Instructions de l’abonnement',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary))),
          ]),
          const SizedBox(height: 12),
          Text(sub.subscriptionName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (widget.userName.isNotEmpty)
            Text(widget.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          Text(sub.providerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text('Réf. ${sub.reference}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const Divider(height: 24),
          Expanded(
            child: _InstructionsPreview(
              text: instructions == null || instructions.isEmpty
                  ? 'Aucune instruction particulière pour cet abonnement.'
                  : instructions,
              onReadMore: _showFullInstructions,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Touchez la carte pour revenir au recto',
              style: TextStyle(fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _InstructionsPreview extends StatelessWidget {
  final String text;
  final VoidCallback onReadMore;
  const _InstructionsPreview({required this.text, required this.onReadMore});

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(const TextStyle(
        fontSize: 14, height: 1.5, color: AppColors.textPrimary));
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final fits = painter.height <= constraints.maxHeight;
      final lineHeight = painter.preferredLineHeight;
      painter.dispose();
      if (fits) return Text(text, style: style);
      final buttonHeight = math.min(48.0, constraints.maxHeight);
      final lines =
          ((constraints.maxHeight - buttonHeight) / lineHeight).floor();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines > 0)
            Expanded(
                child: Text(text,
                    style: style,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis)),
          SizedBox(
              height: buttonHeight,
              child: TextButton(
                onPressed: onReadMore,
                child: const Text('Voir plus'),
              )),
        ],
      );
    });
  }
}
