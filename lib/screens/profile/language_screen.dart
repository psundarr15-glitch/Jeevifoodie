import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/locale_provider.dart';
import '../../theme.dart';
import '../../l10n/app_localizations.dart';

/// Bottom-sheet language picker (flag + name + selection circle, with a
/// confirming "Update" button) — call [showLanguagePicker] rather than
/// pushing this as a route.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => const _LanguagePickerSheet(),
  );
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet();

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  late String _selected = context.read<LocaleProvider>().locale.languageCode;

  static const _languages = [
    (code: 'en', flag: '🇬🇧', name: 'English'),
    (code: 'ta', flag: '🇮🇳', name: 'தமிழ்'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Text(t.chooseYourLanguage, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(t.chooseYourLanguageSubtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
            const SizedBox(height: 20),
            for (final lang in _languages) ...[
              InkWell(
                onTap: () => setState(() => _selected = lang.code),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selected == lang.code ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                    border: Border.all(color: _selected == lang.code ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(lang.name, style: const TextStyle(fontSize: 16))),
                      if (_selected == lang.code)
                        const Icon(Icons.check_circle, color: AppTheme.primary)
                      else
                        Icon(Icons.circle_outlined, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  context.read<LocaleProvider>().setLocale(Locale(_selected));
                  Navigator.of(context).pop();
                },
                child: Text(t.update, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
