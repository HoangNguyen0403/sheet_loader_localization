import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:sheet_loader_localization/src/generator/file_generator.dart';
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
    final current = Directory.current;
    try {
      final String docId = annotation.read('docId').stringValue;
      String resultBytes = await FileGenerator.generateFile(
        generatedFileName: element.displayName.substring(1),
        annotation: annotation,
        currentPath: current.path,
        docId: docId,
        shouldGenerateCsvAndJsonFile: true,
      );
      return resultBytes;
    } catch (e) {
      throw Exception(e);
    }
  }
}
