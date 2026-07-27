from concurrent.futures import ProcessPoolExecutor
from datetime import datetime
from dateutil.relativedelta import relativedelta
import time
from random import randint
from functools import wraps
import sys
import os
import logging
from multiprocessing import Manager
from itertools import repeat

from icecream import ic
import pygsheets as pg
import pandas as pd

pd.set_option('display.max_rows', 500, 'display.expand_frame_repr', False, 'display.max_columns', 500)

from qaas_api import QaasAPI
from myscripts import my_details
from myscripts.mygoogle import mysheet
from myscripts.send_email import send_plain_email_from_fvm

# -----------------------------------------------------------------------------
# Control sheet: "Overwrite and Append control sheet" (tab: Main)
# Columns C3:P -> Run | Subject | Query | Source | Recipients | Fail_Recipients |
#                 RunHour | Override | FileName | Mode | TargetSheetId |
#                 TargetWorksheetName | StartCell | RunMinute
# -----------------------------------------------------------------------------

data_file_path = "/home/siddhantsar.vc/arcade"
cred = '/home/siddhantsar.vc/serviceaccount.json'  # used both for Sheets API (mysheet) and pygsheets auth

control_gsheet_id = "1QxuvuxaOb1yH1g3ZJ4S9lltTCxRLdQNDT1JQT7tl82g"
control_gsheet_sheet_name = "Main"
control_gsheet_table_range = "C3:P"

delete_file_bool = True  # deletes previous local files if True
parallel_workers = 3     # number of parallel workers for ProcessPoolExecutor

now_dt = datetime.today()
date_till_dt = now_dt.replace(minute=0, second=0, microsecond=0) + relativedelta(days=0)
date_till_key = date_till_dt.strftime('%Y%m%d')
date_hour = now_dt.hour
date_minute = now_dt.minute

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


def retry(retries=3, delay=5, backoff=2):
    """
    A decorator to retry a function if it raises an exception.
    """
    def decorator_retry(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            _retries, _delay = retries, delay
            while _retries > 0:
                try:
                    results = func(*args, **kwargs)
                    if results not in [None, -1, -2, -3]:
                        return results
                    raise Exception(f"API returned failure signal: {results}")
                except Exception as e:
                    _retries -= 1
                    if _retries == 0:
                        print(f"All retries failed for {func.__name__}. Last error: {e}")
                        raise e

                    filename_arg = kwargs.get('filename') or (args[3] if len(args) > 3 else 'N/A')
                    print(f"Error in '{func.__name__}' for '{filename_arg}': {e}. Retrying in {_delay}s...")
                    time.sleep(_delay)
                    _delay *= backoff
            return None
        return wrapper
    return decorator_retry


def run_query(query1, source, file_path, filename, shared_token_cache, shared_auth_lock):
    time.sleep(randint(1, 10))
    result = QaasAPI(
        client_id=my_details.QAAS_CLIENT_ID,
        rh_node_id=my_details.QAAS_NODE_ID,
        client_secret=my_details.QAAS_CLIENT_SECRET,
        enable_persistence=True,
        max_retries=10,
        shared_dict=shared_token_cache,
        shared_lock=shared_auth_lock,
    ).run_and_get_csv(
        query=query1,
        queue=my_details.QAAS_QUEUE,
        resubmit_query_on_failure=False,
        source=source,
        output_filename=file_path + filename,
    )
    return result


def _parse_start_cell(start_cell_str):
    """
    Converts an 'A1'-style string into a pygsheets (row, col) tuple.
    Falls back to (1, 1) if parsing fails or the value is blank.
    """
    if not start_cell_str or not str(start_cell_str).strip():
        return (1, 1)
    try:
        return pg.utils.format_addr(str(start_cell_str).strip(), 'tuple')
    except Exception:
        return (1, 1)


@retry(retries=10, delay=5, backoff=2)
def write_csv_to_gsheet(file_path, file_name, sheet_id, worksheet_name, mode, start_cell):
    """
    Reads the local CSV and writes it into the given Google Sheet tab.
    mode = 'Overwrite': clears the tab, then pastes the full dataframe (with headers) at start_cell.
    mode = 'Append': appends data rows after any existing content.
                     Writes headers too if the tab is currently empty.
    Creates the worksheet if it doesn't already exist.
    """
    gc = pg.authorize(service_file=cred)
    sheet = gc.open_by_key(sheet_id)

    try:
        wks = sheet.worksheet_by_title(worksheet_name)
    except pg.exceptions.WorksheetNotFound:
        wks = sheet.add_worksheet(worksheet_name)

    df = pd.read_csv(file_path + file_name)
    mode_clean = str(mode).strip().capitalize()

    if mode_clean == 'Overwrite':
        wks.clear()
        wks.set_dataframe(df, _parse_start_cell(start_cell))

    elif mode_clean == 'Append':
        existing_values = wks.get_all_values(include_tailing_empty=False)
        has_data = any(any(str(cell).strip() for cell in row) for row in existing_values)

        if not has_data:
            # Tab is empty -> write headers + data
            wks.set_dataframe(df, _parse_start_cell(start_cell))
        else:
            # Tab has data -> append rows only, no header repeat
            wks.append_table(values=df.values.tolist(),
                              start=str(start_cell).strip() if start_cell else 'A1',
                              dimension='ROWS',
                              overwrite=False)
    else:
        raise Exception(f"Unknown Mode '{mode}'. Expected 'Overwrite' or 'Append'.")

    return True


def delete_file(file_path, file_name):
    try:
        os.remove(file_path + file_name)
        print(f"Deleted local file: {file_name}")
    except Exception as e:
        print(f"Error deleting file {file_name}: {e}")


def failure_email(subject_text, sender, recipients, result):
    subject = f"VM Upload: {subject_text} Sheet Update Failed for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = (f"The following issues were encountered during the VM -> Google Sheet update process:\n\n"
            f"{result}\n\nPlease investigate and resolve these issues promptly.")
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Failure email sent.")


def success_email(subject_text, sender, recipients, sheet_id, worksheet_name, mode):
    subject = f"VM Upload: {subject_text} Sheet Update Successful for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = (f"The {subject_text} data was successfully written ({mode}) to Google Sheet tab '{worksheet_name}'.\n\n"
            f"https://docs.google.com/spreadsheets/d/{sheet_id}/edit")
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Success email sent.")


def process_job(job_data, shared_token_cache, shared_auth_lock):
    """
    Handles the full lifecycle of one row from the control table:
    run query -> save CSV locally -> overwrite/append into target Google Sheet tab.
    """
    query = job_data['Query']
    source = job_data['Source'].strip().upper()
    file_name = job_data['final_file_name']
    subject = job_data['Subject'].strip()
    mode = job_data['Mode'].strip()
    sheet_id = job_data['TargetSheetId'].strip()
    worksheet_name = job_data['TargetWorksheetName'].strip()
    start_cell = job_data.get('StartCell', '').strip() or 'A1'
    recipients = [i.strip() for i in job_data['Recipients'].split(',')] + [my_details.email]
    fail_recipients = [i.strip() for i in job_data['Fail_Recipients'].split(',')] + [my_details.email]

    print(f"Starting job: {subject} -> {file_name} -> {worksheet_name} ({mode})")

    log_dict = {"Query Pass": [], "Query Fail": [], "Write Pass": [], "Write Fail": []}

    # Run Query
    try:
        result = run_query(query, source, data_file_path, file_name, shared_token_cache, shared_auth_lock)
        if result:
            log_dict['Query Pass'].append(file_name)
        else:
            log_dict['Query Fail'].append(file_name)
    except Exception as e:
        log_dict['Query Fail'].append(file_name)
        error_msg = f"Query failed: {str(e)}"
        print(error_msg)
        failure_email(subject, my_details.email, fail_recipients, error_msg)
        return log_dict

    # Write to Google Sheet
    try:
        if file_name in log_dict['Query Pass']:
            write_csv_to_gsheet(data_file_path, file_name, sheet_id, worksheet_name, mode, start_cell)
            print(f"{file_name}: Sheet update successful ({sheet_id} / {worksheet_name}, mode={mode})")
            log_dict['Write Pass'].append((file_name, sheet_id, worksheet_name))
            success_email(subject, my_details.email, recipients, sheet_id, worksheet_name, mode)
        else:
            log_dict['Write Fail'].append(file_name)
            error_msg = f"Sheet update skipped as {file_name} not queried."
            print(error_msg)
            failure_email(subject, my_details.email, fail_recipients, error_msg)
    except Exception as e:
        log_dict['Write Fail'].append(file_name)
        error_msg = f"Sheet update failed: {str(e)}"
        print(error_msg)
        failure_email(subject, my_details.email, fail_recipients, error_msg)
        return log_dict

    return log_dict


def run_parallel(df, parallel_workers):
    with Manager() as manager:
        shared_token_cache = manager.dict()
        shared_auth_lock = manager.Lock()

        with ProcessPoolExecutor(max_workers=parallel_workers) as p:
            results = p.map(process_job, df.to_dict(orient='records'), repeat(shared_token_cache), repeat(shared_auth_lock))
            aggregated_log = {"Query Pass": [], "Query Fail": [], "Write Pass": [], "Write Fail": []}
            for log in list(results):
                aggregated_log["Query Pass"].extend(log.get("Query Pass", []))
                aggregated_log["Query Fail"].extend(log.get("Query Fail", []))
                aggregated_log["Write Pass"].extend(log.get("Write Pass", []))
                aggregated_log["Write Fail"].extend(log.get("Write Fail", []))

    return aggregated_log


if __name__ == "__main__":

    print(f"--- Script Started for {date_till_key} Hour: {date_hour} Minute: {date_minute} ---")

    if delete_file_bool and os.path.exists(data_file_path):
        print(f"Cleaning up old files in {data_file_path}...")
        for file in os.listdir(data_file_path):
            if file.endswith('.csv') and date_till_key not in file:
                delete_file(data_file_path, file)

    def determine_name(row):
        name = str(row['FileName']).strip()
        return f"{name}_Data_{date_till_key}.csv"

    ss = mysheet.MySheet(cred)
    control_df = ss.read_as_df(control_gsheet_id, control_gsheet_sheet_name, cell_range=control_gsheet_table_range,
                                first_row_as_header=True)
    control_df.dropna(how='all', inplace=True)

    control_df['RunHour'] = pd.to_numeric(control_df['RunHour'], errors='coerce').fillna(-1).astype(int)
    # RunMinute is optional: blank/non-numeric means "any minute within RunHour" (-1 sentinel)
    control_df['RunMinute'] = pd.to_numeric(control_df['RunMinute'], errors='coerce').fillna(-1).astype(int)
    control_df['Run'] = control_df['Run'].apply(lambda x: str(x).strip().upper() == 'TRUE')
    control_df['Override'] = control_df['Override'].apply(lambda x: str(x).strip().upper() == 'TRUE')

    hour_matches = control_df['RunHour'] == date_hour
    minute_matches = (control_df['RunMinute'] == -1) | (control_df['RunMinute'] == date_minute)

    filtered_control_df = control_df[
        ((control_df['Run'] == True) & hour_matches & minute_matches) | (control_df['Override'] == True)
    ].copy()

    filtered_control_df['final_file_name'] = filtered_control_df.apply(determine_name, axis=1)

    print(filtered_control_df)

    if filtered_control_df.empty:
        print(f"No jobs scheduled for hour {date_hour}, minute {date_minute}")
        sys.exit(0)
    else:
        logs = run_parallel(filtered_control_df, parallel_workers)
        ic(logs)