function Dailylevel() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sourceSheet = ss.getSheetByName("Data- Daily_Months");
  const destSheet = ss.getSheetByName("Funnel_RAW_BU_Day");

  // 1. Grab Rows 2 through 542 (Total 540 rows) and Columns 1-11 (A-K)
  const combinedData = sourceSheet.getRange(2, 1, 541, 11).getValues();

  // 2. Safety check: Ensure the first cell (A3) isn't empty
  if (combinedData[0][0] !== "") {
    
    const timezone = ss.getSpreadsheetTimeZone();
    
    // 3. Process the data row by row
    for (let i = 0; i < combinedData.length; i++) {
      
      // LOGIC A: Format the date in Column K (Index 10)
      let dateValue = combinedData[i][10]; 
      if (dateValue instanceof Date) {
        combinedData[i][10] = Utilities.formatDate(dateValue, timezone, "yyyyMMdd");
      }

      // LOGIC B: Check Column C (Index 2). If blank, create "NA" for the new column.
      let geoZone = combinedData[i][2];
      if (geoZone === "" || geoZone === null) {
        combinedData[i].push("NA"); 
      } else {
        combinedData[i].push(geoZone); 
      }
    }

    // --- UPDATED LOGIC: Wipe destination and paste at Row 1 ---
    destSheet.clear(); // This removes all data and formatting from the entire sheet

    destSheet.getRange(
      1,                // Starting Row
      1,                // Starting Column
      combinedData.length, 
      combinedData[0].length 
    ).setValues(combinedData);
    
    Logger.log("Successfully Replaced: Data updated starting from Row 1.");
  } else {
    Logger.log("No data archived: Cell A3 was empty.");
  }
}