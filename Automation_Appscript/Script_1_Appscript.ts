function archiveFixedMarketingData() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sourceSheet = ss.getSheetByName("data - Scat");
  const destSheet = ss.getSheetByName("Scat_Visits_RAW");

  // 1. Define the specific rows to capture (Row 2 and Row 5)
  // We get Row 2 (18 columns wide) and Row 5 (18 columns wide)
  const rowOverall = sourceSheet.getRange(32, 1, 1, 51).getValues();
  const rowDirect = sourceSheet.getRange(45, 1, 1, 51).getValues();

  // 2. Combine them into one array to paste at once
  const combinedData = [rowOverall[0], rowDirect[0]];

  // 3. Safety check to ensure Row 2 isn't empty before archiving
  if (combinedData[0][0] !== "") {
    
    // 4. Find the last empty row in Scat_Visits_RAW and paste the 2 rows
    destSheet.getRange(destSheet.getLastRow() + 1, 1, 2, 51).setValues(combinedData);
    
    Logger.log("Successfully Done");
  } else {
    Logger.log("Row 2 was empty. No data archived.");
  }
}