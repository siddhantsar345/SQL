SELECT
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    sales.analytic_business_unit,

    sum(sales.gmv) as total_gmv,
    sum(sales.units) as total_units,
    COUNT(DISTINCT sales.account_id) AS total_unique_accounts,

    COUNT(DISTINCT CASE WHEN UPPER(demo.gender) = 'MALE' THEN sales.account_id END) AS male_accounts,
    COUNT(DISTINCT CASE WHEN UPPER(demo.gender) = 'FEMALE' THEN sales.account_id END) AS female_accounts,

    COUNT(DISTINCT CASE WHEN c.new_cust_flag = 1 THEN sales.account_id END) AS NN_accounts,
    COUNT(DISTINCT CASE WHEN c.new_cust_flag <> 1 AND c.new_to_bu = 1 THEN sales.account_id END) AS on_customers,
    COUNT(DISTINCT CASE WHEN c.new_cust_flag = 0 AND c.new_to_bu = 0 THEN sales.account_id END) AS OO_accounts,

    COUNT(DISTINCT CASE WHEN sales.city_tier IN ('Tier 2') THEN sales.account_id END) AS tier_2_accounts,
    COUNT(DISTINCT CASE WHEN sales.city_tier IN ('Tier 3 & Others') THEN sales.account_id END) AS tier_3_plus_accounts,
    COUNT(DISTINCT CASE WHEN sales.city_tier IN ('Metro', 'Tier 1A') THEN sales.account_id END) AS mt1_accounts,

    COUNT(DISTINCT CASE WHEN geo.zone = 'NORTH' THEN sales.account_id END) AS north_accounts,
    COUNT(DISTINCT CASE WHEN geo.zone = 'SOUTH' THEN sales.account_id END) AS south_accounts,
    COUNT(DISTINCT CASE WHEN geo.zone = 'EAST' THEN sales.account_id END) AS east_accounts,
    COUNT(DISTINCT CASE WHEN geo.zone = 'WEST' THEN sales.account_id END) AS west_accounts,

    COUNT(DISTINCT sales.order_external_id) * 1.0 / NULLIF(COUNT(DISTINCT sales.account_id), 0) as tpc,
    SUM(sales.units) * 1.0 / NULLIF(COUNT(DISTINCT sales.account_id), 0) AS upc,
    SUM(sales.gmv) * 1.0 / NULLIF(COUNT(DISTINCT sales.account_id), 0) AS spc,
    SUM(sales.units) * 1.0 / NULLIF(COUNT(DISTINCT sales.order_external_id), 0) AS U2O 


FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

LEFT JOIN bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact demo
    ON sales.account_id = demo.account_id

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'home'

LEFT JOIN (
    SELECT 
        order_item_id, 
        MAX(new_cust_flag) as new_cust_flag, 
        MAX(new_to_bu) as new_to_bu
    FROM bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
    WHERE approve_date_key >= 20260301 
      AND approve_date_key <= CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE, 1), 'yyyyMMdd') AS INT)
    GROUP BY order_item_id
) c ON c.order_item_id = sales.order_item_id

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key >= 20260301 
    AND sales.order_date_key <= CAST(DATE_FORMAT(DATE_SUB(CURRENT_DATE, 1), 'yyyyMMdd') AS INT)
    AND LOWER(sales.analytic_business_unit) = 'home'

GROUP BY
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    sales.analytic_business_unit;