SELECT
   YEAR(DATE_ADD(base.month, 3)) AS year,
   MONTH(DATE_ADD(base.month, 3)) AS month,
   DATE_ADD(base.month, 3) AS month_begin_date,
   COUNT(DISTINCT base.account_id) AS base_month_buyers,
   COUNT(DISTINCT ret.account_id) AS fk_repeat_3_months,
   COUNT(DISTINCT CASE WHEN ret.analytic_business_unit = 'Home' THEN ret.account_id END) AS home_repeat_3_months

FROM
    (
    SELECT
        sales.account_id,
        TO_DATE(LAST_DAY(order_date_time)) AS month

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        and lower(sales.marketplace_id) IN ('flipkart')
        AND (sales.order_date_key BETWEEN 20251101 AND 20251204)
        AND sales.analytic_business_unit IN ('Home')
        AND sales.is_shopsy_order = FALSE
    GROUP BY
        sales.account_id,
        TO_DATE(LAST_DAY(order_date_time))
    ) base

LEFT JOIN
    (
    SELECT
        sales.account_id,
        analytic_business_unit,
        TO_DATE(LAST_DAY(order_date_time)) AS month

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        and lower(sales.marketplace_id) IN ('flipkart')
        AND (sales.order_date_key BETWEEN 20251101 AND 20251204)
        AND sales.analytic_business_unit IN ('Home')
        AND sales.is_shopsy_order = FALSE

    GROUP BY
        sales.account_id,
        analytic_business_unit,
        TO_DATE(LAST_DAY(order_date_time))
    ) ret
    ON base.account_id = ret.account_id
    AND MONTHS_BETWEEN(ret.month, base.month) = 3

GROUP BY
   YEAR(DATE_ADD(base.month, 3)),
   MONTH(DATE_ADD(base.month, 3)),
   DATE_ADD(base.month, 3)
ORDER BY
   month_begin_date;