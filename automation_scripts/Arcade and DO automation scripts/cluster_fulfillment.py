import os
import smtplib
import datetime
import logging
import sys
import gzip
import shutil
import pandas as pd
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders


sys.path.extend(['/home/siddhantsar.vc'])
from qaas_api import QaasAPI


logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


# -------------------------------------------------------------------
# QaaS config
# -------------------------------------------------------------------
client_id = 'analytics-da-qaas'
client_secret = 'dR9TxRq6bJZYr623y9KmdhZoQBIgsKoMz13q2kYCAw+bZ8NA'
rh_node_id = 'central-analytics-t'
queue = 'analytics_adhoc'


# -------------------------------------------------------------------
# Email config (Flipkart internal SMTP relay)
# -------------------------------------------------------------------
SMTP_HOST = '10.83.34.197'
FROM_ADDR = 'siddhantsar.vc@flipkart.com'
TO_ADDRS  = ['siddhantsar.vc@flipkart.com']      # add more recipients as needed


# -------------------------------------------------------------------
# Dynamic filename (auto-rolls daily: cf_YYYYMMDD.csv)
# -------------------------------------------------------------------
today_str  = datetime.datetime.now().strftime('%Y%m%d')
file_name  = f'cf_{today_str}.csv'
local_path = f'/tmp/{file_name}'


# -------------------------------------------------------------------
# SQL query
# -------------------------------------------------------------------
sql_query = """

select

cf.actual_reservation_date_key as order_date_key,
prod_cat.analytic_business_unit as analytic_business_unit,
prod_cat.analytic_super_category as analytic_super_category,
prod_cat.analytic_vertical as analytic_vertical,
case when cf.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end as is_alpha_seller,
CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END AS brand, 
case when bmp.brand is not null then 'Branded' else 'Unbranded' end as brand_flag, 
'FBF' as service_profile,

SUM(cf.source_cluster_sale) as source_cluster_sale, 
SUM(case when cf.fr_dr_cluster_type = 'FR_cluster' then  cf.source_cluster_sale else 0 end) as fr_cluster_source_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'DR_cluster' then  cf.source_cluster_sale else 0 end) as dr_cluster_source_cluster_sale,
 
SUM(cf.destination_cluster_sale) as destination_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'FR_cluster' then  cf.destination_cluster_sale else 0 end) as fr_cluster_destination_cluster_sale,
SUM(case when cf.fr_dr_cluster_type = 'DR_cluster' then  cf.destination_cluster_sale else 0 end) as dr_cluster_destination_cluster_sale

from bigfoot_external_neo.retail_ip__cluster_fulfillment_historical_hive_fact cf

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_cat 
    on cf.fsn = prod_cat.product_id 

LEFT JOIN
       (
       select
           brand,
           analytic_super_category
       from fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
       group by      
           brand,
           analytic_super_category
       ) bmp
       on lower(prod_cat.brand) = lower(bmp.brand)
       and lower(prod_cat.analytic_super_category) = lower(bmp.analytic_super_category)


WHERE (cf.actual_reservation_date_key between 20260101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
    AND lower(prod_cat.analytic_business_unit) in ('bgm','home','lifestyle','furniture')
    AND cf.cluster_city is not null 
    AND TRIM(cf.cluster_city) NOT IN ('','PUNE_CLUSTER')
    AND cf.fc not IN ('ban_dol_al_hyb_nl_01nl', 'ban_mad_al_urb_nl_01nl', 'micro_surat_01', 'mum_mah_al_hyb_nl_01nl', 'mum_tha_al_ban_nl_01nl', 'mum_tha_al_urb_nl_01nl', 'mys_bel_wh_nl_01nl', 'new_new_al_urb_nl_01nl', 'ran_gag_al_urb_nl_01nl')

Group by 

cf.actual_reservation_date_key ,
 prod_cat.analytic_business_unit ,
prod_cat.analytic_super_category ,
prod_cat.analytic_vertical ,
case when cf.is_first_party_seller = TRUE then 'Diamond' else 'Rest of MP' end ,
CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END,
case when bmp.brand is not null then 'Branded' else 'Unbranded' end
    
"""


# -------------------------------------------------------------------
# Run query and export to local CSV
# -------------------------------------------------------------------
logging.info('Executing query via QaaS API...')
client = QaasAPI(
   client_id, client_secret, rh_node_id=rh_node_id,
   enable_persistence=True,
   token_cache_path='/home/siddhantsar.vc/token_cache.json',
   max_retries=2, retry_interval=50,
)


df = client.run_and_get_dataframe(query=sql_query, source='BIGQUERY')
client.close()


logging.info(f'Query returned {len(df)} rows. Writing {local_path}')
df.to_csv(local_path, index=False)


# -------------------------------------------------------------------
# Gzip if CSV is >5 MB (stays safely under 25 MB email limit)
# -------------------------------------------------------------------
attach_path = local_path
attach_name = file_name
size_mb = os.path.getsize(local_path) / (1024 * 1024)
logging.info(f'CSV size: {size_mb:.2f} MB')


if size_mb > 5:
   gz_path = local_path + '.gz'
   with open(local_path, 'rb') as f_in, gzip.open(gz_path, 'wb') as f_out:
       shutil.copyfileobj(f_in, f_out)
   attach_path = gz_path
   attach_name = file_name + '.gz'
   gz_mb = os.path.getsize(gz_path) / (1024 * 1024)
   logging.info(f'Gzipped to {gz_mb:.2f} MB → {attach_name}')


# -------------------------------------------------------------------
# Build and send the email
# -------------------------------------------------------------------
msg = MIMEMultipart('alternative')
msg['From']    = FROM_ADDR
msg['To']      = ', '.join(TO_ADDRS)
msg['Subject'] = f'cf Daily Export — {today_str}'


body = (
   f'Automated daily cf export.\n\n'
   f'Rows: {len(df)}\n'
   f'File: {attach_name}\n'
   f'Run time: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n'
)
msg.attach(MIMEText(body, 'plain'))


with open(attach_path, 'rb') as f:
   p = MIMEBase('application', 'octet-stream')
   p.set_payload(f.read())
encoders.encode_base64(p)
p.add_header('Content-Disposition', f'attachment; filename= {attach_name}')
msg.attach(p)


logging.info(f'Sending email via {SMTP_HOST} to {TO_ADDRS}')
s = smtplib.SMTP(SMTP_HOST)
s.sendmail(FROM_ADDR, TO_ADDRS, msg.as_string())
s.quit()
logging.info('Email sent successfully.')


# -------------------------------------------------------------------
# Local cleanup
# -------------------------------------------------------------------
for p in (local_path, local_path + '.gz'):
   if os.path.exists(p):
       try:
           os.remove(p)
           logging.info(f'Removed {p}')
       except OSError as e:
           logging.warning(f'Could not remove {p}: {e}')