import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/localization_generator.dart';

/// A localization generator with build-runner.
Builder localizationGenerator(BuilderOptions options) =>
    SharedPartBuilder([LocalizationGenerator()], 'localization_generator');
