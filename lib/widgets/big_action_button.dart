import 'package:flutter/material.dart';

import 'app_sizes.dart';
import 'custom_text.dart';

/// The one big button a child can see from far away.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Icon(icon, size: AppSizes.iconLarge),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: CustomText(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}
