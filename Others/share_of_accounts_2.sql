SELECT
    lockin_category,
    COUNT(account_id) AS total_accounts,
    COUNT(account_id) * 100.0 / SUM(COUNT(account_id)) OVER() AS share_percent
FROM
    (
        SELECT
            base.account_id,
            CASE
                WHEN sales.lockin_context = 'VIP_ACTIVE' THEN 'VIP'
                WHEN sales.lockin_context IN ('PREMIUM_ACTIVE', 'CLASSIC_ACTIVE', 'DEFAULT_ACTIVE') THEN 'Plus'
                ELSE 'Others'
            END AS lockin_category
        FROM
            adhoc_ttl_90days.homedecor_on_test_till_16th_sep2025 base
        LEFT JOIN
            bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            ON base.account_id = sales.account_id
        WHERE
            rand() <= 0.9
            AND LOWER(sales.status) IN (
            'in_progress', 'undelivered', 'completed', 'delivered', 
            'approved', 'shipped', 'ready_to_ship', 'returned', 
            'return_requested', 'activated')
            AND sales.type != 'service'
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.analytic_business_unit IN ('Home')
            AND order_date_key between 20250718 and 20250918
    ) AS categorized_accounts
GROUP BY
    lockin_category;