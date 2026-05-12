-- MP GST - adoption rate of MP GST  --
WITH Active_MP_Sellers AS (
    SELECT DISTINCT
        sales.seller_id,
        sales.analytic_business_unit,
        sales.analytic_super_category
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART') 
    AND sales.is_shopsy_order = FALSE
    AND lower(sales.analytic_business_unit) IN ('furniture')
    AND sales.is_alpha_seller = FALSE
    AND sales.order_date_key BETWEEN 20251201 AND 20251231
),
Post_Launch_Activity AS (
    SELECT 
        sales.seller_id,
        FLOOR(sales.order_date_key / 100) AS month_key,
        MAX(CASE WHEN sales.gst_applicable = TRUE THEN 1 ELSE 0 END) AS has_adopted_gst
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART') 
    AND sales.is_shopsy_order = FALSE
    AND lower(sales.analytic_business_unit) IN ('furniture')
    AND sales.is_alpha_seller = FALSE
    AND sales.order_date_key >= 20260101

GROUP BY 1, 2
)

SELECT
    t2.month_key,
    t1.analytic_business_unit AS Business_Unit,
    t1.analytic_super_category AS Super_Category,
    COUNT(DISTINCT t1.seller_id) AS total_baseline_sellers,
    COUNT(DISTINCT CASE WHEN t2.has_adopted_gst = 1 THEN t1.seller_id END) AS adopted_sellers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN t2.has_adopted_gst = 1 THEN t1.seller_id END) 
          / NULLIF(COUNT(DISTINCT t1.seller_id), 0), 2) AS adoption_rate
FROM
    Active_MP_Sellers t1
LEFT JOIN
    Post_Launch_Activity t2 ON t1.seller_id = t2.seller_id
WHERE 
    t2.month_key IS NOT NULL
GROUP BY 1, 2, 3



-- 2nd attempt --

WITH Active_MP_Sellers AS (
    SELECT DISTINCT
        sales.seller_id,
        sales.analytic_business_unit,
        sales.analytic_super_category
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART') 
    AND sales.is_shopsy_order = FALSE
    AND lower(sales.analytic_business_unit) IN ('furniture')
    AND sales.is_alpha_seller = FALSE
    AND sales.order_date_key BETWEEN 20251201 AND 20251231
),
Post_Launch_Activity AS (
    SELECT 
        sales.seller_id,
        SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS month_key,
        MAX(CASE WHEN sales.gst_applicable = TRUE THEN 1 ELSE 0 END) AS has_adopted_gst
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART') 
    AND sales.is_shopsy_order = FALSE
    AND lower(sales.analytic_business_unit) IN ('furniture')
    AND sales.is_alpha_seller = FALSE
    AND sales.order_date_key >= 20260101

GROUP BY 1, 2
)

SELECT
    t2.month_key,
    t1.analytic_business_unit AS Business_Unit,
    t1.analytic_super_category AS Super_Category,
    COUNT(DISTINCT t1.seller_id) AS total_baseline_sellers,
    COUNT(DISTINCT CASE WHEN t2.has_adopted_gst = 1 THEN t1.seller_id END) AS adopted_sellers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN t2.has_adopted_gst = 1 THEN t1.seller_id END) 
          / NULLIF(COUNT(DISTINCT t1.seller_id), 0), 2) AS adoption_rate
FROM
    Active_MP_Sellers t1
LEFT JOIN
    Post_Launch_Activity t2 ON t1.seller_id = t2.seller_id
WHERE 
    t2.month_key IS NOT NULL
GROUP BY 1, 2, 3