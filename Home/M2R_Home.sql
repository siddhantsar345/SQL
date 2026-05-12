WITH Jan_Cohort AS (
    SELECT DISTINCT
        sales.account_id
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        and lower(sales.marketplace_id) IN ('flipkart')
        AND (sales.order_date_key BETWEEN 20240101 AND 20240131)
        AND sales.analytic_business_unit IN ('Home')
        AND sales.is_shopsy_order = FALSE
),
Feb_March_Buyers AS (
    SELECT DISTINCT
        sales.account_id
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        and lower(sales.marketplace_id) IN ('flipkart')
        AND (sales.order_date_key BETWEEN 20240201 AND 20240331)
        AND sales.analytic_business_unit IN ('Home')
        AND sales.is_shopsy_order = FALSE
)
SELECT
    COUNT(t1.account_id) AS count_of_repeat_buyers
FROM
    Jan_Cohort t1
LEFT JOIN
    Feb_March_Buyers t2
    ON t1.account_id = t2.account_id
WHERE
    t2.account_id IS NOT NULL;