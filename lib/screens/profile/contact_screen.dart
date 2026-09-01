import 'package:flutter/material.dart';
import '../../services/link_launcher.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

/// Reused for Help & Support and Open Vendor - those don't have a proper
/// in-app flow yet, so rather than a broken/fake button, each of these
/// routes here with copy explaining what it's for and a real way to
/// reach support. (Live Chat now has its own real screen — see
/// screens/chat/chat_screen.dart — and no longer uses this.)
class ContactScreen extends StatelessWidget {
  final String title;
  final String message;
  const ContactScreen({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.support_agent, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => LinkLauncher.email(context, 'support@tvkomalur.xyz'),
              icon: const Icon(Icons.mail_outline),
              label: Text(AppLocalizations.of(context)!.emailSupportButton),
            ),
          ],
        ),
      ),
    );
  }
}
