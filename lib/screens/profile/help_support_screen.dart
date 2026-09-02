import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/link_launcher.dart';
import '../../config/api_config.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

/// Help & Support page: a banner image at the top, then the app's
/// address/phone/email below — all editable from Admin > Help & Support
/// Settings (Api\StaticContentApiController::support), so nothing here
/// is hardcoded.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late final Future<Map<String, dynamic>> _future = ApiClient.get(ApiConfig.pageSupport);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.helpSupport)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(t.couldNotLoadPage(snap.error.toString())));
          }
          final data = snap.data!;
          final bannerUrl = data['banner_image'] as String?;
          final address = data['address'] as String?;
          final phone = data['phone'] as String?;
          final email = data['email'] as String?;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (bannerUrl != null && bannerUrl.isNotEmpty)
                Image.network(
                  bannerUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address != null && address.trim().isNotEmpty) ...[
                      _InfoTile(icon: Icons.location_on_outlined, label: 'Address', value: address),
                      const SizedBox(height: 12),
                    ],
                    if (phone != null && phone.trim().isNotEmpty) ...[
                      _InfoTile(
                        icon: Icons.call_outlined,
                        label: 'Contact Number',
                        value: phone,
                        onTap: () => LinkLauncher.call(context, phone),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (email != null && email.trim().isNotEmpty)
                      _InfoTile(
                        icon: Icons.mail_outline,
                        label: 'Email ID',
                        value: email,
                        onTap: () => LinkLauncher.email(context, email),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoTile({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
