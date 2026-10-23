import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class SubscriptionDescription extends StatefulWidget {
  final String text;
  const SubscriptionDescription({super.key, required this.text});

  @override
  State<SubscriptionDescription> createState() =>
      _SubscriptionDescriptionState();
}

class _SubscriptionDescriptionState extends State<SubscriptionDescription> {
  bool _expanded = false;

  @override
  void didUpdateWidget(SubscriptionDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    // Conserve la ponctuation, les espaces et les retours à la ligne originaux.
    final words = RegExp(r'\S+').allMatches(widget.text).take(17).toList();
    final isLong = words.length > 16;
    final visibleText = isLong && !_expanded
        ? '${widget.text.substring(0, words[15].end).trimRight()}…'
        : widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(visibleText,
            style: const TextStyle(
                fontSize: 16, color: AppColors.textSecondary, height: 1.7)),
        if (isLong)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 0)),
            child: Text(_expanded ? 'Voir moins' : 'Voir plus'),
          ),
      ],
    );
  }
}
