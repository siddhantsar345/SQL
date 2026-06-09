from concurrent.futures import ProcessPoolExecutor
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
import time
from functools import wraps
import sys
import os
import logging
from multiprocessing import Manager
from itertools import repeat

import requests
from icecream import ic
from googleapiclient.http import MediaIoBaseUpload
import pandas as pd

pd.set_option('display.max_rows', 500, 'display.expand_frame_repr', False, 'display.max_columns', 500)

from plato_incremental import download_master_from_drive, merge_incremental_streaming, PLATO_DATE_COL
from myscripts import my_details
from myscripts.mygoogle import service
from myscripts.mygoogle import mysheet
from myscripts.send_email import send_plain_email_from_fvm

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
data_file_path = "/home/siddhantsar.vc/arcade/plato/"
cred = '/home/siddhantsar.vc/serviceaccount.json'

control_gsheet_id = "1ubo8Dd2io-11NVDDMJj9JSB2w7vv1c8lCFebJoc3SQM"
control_gsheet_sheet_name = "Plato"
control_gsheet_table_range = "C3:N"

LINKS_SHEET_ID = "1ih1qKGQzX1m7b_5U9puD4QZiEHz4ll99xh6x_1tONcs"
LINKS_SHEET_NAME = "links"

MAX_URL_STALENESS_HOURS = 24
DOWNLOAD_TIMEOUT_SECONDS = 600

delete_file_bool = True
parallel_workers = 3

date_till_dt = datetime.today().replace(second=0, microsecond=0) + relativedelta(days=0)
date_till_key = date_till_dt.strftime('%Y%m%d')
date_hour = date_till_dt.hour
date_minute = date_till_dt.minute

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


# ---------------------------------------------------------------------------
# RETRY DECORATOR
# ---------------------------------------------------------------------------
def retry(retries=3, delay=5, backoff=2):
    def decorator_retry(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            _retries, _delay = retries, delay
            while _retries > 0:
                try:
                    results = func(*args, **kwargs)
                    if results not in [None, -1, -2, -3]:
                        return results
                    raise Exception(f"Function returned failure signal: {results}")
                except Exception as e:
                    _retries -= 1
                    if _retries == 0:
                        print(f"All retries failed for {func.__name__}. Last error: {e}")
                        raise e
                    filename_arg = kwargs.get('filename') or (args[2] if len(args) > 2 else 'N/A')
                    print(f"Error in '{func.__name__}' for '{filename_arg}': {e}. Retrying in {_delay}s...")
                    time.sleep(_delay)
                    _delay *= backoff
            return None
        return wrapper
    return decorator_retry


# ---------------------------------------------------------------------------
# DOWNLOAD LINK
# ---------------------------------------------------------------------------
@retry(retries=3, delay=10, backoff=2)
def download_link(identifier_key, file_path, filename):
    ss = mysheet.MySheet(cred)
    links_df = ss.read_as_df(LINKS_SHEET_ID, LINKS_SHEET_NAME, first_row_as_header=True)

    row = links_df[links_df['identifier_key'].astype(str).str.strip() == identifier_key.strip()]
    if row.empty:
        raise ValueError(f"identifier_key '{identifier_key}' not found in links sheet")

    url = str(row.iloc[0]['URL']).strip()
    updated_at_str = str(row.iloc[0]['updated_at']).strip()

    if not url or not url.startswith('https://'):
        raise ValueError(f"Invalid URL for '{identifier_key}': '{url}'")

    try:
        updated_at = datetime.fromisoformat(updated_at_str.replace('Z', '+00:00'))
        age_hours = (datetime.now(timezone.utc) - updated_at).total_seconds() / 3600
        if age_hours > MAX_URL_STALENESS_HOURS:
            raise RuntimeError(
                f"URL is stale for '{identifier_key}': updated_at={updated_at_str} "
                f"({age_hours:.1f}h old, threshold={MAX_URL_STALENESS_HOURS}h). "
                f"Apps Script may not have updated the link today."
            )
        print(f"URL freshness OK for '{identifier_key}': {age_hours:.1f}h old")
    except RuntimeError:
        raise
    except Exception as e:
        print(f"Warning: couldn't parse updated_at='{updated_at_str}' for '{identifier_key}': {e}")

    local_path = os.path.join(file_path, filename)
    partial_path = local_path + '.partial'

    try:
        with requests.get(url, stream=True, timeout=DOWNLOAD_TIMEOUT_SECONDS) as r:
            r.raise_for_status()
            with open(partial_path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        f.write(chunk)
    except requests.exceptions.HTTPError as e:
        if os.path.exists(partial_path):
            os.remove(partial_path)
        status = e.response.status_code if e.response is not None else 'unknown'
        if status == 403:
            raise RuntimeError(f"HTTP 403 for '{identifier_key}': signed URL likely expired") from e
        if status == 404:
            raise RuntimeError(f"HTTP 404 for '{identifier_key}': file not found at URL") from e
        raise RuntimeError(f"HTTP {status} downloading '{identifier_key}'") from e
    except requests.exceptions.Timeout:
        if os.path.exists(partial_path):
            os.remove(partial_path)
        raise RuntimeError(f"Download timed out for '{identifier_key}' (>{DOWNLOAD_TIMEOUT_SECONDS}s)")
    except requests.exceptions.RequestException as e:
        if os.path.exists(partial_path):
            os.remove(partial_path)
        raise RuntimeError(f"Network error downloading '{identifier_key}': {e}") from e

    if not os.path.exists(partial_path) or os.path.getsize(partial_path) == 0:
        if os.path.exists(partial_path):
            os.remove(partial_path)
        raise RuntimeError(f"Downloaded file is empty for '{identifier_key}'")

    os.replace(partial_path, local_path)
    size_mb = os.path.getsize(local_path) / (1024 * 1024)
    print(f"Downloaded '{filename}': {size_mb:.2f} MB")
    return local_path


# ---------------------------------------------------------------------------
# UPLOAD / DELETE / EMAIL
# ---------------------------------------------------------------------------
@retry(retries=2, delay=5, backoff=2)
def csv_upload_to_gdrive(ds, file_path, file_name, folder_id, overwrite, file_id):
    file_metadata = {
        'name': file_name,
        'parents': [folder_id],
        'mimeType': 'text/csv'
    }

    with open(file_path + file_name, 'rb') as f:
        media_body = MediaIoBaseUpload(fd=f, mimetype='text/csv', resumable=True)
        if not overwrite:
            response = ds.files().create(media_body=media_body, body=file_metadata).execute()
            print(f"File ID: {response['id']}")
        else:
            file_metadata.pop('parents', None)
            response = ds.files().update(
                fileId=file_id, body=file_metadata, media_body=media_body).execute()
            print(f"File ID: {response['id']} is overwritten.")

    return response['id']


def delete_file(file_path, file_name):
    try:
        os.remove(file_path + file_name)
        print(f"Deleted local file: {file_name}")
    except Exception as e:
        print(f"Error deleting file {file_name}: {e}")


def failure_email(subject_text, sender, recipients, result):
    subject = f"VM Upload: {subject_text} Data Upload Failed for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = (f"The following issues were encountered during the VM data upload process:\n\n"
            f"{result}\n\nPlease investigate and resolve these issues promptly.")
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Failure email sent.")


def success_email(subject_text, sender, recipients, file_id):
    subject = f"VM Upload: {subject_text} Data Upload Successful for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = (f"The {subject_text} Data upload process from VM completed successfully.\n"
            f"The data file can be found at the following link:\n\n"
            f"https://drive.google.com/file/d/{file_id}/view?usp=drive_link")
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Success email sent.")


# ---------------------------------------------------------------------------
# PROCESS JOB
# ---------------------------------------------------------------------------
def process_job(job_data, shared_token_cache, shared_auth_lock):
    identifier_key = str(job_data['Indentifier_key']).strip()
    file_name = job_data['final_file_name']
    folder_id = str(job_data['DriveId']).strip()
    subject = str(job_data['Subject']).strip()
    file_id = str(job_data['FileId']).strip()
    overwrite = job_data['Overwrite']
    recipients = [i.strip() for i in str(job_data['Recipients']).split(',') if i.strip()] + [my_details.email]
    fail_recipients = [i.strip() for i in str(job_data['Fail_Recipients']).split(',') if i.strip()] + [my_details.email]

    print(f"Starting job: {subject} -> {file_name} (identifier_key: {identifier_key})")

    log_dict = {"Download Pass": [], "Download Fail": [], "Write Pass": [], "Write Fail": []}

    ds = service.get_drive_service(cred)

    # ---- Download the fresh 2-month export ----
    try:
        download_link(identifier_key, data_file_path, file_name)
        log_dict['Download Pass'].append(file_name)
    except Exception as e:
        log_dict['Download Fail'].append(file_name)
        error_msg = f"Download failed for identifier_key '{identifier_key}': {str(e)}"
        print(error_msg)
        failure_email(subject, my_details.email, fail_recipients, error_msg)
        return log_dict

    # ---- Merge into master + Upload to Drive ----
    try:
        if file_name in log_dict['Download Pass']:
            # Rename the incoming 2-month export so master can use the real file_name
            incoming_temp = os.path.join(data_file_path, file_name[:-4] + "_incoming.csv")
            os.rename(os.path.join(data_file_path, file_name), incoming_temp)

            master_path = os.path.join(data_file_path, file_name)

            # Pull the current cumulative master down from Drive
            download_master_from_drive(ds, file_id, master_path)

            # Merge: refresh the 2-month window, keep all older history
            added, used = merge_incremental_streaming(
                master_path, incoming_temp, master_path,
                date_col=PLATO_DATE_COL[identifier_key]
            )
            print(f"{file_name}: merged {added} rows on key={used}")

            # Upload merged master back to the same FileId (link never changes)
            file_id = csv_upload_to_gdrive(ds, data_file_path, file_name,
                                           folder_id, True, file_id)
            print(f"{file_name}: Upload Successful (ID: {file_id})")
            log_dict['Write Pass'].append((file_name, file_id))
            success_email(subject, my_details.email, recipients, file_id)
        else:
            log_dict['Write Fail'].append(file_name)
            error_msg = f"Upload skipped: {file_name} was not downloaded."
            print(error_msg)
            failure_email(subject, my_details.email, fail_recipients, error_msg)
    except Exception as e:
        log_dict['Write Fail'].append(file_name)
        error_msg = f"Merge/Upload failed: {str(e)}"
        print(error_msg)
        failure_email(subject, my_details.email, fail_recipients, error_msg)

    return log_dict   # FIX: was missing — caused NoneType crash on success path


# ---------------------------------------------------------------------------
# PARALLEL RUNNER
# ---------------------------------------------------------------------------
def run_parallel(df, parallel_workers):
    with Manager() as manager:
        shared_token_cache = manager.dict()
        shared_auth_lock = manager.Lock()

        with ProcessPoolExecutor(max_workers=parallel_workers) as p:
            results = p.map(process_job, df.to_dict(orient='records'),
                            repeat(shared_token_cache), repeat(shared_auth_lock))
            aggregated_log = {"Download Pass": [], "Download Fail": [], "Write Pass": [], "Write Fail": []}
            for log in list(results):
                aggregated_log["Download Pass"].extend(log.get("Download Pass", []))
                aggregated_log["Download Fail"].extend(log.get("Download Fail", []))
                aggregated_log["Write Pass"].extend(log.get("Write Pass", []))
                aggregated_log["Write Fail"].extend(log.get("Write Fail", []))

    return aggregated_log


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    print(f"--- Script Started for {date_till_key} Hour: {date_hour} Minute: {date_minute:02d} ---")

    if delete_file_bool and os.path.exists(data_file_path):
        print(f"Cleaning up old files in {data_file_path}...")
        for file in os.listdir(data_file_path):
            if file.endswith('.csv') and date_till_key not in file and '_incoming' not in file:
                delete_file(data_file_path, file)

    def determine_name(row):
        name = str(row['FileName']).strip()
        if row['Overwrite']:
            return name + '.csv'
        return f"{name}_Data_{date_till_key}.csv"

    ss = mysheet.MySheet(cred)
    control_df = ss.read_as_df(control_gsheet_id, control_gsheet_sheet_name,
                               cell_range=control_gsheet_table_range, first_row_as_header=True)
    control_df.dropna(how='all', inplace=True)

    control_df['RunHour'] = pd.to_numeric(control_df['RunHour'], errors='coerce').fillna(-1).astype(int)
    control_df['RunMinute'] = pd.to_numeric(control_df['RunMinute'], errors='coerce').fillna(-1).astype(int)
    control_df['Run'] = control_df['Run'].apply(lambda x: str(x).strip().upper() == 'TRUE')
    control_df['Override'] = control_df['Override'].apply(lambda x: str(x).strip().upper() == 'TRUE')
    control_df['Overwrite'] = control_df['FileId'].apply(lambda x: True if str(x).strip() != "" else False)

    filtered_control_df = control_df[
        (
            (control_df['Run'] == True)
            & (control_df['RunHour'] == date_hour)
            & (control_df['RunMinute'] == date_minute)
        )
        | (control_df['Override'] == True)
    ].copy()

    filtered_control_df['final_file_name'] = filtered_control_df.apply(determine_name, axis=1)

    print(filtered_control_df)

    if filtered_control_df.empty:
        print(f"No jobs scheduled for {date_hour:02d}:{date_minute:02d}")
        sys.exit(0)
    else:
        logs = run_parallel(filtered_control_df, parallel_workers)
        ic(logs)