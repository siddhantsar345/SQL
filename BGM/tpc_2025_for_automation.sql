SELECT 
    EXTRACT(YEAR FROM DATE(month_begin_date)) AS year1,
    EXTRACT(MONTH FROM DATE(month_begin_date)) AS month1,
    month_begin_date,
    COUNT(DISTINCT account_id) AS total_customers,

    COUNT(DISTINCT CASE WHEN fk_orders = 0 OR fk_orders IS NULL THEN account_id END) AS tpc_0_customers,
    COUNT(DISTINCT CASE WHEN fk_orders <= 3 AND fk_orders > 0 THEN account_id END) AS tpc_1_3_customers,
    COUNT(DISTINCT CASE WHEN fk_orders <= 7 AND fk_orders > 3 THEN account_id END) AS tpc_4_7_customers,
    COUNT(DISTINCT CASE WHEN fk_orders <= 12 AND fk_orders > 7 THEN account_id END) AS tpc_8_12_customers,
    COUNT(DISTINCT CASE WHEN fk_orders <= 29 AND fk_orders > 12 THEN account_id END) AS tpc_13_29_customers,
    COUNT(DISTINCT CASE WHEN fk_orders >= 30 THEN account_id END) AS tpc_30_plus_customers,
    COUNT(DISTINCT CASE WHEN bgm_orders = 0 OR bgm_orders IS NULL THEN account_id END) AS bgm_tpc_0_customers,
    COUNT(DISTINCT CASE WHEN bgm_orders = 1 THEN account_id END) AS bgm_tpc_1_customers,
    COUNT(DISTINCT CASE WHEN bgm_orders <= 3 AND bgm_orders > 1 THEN account_id END) AS bgm_tpc_2_3_customers,
    COUNT(DISTINCT CASE WHEN bgm_orders <= 5 AND bgm_orders > 3 THEN account_id END) AS bgm_tpc_4_5_customers,
    COUNT(DISTINCT CASE WHEN bgm_orders >= 6 THEN account_id END) AS bgm_tpc_6_plus_customers
FROM
    (
    SELECT 
        base.month_begin_date,
        base.account_id,
        COUNT(DISTINCT fk.order_external_id) AS fk_orders,
        COUNT(DISTINCT CASE WHEN fk.analytic_business_unit = 'BGM' THEN order_external_id END) AS bgm_orders
    FROM
        (
        SELECT
            dates.month_begin_date,
            bgm.account_id
        FROM 
            (
            SELECT 
                month_begin_date
            FROM bigfoot_external_neo.scp_oms__date_dim_fact
            WHERE date_dim_key BETWEEN 20250101 AND CAST(CONCAT('2025', FORMAT_DATE('%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))) AS INT64)
            GROUP BY 1
            ) dates
        LEFT JOIN
            (
            SELECT 
                account_id,
                dates.month_begin_date
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN bigfoot_external_neo.scp_oms__date_dim_fact dates
                ON sales.order_date_key = dates.date_dim_key
            WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
              AND type IN ('physical')
              AND replacement_for_unit IS NULL
              AND exchange_for_unit IS NULL
              AND is_freebie = FALSE
              AND marketplace_id IN ('FLIPKART')
              AND LOWER(analytic_business_unit) IN ('bgm')
              AND is_shopsy_order = FALSE
              AND sales.order_date_key BETWEEN 20250101 AND CAST(CONCAT('2025', FORMAT_DATE('%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))) AS INT64)
            GROUP BY 1, 2
            ) bgm
            ON bgm.month_begin_date = dates.month_begin_date
        GROUP BY 1, 2
        ) base
    LEFT JOIN
        (
        SELECT 
            account_id,
            order_date_time,
            order_external_id,
            analytic_business_unit
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact 
        WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
          AND type IN ('physical')
          AND replacement_for_unit IS NULL
          AND exchange_for_unit IS NULL
          AND is_freebie = FALSE
          AND marketplace_id IN ('FLIPKART')
          AND is_shopsy_order = FALSE
          AND order_date_key >= 20230101 
        GROUP BY 1, 2, 3, 4
        ) fk
        ON base.account_id = fk.account_id
        AND DATE(fk.order_date_time) BETWEEN DATE_SUB(DATE(base.month_begin_date), INTERVAL 366 DAY) 
         AND DATE_SUB(DATE(base.month_begin_date), INTERVAL 1 DAY)
    GROUP BY 1, 2
    ) base2
GROUP BY 1, 2, 3
ORDER BY month_begin_date;