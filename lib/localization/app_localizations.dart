import 'package:flutter/material.dart';
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) 
        ?? AppLocalizations(const Locale('en'));
  }
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
  String translate(String key) => key;
}
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
