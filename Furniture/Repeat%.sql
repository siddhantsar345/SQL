--- 4) Repeat % - how many customers repeat purchases at furniture, SC, and vertical cut as well in 3,6,12 month intervals. --

--M3R--

WITH Base_Cohort AS (
    SELECT DISTINCT
        sales.account_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical
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
        AND sales.order_date_key BETWEEN 20250501 AND 20250531
),
Retention_Cohort AS (
    SELECT DISTINCT
        sales.account_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical
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
        AND sales.order_date_key BETWEEN 20250601 AND 20250831
)
SELECT
    t1.analytic_business_unit AS BU,
    t1.analytic_super_category AS SC,
    t1.analytic_vertical AS Vertical,
    COUNT(DISTINCT t1.account_id) AS total_base_buyers,
    COUNT(DISTINCT t2.account_id) AS repeat_buyers_m3,
    ROUND(100.0 * COUNT(DISTINCT t2.account_id) / COUNT(DISTINCT t1.account_id), 2) AS repeat_percentage
FROM
    Base_Cohort t1
LEFT JOIN
    Retention_Cohort t2
    ON t1.account_id = t2.account_id
    AND t1.analytic_business_unit = t2.analytic_business_unit
    AND t1.analytic_super_category = t2.analytic_super_category
    AND t1.analytic_vertical = t2.analytic_vertical
GROUP BY 1, 2, 3


--M6R--

WITH Base_Cohort AS (
    SELECT DISTINCT
        sales.account_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical
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
        AND sales.order_date_key BETWEEN 20250501 AND 20250531
),
Retention_Cohort AS (
    SELECT DISTINCT
        sales.account_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical
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
        AND sales.order_date_key BETWEEN 20250601 AND 20251130
)
SELECT
    t1.analytic_business_unit AS BU,
    t1.analytic_super_category AS SC,
    t1.analytic_vertical AS Vertical,
    COUNT(DISTINCT t1.account_id) AS total_base_buyers,
    COUNT(DISTINCT t2.account_id) AS repeat_buyers_m6,
    ROUND(100.0 * COUNT(DISTINCT t2.account_id) / COUNT(DISTINCT t1.account_id), 2) AS repeat_percentage
FROM
    Base_Cohort t1
LEFT JOIN
    Retention_Cohort t2
    ON t1.account_id = t2.account_id
    AND t1.analytic_business_unit = t2.analytic_business_unit
    AND t1.analytic_super_category = t2.analytic_super_category
    AND t1.analytic_vertical = t2.analytic_vertical
GROUP BY 1, 2, 3


-- M12R --


WITH Base_Cohort AS (
    SELECT DISTINCT
        sales.account_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical
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
        AND sales.order_date_key BETWEEN 20250101 AND 20250131
),
Retention_Cohort AS (
    SELECT DISTINCT
        sales.account_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical
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
        AND sales.order_date_key BETWEEN 20250201 AND 20260131
)
SELECT
    t1.analytic_business_unit AS BU,
    t1.analytic_super_category AS SC,
    t1.analytic_vertical AS Vertical,
    COUNT(DISTINCT t1.account_id) AS total_base_buyers,
    COUNT(DISTINCT t2.account_id) AS repeat_buyers_m12,
    ROUND(100.0 * COUNT(DISTINCT t2.account_id) / COUNT(DISTINCT t1.account_id), 2) AS repeat_percentage
FROM
    Base_Cohort t1
LEFT JOIN
    Retention_Cohort t2
    ON t1.account_id = t2.account_id
    AND t1.analytic_business_unit = t2.analytic_business_unit
    AND t1.analytic_super_category = t2.analytic_super_category
    AND t1.analytic_vertical = t2.analytic_vertical
GROUP BY 1, 2, 3