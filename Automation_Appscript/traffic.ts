/**
 * Traffic Data — Sync Live → Historic (multi-pair)
 * -----------------------------------------------------------------
 * For each pair in SYNC_PAIRS1:
 *   1. Sync NEW rows from live → historic (dedupe by composite key)
 *   2. UPDATE historic rows that were partial (live now has larger value)
 *   3. SKIP the in-progress hour (max date + max hour in live = partial)
 *   4. CLEAN UP the live tab — keep only rows with the latest date
 *
 * Composite key = date + hour + business_unit + super_category
 *   (BU and SC only used when those columns exist)
 *
 * Schema aliases handled:
 *   Historic                 ↔  Live
 *   day_time_key             ↔  __time
 *   r_bu_visits_hllpp        ↔  bu_visits
 * -----------------------------------------------------------------
 */

// ---- CONFIG ------------------------------------------------------
const SYNC_PAIRS1 = [
  { live: 'Visits_BU_live', historic: 'Visits_BU_historic' },
  { live: 'Visits_SC_live', historic: 'Visits_SC_historic' }
  // { live: 'Visits_FK_live', historic: 'Visits_FK_historic' }
];

const SKIP_INPROGRESS_HOUR  = true;  // skip max(date, hour) row in live
const UPDATE_ON_LARGER_VALUE = true; // overwrite partial historic rows
const CLEANUP_LIVE_OLD_DATES = true; // delete rows from live with date < max date
// ------------------------------------------------------------------


/** Entry point — syncs every pair, logs a summary line per pair. */
function syncAll() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const summary = [];

  SYNC_PAIRS1.forEach(pair => {
    try {
      const r = syncPair(ss, pair.live, pair.historic);
      summary.push(pair.live + ' → ' + pair.historic +
                   ' | Added: ' + r.added +
                   ', Updated: ' + r.updated +
                   ', Skipped dup: ' + r.skipped +
                   ', Skipped in-progress: ' + r.skippedPartial +
                   ', Live rows cleaned: ' + r.cleaned);
    } catch (e) {
      summary.push(pair.live + ' → ' + pair.historic + ' | ERROR: ' + e.message);
    }
  });

  Logger.log(summary.join('\n'));
}


/** Sync a single (live, historic) pair. */
function syncPair(ss, liveTab, historicTab) {
  const live     = ss.getSheetByName(liveTab);
  const historic = ss.getSheetByName(historicTab);

  if (!live)     throw new Error('Tab not found: ' + liveTab);
  if (!historic) throw new Error('Tab not found: ' + historicTab);

  const liveValues = live.getDataRange().getValues();
  const histValues = historic.getDataRange().getValues();

  if (liveValues.length < 2) {
    return { added: 0, updated: 0, skipped: 0, skippedPartial: 0, cleaned: 0 };
  }
  if (histValues.length < 1) throw new Error(historicTab + ' has no header row.');

  const liveHeaders = liveValues[0];
  const histHeaders = histValues[0];

  const liveIdx = locateKeyColumns(liveHeaders);
  const histIdx = locateKeyColumns(histHeaders);

  if (liveIdx.date === -1 || liveIdx.hour === -1) {
    throw new Error('Missing date/hour column in ' + liveTab);
  }
  if (histIdx.date === -1 || histIdx.hour === -1) {
    throw new Error('Missing date/hour column in ' + historicTab);
  }

  const liveMetric = findMetricColumn(liveHeaders);
  const histMetric = findMetricColumn(histHeaders);

  // ---- Find max (date, hour) in live — the in-progress hour ----
  let maxDate = '';
  let maxHour = -1;
  for (let i = 1; i < liveValues.length; i++) {
    const r = liveValues[i];
    if (r.every(c => c === '' || c === null)) continue;
    const d = normalizeDate(r[liveIdx.date]);
    const h = parseInt(r[liveIdx.hour], 10);
    if (d > maxDate || (d === maxDate && h > maxHour)) {
      maxDate = d;
      maxHour = h;
    }
  }

  // ---- Build map of existing historic keys → { sheetRow, value } ----
  const existing = new Map();
  for (let i = 1; i < histValues.length; i++) {
    if (histValues[i].every(c => c === '' || c === null)) continue;
    const key = buildKey(histValues[i], histIdx);
    const val = histMetric >= 0 ? Number(histValues[i][histMetric]) || 0 : 0;
    existing.set(key, { sheetRow: i + 1, value: val });
  }

  // ---- Walk live rows: append new, update partials, skip dups ----
  const newRows = [];
  const updates = [];
  let skipped = 0;
  let skippedPartial = 0;

  for (let i = 1; i < liveValues.length; i++) {
    const row = liveValues[i];
    if (row.every(c => c === '' || c === null)) continue;

    const d = normalizeDate(row[liveIdx.date]);
    const h = parseInt(row[liveIdx.hour], 10);

    if (SKIP_INPROGRESS_HOUR && d === maxDate && h === maxHour) {
      skippedPartial++;
      continue;
    }

    const key = buildKey(row, liveIdx);
    const liveVal = liveMetric >= 0 ? Number(row[liveMetric]) || 0 : 0;
    const remapped = remapRow(row, liveHeaders, histHeaders);

    if (!existing.has(key)) {
      newRows.push(remapped);
      existing.set(key, { sheetRow: -1, value: liveVal });
    } else {
      const prev = existing.get(key);
      if (UPDATE_ON_LARGER_VALUE && liveVal > prev.value && prev.sheetRow > 0) {
        updates.push({ sheetRow: prev.sheetRow, row: remapped });
        existing.set(key, { sheetRow: prev.sheetRow, value: liveVal });
      } else {
        skipped++;
      }
    }
  }

  // ---- Apply updates ----
  updates.forEach(u => {
    historic.getRange(u.sheetRow, 1, 1, histHeaders.length).setValues([u.row]);
  });

  // ---- Batch-append new rows ----
  if (newRows.length > 0) {
    const startRow = historic.getLastRow() + 1;
    historic.getRange(startRow, 1, newRows.length, histHeaders.length)
            .setValues(newRows);
  }

  // ---- Clean up the live tab: keep only max-date rows ----
  let cleaned = 0;
  if (CLEANUP_LIVE_OLD_DATES && maxDate) {
    cleaned = cleanupLiveTab(live, liveValues, liveIdx, liveHeaders, maxDate);
  }

  return {
    added: newRows.length,
    updated: updates.length,
    skipped: skipped,
    skippedPartial: skippedPartial,
    cleaned: cleaned
  };
}


/**
 * Keep only rows with date === maxDate in the live tab.
 * Clears all data rows and re-writes the filtered set. Returns count
 * of rows removed.
 */
function cleanupLiveTab(live, liveValues, liveIdx, liveHeaders, maxDate) {
  const keep = [];
  let removed = 0;

  for (let i = 1; i < liveValues.length; i++) {
    const row = liveValues[i];
    if (row.every(c => c === '' || c === null)) continue;
    if (normalizeDate(row[liveIdx.date]) === maxDate) {
      keep.push(row);
    } else {
      removed++;
    }
  }

  if (removed === 0) return 0;

  // Clear every existing data row (rows 2..lastRow) before rewriting
  const lastRow = live.getLastRow();
  if (lastRow > 1) {
    live.getRange(2, 1, lastRow - 1, liveHeaders.length).clearContent();
  }
  if (keep.length > 0) {
    live.getRange(2, 1, keep.length, liveHeaders.length).setValues(keep);
  }
  return removed;
}


/* ------------------------ helpers ------------------------ */

function locateKeyColumns(headers) {
  const norm = headers.map(h => String(h).toLowerCase().trim());
  return {
    date: norm.findIndex(h =>
      h === 'day_time_key' || h === '__time' || h === 'date' || h === 'time'),
    hour: norm.findIndex(h => h === 'hour'),
    bu:   norm.findIndex(h => h === 'business_unit'),
    sc:   norm.findIndex(h => h === 'super_category')
  };
}

function findMetricColumn(headers) {
  const norm = headers.map(h => String(h).toLowerCase().trim());
  return norm.findIndex(h => h === 'bu_visits' || h === 'r_bu_visits_hllpp');
}

function buildKey(row, idx) {
  const d  = normalizeDate(row[idx.date]);
  const h  = String(row[idx.hour]).trim();
  const bu = idx.bu >= 0 ? String(row[idx.bu]).trim().toLowerCase() : '';
  const sc = idx.sc >= 0 ? String(row[idx.sc]).trim().toLowerCase() : '';
  return d + '|' + h + '|' + bu + '|' + sc;
}

function normalizeDate(val) {
  if (val instanceof Date) {
    return Utilities.formatDate(val, Session.getScriptTimeZone(), 'yyyy-MM-dd');
  }
  if (typeof val === 'string') {
    const m = val.match(/^(\d{4}-\d{2}-\d{2})/);
    if (m) return m[1];
    const d = new Date(val);
    if (!isNaN(d.getTime())) {
      return Utilities.formatDate(d, Session.getScriptTimeZone(), 'yyyy-MM-dd');
    }
    return val.trim();
  }
  return String(val);
}

function remapRow(srcRow, srcHeaders, dstHeaders) {
  const aliases = {
    'day_time_key':       '__time',
    '__time':             'day_time_key',
    'r_bu_visits_hllpp':  'bu_visits',
    'bu_visits':          'r_bu_visits_hllpp'
  };
  const srcMap = {};
  srcHeaders.forEach((h, i) => {
    srcMap[String(h).toLowerCase().trim()] = srcRow[i];
  });
  return dstHeaders.map(h => {
    const key = String(h).toLowerCase().trim();
    if (key in srcMap) return srcMap[key];
    if (aliases[key] && aliases[key] in srcMap) return srcMap[aliases[key]];
    return '';
  });
}


/* --------------------- automation --------------------- */

function createTrigger() {
  ScriptApp.getProjectTriggers().forEach(t => {
    if (t.getHandlerFunction() === 'syncAll') ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger('syncAll')
    .timeBased()
    .everyMinutes(5)
    .create();
  Logger.log('Trigger created: syncAll every 5 minutes.');
}

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('Traffic Sync')
    .addItem('Sync all now', 'syncAll')
    .addItem('Schedule every 5 minutes', 'createTrigger')
    .addToUi();
}