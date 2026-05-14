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
# Dynamic filename (auto-rolls daily: meesho_pi_ci_YYYYMMDD.csv)
# -------------------------------------------------------------------
today_str  = datetime.datetime.now().strftime('%Y%m%d')
file_name  = f'meesho_pi_ci_{today_str}.csv'
local_path = f'/tmp/{file_name}'


# -------------------------------------------------------------------
# SQL query
# -------------------------------------------------------------------
sql_query = """
SELECT
    comp.date_key as order_date_key,
    comp.analytic_business_unit as analytic_business_unit,
    comp.analytic_super_category as analytic_super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN comp.analytic_vertical ELSE 'Non Pareto Vertical' END AS vertical,
    mpp,
    CASE 
            WHEN sales_agg.gmv / sales_agg.units <= 300 THEN "a) 0-300"
            WHEN sales_agg.gmv / sales_agg.units > 300 AND sales_agg.gmv / sales_agg.units <= 500 THEN "b) 300-500"
            WHEN sales_agg.gmv / sales_agg.units > 500 AND sales_agg.gmv / sales_agg.units <= 1000 THEN "c) 500-1000"
            WHEN sales_agg.gmv / sales_agg.units > 1000 THEN "d) 1000+"
    END AS price_bucket,
    sum(comp.m_dw) as m_dw,
    sum(comp.cdw) as cdw,
    sum(comp.cdw_fee) as cdw_fee,
    sum(comp.dw) as dw,
    sum(comp.fk_comp_display) as fk_comp_display,
    sum(comp.ms_comp_display) as ms_comp_display,
    sum(comp.fk_comp_display_fee) as fk_comp_display_fee,
    sum(comp.ms_comp_display_fee) as ms_comp_display_fee
      
FROM bigfoot_external_neo.cp_santa__meesho_pi_2__sc_level_fact AS comp

LEFT JOIN (
    SELECT analytic_super_category, analytic_vertical
    FROM (
        SELECT
            analytic_super_category,
            analytic_vertical,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC ROWS UNBOUNDED PRECEDING) AS vert_gmv_cumilative,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS total_sc_gmv,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC) / SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS percentage_value
        FROM (
            SELECT
                sales.analytic_super_category,
                sales.analytic_vertical,
                SUM(gmv) AS vertical_gmv
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order = FALSE
                AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
                AND order_date_key BETWEEN 20250701 AND 20260331
            GROUP BY sales.analytic_super_category, sales.analytic_vertical
        ) base
    ) base2
    WHERE percentage_value <= 0.8
) pareto
    ON comp.analytic_super_category = pareto.analytic_super_category
    AND comp.analytic_vertical = pareto.analytic_vertical

LEFT JOIN (
    SELECT
        analytic_super_category,
        analytic_vertical,
        SUM(gmv) AS gmv,
        SUM(units) AS units
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND type != 'service'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie = FALSE
        AND marketplace_id IN ('FLIPKART')
        AND is_shopsy_order = FALSE
        AND LOWER(analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
        AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
    GROUP BY analytic_super_category, analytic_vertical
) AS sales_agg
    ON comp.analytic_super_category = sales_agg.analytic_super_category
    AND comp.analytic_vertical = sales_agg.analytic_vertical

WHERE lower(comp.analytic_business_unit) in ('bgm','home','lifestyle','furniture')
    AND CAST(date_key AS BIGINT) between 20260101 and CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)

GROUP BY 
    comp.date_key,
    comp.analytic_business_unit,
    comp.analytic_super_category,
    vertical,
    mpp,
    price_bucket


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
msg['Subject'] = f'Meesho PI CI Daily Export — {today_str}'


body = (
   f'Automated daily Meesho PI CI export.\n\n'
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