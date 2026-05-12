WITH Sept_Cohort AS (
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
        AND LOWER(sales.marketplace_id) IN ('flipkart')
        AND (sales.order_date_key BETWEEN 20250901 AND 20250930)
        AND sales.analytic_business_unit IN ('Home')
        AND sales.is_shopsy_order = FALSE
),
Oct_Nov_Dec_Buyers AS (
    SELECT DISTINCT
        sales.account_id
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN
        fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
        ON sales.analytic_vertical = hl.analytic_vertical
        AND LOWER(hl.bu_final) IN ('bgm')
    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND LOWER(sales.marketplace_id) IN ('flipkart')
        AND (sales.order_date_key BETWEEN 20251001 AND 20251204)
        AND sales.analytic_business_unit IN ('Home')
        AND sales.is_shopsy_order = FALSE
)
SELECT
    COUNT(t2.account_id) / COUNT(t1.account_id) AS repeat_purchase_rate_decimal
FROM
    Sept_Cohort t1
LEFT JOIN
    Oct_Nov_Dec_Buyers t2
    ON t1.account_id = t2.account_id;