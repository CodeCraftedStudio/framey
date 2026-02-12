import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  english('English (US)', 'en'),
  bengali('Bengali', 'bn'),
  spanish('Spanish', 'es'),
  french('French', 'fr');

  final String name;
  final String code;
  const AppLanguage(this.name, this.code);
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((
  ref,
) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void setLanguage(AppLanguage language) {
    state = language;
  }
}
