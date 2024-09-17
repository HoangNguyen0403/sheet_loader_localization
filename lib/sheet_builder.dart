import 'package:build/build.dart';
import 'package:sheet_loader_localization/src/local_csv/local_csv_generator.dart';
import 'package:source_gen/source_gen.dart';

import 'src/sheet_loader/localization_generator.dart';

/// A localization generator with build-runner.
Builder localizationGenerator(BuilderOptions options) => SharedPartBuilder(
    [LocalizationGenerator(), LocalCsvGenerator()], 'localization_generator');
