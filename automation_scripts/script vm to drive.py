import os
import sys
import logging
import datetime

from oauth2client.service_account import ServiceAccountCredentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

sys.path.extend(['/home/siddhantsar.vc'])
from qaas_api import QaasAPI

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# ============================================================
# QaaS CONFIG
# ============================================================
QAAS_CLIENT_ID = 'analytics-da-qaas'
QAAS_CLIENT_SECRET = 'dR9TxRq6bJZYr623y9KmdhZoQBIgsKoMz13q2kYCAw+bZ8NA'
QAAS_RH_NODE_ID = 'central-analytics-t'
QAAS_TOKEN_CACHE = '/home/siddhantsar.vc/token_cache.json'

# ============================================================
# DRIVE CONFIG
# ============================================================
SERVICE_ACCOUNT_FILE = '/home/siddhantsar.vc/shivankautomation.json'
DRIVE_FOLDER_ID = '1mKputiYaRTlRl7zXkCFEmckelJuAbNtE'
TMP_DIR = '/tmp/weeklymailer'

# ============================================================
# REPORTS — filename in Drive will be: <report_name>.csv
# ============================================================
REPORTS = [
    {
        'name': 'Meesho_PI_CI_Weekly_Mailer_1',
        'sql': """
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
    },
    {
        'name': 'Myntra_AZ_PI_CI_Weekly_Mailer_1',
        'sql': """
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
    },
    {
        'name': 'Price_drop_Weekly_Mailer_1',
        'sql': """
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
    },
    {
        'name': 'Instock_Weekly_mailer_1',
        'sql': """
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
    },
    {
        'name': 'Speed_Weekly_Mailer_1',
        'sql': """
SELECT
    sales.order_date_key AS order_date_key,
    sales.analytic_business_unit AS analytic_business_unit,
    sales.analytic_super_category AS analytic_super_category,
    sales.analytic_vertical AS analytic_vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END AS brand,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS brand_flag,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    CASE WHEN hyper.pincode IS NOT NULL THEN 'Serviceable' ELSE 'Non-Serviceable' END AS serviceability_status,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "301-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "501-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "1000+"
    END AS price_bucket,
    case
    when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\_alite\_%') or (lower(sales.source_facility_id) like '%\_al\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF'
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end as service_profile,
    SUM(sales.units) AS overall_units,
    SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
    SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
    SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
    SUM(CASE WHEN sales.sla_in_days <= 4 THEN 1 ELSE 0 END) AS d4_units,
    SUM(CASE WHEN sales.sla_in_days <= 6 THEN 1 ELSE 0 END) AS d6_units,
    SUM(rudata.ru_den) AS ru_den,
    SUM(rudata.ru_num) AS ru_num
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_cat
    ON sales.product_id = prod_cat.product_id
LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON CAST(sales.pincode AS STRING) = CAST(hyper.pincode AS STRING)
LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo
    ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
LEFT JOIN (
    SELECT
        brand,
        analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
) bmp
    ON LOWER(sales.brand) = LOWER(bmp.brand)
    AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
LEFT JOIN (
    SELECT
        ff.fulfill_item_unit_id,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2') THEN fulfill_item_unit_id END) AS ru_num,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2','N1','N2') THEN fulfill_item_unit_id END) AS ru_den
    FROM bigfoot_external_neo.scp_fulfillment__fulfillment_unit_hive_365_fact ff
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON ff.fulfill_item_product_id = cat.product_id
    WHERE (ff.fulfill_item_unit_order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND LOWER(cat.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    GROUP BY ff.fulfill_item_unit_id
) AS rudata
    ON sales.fulfill_item_unit_id = rudata.fulfill_item_unit_id
WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type != 'service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.is_shopsy_order = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND (sales.order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
GROUP BY
    sales.order_date_key,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
    CASE WHEN hyper.pincode IS NOT NULL THEN 'Serviceable' ELSE 'Non-Serviceable' END,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "301-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "501-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "1000+"
    END,
    case
    when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\_alite\_%') or (lower(sales.source_facility_id) like '%\_al\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF'
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end
        """
    },
    {
        'name': 'Sales_with_brand_Weekly_mailer_1',
        'sql': """
SELECT
    order_date_key,
    cat.analytic_business_unit AS business_unit,
    cat.analytic_super_category AS super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN cat.analytic_vertical ELSE 'Non Pareto Vertical' END AS vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END AS brand,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END AS diamond_mp_flag,
    CASE
        WHEN geo.city_tier IN ('Metro') THEN 'Metro'
        WHEN geo.city_tier IN ('Tier 1A', 'Tier 1B') THEN 'T1'
        WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+'
    END AS city_tier,
    geo.zone,
    CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END AS is_minutes_serviceable,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
    END AS price_bucket,
    SUM(gmv) AS gmv,
    SUM(units) AS units
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id
LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode
LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON cat.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON sales.pincode = hyper.pincode
LEFT JOIN (
    SELECT brand, analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
) bmp
    ON LOWER(sales.brand) = LOWER(bmp.brand)
    AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
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
    ON sales.analytic_super_category = pareto.analytic_super_category
    AND sales.analytic_vertical = pareto.analytic_vertical
WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
    AND sales.type != 'service'
    AND replacement_for_unit IS NULL
    AND exchange_for_unit IS NULL
    AND is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(cat.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND sales.is_shopsy_order = FALSE
    AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
GROUP BY
    order_date_key,
    cat.analytic_business_unit,
    cat.analytic_super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN cat.analytic_vertical ELSE 'Non Pareto Vertical' END,
    CASE
        WHEN geo.city_tier IN ('Metro') THEN 'Metro'
        WHEN geo.city_tier IN ('Tier 1A', 'Tier 1B') THEN 'T1'
        WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+'
    END,
    geo.zone,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
    END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END,
    CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END
        """
    },
    {
        'name': 'Sales_without_brand_Weekly_Mailer_1',
        'sql': """
SELECT
    order_date_key,
    cat.analytic_business_unit AS business_unit,
    cat.analytic_super_category AS super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN cat.analytic_vertical ELSE 'Non Pareto Vertical' END AS vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END AS diamond_mp_flag,
    CASE
        WHEN geo.city_tier IN ('Metro') THEN 'Metro'
        WHEN geo.city_tier IN ('Tier 1A', 'Tier 1B') THEN 'T1'
        WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+'
    END AS city_tier,
    geo.zone,
    CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END AS is_minutes_serviceable,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
    END AS price_bucket,
    SUM(gmv) AS gmv,
    SUM(units) AS units
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id
LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode
LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON cat.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON sales.pincode = hyper.pincode
LEFT JOIN (
    SELECT brand, analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
) bmp
    ON LOWER(sales.brand) = LOWER(bmp.brand)
    AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
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
    ON sales.analytic_super_category = pareto.analytic_super_category
    AND sales.analytic_vertical = pareto.analytic_vertical
WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
    AND sales.type != 'service'
    AND replacement_for_unit IS NULL
    AND exchange_for_unit IS NULL
    AND is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(cat.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND sales.is_shopsy_order = FALSE
    AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
GROUP BY
    order_date_key,
    cat.analytic_business_unit,
    cat.analytic_super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN cat.analytic_vertical ELSE 'Non Pareto Vertical' END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    CASE
        WHEN geo.city_tier IN ('Metro') THEN 'Metro'
        WHEN geo.city_tier IN ('Tier 1A', 'Tier 1B') THEN 'T1'
        WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+'
    END,
    geo.zone,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
    END,
    CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END
        """
    },
]


# ============================================================
# AUTHENTICATE GOOGLE DRIVE (same scope/pattern as Saksham's working script)
# ============================================================
scope = ["https://spreadsheets.google.com/feeds", "https://www.googleapis.com/auth/drive"]
creds = ServiceAccountCredentials.from_json_keyfile_name(SERVICE_ACCOUNT_FILE, scope)
service = build('drive', 'v3', credentials=creds)


# ============================================================
# HELPER: find existing file in folder so we can replace it
# ============================================================
def find_existing_file(filename, folder_id):
    q = f"name='{filename}' and '{folder_id}' in parents and trashed=false"
    res = service.files().list(
        q=q,
        fields='files(id,name)',
        supportsAllDrives=True,
        includeItemsFromAllDrives=True
    ).execute()
    files = res.get('files', [])
    return files[0] if files else None


# ============================================================
# MAIN
# ============================================================
os.makedirs(TMP_DIR, exist_ok=True)

saved = replaced = failed = 0

for report in REPORTS:
    name = report['name']
    sql = report['sql']
    filename = f'{name}.csv'
    local_path = os.path.join(TMP_DIR, filename)

    print(f'\n--- Running: {name} ---')

    # Step 1: run query and save CSV
    try:
        client = QaasAPI(
            QAAS_CLIENT_ID, QAAS_CLIENT_SECRET,
            rh_node_id=QAAS_RH_NODE_ID,
            enable_persistence=True,
            token_cache_path=QAAS_TOKEN_CACHE,
            max_retries=2, retry_interval=50,
        )
        df = client.run_and_get_dataframe(query=sql, source='BIGQUERY')
        client.close()
        print(f'  Query returned {len(df)} rows')
        df.to_csv(local_path, index=False)
    except Exception as e:
        print(f'  Query failed for {name}: {e}')
        failed += 1
        continue

    # Step 2: upload or replace in Drive (Saksham's pattern)
    try:
        media = MediaFileUpload(local_path, mimetype='text/csv', resumable=True)
        existing = find_existing_file(filename, DRIVE_FOLDER_ID)

        if existing:
            service.files().update(
                fileId=existing['id'],
                media_body=media,
                supportsAllDrives=True
            ).execute()
            print(f'  Replaced in Drive: {filename}')
            replaced += 1
        else:
            file_metadata = {
                'name': filename,
                'parents': [DRIVE_FOLDER_ID]
            }
            service.files().create(
                body=file_metadata,
                media_body=media,
                fields='id,name,webViewLink',
                supportsAllDrives=True
            ).execute()
            print(f'  Uploaded new to Drive: {filename}')
            saved += 1
    except Exception as e:
        print(f'  Upload failed for {name}: {e}')
        failed += 1
    finally:
        if os.path.exists(local_path):
            try:
                os.remove(local_path)
            except OSError as e:
                print(f'  Could not remove {local_path}: {e}')

print(f'\n=== DONE === New: {saved}, Replaced: {replaced}, Failed: {failed}')