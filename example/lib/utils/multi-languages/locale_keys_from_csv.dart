import 'package:sheet_loader_localization/sheet_loader_localization.dart';

import 'dart:ui' show Locale;

part 'locale_keys_from_csv.g.dart';

@LocalCsvLocalization(path: 'resources/langs/', sourceFile: 'langs.csv')
class _LocaleKeysFromCsv {}
