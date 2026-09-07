import 'package:flutter/material.dart';
import 'package:multilingual/multilingual.dart';
import 'package:multilingual/extensions.dart';
import 'app_languages.dart';
import 'language_store.dart';
import 'theme.dart';

// Settings aur Permission dono screens se yahi bottom sheet khulti hai â€”
// tap karte hi turant switch (MultilingualController.setLocale) + persist

// (LanguageStore) taaki agli baar app khulte hi wahi language mile.
Future<void> showLanguagePicker(BuildContext context) async {
  final current = MultilingualController.locale.languageCode;
  await showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).appColors.tileBg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'select_language'.trans(),
              style: TextStyle(
                  color: onSurface, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // 19 languages — kabhi bhi screen se lambe ho sakte hai, isliye
            // Flexible + shrinkWrap ListView rakha (RenderFlex overflow avoid).
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppLanguages.labels.length,
                itemBuilder: (context, index) {
                  final entry = AppLanguages.labels.entries.elementAt(index);
                  final selected = entry.key == current;
                  return ListTile(
                    title: Text(entry.value, style: TextStyle(color: onSurface)),
                    trailing: selected
                        ? const Icon(Icons.check_rounded, color: kAccent)
                        : null,
                    onTap: () async {
                      await MultilingualController.setLocale(
                          AppLanguages.localeFor(entry.key));
                      await LanguageStore.save(entry.key);
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}