import 'package:csv/csv.dart';

class CSVParser {
  final String fieldDelimiter;
  final String strings;
  final List<List<dynamic>> lines;

  CSVParser(this.strings, {this.fieldDelimiter = ','})
      : lines = const CsvToListConverter()
      .convert(strings, fieldDelimiter: fieldDelimiter);

  List<dynamic> get _localesSupport => lines.first
      .sublist(1, lines.first.length)
      .where((value) => (value as String).isNotEmpty)
      .toList();

  List<List<dynamic>> get _sheetWithLocaleLines => lines
      .map((childLine) => childLine.sublist(0, _localesSupport.length + 1))
      .toList();

  String get supportedLocales {
    final locales = _localesSupport.map((currentLocale) {
      final languages = currentLocale.toString().split('_');
      if (languages.length == 1) {
        return "Locale('${languages[0]}')";
      } else if (languages.length == 2) {
        return "Locale('${languages[0]}', '${languages[1]}')";
      } else {
        throw Exception(
            "You are using wrong locale format. Please check again your wrong value ${currentLocale.toString()}. Correct format is languagesCode_countryCode : en_US");
      }
    }).toList();
    return 'static const List<Locale> supportedLocales = [\n${locales.join(',\n')}\n];';
  }

  String getLocaleKeys(List<String> preservedKeywords) {
    final List<String> oldKeys = _sheetWithLocaleLines
        .getRange(1, _sheetWithLocaleLines.length)
        .map((e) => e.first.toString())
        .toList();

    final List<String> keys = [];
    final strBuilder = StringBuffer();
    oldKeys.forEach((element) {
      _reNewKeys(preservedKeywords, keys, element);
    });
    keys.sort();
    for (int index = 0; index < keys.length; index++) {
      final group1 = keys[index].split(RegExp(r"[._]"));
      if (index == 0) {
        _groupKey(strBuilder, group1, keys[index]);
        continue;
      }
      final group2 = keys[index - 1].split(RegExp(r"[._]"));
      if (group1.isEmpty || group2.isEmpty) {
        continue;
      }
      if (group1.first != group2.first) {
        strBuilder.writeln('\n   // ${group1.first}');
      }
      strBuilder
          .writeln('static const ${_joinKey(group1)} = \'${keys[index]}\';');
    }
    return strBuilder.toString();
  }

  void _groupKey(StringBuffer strBuilder, List<String> group, String key) {
    if (group.isEmpty) return;
    strBuilder.writeln('\n   // ${group.first}');
    strBuilder.writeln('static const ${_joinKey(group)} = \'$key\';');
  }

  void _reNewKeys(
      List<String> preservedKeywords, List<String> newKeys, String key) {
    final keys = key.split('.');
    for (int index = 0; index < keys.length; index++) {
      if (index == 0) {
        _addNewKey(newKeys, keys[index]);
        continue;
      }
      if (index == keys.length - 1 && preservedKeywords.contains(keys[index])) {
        continue;
      }
      _addNewKey(newKeys, keys.sublist(0, index + 1).join('.'));
    }
  }

  void _addNewKey(List<String> newKeys, String key) {
    if (!newKeys.contains(key)) {
      newKeys.add(key);
    }
  }

  List getLanguages() {
    return lines.first.sublist(1, lines.first.length);
  }

  Map<String, String> getLanguageMap(String localeName) {
    final indexLocale = lines.first.indexOf(localeName);

    var translations = <String, String>{};
    for (var i = 1; i < lines.length; i++) {
      translations.addAll({lines[i][0]: lines[i][indexLocale]});
    }
    return translations;
  }

  String _capitalize(String str) =>
      '${str[0].toUpperCase()}${str.substring(1)}';

  String _normalize(String str) => '${str[0].toLowerCase()}${str.substring(1)}';

  String _joinKey(List<String> keys) =>
      _normalize(keys.map((e) => _capitalize(e)).toList().join());
}