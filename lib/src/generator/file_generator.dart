import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:sheet_loader_localization/src/parser/csv_parser.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class FileGenerator {
  static FutureOr<String> generateFile(
      {required String generatedFileName,
      required ConstantReader annotation,
      required String currentPath,
      List<FileSystemEntity> files = const [],
      String docId = '',
      bool shouldGenerateCsvAndJsonFile = false}) async {
    assert(files.isEmpty && docId.isEmpty,
        'At least 1 local file or online doc is provided');
    assert(files.isNotEmpty && docId.isNotEmpty,
        'Only 1 local csv type or online sheet is allow to be provided');

    final classBuilder = StringBuffer();
    classBuilder.writeln(
        '// DO NOT EDIT. This is code generated via package:sheet_loader_localization');

    classBuilder.writeln(
        '// Generated at: ${_formatDateWithOffset(DateTime.now().toLocal())}');
    classBuilder.writeln('class $generatedFileName {');

    final List<String> preservedKeywords = annotation
        .read('preservedKeywords')
        .listValue
        .map((e) => e.toStringValue() ?? "")
        .toList();

    final bodyBytes = files.isNotEmpty
        ? await _getLocalCsvData(files: files)
        : await _getOnlineSheetData(docId: docId);

    final csvParser = CSVParser(utf8.decode(bodyBytes));

    final languages = csvParser.getLanguages();
    Map<String, Map<String, String>> translations = {};
    languages
        .map((e) => {e.toString(): csvParser.getLanguageMap(e)})
        .forEach((element) => translations.addAll(element));
    if (shouldGenerateCsvAndJsonFile) {
      final outputDir = annotation.read('outDir').stringValue;
      final outputFileName = annotation.read('outName').stringValue;
      final output = Directory.fromUri(Uri.parse(outputDir));
      final outputPath = output.path;
      _writeCSVFile(
          currentPath: currentPath,
          outputPath: outputPath,
          outputFileName: outputFileName,
          bodyBytes: bodyBytes);
      _writeJsonFile(
          currentPath: currentPath,
          outputPath: outputPath,
          outputFileName: outputFileName,
          translations: translations);
    }
    classBuilder.writeln(csvParser.supportedLocales);
    classBuilder.writeln(csvParser.getLocaleKeys(preservedKeywords));

    classBuilder.writeln('}');
    return classBuilder.toString();
  }

  static FutureOr<List<int>> _getOnlineSheetData({required String docId}) async {
    try {
      final headers = {
        'Content-Type': 'text/csv; charset=utf-8',
        'Accept': '*/*'
      };
      final response = await http.get(
          Uri.parse(
              "https://docs.google.com/spreadsheets/export?format=csv&id=$docId"),
          headers: headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('http reasonPhrase: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Get data from sheet docID: $docId');
    }
  }

  static FutureOr<List<int>> _getLocalCsvData(
      {required List<FileSystemEntity> files}) {
    if (files.isEmpty) {
      return [];
    }
    final bodyBytes = File(files.first.path).readAsBytesSync();
    return bodyBytes;
  }

  static void _writeCSVFile({
    required String currentPath,
    required String outputPath,
    required String outputFileName,
    required List<int> bodyBytes,
  }) {
    final outputDirectory =
        Directory(path.join(currentPath, outputPath, "$outputFileName.csv"));
    final generatedFile = File(outputDirectory.path);
    if (!generatedFile.existsSync()) {
      generatedFile.createSync(recursive: true);
    }
    generatedFile.writeAsBytesSync(bodyBytes);
  }

  static void _writeJsonFile({
    required String currentPath,
    required String outputPath,
    required String outputFileName,
    required Map<String, Map<String, String>> translations,
  }) {
    final generatedJsonFile = File(
        Directory(path.join(currentPath, outputPath, "$outputFileName.json"))
            .path);
    if (!generatedJsonFile.existsSync()) {
      generatedJsonFile.createSync(recursive: true);
    }
    var encoder = const JsonEncoder.withIndent("  ");
    generatedJsonFile
        .writeAsBytesSync(utf8.encode(encoder.convert(translations)));
  }

  static String _formatDateWithOffset(DateTime date,
      {String format = 'EEE, dd MMM yyyy HH:mm:ss'}) {
    String twoDigits(int n) => n >= 10 ? "$n" : "0$n";

    final hours = twoDigits(date.timeZoneOffset.inHours.abs());
    final minutes = twoDigits(date.timeZoneOffset.inMinutes.remainder(60));
    final sign = date.timeZoneOffset.inHours > 0 ? "+" : "-";
    final formattedDate = DateFormat(format).format(date);

    return "$formattedDate $sign$hours:$minutes";
  }
}
