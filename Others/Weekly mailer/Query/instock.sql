WITH bmp_brands AS (
    SELECT
        brand,
        analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
),

pareto_verticals AS (
    SELECT analytic_super_category, analytic_vertical
    FROM (
        SELECT
            analytic_super_category,
            analytic_vertical,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC ROWS UNBOUNDED PRECEDING) AS vert_gmv_cumilative,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS total_sc_gmv,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC) / SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS percentage_value
        FROM (
            SELECT
                sales.analytic_super_category,
                sales.analytic_vertical,
                SUM(gmv) AS vertical_gmv
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order = FALSE
                AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
                AND order_date_key BETWEEN 20250701 AND 20260331
            GROUP BY sales.analytic_super_category, sales.analytic_vertical
        ) base
    ) base2
    WHERE percentage_value <= 0.8
)

SELECT
    list_dim.process_date_key as order_date_key,
    prod_dim.analytic_business_unit as analytic_business_unit,
    prod_dim.analytic_super_category as analytic_super_category,
    prod_dim.analytic_vertical as analytic_vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN prod_dim.brand ELSE 'Unbranded' END AS brand, 
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    sales.is_alpha_seller as is_alpha_seller,
    CASE 
            WHEN price_agg.gmv / price_agg.units <= 300 THEN "a) 0-300"
            WHEN price_agg.gmv / price_agg.units > 300 AND price_agg.gmv / price_agg.units <= 500 THEN "b) 300-500"
            WHEN price_agg.gmv / price_agg.units > 500 AND price_agg.gmv / price_agg.units <= 1000 THEN "c) 500-1000"
            WHEN price_agg.gmv / price_agg.units > 1000 THEN "d) 1000+"
    END AS price_bucket,
    
    count(distinct list_dim.listing_id) as a_listings,
    count(distinct list_dim.product_id) as a_products,
    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products

FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_dim
    ON list_dim.product_id = prod_dim.product_id

LEFT JOIN bmp_brands bmp 
    ON LOWER(prod_dim.brand) = LOWER(bmp.brand) 
    AND LOWER(prod_dim.analytic_super_category) = LOWER(bmp.analytic_super_category)

LEFT JOIN (
    SELECT 
        listing_id,
        CASE WHEN is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
    GROUP BY 
        listing_id, 
        CASE WHEN is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END
) as sales
    ON list_dim.listing_id = sales.listing_id

LEFT JOIN (
    SELECT
        listing_id,
        SUM(gmv) AS gmv,
        SUM(units) AS units
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact
    WHERE LOWER(status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND type != 'service'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie = FALSE
        AND marketplace_id IN ('FLIPKART')
        AND is_shopsy_order = FALSE
        AND LOWER(analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
        AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
    GROUP BY listing_id
) AS price_agg
    ON list_dim.listing_id = price_agg.listing_id

INNER JOIN pareto_verticals pv
    ON LOWER(prod_dim.analytic_super_category) = LOWER(pv.analytic_super_category)
    AND LOWER(prod_dim.analytic_vertical) = LOWER(pv.analytic_vertical)

WHERE list_dim.marketplace_id = 'FLIPKART'
    AND LOWER(prod_dim.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND list_dim.process_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)

GROUP BY
    list_dim.process_date_key,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    prod_dim.analytic_vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN prod_dim.brand ELSE 'Unbranded' END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    sales.is_alpha_seller,
    price_bucket