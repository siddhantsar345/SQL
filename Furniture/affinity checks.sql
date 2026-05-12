WITH jan_mar_small_furn_cohort AS (
    SELECT
        SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS cohort_month,
        sales.account_id,
        CASE
            WHEN c.new_cust_flag = 1 THEN 'NN'
            WHEN c.new_to_bu = 1 THEN 'ON'
            ELSE 'OO'
        END AS customer_segment
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN (
        SELECT 
            order_item_id, 
            MAX(new_cust_flag) as new_cust_flag, 
            MAX(new_to_bu) as new_to_bu
        FROM bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact
        WHERE approve_date_key BETWEEN 20250101 AND 20250331
        GROUP BY 1
    ) c ON c.order_item_id = sales.order_item_id
    WHERE         
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND lower(sales.analytic_business_unit) IN ('furniture')
        AND lower(sales.analytic_super_category) IN ('smallfurniture')
        AND (sales.order_date_key BETWEEN 20250101 AND  20250331)
        AND (c.new_cust_flag = 1 OR c.new_to_bu = 1)
        AND sales.is_shopsy_order = FALSE
    GROUP BY 1, 2, 3
),
affinity_check AS (
    SELECT DISTINCT 
    f.account_id
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact f
    INNER JOIN jan_mar_small_furn_cohort base ON f.account_id = base.account_id
    WHERE
        LOWER(f.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND f.type  = 'physical'
        AND f.replacement_for_unit IS NULL
        AND f.exchange_for_unit IS NULL
        AND f.is_freebie = FALSE
        AND f.marketplace_id IN ('FLIPKART')
        AND lower(f.analytic_business_unit) IN ('furniture')
        AND lower(f.analytic_super_category) IN ('largefurniture')
        AND (f.order_date_key BETWEEN 20250401 AND  20251231)
        AND f.is_shopsy_order = FALSE
)
SELECT
    base.cohort_month,
    base.customer_segment,
    COUNT(DISTINCT base.account_id) AS jan_mar_small_furn_cohort,
    COUNT(DISTINCT aff.account_id) AS bought_large_furn_later,
    ROUND(COUNT(DISTINCT aff.account_id) * 100.0 / COUNT(DISTINCT base.account_id), 2) AS affinity_percentage
FROM jan_mar_small_furn_cohort base
LEFT JOIN affinity_check aff ON base.account_id = aff.account_id
GROUP BY 1,2