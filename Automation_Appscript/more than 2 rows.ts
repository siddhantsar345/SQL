function archiveFixedMarketingData1() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sourceSheet = ss.getSheetByName("data - Scat");
  const destSheet = ss.getSheetByName("SCat_Visits_all_platform");


  // Scat visits
  const r1 = sourceSheet.getRange(107, 1, 1, 152).getValues();
  const r2 = sourceSheet.getRange(108, 1, 1, 152).getValues();
  const r3 = sourceSheet.getRange(109, 1, 1, 152).getValues();
  const r4 = sourceSheet.getRange(110, 1, 1, 152).getValues();
  const r5 = sourceSheet.getRange(111, 1, 1, 152).getValues();
  const r6 = sourceSheet.getRange(112, 1, 1, 152).getValues();
  const r7 = sourceSheet.getRange(113, 1, 1, 152).getValues();
  const r8 = sourceSheet.getRange(114, 1, 1, 152).getValues();
  const r9 = sourceSheet.getRange(115, 1, 1, 152).getValues();
  const r10 = sourceSheet.getRange(116, 1, 1, 152).getValues();
  const r11 = sourceSheet.getRange(117, 1, 1, 152).getValues();
  const r12 = sourceSheet.getRange(118, 1, 1, 152).getValues();
  const r13 = sourceSheet.getRange(119, 1, 1, 152).getValues();
  const r14 = sourceSheet.getRange(120, 1, 1, 152).getValues();
  const r15 = sourceSheet.getRange(121, 1, 1, 152).getValues();
  const r16 = sourceSheet.getRange(122, 1, 1, 152).getValues();
  const r17 = sourceSheet.getRange(123, 1, 1, 152).getValues();
  const r18 = sourceSheet.getRange(124, 1, 1, 152).getValues();
  const r19 = sourceSheet.getRange(125, 1, 1, 152).getValues();

  // Scat visits direct

  const r20 = sourceSheet.getRange(134, 1, 1, 152).getValues();
  const r21 = sourceSheet.getRange(135, 1, 1, 152).getValues();
  const r22 = sourceSheet.getRange(136, 1, 1, 152).getValues();
  const r23 = sourceSheet.getRange(137, 1, 1, 152).getValues();
  const r24 = sourceSheet.getRange(138, 1, 1, 152).getValues();
  const r25 = sourceSheet.getRange(139, 1, 1, 152).getValues();
  const r26 = sourceSheet.getRange(140, 1, 1, 152).getValues();
  const r27 = sourceSheet.getRange(141, 1, 1, 152).getValues();
  const r28 = sourceSheet.getRange(142, 1, 1, 152).getValues();
  const r29 = sourceSheet.getRange(143, 1, 1, 152).getValues();
  const r30 = sourceSheet.getRange(144, 1, 1, 152).getValues();
  const r31 = sourceSheet.getRange(145, 1, 1, 152).getValues();
  const r32 = sourceSheet.getRange(146, 1, 1, 152).getValues();
  const r33 = sourceSheet.getRange(147, 1, 1, 152).getValues();
  const r34 = sourceSheet.getRange(148, 1, 1, 152).getValues();
  const r35 = sourceSheet.getRange(149, 1, 1, 152).getValues();
  const r36 = sourceSheet.getRange(150, 1, 1, 152).getValues();
  const r37 = sourceSheet.getRange(151, 1, 1, 152).getValues();
  const r38 = sourceSheet.getRange(152, 1, 1, 152).getValues();

  // 2. Combine them into one array to paste at once
  const combinedData = [
    r1[0], r2[0], r3[0], r4[0], r5[0], r6[0], r7[0],
    r8[0], r9[0], r10[0], r11[0], r12[0], r13[0], r14[0], r15[0], r16[0], r17[0], r18[0], r19[0],
    r20[0], r21[0], r22[0], r23[0], r24[0], r25[0], r26[0], r27[0], r28[0], r29[0], r30[0], 
    r31[0], r32[0], r33[0], r34[0], r35[0], r36[0], r37[0], r38[0]
  ];

  // 3. Safety check to ensure the first row isn't empty before archiving
  if (combinedData[0][0] !== "") {
    
    // 4. Find the last empty row and paste the 2 rows
    destSheet.getRange(destSheet.getLastRow() + 1, 1, 38, 152).setValues(combinedData);
    
    Logger.log("Successfully Done");
  } else {
    Logger.log(" No data archived.");
  }
}