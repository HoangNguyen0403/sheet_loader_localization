/**
 * 🌍 Dynamic Localization Script (V3)
 * Features: Auto-highlighting [ERR] cells & UI Cleanup tools.
 */

// ==========================================
// ⚙️ CONFIGURATION
// ==========================================

const CONFIG = {
  SOURCE_COLUMN_HEADER: 'en_US',
  SOURCE_LANGUAGE_CODE: 'en',
  HEADER_ROW: 1,
  BATCH_SIZE: 50,
  CACHE_DURATION: 21600,
  ERROR_COLOR: '#f4cccc', // Light red background for failed cells
  DUPLICATE_COLOR: '#ea9999', // A slightly darker red for duplicates
  KEY_COLUMN_INDEX: 0, // Column A (str)
  ENGLISH_COLUMN_INDEX: 1, // Column B
};

// ==========================================
// 📱 UI & MENUS
// ==========================================

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('🌐 Localization Hub')
    .addItem(
      '🚀 Translate All Columns (Fill Missing)',
      'translateAllColumnsMissing',
    )
    .addItem('✅ Translate Selected Cells', 'translateSelectedRange')
    .addSeparator()
    .addItem('🔍 Smart Duplicate Manager', 'openDuplicateManager')
    .addSeparator()
    .addItem('📝 Translate Specific Column...', 'promptTranslateColumn')
    .addItem('🧹 Clear Specific Column...', 'promptClearColumn')
    .addSeparator()
    .addItem('🎨 Clear Error Highlighting', 'clearAllErrorFormatting')
    .addSeparator()
    .addItem('⚙️ Check Configuration', 'showConfiguration')
    .addItem('🗑️ Remove Old Menu Ghosting', 'cleanupOldMenus')
    .addToUi();
}

/**
 * 🛠️ UI CLEANUP TOOL
 * Run this to refresh the menu bar if "Translation Tools" won't disappear.
 */
function cleanupOldMenus() {
  const ui = SpreadsheetApp.getUi();
  ui.alert(
    'Menu Refresh',
    'Google Sheets sometimes "ghosts" old menus. To fix this:\n\n1. Refresh your browser tab (F5).\n2. If it still appears, the old script might still be attached to this sheet. Check Extensions > Apps Script to ensure only ONE script is active.',
    ui.ButtonSet.OK,
  );
}

// ==========================================
// 🚀 MAIN FUNCTIONS
// ==========================================

function translateSelectedRange() {
  const ui = SpreadsheetApp.getUi();
  const sheet = getTargetSheet();
  const range = sheet.getActiveRange();

  if (!range) return showAlert('Error', 'Please select cells to translate.');

  const startRow = range.getRow();
  const numRows = range.getNumRows();
  const colIndex = range.getColumn();

  if (startRow <= CONFIG.HEADER_ROW)
    return showAlert('Error', 'Please select data rows, not headers.');

  const headers = getHeaderRow(sheet);
  const targetHeader = headers[colIndex - 1];

  if (!targetHeader || targetHeader === CONFIG.SOURCE_COLUMN_HEADER)
    return showAlert('Error', 'Invalid target column.');

  const targetLangCode = targetHeader.split('_')[0].toLowerCase();
  const sourceColIndex = headers.indexOf(CONFIG.SOURCE_COLUMN_HEADER);

  const confirm = ui.alert(
    'Translate Selection',
    `Translate ${numRows} rows in "${targetHeader}"?`,
    ui.ButtonSet.YES_NO,
  );

  processTranslation(
    sheet,
    sourceColIndex,
    colIndex - 1,
    targetLangCode,
    targetHeader,
    confirm === ui.Button.YES,
    startRow,
    numRows,
  );
}

function translateAllColumnsMissing() {
  const sheet = getTargetSheet();
  const headers = getHeaderRow(sheet);
  const sourceIdx = headers.indexOf(CONFIG.SOURCE_COLUMN_HEADER);

  const validTargets = [];
  headers.forEach((header, index) => {
    if (
      header &&
      header !== CONFIG.SOURCE_COLUMN_HEADER &&
      header.includes('_')
    ) {
      const code = header.split('_')[0].toLowerCase();
      if (code.length === 2) validTargets.push({ header, code, index });
    }
  });

  if (validTargets.length === 0)
    return showAlert('Info', 'No target columns found.');

  const ui = SpreadsheetApp.getUi();
  const confirm = ui.alert(
    'Translate All',
    `Translate missing cells for: ${validTargets.map((t) => t.header).join(', ')}?`,
    ui.ButtonSet.YES_NO,
  );

  if (confirm === ui.Button.YES) {
    validTargets.forEach((target) =>
      processTranslation(
        sheet,
        sourceIdx,
        target.index,
        target.code,
        target.header,
        false,
      ),
    );
    SpreadsheetApp.getActiveSpreadsheet().toast(
      '🎉 All columns processed!',
      'Done',
    );
  }
}

// ==========================================
// ⚙️ CORE LOGIC (WITH HIGHLIGHTING)
// ==========================================

function processTranslation(
  sheet,
  sourceColIdx,
  targetColIdx,
  targetLangCode,
  targetHeader,
  overwrite,
  startRowOpt = null,
  numRowsOpt = null,
) {
  const lastRow = sheet.getLastRow();
  const startRow = startRowOpt || CONFIG.HEADER_ROW + 1;
  const numRows = numRowsOpt || lastRow - CONFIG.HEADER_ROW;

  if (numRows <= 0) return;

  const sourceRange = sheet.getRange(startRow, sourceColIdx + 1, numRows, 1);
  const targetRange = sheet.getRange(startRow, targetColIdx + 1, numRows, 1);
  const sourceValues = sourceRange.getValues();
  const targetValues = targetRange.getValues();

  // Array to track colors (white by default, red for error)
  const bgColors = targetRange.getBackgrounds();

  const tasks = [];
  for (let i = 0; i < sourceValues.length; i++) {
    const src = sourceValues[i][0];
    const tgt = targetValues[i][0];
    if (src && String(src).trim() !== '') {
      if (overwrite || !tgt || String(tgt).trim() === '' || tgt === '[ERR]') {
        tasks.push({ index: i, text: String(src).trim() });
      }
    }
  }

  if (tasks.length === 0) {
    SpreadsheetApp.getActiveSpreadsheet().toast(
      `No updates needed for ${targetHeader}.`,
      'Skipped',
    );
    return;
  }

  SpreadsheetApp.getActiveSpreadsheet().toast(
    `Translating ${tasks.length} items to ${targetHeader}...`,
    'Working',
    -1,
  );

  const newValues = [...targetValues];
  const cache = CacheService.getScriptCache();

  for (let i = 0; i < tasks.length; i++) {
    const task = tasks[i];
    const cacheKey = `${CONFIG.SOURCE_LANGUAGE_CODE}_${targetLangCode}_${Utilities.base64Encode(task.text).substring(0, 100)}`;

    try {
      let translated = cache.get(cacheKey);
      if (!translated) {
        translated = LanguageApp.translate(
          task.text,
          CONFIG.SOURCE_LANGUAGE_CODE,
          targetLangCode,
        );
        if (translated) cache.put(cacheKey, translated, CONFIG.CACHE_DURATION);
        Utilities.sleep(50);
      }
      newValues[task.index][0] = translated;
      bgColors[task.index][0] = '#ffffff'; // Reset to white on success
    } catch (e) {
      newValues[task.index][0] = `[ERR]`;
      bgColors[task.index][0] = CONFIG.ERROR_COLOR; // 🎨 Highlight red
    }

    if (i % 20 === 0) {
      targetRange.setValues(newValues);
      targetRange.setBackgrounds(bgColors);
    }
  }

  targetRange.setValues(newValues);
  targetRange.setBackgrounds(bgColors);
  SpreadsheetApp.getActiveSpreadsheet().toast(
    `Completed ${targetHeader}`,
    'Success',
  );
}

/**
 * 🎨 Helper to clear all red error formatting when you're done fixing them.
 */
function clearAllErrorFormatting() {
  const sheet = getTargetSheet();
  sheet
    .getRange(1, 1, sheet.getLastRow(), sheet.getLastColumn())
    .setBackground('#ffffff');
  SpreadsheetApp.getActiveSpreadsheet().toast('Formatting cleared.', 'Success');
}

// ==========================================
// 🛠️ UTILITIES & CONFIG PROMPTS (REST OF CODE)
// ==========================================

function promptTranslateColumn() {
  const ui = SpreadsheetApp.getUi();
  const result = ui.prompt(
    'Translate Column',
    'Enter Header (e.g. vi_VN):',
    ui.ButtonSet.OK_CANCEL,
  );
  if (result.getSelectedButton() !== ui.Button.OK) return;
  const targetHeader = result.getResponseText().trim();
  const sheet = getTargetSheet();
  const headers = getHeaderRow(sheet);
  const targetIdx = headers.indexOf(targetHeader);
  const sourceIdx = headers.indexOf(CONFIG.SOURCE_COLUMN_HEADER);
  if (sourceIdx === -1 || targetIdx === -1)
    return showAlert('Error', 'Column not found.');
  const targetLangCode = targetHeader.split('_')[0].toLowerCase();
  const overwriteResponse = ui.alert(
    'Overwrite?',
    `Overwrite everything in ${targetHeader}?`,
    ui.ButtonSet.YES_NO,
  );
  processTranslation(
    sheet,
    sourceIdx,
    targetIdx,
    targetLangCode,
    targetHeader,
    overwriteResponse === ui.Button.YES,
  );
}

function promptClearColumn() {
  const ui = SpreadsheetApp.getUi();
  const result = ui.prompt(
    'Clear Column',
    'Enter Header (e.g. vi_VN):',
    ui.ButtonSet.OK_CANCEL,
  );
  if (result.getSelectedButton() !== ui.Button.OK) return;
  const targetHeader = result.getResponseText().trim();
  const sheet = getTargetSheet();
  const headers = getHeaderRow(sheet);
  const colIdx = headers.indexOf(targetHeader);
  if (colIdx === -1) return showAlert('Error', 'Column not found.');
  const confirm = ui.alert(
    'Confirm',
    `Delete ALL in ${targetHeader}?`,
    ui.ButtonSet.YES_NO,
  );
  if (confirm === ui.Button.YES) {
    sheet
      .getRange(CONFIG.HEADER_ROW + 1, colIdx + 1, sheet.getLastRow(), 1)
      .clearContent();
    SpreadsheetApp.getActiveSpreadsheet().toast(
      `${targetHeader} cleared.`,
      'Success',
    );
  }
}

/**
 * Opens the UI Modal for the user to choose deletion options.
 */
function openDuplicateManager() {
  const html = HtmlService.createHtmlOutputFromFile('DuplicateUI')
    .setWidth(450)
    .setHeight(350)
    .setTitle('Smart Duplicate Manager');
  SpreadsheetApp.getUi().showModalDialog(html, 'Duplicate Cleanup Options');
}

/**
 * The core logic engine called from the UI.
 */
function processDuplicates(options) {
  const sheet = getTargetSheet();
  const lastRow = sheet.getLastRow();
  if (lastRow <= CONFIG.HEADER_ROW)
    return { success: false, msg: 'Sheet is empty.' };

  const range = sheet.getRange(
    CONFIG.HEADER_ROW + 1,
    1,
    lastRow - CONFIG.HEADER_ROW,
    sheet.getLastColumn(),
  );
  const data = range.getValues();
  const backgrounds = range.getBackgrounds();

  let rowsToDelete = [];
  let stats = { identical: 0, keys: 0, highlighted: 0 };

  let seenKeys = {};
  let seenEnglish = {};
  let seenRows = {};

  for (let i = 0; i < data.length; i++) {
    const key = String(data[i][CONFIG.KEY_COLUMN_INDEX]).trim();
    const english = String(data[i][CONFIG.ENGLISH_COLUMN_INDEX]).trim();
    const fullRowStr = data[i].join('|||'); // Unique string for entire row check
    const currentRowIndex = i + CONFIG.HEADER_ROW + 1;

    if (!key) continue;

    let markedForDelete = false;

    // 1. Case: Entirely Identical Row
    if (seenRows[fullRowStr]) {
      if (options.deleteFull) {
        rowsToDelete.push(currentRowIndex);
        stats.identical++;
        markedForDelete = true;
      } else {
        backgrounds[i][CONFIG.KEY_COLUMN_INDEX] = CONFIG.DUPLICATE_COLOR;
        stats.highlighted++;
      }
    } else {
      seenRows[fullRowStr] = true;
    }

    // 2. Case: Duplicate Key (only if row wasn't already deleted as an identical match)
    if (!markedForDelete) {
      if (seenKeys[key]) {
        if (options.deleteKeys) {
          rowsToDelete.push(currentRowIndex);
          stats.keys++;
        } else {
          backgrounds[i][CONFIG.KEY_COLUMN_INDEX] = CONFIG.DUPLICATE_COLOR;
          stats.highlighted++;
        }
      } else {
        seenKeys[key] = true;
      }
    }

    // 3. Case: Duplicate English (Highlight ONLY)
    if (english && seenEnglish[english]) {
      backgrounds[i][CONFIG.ENGLISH_COLUMN_INDEX] = CONFIG.DUPLICATE_COLOR;
      // We don't auto-delete these, but we count them as highlighted if they weren't keys
      if (
        !markedForDelete &&
        backgrounds[i][CONFIG.KEY_COLUMN_INDEX] !== CONFIG.DUPLICATE_COLOR
      ) {
        stats.highlighted++;
      }
    } else {
      seenEnglish[english] = true;
    }
  }

  // Update sheet colors
  range.setBackgrounds(backgrounds);

  // Perform deletion in reverse order
  const uniqueRowsToDelete = [...new Set(rowsToDelete)].sort((a, b) => b - a);
  uniqueRowsToDelete.forEach((row) => sheet.deleteRow(row));

  return {
    success: true,
    stats: stats,
    totalDeleted: uniqueRowsToDelete.length,
  };
}

function getTargetSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getActiveSheet();
}

function getHeaderRow(sheet) {
  return sheet
    .getRange(CONFIG.HEADER_ROW, 1, 1, sheet.getLastColumn())
    .getValues()[0];
}

function showAlert(title, message) {
  SpreadsheetApp.getUi().alert(
    title,
    message,
    SpreadsheetApp.getUi().ButtonSet.OK,
  );
}

function showConfiguration() {
  const sheet = getTargetSheet();
  const headers = getHeaderRow(sheet);
  const detected = headers.filter(
    (h) => h && h.includes('_') && h !== CONFIG.SOURCE_COLUMN_HEADER,
  );
  showAlert(
    'Config',
    `Source: ${CONFIG.SOURCE_COLUMN_HEADER}\nDetected: ${detected.join(', ')}`,
  );
}
