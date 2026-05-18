function updateSheetFromEmail() {
  const SHEET_NAME = 'links';
  const SENDER     = 'bigfoot-reporting@flipkart.com';

  // Exact subject line → identifier_key in column A
  const SUBJECT_TO_IDENTIFIER = {
    'keyword_level_search_count_final': 'keyword_level_search_count',
    'SC_C_V level search count 2':      'sc_level_search_count'
  };

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);
  const data  = sheet.getDataRange().getValues();

  for (const [subject, identifierKey] of Object.entries(SUBJECT_TO_IDENTIFIER)) {
    const query = `from:${SENDER} subject:"${subject}" is:unread newer_than:1d`;
    const threads = GmailApp.search(query);
    if (threads.length === 0) continue;

    // Most recent thread → most recent message
    const msg  = threads[0].getMessages().pop();
    const body = msg.getPlainBody();

    // Grab the storage.googleapis.com signed URL specifically
    const match = body.match(/https:\/\/storage\.googleapis\.com\/[^\s)>"']+/);
    if (!match) continue;

    const url = match[0];
    const nowDate = new Date();
    const now = nowDate.toISOString();

    // data_date = yesterday (D-1) in YYYY-MM-DD
    const dataDate = new Date(nowDate);
    dataDate.setDate(dataDate.getDate() - 1);
    const dataDateStr = dataDate.toISOString().slice(0, 10);

    // Find matching identifier_key row and update
    for (let i = 1; i < data.length; i++) {
      if (data[i][0] === identifierKey) {
        sheet.getRange(i + 1, 2).setValue(url);          // column B - URL
        sheet.getRange(i + 1, 3).setValue(now);          // column C - updated_at
        sheet.getRange(i + 1, 4).setValue(dataDateStr);  // column D - data_date
        break;
      }
    }

    msg.markRead();
  }
}