class LocalCsvLocalization {
  final String path;
  final String sourceFile;
  final int version;
  final List<String> preservedKeywords;

  const LocalCsvLocalization( {
    required this.path,
    required this.sourceFile,
    this.version = 1,
    this.preservedKeywords = const [],
  });
}
