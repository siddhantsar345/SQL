/**
 * Traffic Data — Sync Live → Historic (FK ONLY, with aggregation)
 * -----------------------------------------------------------------
 * Standalone version for the FK pair, independent of the main script.
 * Every function and global has an FK suffix so it can coexist with
 * the main script in the same Apps Script project.
 *
 * Pair:  Visits_FK_live  →  Visits_FK_historic
 *
 * KEY BEHAVIOR — aggregation:
 *   The live tab splits each (date, hour) into multiple rows by
 *   marketplace_id + platform (e.g. FLIPKART/IOSApp, FLIPKART/AndroidApp).
 *   The historic tab has no platform column. Before syncing, all live
 *   rows that share the same composite key (date + hour + bu + sc) are
 *   AGGREGATED — numeric columns are summed. So iOS + Android visits
 *   become one combined row in historic.
 *
 * Other behavior (same as main script):
 *   - Composite key dedupe
 *   - Skip in-progress hour (max date + max hour in live)
 *   - Update partial historic rows when aggregated live value is larger
 *   - Clean up live tab so only the latest date remains
 *
 * Schema mapping (live → historic):
 *   __time             → day_time_key
 *   visits             → r_bu_visits_hllpp
 *   marketplace_id     → IGNORED
 *   platform           → IGNORED (used for splitting; aggregated away)
 * -----------------------------------------------------------------
 */

// ---- CONFIG ------------------------------------------------------
const SYNC_PAIRS_FK = [
  { live: 'Visits_FK_live', historic: 'Visits_FK_historic' }
];

const IGNORE_COLUMNS_FK = ['marketplace_id', 'platform'];

const SKIP_INPROGRESS_HOUR_FK    = false; // FK report publishes complete hours
const UPDATE_ON_LARGER_VALUE_FK  = true;
const CLEANUP_LIVE_OLD_DATES_FK  = true;
const AGGREGATE_DUPLICATE_KEYS_FK = true; // sum platform-split rows
// ------------------------------------------------------------------


/** Entry point — syncs the FK pair. */
function syncAllFK() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const summary = [];

  SYNC_PAIRS_FK.forEach(pair => {
    try {
      const r = syncPairFK(ss, pair.live, pair.historic);
      summary.push(pair.live + ' → ' + pair.historic +
                   ' | Aggregated groups: ' + r.aggregated +
                   ', Added: ' + r.added +
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


function syncPairFK(ss, liveTab, historicTab) {
  const live     = ss.getSheetByName(liveTab);
  const historic = ss.getSheetByName(historicTab);

  if (!live)     throw new Error('Tab not found: ' + liveTab);
  if (!historic) throw new Error('Tab not found: ' + historicTab);

  const liveValues = live.getDataRange().getValues();
  const histValues = historic.getDataRange().getValues();

  if (liveValues.length < 2) {
    return { aggregated: 0, added: 0, updated: 0, skipped: 0, skippedPartial: 0, cleaned: 0 };
  }
  if (histValues.length < 1) throw new Error(historicTab + ' has no header row.');

  const liveHeaders = liveValues[0];
  const histHeaders = histValues[0];

  const liveIdx = locateKeyColumnsFK(liveHeaders);
  const histIdx = locateKeyColumnsFK(histHeaders);

  if (liveIdx.date === -1 || liveIdx.hour === -1) {
    throw new Error('Missing date/hour column in ' + liveTab);
  }
  if (histIdx.date === -1 || histIdx.hour === -1) {
    throw new Error('Missing date/hour column in ' + historicTab);
  }

  const liveMetric = findMetricColumnFK(liveHeaders);
  const histMetric = findMetricColumnFK(histHeaders);

  // ---- Find max (date, hour) in live — the in-progress hour ----
  let maxDate = '';
  let maxHour = -1;
  for (let i = 1; i < liveValues.length; i++) {
    const r = liveValues[i];
    if (r.every(c => c === '' || c === null)) continue;
    const d = normalizeDateFK(r[liveIdx.date]);
    const h = parseInt(r[liveIdx.hour], 10);
    if (d > maxDate || (d === maxDate && h > maxHour)) {
      maxDate = d;
      maxHour = h;
    }
  }

  // ---- Aggregate live rows by composite key ----
  const aggregated = AGGREGATE_DUPLICATE_KEYS_FK
    ? aggregateLiveRowsFK(liveValues, liveHeaders, liveIdx, liveMetric, maxDate, maxHour)
    : passThroughLiveRowsFK(liveValues, liveHeaders, liveIdx, liveMetric, maxDate, maxHour);

  // ---- Build map of existing historic keys → { sheetRow, value } ----
  const existing = new Map();
  for (let i = 1; i < histValues.length; i++) {
    if (histValues[i].every(c => c === '' || c === null)) continue;
    const key = buildKeyFK(histValues[i], histIdx);
    const val = histMetric >= 0 ? Number(histValues[i][histMetric]) || 0 : 0;
    existing.set(key, { sheetRow: i + 1, value: val });
  }

  // ---- Walk aggregated entries ----
  const newRows = [];
  const updates = [];
  let skipped = 0;
  let skippedPartial = 0;

  aggregated.forEach(entry => {
    if (SKIP_INPROGRESS_HOUR_FK && entry.isInProgress) {
      skippedPartial++;
      return;
    }
    const remapped = remapRowFK(entry.row, liveHeaders, histHeaders);

    if (!existing.has(entry.key)) {
      newRows.push(remapped);
      existing.set(entry.key, { sheetRow: -1, value: entry.liveVal });
    } else {
      const prev = existing.get(entry.key);
      if (UPDATE_ON_LARGER_VALUE_FK && entry.liveVal > prev.value && prev.sheetRow > 0) {
        updates.push({ sheetRow: prev.sheetRow, row: remapped });
        existing.set(entry.key, { sheetRow: prev.sheetRow, value: entry.liveVal });
      } else {
        skipped++;
      }
    }
  });

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

  // ---- Clean up live tab: keep only max-date rows ----
  let cleaned = 0;
  if (CLEANUP_LIVE_OLD_DATES_FK && maxDate) {
    cleaned = cleanupLiveTabFK(live, liveValues, liveIdx, liveHeaders, maxDate);
  }

  return {
    aggregated: aggregated.length,
    added: newRows.length,
    updated: updates.length,
    skipped: skipped,
    skippedPartial: skippedPartial,
    cleaned: cleaned
  };
}


/**
 * Group live rows by composite key and SUM all numeric columns.
 * Returns: [{ key, row, liveVal, isInProgress }, ...]
 *
 * - Key columns (date, hour, bu, sc) are taken from the first row.
 * - Numeric columns (visits, Direct_visits, …) are summed.
 * - Ignored columns and Updated_at keep the first row's value.
 */
function aggregateLiveRowsFK(liveValues, liveHeaders, liveIdx, liveMetric, maxDate, maxHour) {
  const ignore = new Set(IGNORE_COLUMNS_FK.map(c => c.toLowerCase().trim()));

  // Which columns should be summed? Everything except keys, ignored, and Updated_at.
  const summable = liveHeaders.map(h => {
    const k = String(h).toLowerCase().trim();
    if (k === '__time' || k === 'day_time_key' || k === 'date' || k === 'time') return false;
    if (k === 'hour' || k === 'business_unit' || k === 'super_category') return false;
    if (k === 'updated_at') return false;
    if (ignore.has(k)) return false;
    return true;
  });

  const groups = new Map();  // key → { row, isInProgress }

  for (let i = 1; i < liveValues.length; i++) {
    const row = liveValues[i];
    if (row.every(c => c === '' || c === null)) continue;

    const key = buildKeyFK(row, liveIdx);
    const d = normalizeDateFK(row[liveIdx.date]);
    const h = parseInt(row[liveIdx.hour], 10);
    const isInProgress = (d === maxDate && h === maxHour);

    if (!groups.has(key)) {
      // First row in this group — clone so we can mutate while summing
      groups.set(key, { row: row.slice(), isInProgress: isInProgress });
    } else {
      // Subsequent row — sum numeric columns into the existing aggregate
      const agg = groups.get(key);
      summable.forEach((doSum, colIdx) => {
        if (!doSum) return;
        agg.row[colIdx] = (Number(agg.row[colIdx]) || 0) + (Number(row[colIdx]) || 0);
      });
    }
  }

  // Build result with key + metric value + in-progress flag
  const result = [];
  groups.forEach((group, key) => {
    const liveVal = liveMetric >= 0 ? Number(group.row[liveMetric]) || 0 : 0;
    result.push({ key: key, row: group.row, liveVal: liveVal, isInProgress: group.isInProgress });
  });
  return result;
}

/** Fallback when aggregation is off: emit each live row as its own entry. */
function passThroughLiveRowsFK(liveValues, liveHeaders, liveIdx, liveMetric, maxDate, maxHour) {
  const result = [];
  for (let i = 1; i < liveValues.length; i++) {
    const row = liveValues[i];
    if (row.every(c => c === '' || c === null)) continue;
    const key = buildKeyFK(row, liveIdx);
    const d = normalizeDateFK(row[liveIdx.date]);
    const h = parseInt(row[liveIdx.hour], 10);
    const liveVal = liveMetric >= 0 ? Number(row[liveMetric]) || 0 : 0;
    result.push({
      key: key,
      row: row,
      liveVal: liveVal,
      isInProgress: (d === maxDate && h === maxHour)
    });
  }
  return result;
}


function cleanupLiveTabFK(live, liveValues, liveIdx, liveHeaders, maxDate) {
  const keep = [];
  let removed = 0;

  for (let i = 1; i < liveValues.length; i++) {
    const row = liveValues[i];
    if (row.every(c => c === '' || c === null)) continue;
    if (normalizeDateFK(row[liveIdx.date]) === maxDate) {
      keep.push(row);
    } else {
      removed++;
    }
  }

  if (removed === 0) return 0;

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

function locateKeyColumnsFK(headers) {
  const norm = headers.map(h => String(h).toLowerCase().trim());
  return {
    date: norm.findIndex(h =>
      h === 'day_time_key' || h === '__time' || h === 'date' || h === 'time'),
    hour: norm.findIndex(h => h === 'hour'),
    bu:   norm.findIndex(h => h === 'business_unit'),
    sc:   norm.findIndex(h => h === 'super_category')
  };
}

function findMetricColumnFK(headers) {
  const norm = headers.map(h => String(h).toLowerCase().trim());
  return norm.findIndex(h =>
    h === 'visits' || h === 'bu_visits' || h === 'r_bu_visits_hllpp');
}

function buildKeyFK(row, idx) {
  const d  = normalizeDateFK(row[idx.date]);
  const h  = String(row[idx.hour]).trim();
  const bu = idx.bu >= 0 ? String(row[idx.bu]).trim().toLowerCase() : '';
  const sc = idx.sc >= 0 ? String(row[idx.sc]).trim().toLowerCase() : '';
  return d + '|' + h + '|' + bu + '|' + sc;
}

function normalizeDateFK(val) {
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

function remapRowFK(srcRow, srcHeaders, dstHeaders) {
  const aliases = {
    'day_time_key':       ['__time'],
    '__time':             ['day_time_key'],
    'r_bu_visits_hllpp':  ['visits', 'bu_visits'],
    'bu_visits':          ['visits', 'r_bu_visits_hllpp'],
    'visits':             ['r_bu_visits_hllpp', 'bu_visits']
  };
  const ignore = new Set(IGNORE_COLUMNS_FK.map(c => c.toLowerCase().trim()));

  const srcMap = {};
  srcHeaders.forEach((h, i) => {
    const key = String(h).toLowerCase().trim();
    if (ignore.has(key)) return;
    srcMap[key] = srcRow[i];
  });

  return dstHeaders.map(h => {
    const key = String(h).toLowerCase().trim();
    if (ignore.has(key)) return '';
    if (key in srcMap) return srcMap[key];
    const altList = aliases[key] || [];
    for (let j = 0; j < altList.length; j++) {
      if (altList[j] in srcMap) return srcMap[altList[j]];
    }
    return '';
  });
}


/* --------------------- automation --------------------- */

function createTriggerFK() {
  ScriptApp.getProjectTriggers().forEach(t => {
    if (t.getHandlerFunction() === 'syncAllFK') ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger('syncAllFK')
    .timeBased()
    .everyMinutes(5)
    .create();
  Logger.log('Trigger created: syncAllFK every 5 minutes.');
}