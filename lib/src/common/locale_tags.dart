import 'dart:ui';

/// Parse a BCP47-ish tag into a Flutter [Locale].
///
/// Handles the shapes locale FILES are named with: `en`, `en-US`,
/// `zh-Hans`, `zh-Hant-TW` (underscores accepted too). A 4-letter
/// middle subtag is a script; a 2–3 letter or 3-digit trailing subtag
/// is a region. Anything longer collapses to the first three subtags —
/// FTL layouts don't carry variants. The reverse direction is
/// [Locale.toLanguageTag].
Locale localeFromTag(String tag) {
  final parts = tag.replaceAll('_', '-').split('-');
  final language = parts[0].toLowerCase();
  if (parts.length == 1) return Locale(language);
  final second = parts[1];
  final isScript = second.length == 4;
  final script = isScript ? _titleCase(second) : null;
  final regionPart = isScript ? (parts.length > 2 ? parts[2] : null) : second;
  return Locale.fromSubtags(
    languageCode: language,
    scriptCode: script,
    countryCode: regionPart?.toUpperCase(),
  );
}

String _titleCase(String subtag) =>
    subtag[0].toUpperCase() + subtag.substring(1).toLowerCase();
