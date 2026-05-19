SELECT
    SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS month_key,
    sales.analytic_super_category,
    CASE 
        WHEN sales.gmv / sales.units > 0    AND sales.gmv / sales.units <= 200  THEN '0 - 200'
        WHEN sales.gmv / sales.units > 200  AND sales.gmv / sales.units <= 300  THEN '201 - 300'
        WHEN sales.gmv / sales.units > 300  AND sales.gmv / sales.units <= 500  THEN '301 - 500'
        WHEN sales.gmv / sales.units > 500  AND sales.gmv / sales.units <= 1000 THEN '501 - 1000'
        WHEN sales.gmv / sales.units > 1000 THEN '1001+'
    END AS price_bucket,


    SUM(sales.units) AS home_units,
    SUM(sales.gmv)   AS home_gmv,

    SUM(CASE WHEN sales.marketplace_id = 'FLIPKART' THEN sales.units END) AS flipkart_units,
    SUM(CASE WHEN sales.marketplace_id = 'FLIPKART' THEN sales.gmv   END) AS flipkart_gmv,

    SUM(CASE WHEN sales.marketplace_id = 'FLIPKART' 
              AND sales.is_alpha_seller = FALSE THEN sales.units END) AS mp_units,
    SUM(CASE WHEN sales.marketplace_id = 'FLIPKART' 
              AND sales.is_alpha_seller = FALSE THEN sales.gmv   END) AS mp_gmv,

    SUM(CASE WHEN sales.marketplace_id = 'HYPERLOCAL' THEN sales.units END) AS hl_units,
    SUM(CASE WHEN sales.marketplace_id = 'HYPERLOCAL' THEN sales.gmv   END) AS hl_gmv

FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
   AND LOWER(hl.bu_final) = 'home'

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (
        sales.marketplace_id = 'FLIPKART'
        OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL)
    )
    AND (
        sales.order_date_key BETWEEN 20250401 AND 20250518
        OR sales.order_date_key BETWEEN 20260401 AND 20260518
    )
    AND sales.analytic_business_unit = 'Home'
    AND sales.is_shopsy_order = FALSE

GROUP BY
    SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6),
    sales.analytic_super_category,
    CASE 
        WHEN sales.gmv / sales.units > 0    AND sales.gmv / sales.units <= 200  THEN '0 - 200'
        WHEN sales.gmv / sales.units > 200  AND sales.gmv / sales.units <= 300  THEN '201 - 300'
        WHEN sales.gmv / sales.units > 300  AND sales.gmv / sales.units <= 500  THEN '301 - 500'
        WHEN sales.gmv / sales.units > 500  AND sales.gmv / sales.units <= 1000 THEN '501 - 1000'
        WHEN sales.gmv / sales.units > 1000 THEN '1001+'
    END;