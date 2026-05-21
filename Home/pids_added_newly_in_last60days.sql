WITH pid_birth AS (
    SELECT 
        product_id,
        CAST(MIN(listing_created_on) AS DATE) AS pid_first_added_date
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
    GROUP BY 1
),

transacted_pids AS (
    SELECT DISTINCT 
        sales.product_id
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS sales
    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim AS prod_dim
        ON sales.product_id = prod_dim.product_id
    WHERE
        LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND sales.type != 'service'
        AND sales.category_id NOT IN (21726, 21651)
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id = 'FLIPKART'
        AND sales.is_shopsy_order = FALSE
        AND sales.order_date_key BETWEEN CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)) AS INT64) AND CAST(FORMAT_DATE('%Y%m%d', CURRENT_DATE()) AS INT64)
        AND LOWER(prod_dim.analytic_business_unit) = 'home'
)

SELECT
    COUNT(DISTINCT t.product_id) AS total_transacted_pids,
    COUNT(DISTINCT CASE 
                       WHEN b.pid_first_added_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY) 
                       THEN t.product_id 
                   END) AS pids_added_last_60_days

FROM transacted_pids t
LEFT JOIN pid_birth b
    ON t.product_id = b.product_id;