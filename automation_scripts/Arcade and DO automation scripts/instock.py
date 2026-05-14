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
# Dynamic filename (auto-rolls daily: instock_YYYYMMDD.csv)
# -------------------------------------------------------------------
today_str  = datetime.datetime.now().strftime('%Y%m%d')
file_name  = f'instock_{today_str}.csv'
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
    list_dim.process_date_key as order_date_key,
    prod_dim.analytic_business_unit as analytic_business_unit,
    prod_dim.analytic_super_category as analytic_super_category,
    prod_dim.analytic_vertical as analytic_vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN prod_dim.brand ELSE 'Unbranded' END AS brand, 
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    sales.is_alpha_seller as is_alpha_seller,
    CASE 
            WHEN price_agg.gmv / price_agg.units <= 300 THEN "a) 0-300"
            WHEN price_agg.gmv / price_agg.units > 300 AND price_agg.gmv / price_agg.units <= 500 THEN "b) 300-500"
            WHEN price_agg.gmv / price_agg.units > 500 AND price_agg.gmv / price_agg.units <= 1000 THEN "c) 500-1000"
            WHEN price_agg.gmv / price_agg.units > 1000 THEN "d) 1000+"
    END AS price_bucket,
    
    count(distinct list_dim.listing_id) as a_listings,
    count(distinct list_dim.product_id) as a_products,
    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products

FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_dim
    ON list_dim.product_id = prod_dim.product_id

LEFT JOIN bmp_brands bmp 
    ON LOWER(prod_dim.brand) = LOWER(bmp.brand) 
    AND LOWER(prod_dim.analytic_super_category) = LOWER(bmp.analytic_super_category)

LEFT JOIN (
    SELECT 
        listing_id,
        CASE WHEN is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
    GROUP BY 
        listing_id, 
        CASE WHEN is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END
) as sales
    ON list_dim.listing_id = sales.listing_id

LEFT JOIN (
    SELECT
        listing_id,
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
    GROUP BY listing_id
) AS price_agg
    ON list_dim.listing_id = price_agg.listing_id

INNER JOIN pareto_verticals pv
    ON LOWER(prod_dim.analytic_super_category) = LOWER(pv.analytic_super_category)
    AND LOWER(prod_dim.analytic_vertical) = LOWER(pv.analytic_vertical)

WHERE list_dim.marketplace_id = 'FLIPKART'
    AND LOWER(prod_dim.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND list_dim.process_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)

GROUP BY
    list_dim.process_date_key,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    prod_dim.analytic_vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN prod_dim.brand ELSE 'Unbranded' END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    sales.is_alpha_seller,
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
msg['Subject'] = f'Instock Daily Export — {today_str}'


body = (
   f'Automated daily Instock export.\n\n'
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