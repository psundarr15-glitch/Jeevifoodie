import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../state/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class StaticPageScreen extends StatefulWidget {
  final String url;
  const StaticPageScreen({super.key, required this.url});

  @override
  State<StaticPageScreen> createState() => _StaticPageScreenState();
}

class _StaticPageScreenState extends State<StaticPageScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    final lang = context.read<LocaleProvider>().locale.languageCode;
    _future = ApiClient.get('${widget.url}?lang=$lang');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.couldNotLoadPage(snap.error.toString())));
          }
          final data = snap.data!;
          final title = data['title']?.toString() ?? '';
          final updated = data['updated']?.toString();
          final sections = (data['sections'] as List? ?? []).cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (updated != null) ...[
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.lastUpdated(updated), style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              for (final s in sections) ...[
                if (s['heading'] != null) ...[
                  Text(s['heading'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                  const SizedBox(height: 6),
                ],
                Text(s['body']?.toString() ?? '', style: const TextStyle(fontSize: 14.5, height: 1.5)),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}
