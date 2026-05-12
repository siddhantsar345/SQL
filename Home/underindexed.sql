WITH weekly_snapshot AS (
    SELECT 
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        MIN(wd.date_dim_key) as week_start_key,
        MAX(wd.date_dim_key) as report_date
    FROM bigfoot_external_neo.scp_oms__date_dim_fact wd
    WHERE wd.date_dim_key BETWEEN 20260301 AND 20260329
    GROUP BY 1, 2, 3
),

target_verticals AS (
    SELECT DISTINCT sc, vertical 
    FROM fdp_uploads.ds_fkint_analytics_cdo_underindexed_verticals_1_0
),

ai_listings_snapshot AS (
    SELECT 
        snap.week_begin_date,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        COUNT(DISTINCT CASE WHEN list_dim.final_atp > 0 THEN list_dim.listing_id END) as ai_listings
    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

    INNER JOIN weekly_snapshot snap 
        ON list_dim.process_date_key = snap.report_date

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim 
        ON list_dim.product_id = prod_dim.product_id

    INNER JOIN target_verticals tv
        ON prod_dim.analytic_super_category = tv.sc
        AND prod_dim.analytic_vertical = tv.vertical

    WHERE list_dim.marketplace_id = 'FLIPKART'
      AND LOWER(prod_dim.analytic_business_unit) IN ('furniture', 'home')
    GROUP BY 1, 2, 3
),

sales_metrics AS (
    SELECT
        snap.week_begin_date,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        COUNT(DISTINCT sales.listing_id) as trans_lid_count,
        SUM(sales.gmv) as total_gmv,
        SUM(sales.units) as sales_units

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    INNER JOIN weekly_snapshot snap 
        ON sales.order_date_key BETWEEN snap.week_start_key AND snap.report_date

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim as prod_dim 
        ON sales.product_id = prod_dim.product_id

    INNER JOIN target_verticals tv
        ON prod_dim.analytic_super_category = tv.sc
        AND sales.analytic_vertical = tv.vertical

    WHERE sales.marketplace_id = 'FLIPKART'
        AND LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type != 'service'
        AND sales.category_id NOT IN (21726, 21651)
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.is_shopsy_order = FALSE
        AND LOWER(prod_dim.analytic_business_unit) IN ('home', 'furniture')
    GROUP BY 1, 2, 3
),

new_selection AS (
    SELECT
        snap.week_begin_date,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        COUNT(DISTINCT list.listing_id) AS new_selection_listings,
        SUM(sales.gmv) AS new_selection_gmv

    FROM (
        SELECT listing_id, product_id,
               CAST(FORMAT_DATETIME('%Y%m%d', CAST(listing_created_on AS TIMESTAMP)) AS INT64) AS process_date_key
        FROM bigfoot_external_neo.sp_product__listing_hive_dim
        WHERE marketplace_id = 'FLIPKART'
    ) AS list

    INNER JOIN weekly_snapshot snap 
        ON list.process_date_key BETWEEN snap.week_start_key AND snap.report_date

    INNER JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim 
        ON list.product_id = prod_dim.product_id 

    INNER JOIN target_verticals tv
        ON prod_dim.analytic_super_category = tv.sc
        AND prod_dim.analytic_vertical = tv.vertical

    LEFT JOIN bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        ON list.listing_id = sales.listing_id
        AND sales.order_date_key BETWEEN snap.week_start_key AND snap.report_date

    WHERE LOWER(prod_dim.analytic_business_unit) IN ('home', 'furniture')
    GROUP BY 1, 2, 3
)


SELECT 
    sm.week_begin_date,
    snap.yearmo,
    snap.week_num_in_year,
    sm.analytic_business_unit,
    sm.analytic_super_category,
    ai.ai_listings,
    sm.trans_lid_count,
    sm.total_gmv,
    sm.sales_units,
    ns.new_selection_listings,
    COALESCE(ns.new_selection_gmv, 0) as new_selection_gmv

FROM sales_metrics sm

INNER JOIN weekly_snapshot snap 
    ON sm.week_begin_date = snap.week_begin_date

LEFT JOIN ai_listings_snapshot ai 
    ON  sm.week_begin_date = ai.week_begin_date
    AND sm.analytic_business_unit = ai.analytic_business_unit
    AND sm.analytic_super_category = ai.analytic_super_category

LEFT JOIN new_selection ns
    ON  sm.week_begin_date = ns.week_begin_date
    AND sm.analytic_business_unit = ns.analytic_business_unit
    AND sm.analytic_super_category = ns.analytic_super_category;