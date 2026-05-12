WITH
    base_sales AS (
        SELECT
            sales.account_id,
            sales.order_date_key
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
            AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
            AND (sales.order_date_key BETWEEN 20250101 AND 20250831)
            AND sales.analytic_business_unit IN ('BGM')
            AND LOWER(sales.analytic_super_category) IN ('babycare')
            AND sales.is_shopsy_order = FALSE
    ),
    
    customer_cohorts AS (
        SELECT
            account_id,
            MIN(CAST(SUBSTR(CAST(order_date_key AS STRING), 1, 6) AS INT)) AS first_order_month
        FROM
            base_sales
        GROUP BY
            account_id
    )
    
-- 3. Final Calculation of M1R and M3R
SELECT
    -- M1R Calculation: (July Cohort retained in Aug) / (July Cohort size)
    CAST(COUNT(DISTINCT 
        CASE WHEN c.first_order_month = 202507 
             -- Check for *any* purchase in the retention month (Aug 2025)
             AND CAST(SUBSTR(CAST(s.order_date_key AS STRING), 1, 6) AS INT) = 202508 
        THEN c.account_id END
    ) AS DOUBLE) 
    / 
    NULLIF(COUNT(DISTINCT CASE WHEN c.first_order_month = 202507 THEN c.account_id END), 0) AS M1R,
    
    -- M3R Calculation: (May Cohort retained in JJA) / (May Cohort size)
    CAST(COUNT(DISTINCT 
        CASE WHEN c.first_order_month = 202505 
             -- Check for *any* purchase in the retention period (June, July, or Aug 2025)
             AND CAST(SUBSTR(CAST(s.order_date_key AS STRING), 1, 6) AS INT) IN (202506, 202507, 202508)
        THEN c.account_id END
    ) AS DOUBLE) 
    / 
    NULLIF(COUNT(DISTINCT CASE WHEN c.first_order_month = 202505 THEN c.account_id END), 0) AS M3R

FROM
    customer_cohorts c
INNER JOIN
    base_sales s ON c.account_id = s.account_id;