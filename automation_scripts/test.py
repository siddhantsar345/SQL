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
from googleapiclient.http import MediaIoBaseUpload
import pandas as pd

pd.set_option('display.max_rows', 500, 'display.expand_frame_repr', False, 'display.max_columns', 500)

from qaas_api import QaasAPI
from myscripts import my_details
from myscripts.mygoogle import service
from myscripts.mygoogle import mysheet
from myscripts.send_email import send_plain_email_from_fvm

data_file_path = "/home/chinmaya.cm/analytics/lifestyle_lid_data_upload/Data/"
cred = '/home/chinmaya.cm/analytics/vm_py_scripts/gcred/gcred.json'
#cred = 'gcred/gcred.json'

control_gsheet_id = "1ubo8Dd2io-11NVDDMJj9JSB2w7vv1c8lCFebJoc3SQM" # Update
control_gsheet_sheet_name = "Main" # Update
control_gsheet_table_range = "C3:M" # Update

delete_file_bool = True # deletes previous files if True
parallel_workers = 3 # update, number of parallel workers for ProcessPoolExecutor

date_till_dt = datetime.today().replace(minute=0, second=0, microsecond=0) + relativedelta(days=0)
# date_till_dt = datetime(2025, 8, 21, 13) + relativedelta(days=0)

date_till_key = date_till_dt.strftime('%Y%m%d')
date_hour = date_till_dt.hour

# enabling info level logging
logging.basicConfig(level=logging.INFO ,format='%(levelname)s: %(message)s' )

def retry(retries=3, delay=5, backoff=2):
    """
    A decorator to retry a function if it raises an exception.

    :param retries: The number of times to retry.
    :param delay: The initial delay between retries in seconds.
    :param backoff: Multiplier for the delay (e.g., 2 means the delay doubles each time).
    """

    def decorator_retry(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            _retries, _delay = retries, delay
            while _retries > 0:
                try:
                    results = func(*args, **kwargs)

                    # Check for failure signals. If result is valid, return it.
                    # Adjust this list based on what you consider a "retryable" failure.
                    if results not in [None, -1, -2, -3]:
                        return results

                    # If we got here, it's a logical failure, so we force an exception to trigger retry
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

def run_query(query1, source, file_path, filename,shared_token_cache,shared_auth_lock):
    time.sleep(randint(1, 10))
    result = QaasAPI(client_id= my_details.QAAS_CLIENT_ID,rh_node_id=my_details.QAAS_NODE_ID,client_secret=my_details.QAAS_CLIENT_SECRET,
                     enable_persistence=True,max_retries=2,
                     shared_dict=shared_token_cache,shared_lock=shared_auth_lock).run_and_get_csv(query=query1,
                                                                    queue=my_details.QAAS_QUEUE,
                                                                    resubmit_query_on_failure= False,
                                                                    source=source,
                                                                    output_filename=file_path+filename)
    # print(f"{result=}")
    return result

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
    body = f"The following issues were encountered during the VM data upload process:\n\n{result}\n\nPlease investigate and resolve these issues promptly."
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Failure email sent.")

def success_email(subject_text, sender, recipients, file_id):
    subject = f"VM Upload: {subject_text} Data Upload Successful for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = f"The {subject_text} Data upload process from VM completed successfully.\nThe data file can be found at the following link:\n\nhttps://drive.google.com/file/d/{file_id}/view?usp=drive_link"
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Success email sent.")

def process_job(job_data, shared_token_cache, shared_auth_lock):
    """
    Handles the full lifecycle of one row from the control table.
    job_data is a dictionary containing all row info.
    """
    query = job_data['Query']
    source = job_data['Source'].strip().upper()
    file_name = job_data['final_file_name']
    folder_id = job_data['DriveId'].strip()
    subject = job_data['Subject'].strip()
    file_id = job_data['FileId'].strip()
    overwrite = job_data['Overwrite']
    recipients = [i.strip() for i in job_data['Recipients'].split(',')] + [my_details.email]
    fail_recipients = [i.strip() for i in job_data['Fail_Recipients'].split(',')] + [my_details.email]

    print(f"Starting job: {subject} -> {file_name}")

    log_dict = {"Query Pass": [], "Query Fail": [], "Write Pass": [], "Write Fail": []}

    ds = service.get_drive_service(cred, my_details.email)

    # Run Query
    try:
        result = run_query(query, source, data_file_path, file_name,shared_token_cache,shared_auth_lock)
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

    # Upload to Drive
    try:
        if file_name in log_dict['Query Pass']:
            file_id = csv_upload_to_gdrive(ds, data_file_path, file_name, folder_id, overwrite, file_id)
            print(f"{file_name}: Upload Successful (ID: {file_id})")
            log_dict['Write Pass'].append((file_name, file_id))
            success_email(subject, my_details.email, recipients, file_id)
        else:
            log_dict['Write Fail'].append(file_name)
            error_msg = f"Upload failed as {file_name} not queried."
            print(error_msg)
            failure_email(subject, my_details.email, fail_recipients, error_msg)
    except Exception as e:
        # Failure Email
        log_dict['Write Fail'].append(file_name)
        error_msg = f"Upload failed: {str(e)}"
        print(error_msg)
        failure_email(subject, my_details.email, fail_recipients, error_msg)
        return log_dict

    return log_dict

def run_parallel(df, parallel_workers):
    with Manager() as manager:
        shared_token_cache = manager.dict() # Shared token storage
        shared_auth_lock = manager.Lock()

        with ProcessPoolExecutor(max_workers=parallel_workers) as p:
            results = p.map(process_job, df.to_dict(orient='records'),repeat(shared_token_cache), repeat(shared_auth_lock))
            aggregated_log = {"Query Pass": [], "Query Fail": [], "Write Pass": [], "Write Fail": []}
            for log in list(results):
                aggregated_log["Query Pass"].extend(log.get("Query Pass", []))
                aggregated_log["Query Fail"].extend(log.get("Query Fail", []))
                aggregated_log["Write Pass"].extend(log.get("Write Pass", []))
                aggregated_log["Write Fail"].extend(log.get("Write Fail", []))

    return aggregated_log

if __name__ == "__main__":

    print(f"--- Script Started for {date_till_key} Hour: {date_hour} ---")

    if delete_file_bool and os.path.exists(data_file_path):
        print(f"Cleaning up old files in {data_file_path}...")
        for file in os.listdir(data_file_path):
            if file.endswith('.csv') and date_till_key not in file:
                delete_file(data_file_path, file)

    def determine_name(row):
        name = str(row['FileName']).strip()
        if row['Overwrite']:
            return name + '.csv'
        return f"{name}_Data_{date_till_key}.csv"

    # reading control table from Google spreadsheet
    ss = mysheet.MySheet(cred)
    control_df = ss.read_as_df(control_gsheet_id, control_gsheet_sheet_name, cell_range=control_gsheet_table_range,
                               first_row_as_header=True)
    control_df.dropna(how='all', inplace=True)

    # covert control_df['RunHour'] to int and Run, Override to Bool
    control_df['RunHour'] = pd.to_numeric(control_df['RunHour'], errors='coerce').fillna(-1).astype(int)
    control_df['Run'] = control_df['Run'].apply(lambda x: str(x).strip().upper() == 'TRUE')
    control_df['Override'] = control_df['Override'].apply(lambda x: str(x).strip().upper() == 'TRUE')
    control_df['Overwrite'] = control_df['FileId'].apply(lambda x: True if x!= "" else False)

    # filtering control_df based on Run and RunHour
    filtered_control_df = control_df[((control_df['Run'] == True) & (control_df['RunHour'] == date_hour)) | (
                control_df['Override'] == True)].copy()
    
    
    filtered_control_df['final_file_name'] = filtered_control_df.apply(determine_name, axis=1)

    print(filtered_control_df)

    if filtered_control_df.empty:
        print(f"No jobs scheduled for hour {date_hour}")
        sys.exit(0)
    else:
        logs = run_parallel(filtered_control_df, parallel_workers)
        ic(logs)