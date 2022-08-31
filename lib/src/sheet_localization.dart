/// A sheet localization generator class.
class SheetLocalization {
  final String docId;
  final int version;
  final String outDir; //output directory
  final String outName; //output file name
  final List<String> preservedKeywords;

  const SheetLocalization({
    required this.docId,
    this.version = 1,
    this.outDir = 'resources/langs',
    this.outName = 'langs',
    this.preservedKeywords = const [],
  });
}
