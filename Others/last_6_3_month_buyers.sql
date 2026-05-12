--- TD: Large Appliances Buyers L6M, Home Buyers L3M, Furniture PPVs >2 ---
-- Last 3 months home buyers --


SELECT
    FORMAT_DATE(
        '%Y%m', 
        PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING))
    ) AS order_year_month,
    COUNT(DISTINCT sales.account_id) AS unique_home_buyers
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.marketplace_id) IN ('flipkart')
    AND sales.order_date_key BETWEEN 20250801 AND 20251125 
    AND LOWER(sales.analytic_business_unit) IN ('home')
    AND sales.is_shopsy_order = FALSE
GROUP BY
    order_year_month



--- Last 6 months large appliances buyers ---

SELECT
    FORMAT_DATE(
        '%Y%m', 
        PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING))
    ) AS order_year_month,
    COUNT(DISTINCT sales.account_id) AS unique_largeappliances_buyers
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.marketplace_id) IN ('flipkart')
    AND sales.order_date_key BETWEEN 20250801 AND 20251125 
    AND LOWER(sales.analytic_business_unit) IN ('largeappliances')
    AND sales.is_shopsy_order = FALSE
GROUP BY
    order_year_month