/**
 * Sales / Price Drop — Automation → Live Sync
 * -----------------------------------------------------------------
 * Source tabs:
 *   "Sales Automation"       -> order_date_key, hour_of_day, business_unit,
 *                                super_category, diamond_mp_flag, marketplace_id,
 *                                units, gmv
 *   "Price drop Automation"  -> order_date_key, hour_of_day, analytic_business_unit,
 *                                analytic_super_category, is_alpha_seller,
 *                                marketplace_id, input_bau_weighted_asp,
 *                                input_fes_weighted_asp, output_bau_weighted_asp,
 *                                output_fes_weighted_asp
 *
 * Destination tabs:
 *   "Sales Live"       (identical header to Sales Automation)
 *   "Price Drop Live"  (identical header to Price drop Automation)
 *
 * Both source/destination pairs share the exact same column names
 * (no aliasing needed, unlike the Traffic sync). Logic:
 *   1. Read source tab.
 *   2. Build a composite key per row from its KEY_COLUMNS.
 *   3. Build the same keys for every existing row in the destination.
 *   4. Append any source row whose key isn't already in the destination.
 *   5. Never update or delete existing rows in either tab.
 * -----------------------------------------------------------------
 */

// ---- CONFIG --------------------------------------------------------
const SALES_PRICEDROP_PAIRS = [
  {
    name: 'Sales',
    sourceTab: 'Sales Automation',
    destTab: 'Sales Live',
    keyColumns: ['order_date_key', 'hour_of_day', 'business_unit',
                 'super_category', 'diamond_mp_flag', 'marketplace_id']
  },
  {
    name: 'Price Drop',
    sourceTab: 'Price drop Automation',
    destTab: 'Price Drop Live',
    keyColumns: ['order_date_key', 'hour_of_day', 'analytic_business_unit',
                 'analytic_super_category', 'is_alpha_seller', 'marketplace_id']
  }
];
// ---------------------------------------------------------------------


/** Entry point — syncs both pairs, logs a summary line per pair. */
function syncSalesPriceDrop() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const summary = [];

  SALES_PRICEDROP_PAIRS.forEach(pair => {
    try {
      const source = ss.getSheetByName(pair.sourceTab);
      const dest   = ss.getSheetByName(pair.destTab);
      if (!source) throw new Error('Tab not found: ' + pair.sourceTab);
      if (!dest)   throw new Error('Tab not found: ' + pair.destTab);

      const result = syncSimplePair(source, dest, pair.keyColumns);
      summary.push(
        pair.name + ' (' + pair.sourceTab + ' → ' + pair.destTab + ')' +
        ' | Added: ' + result.added +
        ', Already present: ' + result.skipped +
        ', Blank rows skipped: ' + result.blank
      );
    } catch (e) {
      summary.push(pair.name + ' | ERROR: ' + e.message);
    }
  });

  Logger.log(summary.join('\n'));
}


/**
 * Syncs a source sheet into a destination sheet that shares the exact
 * same header row. Appends rows whose composite key (built from
 * keyColumnNames) isn't already present in the destination.
 */
function syncSimplePair(source, dest, keyColumnNames) {
  const lastRow = source.getLastRow();
  const lastCol = source.getLastColumn();

  if (lastRow < 2) {
    return { added: 0, skipped: 0, blank: 0 };
  }

  const srcValues = source.getRange(1, 1, lastRow, lastCol).getValues();
  const srcHeaders = srcValues[0];

  const destValues = dest.getDataRange().getValues();
  if (destValues.length < 1) throw new Error(dest.getName() + ' has no header row.');
  const destHeaders = destValues[0];

  const keyIdxSrc  = resolveKeyIndexes(srcHeaders, keyColumnNames, source.getName());
  const keyIdxDest = resolveKeyIndexes(destHeaders, keyColumnNames, dest.getName());

  // ---- Build set of existing keys already in the destination ----
  const existingKeys = new Set();
  for (let i = 1; i < destValues.length; i++) {
    const row = destValues[i];
    if (row.every(c => c === '' || c === null)) continue;
    existingKeys.add(buildSimpleKey(row, keyIdxDest));
  }

  // ---- Walk source rows: append any whose key isn't already there ----
  const newRows = [];
  let skipped = 0;
  let blank = 0;

  for (let i = 1; i < srcValues.length; i++) {
    const row = srcValues[i];
    if (row.every(c => c === '' || c === null)) { blank++; continue; }

    const key = buildSimpleKey(row, keyIdxSrc);

    if (existingKeys.has(key)) {
      skipped++;
      continue;
    }

    newRows.push(remapBySameHeaders(row, srcHeaders, destHeaders));
    existingKeys.add(key); // guard against dupes within the same source pull
  }

  // ---- Batch-append new rows ----
  if (newRows.length > 0) {
    const startRow = dest.getLastRow() + 1;
    dest.getRange(startRow, 1, newRows.length, destHeaders.length)
        .setValues(newRows);
  }

  return { added: newRows.length, skipped: skipped, blank: blank };
}


/* ------------------------ helpers ------------------------ */

/** Resolves each key column name to its index in a given header row. */
function resolveKeyIndexes(headers, keyColumnNames, tabNameForError) {
  const norm = headers.map(h => String(h).toLowerCase().trim());
  return keyColumnNames.map(name => {
    const idx = norm.indexOf(name.toLowerCase().trim());
    if (idx === -1) {
      throw new Error('Column "' + name + '" not found in ' + tabNameForError);
    }
    return idx;
  });
}

/** Builds a composite key string from a row given the key column indexes. */
function buildSimpleKey(row, keyIdx) {
  return keyIdx
    .map(idx => String(row[idx]).trim().toLowerCase())
    .join('|');
}

/**
 * Remaps a source row onto the destination header order by column name.
 * Since Sales/Price Drop source and destination share identical headers,
 * this is a straight name-to-name lookup (no aliasing needed).
 */
function remapBySameHeaders(srcRow, srcHeaders, dstHeaders) {
  const srcMap = {};
  srcHeaders.forEach((h, i) => {
    srcMap[String(h).toLowerCase().trim()] = srcRow[i];
  });
  return dstHeaders.map(h => {
    const key = String(h).toLowerCase().trim();
    return key in srcMap ? srcMap[key] : '';
  });
}


/* --------------------- automation trigger --------------------- */

function createSalesPriceDropTrigger() {
  ScriptApp.getProjectTriggers().forEach(t => {
    if (t.getHandlerFunction() === 'syncSalesPriceDrop') ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger('syncSalesPriceDrop')
    .timeBased()
    .everyMinutes(15)
    .create();
  Logger.log('Trigger created: syncSalesPriceDrop every 15 minutes.');
}

function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('Sales/Pricedrop Sync')
    .addItem('Sync all now', 'syncSalesPriceDrop')
    .addItem('Schedule every 15 minutes', 'createSalesPriceDropTrigger')
    .addToUi();
}