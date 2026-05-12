function SCDailylevel() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sourceSheet = ss.getSheetByName("Data- Daily_Months");
  const destSheet = ss.getSheetByName("Funnel_RAW_SC_Day");

  // 1. Pulling 12 columns (A to L)
  // Starting Row 557, Column 1, Rows 7268, Cols 12
  const combinedData = sourceSheet.getRange(557, 1, 6712, 12).getValues();

  // 2. Check if the first cell of the range (A557) is not empty
  if (combinedData[0][0] !== "") {
    const timezone = ss.getSpreadsheetTimeZone();
    
    for (let i = 0; i < combinedData.length; i++) {
      
      // LOGIC: Column L (Index 11) - Date Formatting
      let dateValue = combinedData[i][11]; 
      if (dateValue instanceof Date) {
        combinedData[i][11] = Utilities.formatDate(dateValue, timezone, "yyyyMMdd");
      }

      // LOGIC: Column M (Index 12) - The "NA" thing
      // CHANGED: We now look at Column D (Index 3)
      let geoZone = combinedData[i][3]; 
      if (geoZone === "" || geoZone === null) {
        combinedData[i].push("NA"); 
      } else {
        combinedData[i].push(geoZone);
      }
    }

    // 3. Clear existing data and paste starting at Row 1
    destSheet.clear(); 

    destSheet.getRange(
      1,                // Start at Row 1
      1,                // Start at Column 1 (A)
      combinedData.length, 
      combinedData[0].length 
    ).setValues(combinedData);

    Logger.log("Successfully Replaced: Data updated using Column D for GeoZone.");
  } else {
    Logger.log("No data archived: Starting cell was empty.");
  }
}