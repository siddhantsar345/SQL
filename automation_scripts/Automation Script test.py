import jaydebeapi
import os
import subprocess
import smtplib, ssl
import csv
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import datetime
import readline
import pandas as pd
import numpy as np
import pygsheets as pg
import sys
#sys.path.extend()
#from gcp_connect import GCPConn
#gcp = GCPConn(username='siddhantsar.vc', password='Ommedhanshi$0@5892')
output = subprocess.check_output(['bash', '-c', 'echo $CLASSPATH:/usr/local/fdp-infra-hive/lib/*'])
os.environ['CLASSPATH'] = '/usr/local/fdp-infra-hive/lib/*'
url = ("jdbc:hive2://fkp-fdp-galaxy-sun-zkjn-0001.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0002.c.fkp-fdp-galaxy.internal:2181,fkp-fdp-galaxy-sun-zkjn-0003.c.fkp-fdp-galaxy.internal:2181/default;transportMode=http;httpPath=cliservice;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=fkp-fdp-galaxy-hive3-hs2-agni;hive.client.read.socket.timeout=300?hive.metastore.client.socket.timeout=180;hive.server.tcp.keepalive=true;hive.server.read.socket.timeout=300")
conn = jaydebeapi.connect("org.apache.hive.jdbc.HiveDriver", url,{'user': "siddhantsar.vc", 'password': "Ommedhanshi$0@5892"})
cursor = conn.cursor()
cursor.execute("ADD JAR /usr/share/fk-bigfoot-hivejsonserde/json-serde-1.3-SNAPSHOT-jar-with-dependencies.jar")
cursor.execute("ADD JAR /usr/share/fk-bigfoot-dimlookup/dimlookup-hive-udf-1.0-SNAPSHOT-jar-with-dependencies.jar")
cursor.execute("ADD JAR gs://fkpdp-mhosy-2nig-1a5d-systemlibs/libraries/hive/jars/hive-udfs-1.0-SNAPSHOT.jar")
cursor.execute("CREATE TEMPORARY FUNCTION lookup as 'com.flipkart.bigfoot.dimlookup.udf.HiveLookupUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION arrToString as 'com.flipkart.fdp.CustomCaster'")
cursor.execute("CREATE TEMPORARY FUNCTION lookupkey as 'com.flipkart.bigfoot.dimlookup.udf.HiveKeyGeneratorUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION lookup_date as 'com.flipkart.bigfoot.dimlookup.udf.DateLookupUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION lookup_time as 'com.flipkart.bigfoot.dimlookup.udf.TimeLookupUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION aggregate_filter as 'com.flipkart.bigfoot.dimlookup.udf.AggregateConditionUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION aggregate as 'com.flipkart.bigfoot.dimlookup.udf.AggregateUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION ISOToSqlTs as 'com.flipkart.bigfoot.dimlookup.udf.DateISOToSqlUDF'")
cursor.execute("CREATE TEMPORARY FUNCTION business_date_diff as 'com.flipkart.bigfoot.dimlookup.udf.BusinessDayDiffUDF'")
cursor.execute("set mapreduce.input.fileinputformat.input.dir.recursive=true")
viewed_sla_query = """
SELECT

    marketplace AS marketplace,
    analytic_business_unit AS analytic_business_unit,
    analytic_super_category AS analytic_super_category,
    analytic_vertical AS analytic_vertical,
    is_alpha_seller AS is_alpha_seller,
    listing_id, 
    seller_id,
    
    kam_nkam_flag,
    branded_flag,
    rc_branded_flag,
    winter_vertical_flag,

    brand, 
    cms_vertical, 
    mop_flag, 
    brand_exclusion_flag, 
    codb_increase_decrease,
        sum(bau_gmv) as bau_gmv,

    SUM(input_bau_weighted_asp) AS input_bau_weighted_asp,
    SUM(input_fes_weighted_asp) AS input_fes_weighted_asp,
    SUM(output_bau_weighted_asp) AS output_bau_weighted_asp,
    SUM(output_fes_weighted_asp) AS output_fes_weighted_asp,

sum(input_bau_weighted_fsp) as input_bau_weighted_fsp,
sum(input_fes_weighted_fsp) as input_fes_weighted_fsp,
sum(outut_bau_weighted_fsp) as outut_bau_weighted_fsp,
sum(output_fes_weighted_fsp) as output_fes_weighted_fsp,
0 as dw,

sum(bau_listing_price) as bau_listing_price,
sum(bau_units) as bau_units        ,
sum(festive_listing_price) as festive_listing_price ,
sum(fes_units) as fes_units,
sum(bau_listing_price)/sum(bau_units) as FSP_BAU,
sum(festive_listing_price)/sum(fes_units) as FSP_Fest,
case when sum(festive_listing_price)/sum(fes_units) > sum(bau_listing_price)/sum(bau_units)then "Inc" else "Dec" end as FSP_Inc_Dec_Flag,

lookup_date(date_sub(current_date(),1)) as festive_day


FROM
(
SELECT
    bau.marketplace,
    bau.analytic_business_unit AS analytic_business_unit,
    bau.analytic_super_category AS analytic_super_category,
    bau.analytic_vertical AS analytic_vertical,
    bau.is_alpha_seller AS is_alpha_seller,
    bau.kam_nkam_flag AS kam_nkam_flag,
    bau.branded_flag AS branded_flag,
    bau.rc_branded_flag AS rc_branded_flag,
    bau.winter_vertical_flag AS winter_vertical_flag,
    bau.product_id AS product_id,
    bau.listing_id AS listing_id,
    bau.seller_id as seller_id, 
    fes.order_date_key AS order_date_key,
    bau.gmv / bau.units AS bau_price_point,
    brand, 
    cms_vertical, 
    mop_flag, 
    brand_exclusion_flag, 
    codb_increase_decrease,
  
  bau.gmv as bau_gmv,

    (bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
    (fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
    (bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
    (fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp,

     
    (bau.lp/bau.units)*bau.units as input_bau_weighted_fsp,
    (fes.lp/fes.units)*bau.units as input_fes_weighted_fsp,
    (bau.lp/bau.units)*fes.units as outut_bau_weighted_fsp,
    (fes.lp/fes.units)*fes.units as output_fes_weighted_fsp,
  
  bau.lp as       bau_listing_price, 
  bau.units as bau_units, 
  fes.lp as         festive_listing_price, 
  fes.units as   fes_units
   

FROM

(
SELECT
    sales.marketplace_id AS marketplace,
    cat.analytic_business_unit,
    cat.analytic_super_category,
    cat.analytic_vertical,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END AS is_alpha_seller,
    CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,
    CASE WHEN LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    CASE WHEN bgm_zc.brand IS NOT NULL THEN 'RC - Branded' ELSE 'RC - Unbranded' END AS rc_branded_flag,
    CASE WHEN bgm_wv.analytic_vertical IS NOT NULL THEN 'Winter Vertical' ELSE 'Rest' END AS winter_vertical_flag,

    b.brand, 
    b.analytic_vertical as cms_vertical, 
    b.mop_flag,
    b.brand_exclusion_flag,
    b.codb_increase_decrease,

    sales.product_id,
    sales.listing_id,
    sales.seller_id,

    SUM(units)/11 AS units,
    SUM(gmv)/11 AS gmv,
    (SUM(listing_price)+ SUM(coalesce((cast(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) as float)),0)))  /11 as lp
  

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

left join 

fdp_uploads.ds_fkint_analytics_cdo_new_rc_impact_flags_exclusion_and_codb_increase_decrease_and_mop1_fact_1_0 as b
on 

lower(b.business_unit)=lower(sales.analytic_business_unit) and 
lower(b.analytic_super_category)=lower(sales.analytic_super_category) and
lower(b.analytic_vertical)=lower(sales.cms_vertical) and
lower(b.brand)=lower(sales.brand)


LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
      ON sales.product_id = cat.product_id

LEFT JOIN
    (
    SELECT
      seller_id,
      MIN(managed_by) AS owner
      FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0
      GROUP BY
      seller_id
    ) AS t5
    ON sales.seller_id = t5.seller_id

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_bgm_zc_branded_list_1_0 bgm_zc
    ON LOWER(sales.brand) = LOWER(bgm_zc.brand)

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_bgm_winter_verticals_list_1_0 bgm_wv
    ON LOWER(sales.analytic_vertical) = LOWER(bgm_wv.analytic_vertical)

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm')
    AND sales.marketplace_id = 'HYPERLOCAL'

LEFT JOIN
    (
    SELECT
        LOWER(analytic_super_category) AS analytic_super_category,
        LOWER(brand) AS brand,
        MIN(branded_flag) AS branded_flag,
        MIN(brand_type) AS brand_type,
        MIN(brand_tier) AS brand_tier,
        MIN(is_priority_brand) AS is_priority_brand
    FROM
        fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
    GROUP BY
        LOWER(analytic_super_category),
        LOWER(brand)
    ) AS bgm_b
    ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
    AND LOWER(sales.brand) = LOWER(bgm_b.brand)

WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type != 'service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART'))
    AND sales.is_shopsy_order = FALSE
    AND sales.analytic_business_unit IN ('BGM')
    AND order_date_key BETWEEN 20251120 AND 20251130
    and is_alpha_seller <> TRUE

GROUP BY
    sales.marketplace_id ,
    cat.analytic_business_unit,
    cat.analytic_super_category,
    cat.analytic_vertical,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END ,
    CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END ,
    sales.product_id,
    sales.listing_id,
     sales.seller_id,

     b.brand, 
    b.analytic_vertical ,
    b.mop_flag,
    b.brand_exclusion_flag,
    b.codb_increase_decrease,

    CASE WHEN LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded' ELSE 'Unbranded' END,
    CASE WHEN bgm_zc.brand IS NOT NULL THEN 'RC - Branded' ELSE 'RC - Unbranded' END,
    CASE WHEN bgm_wv.analytic_vertical IS NOT NULL THEN 'Winter Vertical' ELSE 'Rest' END
) AS bau



INNER JOIN
(
SELECT
sales.listing_id,
order_date_key,
SUM(units) AS units,
SUM(gmv) AS gmv,
  (SUM(listing_price)+ SUM(coalesce((cast(regexp_extract(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) as float)),0)))  as lp

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
    ON sales.order_date_key = date_map.dates_current_year

WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
AND sales.type != 'service'
AND sales.replacement_for_unit IS NULL
AND sales.exchange_for_unit IS NULL
AND sales.is_freebie = FALSE
AND (sales.marketplace_id IN ('FLIPKART'))
AND sales.is_shopsy_order = FALSE
AND sales.analytic_business_unit IN ('BGM')
and is_alpha_seller <> TRUE
AND (order_date_key BETWEEN lookup_date(date_sub(current_date(),1)) AND 
lookup_date(date_sub(current_date(),1)))

GROUP BY
    sales.listing_id,
    order_date_key
) AS fes
ON bau.listing_id = fes.listing_id
  
  where bau.rc_branded_flag = 'RC - Branded'
  
) AS sub_pricing

GROUP BY
    marketplace,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    is_alpha_seller,
         listing_id, 
    seller_id,


    kam_nkam_flag,
    branded_flag,
    rc_branded_flag,
    winter_vertical_flag,
    brand, 
    cms_vertical, 
    mop_flag, 
    brand_exclusion_flag, 
    codb_increase_decrease,
    lookup_date(date_sub(current_date(),1))

"""
viewed_sla_query = viewed_sla_query.replace('\n', ' ')
viewed_sla_query = viewed_sla_query.replace('\t', ' ')
cursor.execute(viewed_sla_query)
# file_path = '/home/siddhantsar.vc/projects/price_drop.csv'
# gcp.query_to_csv(viewed_sla_query, output_path = file_path)
df = pd.DataFrame.from_records(cursor.fetchall(), columns=[i[0] for i in cursor.description])
df.to_csv('/home/siddhantsar.vc/projects/price_drop.csv',index=False)
# To paste in google sheet
gc = pg.authorize(service_file='/home/siddhantsar.vc/ShivankAutomation-fd5dab44a774.json')
gsheet = gc.open_by_key('1Njf1IlBoMq93cUObZ1TRXI7vMe0vnLM2XLT6LAqKOaY')
wks1 = gsheet.worksheet('title','Raw data')
# Clear the contents of the worksheet
wks1.clear()
df1 = pd.read_csv('/home/siddhantsar.vc/projects/price_drop.csv')
wks1.set_dataframe(df1, (1,1))