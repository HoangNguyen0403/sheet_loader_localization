import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;
import 'package:sheet_loader_localization/src/generator/file_generator.dart';
import 'package:sheet_loader_localization/src/local_csv/local_csv_localization.dart';
import 'package:source_gen/source_gen.dart';

class LocalCsvGenerator extends GeneratorForAnnotation<LocalCsvLocalization> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    try {
      final current = Directory.current;

      final sourceDir = annotation.read('path').stringValue;
      final sourceFile = annotation.read('sourceFile').stringValue;

      final source = Directory.fromUri(Uri.parse(sourceDir));
      final sourcePath = Directory(path.join(current.path, source.path));

      if (!await sourcePath.exists()) {
        String errorMessage = 'Source path does not exist';

        stderr.writeln(errorMessage);
        throw Exception(errorMessage);
      }

      var files = await dirContents(sourcePath);
      if (sourceFile.isNotEmpty) {
        final seekSourceFile = File(path.join(source.path, sourceFile));
        if (!await seekSourceFile.exists()) {
          throw ('Source file does not exist (${sourceFile.toString()})');
        }
        files = [seekSourceFile];
      } else {
        //filtering format
        files = files.where((f) => f.path.contains('.csv')).toList();
      }

      var result = '';
      if (files.isNotEmpty) {
        result = await FileGenerator.generateFile(
              generatedFileName: element.displayName.substring(1),
              annotation: annotation,
              currentPath: current.path,
              files: files,
            );
      } else {
        throw (Exception('Source path empty'));
      }
      return result;
    } catch (e) {
      throw Exception('File generation error $e');
    }
  }

  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: false);
    lister.listen((file) => files.add(file),
        onDone: () => completer.complete(files));
    return completer.future;
  }
}
