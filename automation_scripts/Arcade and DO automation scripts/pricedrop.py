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
# Dynamic filename (auto-rolls daily: pricedrop_YYYYMMDD.csv)
# -------------------------------------------------------------------
today_str  = datetime.datetime.now().strftime('%Y%m%d')
file_name  = f'pricedrop_{today_str}.csv'
local_path = f'/tmp/{file_name}'


# -------------------------------------------------------------------
# SQL query
# -------------------------------------------------------------------
sql_query = """

WITH bmp_brands AS (
    SELECT
        brand,
        analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
),

pareto_verticals AS (
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
)

SELECT
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    brand, 
    branded_flag,
    is_alpha_seller,
    price_bucket,

    SUM(input_bau_weighted_asp) as input_bau_weighted_asp,
    SUM(input_fes_weighted_asp) as input_fes_weighted_asp,
    SUM(output_bau_weighted_asp) as output_bau_weighted_asp,
    SUM(output_fes_weighted_asp) as output_fes_weighted_asp

FROM (
    SELECT
        fes.order_date_key as order_date_key,
        bau.analytic_business_unit,
        bau.analytic_super_category,
        bau.analytic_vertical,
        bau.brand, 
        bau.branded_flag,
        bau.is_alpha_seller,
        bau.product_id as product_id,
        bau.listing_id as listing_id,
        CASE 
        WHEN bau.gmv / bau.units <= 300 THEN "0-300"
        WHEN bau.gmv / bau.units > 300 AND bau.gmv / bau.units <= 500 THEN "300-500"
        WHEN bau.gmv / bau.units > 500 AND bau.gmv / bau.units <= 1000 THEN "500-1000"
        WHEN bau.gmv / bau.units > 1000 THEN "1000+"
        ELSE "Unknown"
        END AS price_bucket,

        (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
        (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
        (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
        (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp

    FROM (
        SELECT
            sales.analytic_super_category,
            sales.analytic_business_unit,
            sales.analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END AS brand, 
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END as is_alpha_seller,
            sales.product_id,
            sales.listing_id,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN bmp_brands bmp 
            ON LOWER(sales.brand) = LOWER(bmp.brand) 
            AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
        WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
            AND sales.type != 'service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order = FALSE
            AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key BETWEEN 20250701 AND 20250831
        GROUP BY
            sales.analytic_super_category,
            sales.analytic_business_unit,
            sales.analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END,
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
            sales.product_id,
            sales.listing_id
    ) bau

    INNER JOIN (
        SELECT
            sales.listing_id,
            order_date_key,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
            AND sales.type != 'service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order = FALSE
            AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
        GROUP BY
            sales.listing_id,
            order_date_key
    ) fes
        ON bau.listing_id = fes.listing_id

    LEFT JOIN pareto_verticals pv
        ON LOWER(bau.analytic_super_category) = LOWER(pv.analytic_super_category)
        AND LOWER(bau.analytic_vertical) = LOWER(pv.analytic_vertical)

) sub

GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    brand, 
    branded_flag,
    is_alpha_seller,
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
msg['Subject'] = f'Price Drop Daily Export — {today_str}'


body = (
   f'Automated daily Price Drop export.\n\n'
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