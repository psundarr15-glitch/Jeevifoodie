import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final current = context.watch<LocaleProvider>().locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.language)),
      body: ListView(
        children: [
          RadioListTile<String>(
            value: 'en',
            groupValue: current,
            title: const Text('English'),
            onChanged: (v) => context.read<LocaleProvider>().setLocale(const Locale('en')),
          ),
          RadioListTile<String>(
            value: 'ta',
            groupValue: current,
            title: const Text('தமிழ்'),
            onChanged: (v) => context.read<LocaleProvider>().setLocale(const Locale('ta')),
          ),
        ],
      ),
    );
  }
}
