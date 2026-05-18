import logging
import pandas as pd
import pygsheets as pg
from qaas_api import QaasAPI  
#enabling run time log messages
logging.basicConfig(level=logging.INFO ,format='%(levelname)s: %(message)s' )
# DO NOT HARDCODE CREDENTIALS LIKE BELOW.
# This is just for brevity.
# Refer safe ways to use credentials in the next section 
client_id = 'analytics-da-qaas'  
client_secret = 'dR9TxRq6bJZYr623y9KmdhZoQBIgsKoMz13q2kYCAw+bZ8NA' 
rh_node_id = 'central-analytics-t'  
queue = 'analytics_adhoc'
current_time = datetime.now()
formatted_time = current_time.strftime('%d %b %Y %I%p')
current_hour = datetime.now().hour
DUPLOADER_IP = "dart-service.fdp-dataset-uploader-prod.fkcloud.in"
PORT = "80"
USER = “user_name"  
base_url = f"http://{DUPLOADER_IP}/dart-service/dataset-upload/v1"
BASE_URL = f"http://{DUPLOADER_IP}/dart-service/dataset-upload/v1"
SESSION_URL = f"{BASE_URL}/sessions/"
# Dataset information
COMPANY = 'fkint'
ORG = "analytics"
NAMESPACE = "grocery"
DATASET_NAME = "analytics_grocery_grocery_in_extrasaver_polygon_new"
SCHEMA_VERSION = "1.0"
COMMENTS = "first upload"
ALGO = "sha1"
HASH = "hash_value"
count = 0
Today = datetime.now()
Today_date = Today.strftime('%Y%m%d')
def create_session():
    """Create a new session."""
    session_data = {
        "company": COMPANY,
        "org": ORG,
        "namespace": NAMESPACE,
        "crypt": {
            "algo": ALGO,
            "hash": HASH
        },
        "dataset": {
            "name": DATASET_NAME,
            "schema-version": SCHEMA_VERSION,
            "comments": COMMENTS
        }
    }
    headers = {
        'accept-encoding': 'gzip, deflate',
        'accept-type': 'application/json',
        'content-type': 'application/json',
        'x-authenticated-user': USER
    }
    print(SESSION_URL)
    response = requests.post(SESSION_URL, json=session_data, headers=headers)
    
    if response.status_code == 201:
        print("Session created successfully.")
        print(response.json())
        return response.json()  # This will return the session info (including session ID)
    else:
        print(f"Error creating session: {response.status_code} - {response.text}")
        return None
headers = {
    'accept-encoding': 'gzip, deflate',
    'accept-type': 'application/json',
    'cache-control': 'no-cache',
    'x-authenticated-user': 'rahul.a'  
}
def upload_file(session_id, dataset_id, file_path):
    url = f'{base_url}/sessions/{session_id}/dataset/{dataset_id}/file'
    
    # Open the file in binary mode for uploading
    with open(file_path, 'rb') as f:
        files = {'file': f}
        
        timeout = (320, 7600)  
        
        # Send the PUT request to upload the file
        response = requests.put(url, files=files, headers=headers, timeout=timeout)
    
    # Print raw response for debugging
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Content: {response.text}")  # Print raw response content
    if response.status_code == 200:
        print('File uploaded successfully!')
    else:
        print(f"Failed to upload file: {response.status_code}")
        try:
            # Attempt to print response as JSON
            print(response.json())  
        except ValueError:
            print("Response is not in JSON format.")
def close_session(session_id):
    url = f'{base_url}/sessions/{session_id}/close'
    
    # Send the PUT request to close the session
    response = requests.put(url, headers=headers)
    
    # Print the response for debugging
    print(f"Closing Session - Status Code: {response.status_code}")
    print(f"Response Content: {response.text}")
    
    if response.status_code == 200:
        print('Session closed successfully!')
    else:
        print(f"Failed to close session: {response.status_code}")
        try:
            # Attempt to print response as JSON
            print(response.json())  
        except ValueError:
            print("Response is not in JSON format.")
def FDG_uploader(file_path):
    
    #create a session
    session= create_session()
    dataset_id = session.get('dataset-id')
    session_id = session.get('id')
    #upload()
    upload_file(session_id, dataset_id, file_path)
    # close session
    close_session(session_id)
    return session_id
def main(file_path):
    id = FDG_uploader(file_path)
    return 'success'
def delete_dataset(dataset_id, duploader_ip, port, user):
    url = f'http://{duploader_ip}:{port}/dart-service/dataset-upload/v1/data-set/{dataset_id}/inactive'
    # Define the headers for the request
    headers = {
        'accept-encoding': 'gzip, deflate',
        'accept-type': 'application/json',
        'cache-control': 'no-cache',
        'content-type': 'application/json',
        'x-authenticated-user': user
    }
    # Send the DELETE request to delete the dataset
    response = requests.put(url, headers=headers)  # Using PUT method as in the curl example
    # Check the status of the request and return the result
    if response.status_code == 200:
        print(f"Dataset with ID {dataset_id} deleted successfully.")
    else:
        print(f"Failed to delete dataset with ID {dataset_id}. Status Code: {response.status_code}")
        print("Response Content:", response.text)
    return response.text
query_str = f"""
              SELECT 
                  DISTINCT grocery.order_external_id,
                  grocery.store_id
              FROM bigfoot_external_neo.cp_santa__minutes_sales_polygon_share_fact AS grocery
              INNER JOIN 
                  (
                      SELECT 
                          DISTINCT store_id, 
                          go_live_date_key
                      FROM fdp_uploads.ds_fkint_analytics_grocery_xtrasaver_store_id_go_live_dataset_1_0
                  ) AS go_live
              ON grocery.store_id = go_live.store_id
              WHERE 
                  grocery.order_date_key BETWEEN 20251101 AND CAST(FORMAT_DATE('%Y%m%d', CAST(DATE_SUB(current_date(), interval 1 day) AS DATE)) AS INT64)
                  AND LOWER(grocery.marketplace_id) = 'grocery'
            """
df=client.run_and_get_csv(query=query_str, source="BIGQUERY", poll_interval=20,output_filename="file_path”)
gc = pg.authorize(service_file=’service account path’')
main('output path')

