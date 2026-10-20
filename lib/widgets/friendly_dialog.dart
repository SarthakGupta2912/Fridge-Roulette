import 'package:flutter/material.dart';

/// Shows a friendly pop-up with one or two big choices.
/// Returns true for the main choice, false for the second choice,
/// or null when the pop-up is closed without choosing.
Future<bool?> showFriendlyDialog(
  BuildContext context, {
  required String emoji,
  required String title,
  required String body,
  required String primaryLabel,
  String? secondaryLabel,
}) async {
  final bool? answer = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: ExcludeSemantics(
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.bodyLarge,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (secondaryLabel != null)
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(secondaryLabel),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(primaryLabel),
          ),
        ],
      );
    },
  );
  return answer;
}

/// Shows a short message with one OK button.
Future<void> showMessageDialog(
  BuildContext context, {
  required String emoji,
  required String title,
  required String body,
  required String buttonLabel,
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        icon: ExcludeSemantics(
          child: Text(emoji, style: const TextStyle(fontSize: 48)),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(dialogContext).textTheme.bodyLarge,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(buttonLabel),
          ),
        ],
      );
    },
  );
}
