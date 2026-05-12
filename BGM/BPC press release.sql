---Q1. What is the year on year growth in beauty and personal care orders on Flipkart Minutes as per the above mentioned timeline? --- 

WITH existing_stores AS (
    SELECT DISTINCT business_zone
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE (order_date_key BETWEEN 20250301 AND 20250430)
    AND (order_date_key BETWEEN 20260101 AND 20260228)
    AND sales.marketplace_id = 'HYPERLOCAL' 
    AND hl.analytic_vertical IS NOT NULL
    AND LOWER(sales.analytic_business_unit) IN ('bgm')
    AND LOWER(sales.analytic_super_category) IN ('makeupfragrances', 'grooming')
)

SELECT
    SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS month,
    CASE 
        WHEN est.business_zone IS NOT NULL THEN 'Existing Store' 
        ELSE 'New Store' 
    END AS store_bucket,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
    SUM(sales.gmv) AS total_gmv,
    SUM(sales.units) AS total_units,
    COUNT(DISTINCT sales.order_external_id) AS order_count

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN existing_stores est
    ON sales.business_zone = est.business_zone

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'bgm'

WHERE 
    sales.order_date_key BETWEEN 20250301 AND 20260228
    AND LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL
    AND sales.is_shopsy_order = FALSE
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.analytic_business_unit) IN ('bgm')
    AND LOWER(sales.analytic_super_category) IN ('makeupfragrances', 'grooming')

GROUP BY 1, 2, 3, 4, 5



-- Q10. Which top 5 cities or pin codes are showing unexpected traction in essentials and hygiene categories, especially outside Tier 1 metros? (BPC) --

SELECT 
    sales.pincode,
    geo.city,
    SUM(sales.gmv) AS total_gmv,
    SUM(sales.units) AS total_units,
    COUNT(DISTINCT sales.order_external_id) AS order_count

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'bgm'

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
   ON geo.pincode = sales.pincode

WHERE 
    sales.order_date_key BETWEEN 20250301 AND 20260228
    AND sales.city_tier IN ('Tier 2', 'Tier 3 & Others')
    AND LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL
    AND sales.is_shopsy_order = FALSE
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.analytic_business_unit) IN ('bgm')
    AND LOWER(sales.analytic_super_category) IN ('makeupfragrances', 'grooming')

GROUP BY 1, 2
ORDER BY total_gmv DESC
LIMIT 5;


-- Q12. Which top 5 days or time slots in 2025 saw the highest spike in beauty or essentials orders, indicating on-demand or event-ready usage? ---
  

SELECT
    sales.order_date_key,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
    SUM(sales.units) AS total_units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'bgm'

WHERE
    sales.order_date_key BETWEEN 20250101 AND 20251231
    AND LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.marketplace_id = 'HYPERLOCAL' 
    AND hl.analytic_vertical IS NOT NULL
    AND sales.is_shopsy_order = FALSE
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.analytic_business_unit) IN ('bgm')
    AND LOWER(sales.analytic_super_category) IN ('makeupfragrances', 'grooming')

GROUP BY 
    sales.order_date_key,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical

ORDER BY 
    total_units DESC

LIMIT 5;



--  Q2. Within these, which top 5 SKUs drove the largest number of orders during the same period? (top 50 prod_ids/prod title for each vert - m-m), --
-- Q4. Which top 5 cities or pin codes showed the strongest growth in newer formats such as scalp serums, hybrid SPFs, or lip-and-cheek tints? (top 5 cities, top 100 p_id at vertical lv, month lvl) --


-- attempt --

WITH base_metrics AS (
    SELECT
        sales.product_id,
        sales.product_title,
        SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS month,
        sales.analytic_vertical,
        CASE 
            WHEN sales.city_tier IN ('Metro', 'Tier 1A') THEN 'MT1+' 
            WHEN sales.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+' 
        END AS city_tier_group,
        SUM(sales.units) AS total_units,
        SUM(sales.gmv) AS total_gmv,
        COUNT(DISTINCT sales.order_external_id) AS total_orders

    from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    left join bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
       ON geo.pincode = sales.pincode

    left join bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id

    left join fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'bgm'

    WHERE
       LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
       AND sales.type = 'physical'
       AND sales.replacement_for_unit IS NULL
       AND sales.exchange_for_unit IS NULL
       AND sales.is_freebie = FALSE
       AND sales.marketplace_id = 'HYPERLOCAL' 
       AND hl.analytic_vertical IS NOT NULL
       AND (sales.order_date_key BETWEEN 20250301 AND 20260228)
       AND LOWER(sales.analytic_business_unit) IN ('bgm')
       AND LOWER(sales.analytic_super_category) IN ('makeupfragrances', 'grooming')
       AND sales.is_shopsy_order = FALSE
    GROUP BY 1, 2, 3, 4, 5

),
ranked_products AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY analytic_vertical
            ORDER BY total_units DESC
        ) as product_rank
    from base_metrics
)
SELECT 
    month,
    analytic_vertical,
    city_tier_group,
    product_rank,
     CASE 
        WHEN product_rank <= 100 THEN CAST(product_id AS STRING) 
        ELSE 'not top 100' 
    END AS product_id_display,
    product_title,
    total_units,
    total_gmv,
    total_orders
FROM ranked_products
ORDER BY analytic_vertical, product_rank;



-- attempt new --

WITH base_metrics AS (
    SELECT
        sales.product_id,
        sales.product_title,
        SUBSTR(CAST(sales.order_date_key AS STRING), 1, 6) AS month,
        sales.analytic_vertical,
        CASE 
            WHEN sales.city_tier IN ('Metro', 'Tier 1A') THEN 'MT1+' 
            WHEN sales.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+' 
        END AS city_tier_group,
        SUM(sales.units) AS total_units,
        SUM(sales.gmv) AS total_gmv,
        COUNT(DISTINCT sales.order_external_id) AS total_orders

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
       ON geo.pincode = sales.pincode

    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id

    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 hl
        ON sales.analytic_vertical = hl.analytic_vertical
        AND LOWER(hl.bu_final) = 'bgm'

    WHERE
       LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
       AND sales.type = 'physical'
       AND sales.replacement_for_unit IS NULL
       AND sales.exchange_for_unit IS NULL
       AND sales.is_freebie = FALSE
       AND sales.marketplace_id = 'HYPERLOCAL' 
       AND hl.analytic_vertical IS NOT NULL
       AND (sales.order_date_key BETWEEN 20250301 AND 20260228)
       AND LOWER(sales.analytic_business_unit) IN ('bgm')
       AND LOWER(sales.analytic_super_category) IN ('makeupfragrances', 'grooming')
       AND sales.is_shopsy_order = FALSE
    GROUP BY 1, 2, 3, 4, 5
),
product_overall_totals AS (
    SELECT 
        product_id,
        analytic_vertical,
        DENSE_RANK() OVER (
            PARTITION BY analytic_vertical 
            ORDER BY SUM(total_units) DESC
        ) as overall_product_rank
    FROM base_metrics
    GROUP BY 1, 2
)
SELECT 
    b.month,
    b.city_tier_group,
    b.analytic_vertical,
    p.overall_product_rank,
    CASE 
        WHEN p.overall_product_rank <= 100 THEN CAST(b.product_id AS STRING) 
        ELSE 'not top 100' 
    END AS product_id_display,
    b.product_title,
    b.total_units,
    b.total_gmv,
    b.total_orders
FROM base_metrics b
JOIN product_overall_totals p 
    ON b.product_id = p.product_id 
    AND b.analytic_vertical = p.analytic_vertical
ORDER BY b.analytic_vertical, p.overall_product_rank, b.month, b.city_tier_group;