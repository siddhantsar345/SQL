SELECT 
   base.week_begin_date AS cohort_week,
   COUNT(DISTINCT base.account_id) AS base_users,
   COUNT(DISTINCT ret.account_id) AS fk_m1_repeat_users,
   COUNT(DISTINCT CASE WHEN LOWER(ret.analytic_business_unit) = 'home' THEN ret.account_id END) AS home_m1_repeat_users
FROM
    (
    SELECT
        sales.account_id,
        wd.week_begin_date
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
        ON sales.order_date_key = wd.date_dim_key
    WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND type != 'service'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie = FALSE
        AND marketplace_id IN ('FLIPKART')
        AND LOWER(analytic_business_unit) IN ('home')
        AND is_shopsy_order = FALSE
        AND order_date_key BETWEEN 20260320 AND 20260329
    GROUP BY 
        sales.account_id,
        wd.week_begin_date
    ) base
LEFT JOIN
    (
    SELECT 
        sales.account_id,
        to_date(sales.order_date_time) as order_date,
        sales.analytic_business_unit
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND type != 'service'
        AND is_freebie = FALSE
        AND marketplace_id IN ('FLIPKART')
        AND is_shopsy_order = FALSE
        AND order_date_key >= 20251101 
    ) ret
    ON base.account_id = ret.account_id
    AND ret.order_date >= DATE_SUB(base.week_begin_date, 31)
    AND ret.order_date <= DATE_SUB(base.week_begin_date, 1)
GROUP BY 
   base.week_begin_date