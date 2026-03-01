import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../localization/locale_provider.dart';
import '../../../localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('settings'),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).translate('language'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 20),
            DropdownButton<Locale>(
              value: localeProvider.locale,
              items: const [
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: Locale('hi'),
                  child: Text('Hindi'),
                ),
                DropdownMenuItem(
                  value: Locale('es'),
                  child: Text('Spanish'),
                ),
              ],
              onChanged: (Locale? locale) {
                if (locale != null) {
                  localeProvider.setLocale(locale);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
