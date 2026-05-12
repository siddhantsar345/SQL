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
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    brand, 
    branded_flag,
    is_alpha_seller,
    price_bucket,

    SUM(input_bau_weighted_asp) as input_bau_weighted_asp,
    SUM(input_fes_weighted_asp) as input_fes_weighted_asp,
    SUM(output_bau_weighted_asp) as output_bau_weighted_asp,
    SUM(output_fes_weighted_asp) as output_fes_weighted_asp

FROM (
    SELECT
        fes.order_date_key as order_date_key,
        bau.analytic_business_unit,
        bau.analytic_super_category,
        bau.analytic_vertical,
        bau.brand, 
        bau.branded_flag,
        bau.is_alpha_seller,
        bau.product_id as product_id,
        bau.listing_id as listing_id,
        CASE 
        WHEN bau.gmv / bau.units <= 300 THEN "0-300"
        WHEN bau.gmv / bau.units > 300 AND bau.gmv / bau.units <= 500 THEN "300-500"
        WHEN bau.gmv / bau.units > 500 AND bau.gmv / bau.units <= 1000 THEN "500-1000"
        WHEN bau.gmv / bau.units > 1000 THEN "1000+"
        ELSE "Unknown"
        END AS price_bucket,

        (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
        (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
        (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
        (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp

    FROM (
        SELECT
            sales.analytic_super_category,
            sales.analytic_business_unit,
            sales.analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END AS brand, 
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END as is_alpha_seller,
            sales.product_id,
            sales.listing_id,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        LEFT JOIN bmp_brands bmp 
            ON LOWER(sales.brand) = LOWER(bmp.brand) 
            AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
        WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
            AND sales.type != 'service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order = FALSE
            AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key BETWEEN 20250701 AND 20250831
        GROUP BY
            sales.analytic_super_category,
            sales.analytic_business_unit,
            sales.analytic_vertical,
            CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END,
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
            sales.product_id,
            sales.listing_id
    ) bau

    INNER JOIN (
        SELECT
            sales.listing_id,
            order_date_key,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
            AND sales.type != 'service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order = FALSE
            AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
        GROUP BY
            sales.listing_id,
            order_date_key
    ) fes
        ON bau.listing_id = fes.listing_id

    LEFT JOIN pareto_verticals pv
        ON LOWER(bau.analytic_super_category) = LOWER(pv.analytic_super_category)
        AND LOWER(bau.analytic_vertical) = LOWER(pv.analytic_vertical)

) sub

GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    brand, 
    branded_flag,
    is_alpha_seller,
    price_bucket