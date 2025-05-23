import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';

import 'sheet_localization.dart';

/// A localization generator to create csv file from google sheet.
class LocalizationGenerator extends GeneratorForAnnotation<SheetLocalization> {
  @override
  FutureOr<String> generateForAnnotatedElement(
          Element element, ConstantReader annotation, BuildStep buildStep) =>
      _generateSource(element, annotation);

  Future<String> _generateSource(
      Element element, ConstantReader annotation) async {
    try {
      final headers = {
        'Content-Type': 'text/csv; charset=utf-8',
        'Accept': '*/*'
      };
      final docId = annotation.read('docId').stringValue;
      final apiKey = annotation.read('apiKey').isNull
          ? null
          : annotation.read('apiKey').stringValue;

      if (docId.isEmpty) {
        throw Exception('Doc id is required in locale_keys.dart');
      }

      final response = apiKey?.isNotEmpty == true
          ? await http.get(
              Uri.parse(
                "https://www.googleapis.com/drive/v3/files/$docId/export?mimeType=text/csv&key=$apiKey",
              ),
              headers: headers,
            )
          : await http.get(
              Uri.parse(
                  "https://docs.google.com/spreadsheets/export?format=csv&id=$docId"),
              headers: headers,
            );

      if (response.statusCode != 200) {
        throw Exception('http reasonPhrase: ${response.reasonPhrase}');
      }

      return _handleResponseCsv(
        bodyBytes: response.bodyBytes,
        element: element,
        annotation: annotation,
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  String _handleResponseCsv({
    required Uint8List bodyBytes,
    required Element element,
    required ConstantReader annotation,
  }) {
    final classBuilder = StringBuffer();
    classBuilder.writeln(
        '// Generated at: ${_formatDateWithOffset(DateTime.now().toLocal())}');
    classBuilder.writeln('class ${element.displayName.substring(1)}{');
    final outputDir = annotation.read('outDir').stringValue;
    final outputFileName = annotation.read('outName').stringValue;
    final List<String> preservedKeywords = annotation
        .read('preservedKeywords')
        .listValue
        .map((e) => e.toStringValue() ?? "")
        .toList();
    final current = Directory.current;
    final output = Directory.fromUri(Uri.parse(outputDir));
    final outputPath =
        Directory(path.join(current.path, output.path, "$outputFileName.csv"));

    final generatedFile = File(outputPath.path);
    if (!generatedFile.existsSync()) {
      generatedFile.createSync(recursive: true);
    }

    generatedFile.writeAsBytesSync(bodyBytes);

    final csvParser = _CSVParser(utf8.decode(bodyBytes));

    final generatedJsonFile = File(
        Directory(path.join(current.path, output.path, "$outputFileName.json"))
            .path);
    if (!generatedJsonFile.existsSync()) {
      generatedJsonFile.createSync(recursive: true);
    }

    final languages = csvParser.getLanguages();
    Map<String, Map<String, String>> translations = {};
    languages
        .map((e) => {e.toString(): csvParser.getLanguageMap(e)})
        .forEach((element) => translations.addAll(element));

    var encoder = const JsonEncoder.withIndent("  ");
    generatedJsonFile
        .writeAsBytesSync(utf8.encode(encoder.convert(translations)));

    classBuilder.writeln(csvParser._supportedLocales);
    classBuilder.writeln(csvParser._getLocaleKeys(preservedKeywords));
    classBuilder.writeln('}');
    return classBuilder.toString();
  }

  String _formatDateWithOffset(DateTime date,
      {String format = 'EEE, dd MMM yyyy HH:mm:ss'}) {
    String twoDigits(int n) => n >= 10 ? "$n" : "0$n";

    final hours = twoDigits(date.timeZoneOffset.inHours.abs());
    final minutes = twoDigits(date.timeZoneOffset.inMinutes.remainder(60));
    final sign = date.timeZoneOffset.inHours > 0 ? "+" : "-";
    final formattedDate = DateFormat(format).format(date);

    return "$formattedDate $sign$hours:$minutes";
  }
}

class _CSVParser {
  final String fieldDelimiter;
  final String strings;
  final List<List<dynamic>> lines;

  _CSVParser(this.strings, {this.fieldDelimiter = ','})
      : lines = const CsvToListConverter()
            .convert(strings, fieldDelimiter: fieldDelimiter);

  List<dynamic> get _localesSupport => lines.first
      .sublist(1, lines.first.length)
      .where((value) => (value as String).isNotEmpty)
      .toList();

  List<List<dynamic>> get _sheetWithLocaleLines => lines
      .map((childLine) => childLine.sublist(0, _localesSupport.length + 1))
      .toList();

  String get _supportedLocales {
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
    return 'static const supportedLocales = [\n${locales.join(',\n')}\n];';
  }

  String _getLocaleKeys(List<String> preservedKeywords) {
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
