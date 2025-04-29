Here's your updated `README.md` content with the added instructions for handling **private Google Sheets** using an API key:

---

```markdown
# sheet_loader_localization

## Sheet Localization Generator

Download a CSV file and generate localization keys from an online Google Sheet to work
with [easy_localization](https://pub.dev/packages/easy_localization)
and [easy_localization_loader](https://pub.dev/packages/easy_localization_loader).

This tool is inspired by [flutter_sheet_localization_generator](https://pub.dev/packages/flutter_sheet_localization_generator)
and the original author [RinLV](https://github.com/rinlv).

---

### 🔩 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  easy_localization: <latest_version>
  easy_localization_loader: <latest_version>

dev_dependencies:
  build_runner: <latest_version>
  sheet_loader_localization: <latest_version>
```

---

### 🔌 Usage

#### 1. Create a CSV Google Sheet

Create a sheet with your translations (follow the format below;
[example sheet here](https://docs.google.com/spreadsheets/d/1v2Y3e0Uvn0JTwHvsduNT70u7Fy9TG43DIcZYJxPu1ZA/edit?usp=sharing)):

![CSV example](https://github.com/Hoang-Nguyenn/sheet_loader_localization/raw/main/csv_example.png)

#### 2. Share the Sheet

There are two options:

- **If your Google Sheet is _public_**, keep the setup as-is.
- **If your Google Sheet is _private_**, follow these steps:

    1. **Enable Google Drive API and Generate an API Key**  
       Follow this guide: [How to Use Google Drive API and Get an API Key](https://elfsight.com/blog/how-to-use-google-drive-api-and-get-an-api-key/)

    2. **Set the `apiKey` parameter** in the `@SheetLocalization` annotation.

---

#### 3. Declare the Localization Delegate

Create a Dart file (`lib/utils/multi-languages/locale_keys.dart`) with the following content:

```dart
import 'dart:ui';
import 'package:sheet_loader_localization/sheet_loader_localization.dart';

part 'locale_keys.g.dart';

@SheetLocalization(
  docId: 'DOCID',
  version: 1,
  outDir: 'resources/langs',
  outName: 'langs.csv',
  preservedKeywords: [],
  // OPTIONAL: Only required if your sheet is private
  apiKey: 'YOUR_GOOGLE_API_KEY',
)
class _LocaleKeys {}
```

---

#### 4. Generate the Localizations

Run the command below to generate the localization file:

```bash
flutter pub run build_runner build
# or
flutter pub run build_runner build --delete-conflicting-outputs
```

---

#### 5. Configure Your App

Follow the setup guide from the [easy_localization README](https://github.com/aissat/easy_localization/blob/develop/README.md).

---

### ⚡ Regeneration

To force regeneration of the CSV and localization files (due to caching), simply increment the `version` field in `@SheetLocalization` and rerun the build command.

---

### ❓ Why This Tool?

`easy_localization` supports code generation, but not directly from Google Sheets. This tool simplifies localization workflows by using Google Sheets (ideal for collaboration with non-devs) and supports Flutter null safety.
```