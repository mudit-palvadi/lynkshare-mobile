import 'package:flutter/material.dart';

import '../release_notes.dart';
import '../theme/app_theme.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({required this.notes, super.key});

  final ReleaseNotes? notes;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardBg,
      title: Text(
        notes == null ? 'What’s New' : 'What’s New in ${notes!.version}',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: notes == null
              ? Text(
                  'This update includes performance improvements and bug fixes.',
                  style: TextStyle(color: theme.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final section in notes!.sections) ...[
                      Text(
                        section.title,
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final item in section.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•'),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got It'),
        ),
      ],
    );
  }
}
