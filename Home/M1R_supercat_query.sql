SELECT 
   YEAR(DATE_ADD(base.month, 1)) AS year,
   MONTH(DATE_ADD(base.month, 1)) AS month,
   CAST(DATE_ADD(base.month, 1) AS DATE) AS month_begin_date,
   base.analytic_super_category,
   COUNT(DISTINCT base.account_id) AS base,
   COUNT(DISTINCT CASE WHEN ret.analytic_business_unit = 'Home' AND ret.analytic_super_category = base.analytic_super_category THEN ret.account_id END) AS home_repear

FROM (
    SELECT  
        sales.account_id,
        sales.analytic_super_category,
        TO_DATE(LAST_DAY(order_date_time)) AS month

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE 
        LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND type = 'physical'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie = FALSE
        AND marketplace_id = 'FLIPKART'
        AND LOWER(analytic_business_unit) = 'home'
        AND is_shopsy_order = FALSE
        AND order_date_key BETWEEN 20241201 AND 20251030

    GROUP BY 
        sales.account_id,
        sales.analytic_super_category,
        TO_DATE(LAST_DAY(order_date_time))
) base

LEFT JOIN (
    SELECT 
        sales.account_id,
        analytic_business_unit,
        sales.analytic_super_category,
        TO_DATE(LAST_DAY(order_date_time)) AS month

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE 
        LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND type = 'physical'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie = FALSE
        AND marketplace_id = 'FLIPKART'
        AND is_shopsy_order = FALSE
        AND order_date_key BETWEEN 20241201 AND 20251030

    GROUP BY  
        sales.account_id,
        analytic_business_unit,
        sales.analytic_super_category,
        TO_DATE(LAST_DAY(order_date_time))
) ret
ON base.account_id = ret.account_id
AND months_between(ret.month, base.month) = 1
AND ret.analytic_super_category = base.analytic_super_category

GROUP BY 
   YEAR(DATE_ADD(base.month, 1)),
   MONTH(DATE_ADD(base.month, 1)),
   CAST(DATE_ADD(base.month, 1) AS DATE),
   base.analytic_super_category