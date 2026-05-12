from datetime import datetime
from dateutil.relativedelta import relativedelta
import time
from random import randint
from functools import wraps
import os

from icecream import ic
from googleapiclient.http import MediaIoBaseUpload

from myscripts.gcp_connect import GCPConn
from myscripts import my_details
from myscripts.mygoogle import service
from myscripts.send_email import send_plain_email_from_fvm

file_path = "/home/chinmaya.cm/analytics/lifestyle_lid_data_upload/Data/"
folder_id = "1h43Es7-p8IX__ktZVXKeXPRT8a7Ar09m"  #update
cred = '/home/chinmaya.cm/analytics/vm_py_scripts/gcred/gcred.json'


day_lag = 0  # update
delete_file_bool = True # deletes previous day file if True
email_recipients = [my_details.email,'siddhantsar.vc@flipkart.com','allan.menezes@flipkart.com','solayappan.a@flipkart.com']
fail_email_recipients = [my_details.email,'siddhantsar.vc@flipkart.com','allan.menezes@flipkart.com','solayappan.a@flipkart.com']

query = f"""
select * from bigfoot_external_neo.analytics_cdo__Sales_with_brand_Weekly_Mailer_fact
"""

date_till_dt = datetime.today().replace(
    hour=0, minute=0, second=0, microsecond=0
) + relativedelta(days=-day_lag)
# date_till_dt = datetime(2025, 8, 21) + relativedelta(days=-day_lag)

date_till_key = date_till_dt.strftime('%Y%m%d')
prev_date_till_key = (date_till_dt + relativedelta(days=-1)).strftime('%Y%m%d')

file_name = "Brand Level Sales Data 2026" + date_till_key + ".csv"
prev_day_file_name = "Brand Level Sales Data 2026" + prev_date_till_key + ".csv"

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
                    # Attempt to run the decorated function
                    return func(*args, **kwargs)
                except Exception as e:
                    _retries -= 1
                    if _retries == 0:
                        # If all retries fail, re-raise the last exception
                        print(f"All retries failed for {func.__name__}. Last error: {e}")
                        raise e

                    # Log the failure and wait before the next attempt
                    func_name = func.__name__
                    # Extract filename if available for better logging
                    filename_arg = kwargs.get('filename') or (args[2] if len(args) > 2 else 'N/A')
                    print(f"Error in '{func_name}' for '{filename_arg}': {e}. Retrying in {_delay}s...")
                    time.sleep(_delay)
                    _delay *= backoff

        return wrapper

    return decorator_retry


@retry(retries=2, delay=5, backoff=2)
def hive_query(query1, file_path, filename):
    time.sleep(randint(1, 10))
    GCPConn(username=my_details.username, password='').query_to_csv(query1, output_path=file_path + filename,
                                                                    execution_engine='tez')

@retry(retries=2, delay=5, backoff=2)
def csv_upload_to_gdrive(file_path, file_name, folder_id):
    ds = service.get_drive_service(cred, my_details.email)
    file_metadata = {
        'name': file_name,
        'parents': [folder_id],
        'mimeType': 'text/csv'
    }

    media_body = MediaIoBaseUpload(fd=open(file_path + file_name, 'rb'),
                                   mimetype='text/csv',
                                   resumable=True)
    response = ds.files().create(media_body=media_body, body=file_metadata).execute()
    print(f"File ID: {response['id']}")
    return response['id']


def run_all():
    result = {}
    try:
        hive_query(query, file_path, file_name)
        result['Query Pass'] = file_name
        print(file_name, "queried")
    except Exception as e:
        result['Query Fail'] = file_name
        print(file_name, "not queried")
        return result  # Exit early if the query fails

    try:
        print("Attempting to upload ", file_name, "to drive...")
        file_id = csv_upload_to_gdrive(file_path, file_name, folder_id)
        result["Write Pass"] = [file_name, file_id]
    except Exception as e:
        # This block runs if the sheet write fails after all retries
        result["Write Fail"] = [file_name, None]

    return result

def delete_file(file_path, file_name):
    try:
        os.remove(file_path + file_name)
        print(f"Deleted local file: {file_name}")
    except Exception as e:
        print(f"Error deleting file {file_name}: {e}")

def failure_email(sender, recipients, result):
    subject = f"VM Upload: FK MFB DS Data Upload Failed for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = f"The following issues were encountered during the VM data upload process:\n\n{result}\n\nPlease investigate and resolve these issues promptly."
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Failure email sent.")

def success_email(sender, recipients, result):
    subject = f"VM Upload: FK MFB DS Data Upload Successful for Data dated {date_till_dt.strftime('%Y%m%d')}"
    body = f"The FK MFB DS Data upload process from VM completed successfully.\n The data file can be found at the following link:\n\nhttps://drive.google.com/file/d/{result['Write Pass'][1]}/view?usp=drive_link"
    send_plain_email_from_fvm(subject, body, sender, recipients)
    print("Success email sent.")

result = run_all()
ic(result)

if 'Query Fail' in result or 'Write Fail' in result:
    failure_email(my_details.email, fail_email_recipients,result)
else:
    success_email(my_details.email, email_recipients, result)
    if delete_file_bool:
        if os.path.exists(file_path + prev_day_file_name):
            delete_file(file_path, prev_day_file_name)