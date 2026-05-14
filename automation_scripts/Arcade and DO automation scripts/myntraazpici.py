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
# Dynamic filename (auto-rolls daily: myntra_az_pi_ci_YYYYMMDD.csv)
# -------------------------------------------------------------------
today_str  = datetime.datetime.now().strftime('%Y%m%d')
file_name  = f'myntra_az_pi_ci_{today_str}.csv'
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
    a.order_date_key,
    a.analytic_business_unit,  
    a.analytic_super_category,
    a.analytic_vertical,
    a.brand, 
    a.branded_flag,
    a.is_alpha_seller,
    a.price_bucket,

    SUM(CASE WHEN lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.search_ppvs ELSE 0 END) AS ai_search_ppvs,
    SUM(CASE WHEN a.fsn_coupon_landscape = "FK_Comp" AND lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.search_ppvs ELSE 0 END) AS ai_fk_cd,
    SUM(CASE WHEN a.fsn_coupon_landscape = "AI_Comp" AND lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.search_ppvs ELSE 0 END) AS ai_az_cd,
    SUM(CASE WHEN lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.fk_price_post_coupon * a.search_ppvs ELSE 0 END) AS ai_wfcp,
    SUM(CASE WHEN lower(a.competitor) IN ('ai') AND a.ci_business_unit NOT IN ("BGM(Books)", "Electronics") THEN a.comp_price_post_coupon * a.search_ppvs ELSE 0 END) AS ai_wccp,

    SUM(CASE WHEN lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.search_ppvs ELSE 0 END) AS myntra_search_ppvs,
    SUM(CASE WHEN a.fsn_coupon_landscape = "FK_Comp" AND lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.search_ppvs ELSE 0 END) AS myntra_fk_cd,
    SUM(CASE WHEN a.fsn_coupon_landscape = "AI_Comp" AND lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.search_ppvs ELSE 0 END) AS myntra_az_cd,
    SUM(CASE WHEN lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.fk_price_post_coupon * a.search_ppvs ELSE 0 END) AS myntra_wfcp,
    SUM(CASE WHEN lower(a.competitor) IN ("myntra") AND a.ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel") THEN a.comp_price_post_coupon * a.search_ppvs ELSE 0 END) AS myntra_wccp

FROM  
    (
    SELECT  
        CAST(date_key AS int64) AS order_date_key,
        a.competitor,  
        a.yearmo,  
        b.week_num_in_year,  
        a.analytic_business_unit,  
        a.ci_business_unit,  
        a.analytic_super_category,  
        CASE WHEN lower(prod.analytic_business_unit) = 'lifestyle' THEN prod.cms_vertical ELSE prod.analytic_vertical END AS analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN a.brand ELSE 'Unbranded' END AS brand, 
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
        a.fk_seller_type AS is_alpha_seller,
        CASE 
            WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
            WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
            WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
            WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
        END AS price_bucket,
        a.mcat_tag,
        a.az_seller_type,  
        search_ppvs,  
        fsn_landscape,  
        fk_price, 
        comp_price,  
        fk_price_post_coupon,  
        (comp_price - COALESCE(comp_coupon_discount, 0)) AS comp_price_post_coupon,
        CASE
            WHEN fk_price_post_coupon < 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) > 1.02 THEN "FK_Comp"
            WHEN fk_price_post_coupon < 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) < 0.98 THEN "AI_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) > 1.01 THEN "FK_Comp"
            WHEN fk_price_post_coupon >= 1000 AND (comp_price - COALESCE(comp_coupon_discount, 0)) / NULLIF(fk_price_post_coupon, 0) < 0.99 THEN "AI_Comp"
            ELSE "Parity"
        END AS fsn_coupon_landscape

    FROM bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact AS a

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod
        ON prod.product_id = a.fsn

    LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact AS b  
        ON CAST(b.date_dim_key AS string) = a.date_key

    LEFT JOIN bmp_brands bmp 
        ON LOWER(a.brand) = LOWER(bmp.brand) 
        AND LOWER(a.analytic_super_category) = LOWER(bmp.analytic_super_category)

    LEFT JOIN (
        SELECT
            product_id,
            order_date_key,
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
        GROUP BY product_id, order_date_key
    ) AS sales
        ON a.fsn = sales.product_id
        AND CAST(a.date_key AS int64) = sales.order_date_key

    WHERE (CAST(date_key AS int64) BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND (
            (lower(competitor) IN ("ai") AND ci_business_unit NOT IN ("BGM(Books)", "Electronics"))
            OR
            (lower(competitor) IN ("myntra") AND ci_business_unit IN ("lifestyle-Non_Apparel","lifestyle-Apparel"))
        )
    ) AS a

LEFT JOIN pareto_verticals pv
    ON LOWER(a.analytic_super_category) = LOWER(pv.analytic_super_category)
    AND LOWER(a.analytic_vertical) = LOWER(pv.analytic_vertical)

GROUP BY
    a.order_date_key,
    a.analytic_business_unit,
    a.analytic_super_category,
    a.analytic_vertical,
    a.brand, 
    a.branded_flag,
    a.is_alpha_seller,
    a.price_bucket

    
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
msg['Subject'] = f'Myntra/AZ PI CI Daily Export — {today_str}'


body = (
   f'Automated daily Myntra/AZ PI CI export.\n\n'
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