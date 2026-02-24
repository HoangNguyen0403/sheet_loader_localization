# sheet_loader_localization

## Sheet Localization Generator

Download a CSV file and generate localization keys from an online Google Sheet to work
with [easy_localization](https://pub.dev/packages/easy_localization)
and [easy_localization_loader](https://pub.dev/packages/easy_localization_loader).

This tool is inspired by [flutter_sheet_localization_generator](https://pub.dev/packages/flutter_sheet_localization_generator)
and the original author [RinLV](https://github.com/rinlv).

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

Create a sheet with your translations (follow the format below or can make a copy of;
[example sheet here](https://docs.google.com/spreadsheets/d/1uom6PBN6fS1tg8dB76xiL2VBXcN4EiyxPSXL4nEIYVA/edit?gid=1013756643#gid=1013756643)):
[Make a copy of the sheet](https://docs.google.com/spreadsheets/d/1uom6PBN6fS1tg8dB76xiL2VBXcN4EiyxPSXL4nEIYVA/copy)

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

### 🚀 Google Sheets Automation (Recommended)

To eliminate the manual toil of translating keys, we provide an **Automation Script** that runs directly inside your Google Sheet. This bridges the gap between creating a key and having it ready for the Dart generator.

#### **Why use the automation script?**

- **Instant Multi-Language Support**: Translate an entire sheet into 10+ languages (Vietnamese, French, Japanese, etc.) with one click.
- **Incremental Updates**: Only translate new keys ("Fill Missing"), preserving your existing manual adjustments.
- **Smart Duplicate Management**: Identify and remove identical rows or duplicate keys automatically, and highlight similar English translations for manual review.
- **Error Highlighting**: Automatically flags rows that fail to translate in red background for easy debugging.
- **Zero Configuration**: Automatically detects language codes from your headers (e.g., `vi_VN` → `vi`).

#### **Setup Automation**

> [!TIP]
> **Recommended: One-Click Setup**  
> To get full support with automation scripts pre-configured, simply:  
> [**Make a copy of the Example Spreadsheet**](https://docs.google.com/spreadsheets/d/1uom6PBN6fS1tg8dB76xiL2VBXcN4EiyxPSXL4nEIYVA/copy)
>
> Once copied, refresh your Spreadsheet browser tab to see the menu.

---

#### **Manual Setup (Alternative)**

If you prefer to set up the scripts manually in your existing spreadsheet:

1. In your Google Sheet, go to **Extensions** > **Apps Script**.
2. Copy the code from [LanguageTranslation.gs](https://github.com/Hoang-Nguyenn/sheet_loader_localization/blob/main/apps_script/LanguageTranslation.gs) for Language Translation setup and paste it into the editor.
3. Copy the code from [DuplicateUI.html](https://github.com/Hoang-Nguyenn/sheet_loader_localization/blob/main/apps_script/DuplicateUI.html) for UI duplication manager setup and paste it into the editor.
4. Save the project, Click Run button and refresh your Spreadsheet browser tab.
5. A new menu **"🌐 Localization Hub"** will appear in your toolbar.

![Localization Hub Config](https://github.com/Hoang-Nguyenn/sheet_loader_localization/raw/main/localization_hub_config.png)

---

### 🛡️ Security & Privacy (For Engineers)

We prioritize data sovereignty and local execution:

- **Local Execution**: This script runs entirely within **your** Google Workspace environment (Apps Script). No data is ever sent to third-party servers.
- **No Data Collection**: We do not collect or track your sheet IDs, translation content, or user identity.
- **Direct API Usage**: The script uses Google's built-in `LanguageApp`, communicating directly between your sheet and the translation service.
- **Transparent Code**: 100% open-source. We encourage you to audit the code before adding it to your workflow.

---

### ⏱️ Productivity Comparison

| Task                               | Manual Workflow               | With This Tool & Script             |
| :--------------------------------- | :---------------------------- | :---------------------------------- |
| **Adding a new key (5 languages)** | ~10 mins (Manual Copy/Paste)  | **< 10 seconds**                    |
| **Fixing translation errors**      | Manual search & fix           | **"Translate Selected" (2 clicks)** |
| **Cleaning duplicates**            | Manual searching & deleting   | **"Smart Duplicate Manager"**       |
| **Handling placeholders**          | High risk of breaking `{var}` | **Preserved via script logic**      |
| **Security Audit**                 | Unknown 3rd party apps        | **100% Transparent Script**         |

---

### 🛠 Troubleshooting

**Ghosting Menus**: If you see duplicate menus (like "Translation Tools" and "Localization Hub") after updating the script, simply refresh your browser tab. Google Sheets caches UI elements; a reload clears the old definitions.

### ⚡ Regeneration

To force regeneration of the CSV and localization files (due to caching), simply increment the `version` field in `@SheetLocalization` and rerun the build command.

---

### ❓ Why This Tool?

`easy_localization` supports code generation, but not directly from Google Sheets. This tool simplifies localization workflows by using Google Sheets (ideal for collaboration with non-devs) and supports Flutter null safety.
