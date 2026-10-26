import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/current_account.dart';
import '../../../core/api/api_client.dart';
import '../../../app/theme/app_colors.dart';
import '../../subscriptions/domain/entities/subscription_entity.dart';
import 'favorites_controller.dart';

class FavoriteButton extends ConsumerStatefulWidget {
  final SubscriptionEntity subscription;
  const FavoriteButton({super.key, required this.subscription});

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _landing;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _landing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30 / 0.65),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.22)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 14 / 0.65),
      TweenSequenceItem(
          tween: Tween(begin: 1.22, end: 0.94), weight: 10.5 / 0.65),
      TweenSequenceItem(
          tween: Tween(begin: 0.94, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 10.5 / 0.65),
    ]).animate(_landing);
  }

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subscription.id != widget.subscription.id) _landing.reset();
  }

  @override
  void dispose() {
    _landing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = widget.subscription;
    ref.listen<String?>(currentAccountIdProvider, (previous, next) {
      if (previous != next) _landing.reset();
    });
    final account = ref.watch(currentAccountIdProvider);
    final state = ref.watch(favoritesControllerProvider);
    final selected = account != null &&
        (state.flags[subscription.id] ?? subscription.isFavorite);
    final pending = state.pending.contains(subscription.id);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    Widget bounceIcon(Widget icon) => AnimatedBuilder(
          animation: _landing,
          child: icon,
          builder: (_, child) => Transform.scale(
              scale: reduceMotion ? 1 : _bounce.value, child: child),
        );
    final button = IconButton(
      tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
      isSelected: selected,
      onPressed: pending || subscription.id.isEmpty
          ? null
          : () async {
              if (account == null) {
                final redirect = Uri.encodeComponent(
                    GoRouterState.of(context).uri.toString());
                context.push('/login?redirect=$redirect');
                return;
              }
              _landing.reset();
              final controller = ref.read(favoritesControllerProvider.notifier);
              try {
                await controller.toggle(subscription);
                if (!context.mounted ||
                    ref.read(currentAccountIdProvider) != account ||
                    ref.read(favoritesControllerProvider.notifier) !=
                        controller) {
                  return;
                }
                if (!selected &&
                    ref
                            .read(favoritesControllerProvider)
                            .flags[subscription.id] ==
                        true &&
                    !MediaQuery.of(context).disableAnimations) {
                  _landing.forward(from: 0);
                }
              } catch (error) {
                if (!context.mounted ||
                    ref.read(currentAccountIdProvider) != account) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(extractException(error).message)));
              }
            },
      style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.96),
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8)),
      icon: pending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary))
          : bounceIcon(const Icon(Icons.favorite_border_rounded, size: 20)),
      selectedIcon: pending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary))
          : bounceIcon(const Icon(Icons.favorite_rounded,
              size: 20, color: AppColors.accent)),
    );
    return AnimatedBuilder(
      animation: _landing,
      builder: (context, _) {
        final t = _landing.value;
        // Match the web heart's keyframes at 0%, 20%, 65% and 100%.
        double frame(List<double> values) {
          const times = [0.0, 0.2, 0.65, 1.0];
          final index = t < times[1] ? 0 : (t < times[2] ? 1 : 2);
          final progress = Curves.easeOut.transform(
              ((t - times[index]) / (times[index + 1] - times[index]))
                  .clamp(0.0, 1.0));
          return values[index] + (values[index + 1] - values[index]) * progress;
        }

        final opacity = frame([0, 1, 1, 0]);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            button,
            if (_landing.isAnimating && selected && !reduceMotion)
              Positioned.fill(
                  child: IgnorePointer(
                      child: ExcludeSemantics(
                child: Center(
                    child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset:
                        Offset(frame([-5, -3, 0, 0]), frame([-26, -17, 0, 0])),
                    child: Transform.rotate(
                      angle: frame([-14, -8, 0, 0]) * 3.141592653589793 / 180,
                      child: Transform.scale(
                          scale: frame([0.65, 1, 1.05, 0.7]),
                          child: const Icon(Icons.favorite_rounded,
                              key: Key('favorite-landing-heart'),
                              size: 20,
                              color: AppColors.accent)),
                    ),
                  ),
                )),
              ))),
          ],
        );
      },
    );
  }
}
