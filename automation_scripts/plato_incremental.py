"""
plato_incremental.py
====================
This file does TWO things depending on how you use it:

  1. DAILY (imported by platoscriptincrement.py):
        from plato_incremental import (
            download_master_from_drive,
            merge_incremental_streaming,
            PLATO_DATE_COL,
        )
     Called every day automatically to grow the cumulative master.

  2. SEED — RUN ONCE (run directly on the VM):
        cd ~/arcade/plato
        python plato_incremental.py
     Seeds BOTH reports in one run.
     Edit the SEED CONFIG section below before running.
"""

import os
import pandas as pd
from googleapiclient.http import MediaIoBaseDownload


# ---------------------------------------------------------------------------
# Per-report date column
# Key  = Indentifier_key in the Plato control sheet
# Value = per-row date column name inside that report's CSV
# ---------------------------------------------------------------------------
PLATO_DATE_COL = {
    "PPVS_Non_Branded":"event_time",
    "Vertical_Traffic_Euclid_Arcade": "order_date_key",
}


# ---------------------------------------------------------------------------
# FUNCTION 1 — Pull the current master down from Drive
# ---------------------------------------------------------------------------
def download_master_from_drive(ds, file_id, local_path):
    """
    Downloads the cumulative master from Drive to local_path.
    Returns True on success, False if the file doesn't exist yet (first run).
    """
    file_id = str(file_id).strip()
    if not file_id:
        return False
    tmp = local_path + ".partial"
    try:
        request = ds.files().get_media(fileId=file_id)
        with open(tmp, "wb") as fh:
            downloader = MediaIoBaseDownload(fh, request)
            done = False
            while not done:
                _, done = downloader.next_chunk()
        if os.path.getsize(tmp) == 0:
            os.remove(tmp)
            return False
        os.replace(tmp, local_path)
        return True
    except Exception as e:
        print(f"  No existing master for FileId={file_id}: {e}")
        if os.path.exists(tmp):
            os.remove(tmp)
        return False


# ---------------------------------------------------------------------------
# FUNCTION 2 — Merge fresh 2-month export into the master (memory-safe)
# ---------------------------------------------------------------------------
def merge_incremental_streaming(master_path, incoming_path, output_path,
                                date_col, chunksize=500_000):
    """
    Streams the master in chunks (safe for GB-scale files), drops the dates
    that the new export covers, then appends the fresh export at the end.

    master_path  : current cumulative master (may be large; may not exist yet)
    incoming_path: freshly downloaded 2-month export (smaller piece)
    output_path  : where to write the merged result (can equal master_path)
    date_col     : per-row date column, e.g. "event_time"
    Returns (incoming_rows, date_col).
    """
    incoming = pd.read_csv(incoming_path, low_memory=False)
    if incoming.empty:
        raise RuntimeError(f"Incoming export has 0 rows: {incoming_path}")
    if date_col not in incoming.columns:
        raise RuntimeError(
            f"date_col '{date_col}' not found. "
            f"Columns in file: {list(incoming.columns)[:12]}"
        )

    incoming_dates = set(incoming[date_col].astype(str).str.strip().unique())

    tmp = output_path + ".partial"
    if os.path.exists(tmp):
        os.remove(tmp)

    header_written = False

    # Stream the master, keeping only rows OUTSIDE the incoming window
    if os.path.exists(master_path) and os.path.getsize(master_path) > 0:
        for chunk in pd.read_csv(master_path, low_memory=False, chunksize=chunksize):
            keep = chunk[~chunk[date_col].astype(str).str.strip().isin(incoming_dates)]
            if not keep.empty:
                keep.to_csv(tmp, mode="a", index=False, header=not header_written)
                header_written = True

    # Append the fresh 2-month window at the end
    incoming.to_csv(tmp, mode="a", index=False, header=not header_written)

    os.replace(tmp, output_path)   # atomic: master never left half-written
    return len(incoming), date_col


# ===========================================================================
# SEED MODE — only runs when you execute this file directly:
#                 cd ~/arcade/plato
#                 python plato_incremental.py
#
# Seeds BOTH reports in one run, one after the other.
# For each report, drop its historical chunk CSVs into the matching
# chunk_folder before running.
# ===========================================================================
if __name__ == "__main__":
    import glob
    import shutil
    from myscripts.mygoogle import service
    from platoscriptincrement import csv_upload_to_gdrive

    cred     = "/home/siddhantsar.vc/serviceaccount.json"
    WORK_DIR = "/home/siddhantsar.vc/arcade/plato/"

    # -----------------------------------------------------------------------
    # SEED CONFIG — one entry per report
    # Each report has its own chunk_folder, drive_folder_id, file_id, master_name
    # -----------------------------------------------------------------------
    SEED_REPORTS = [
    {
        "report":          "PPVS_Non_Branded",
        "chunk_folder":    "/home/siddhantsar.vc/arcade/plato/seed_ppvs/",  # ← dedicated folder
        "drive_folder_id": "1WicThm6Su3hU6LFADug-H2inU16UaN0l",
        "file_id":         "1h8oGTmJQ2nCdZOztf9YeVwXldr0ATGTO",
        "master_name":     "PPVS_Unbranded_2026.csv",
    },
    {
        "report":          "Vertical_Traffic_Euclid_Arcade",
        "chunk_folder":    "/home/siddhantsar.vc/arcade/plato/seed_vertical_traffic/",  # ← dedicated folder
        "drive_folder_id": "1WicThm6Su3hU6LFADug-H2inU16UaN0l",
        "file_id":         "17vkoyzZoh6Ig7MAdODj4wuplD-tMub5E",
        "master_name":     "Traffic_vertical_2026.csv",
    },
    ]
    # -----------------------------------------------------------------------

    ds = service.get_drive_service(cred)

    for cfg in SEED_REPORTS:
        report          = cfg["report"]
        chunk_folder    = cfg["chunk_folder"]
        drive_folder_id = cfg["drive_folder_id"]
        file_id         = cfg["file_id"]
        master_name     = cfg["master_name"]
        date_col        = PLATO_DATE_COL[report]

        print(f"\n{'='*60}")
        print(f"Seeding: {report}  (key={date_col})")
        print(f"{'='*60}")

        chunks = sorted(glob.glob(os.path.join(chunk_folder, "*.csv")))
        if not chunks:
            print(f"  SKIPPED — no CSVs found in {chunk_folder}")
            print(f"  Drop the historical export chunks there and re-run.")
            continue

        master_path = os.path.join(WORK_DIR, master_name)
        if os.path.exists(master_path):
            os.remove(master_path)

        print(f"  Folding {len(chunks)} chunk(s) into {master_name} ...")

        for i, chunk in enumerate(chunks):
            if i == 0:
                shutil.copy(chunk, master_path)
                print(f"  base : {os.path.basename(chunk)}")
            else:
                added, used = merge_incremental_streaming(
                    master_path, chunk, master_path, date_col=date_col
                )
                print(f"  merge: {os.path.basename(chunk)}  (+{added} rows, key={used})")

        fid = csv_upload_to_gdrive(ds, WORK_DIR, master_name,
                                   drive_folder_id, True, file_id)
        print(f"  Done. Uploaded → FileId={fid}  (shared link unchanged)")

    print(f"\nAll reports seeded.")
