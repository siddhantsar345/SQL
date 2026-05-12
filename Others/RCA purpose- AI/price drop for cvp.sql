WITH bmp_brands AS (
    SELECT
        brand,
        analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY       
        brand,
        analytic_super_category
),

pareto_verticals AS (
    SELECT 
        analytic_super_category, 
        analytic_vertical
    FROM fdp_uploads.ds_fkint_analytics_cdo_pareto_verticals_bgmhfl_fact_1_0
    GROUP BY 
        analytic_super_category, 
        analytic_vertical
)

SELECT
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    price_bucket,
    branded_flag,
    is_alpha_seller, 


    SUM(input_bau_weighted_asp) as input_bau_weighted_asp,
    SUM(input_fes_weighted_asp) as input_fes_weighted_asp,
    SUM(output_bau_weighted_asp) as output_bau_weighted_asp,
    SUM(output_fes_weighted_asp) as output_fes_weighted_asp
FROM
(
    SELECT
        fes.order_date_key as order_date_key,
        bau.analytic_business_unit,
        bau.analytic_super_category,
        bau.analytic_vertical,
        bau.price_bucket,
        bau.branded_flag,
        bau.is_alpha_seller, 
        bau.product_id as product_id,
        bau.listing_id as listing_id,

        (bau.gmv/bau.units)*bau.units as input_bau_weighted_asp,
        (fes.gmv/fes.units)*bau.units as input_fes_weighted_asp,
        (bau.gmv/bau.units)*fes.units as output_bau_weighted_asp,
        (fes.gmv/fes.units)*fes.units as output_fes_weighted_asp
    FROM
    (
        SELECT
            sales.analytic_super_category,
            analytic_business_unit,
            sales.analytic_vertical, 
            CASE
               WHEN sales.gmv / sales.units <= 300 THEN '0-300'
               WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN '301-500'
               WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN '501-1000'
               WHEN sales.gmv / sales.units > 1000 THEN '1000+'
            END AS price_bucket,
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END as is_alpha_seller,
            sales.product_id,
            sales.listing_id,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp

        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
        
        INNER JOIN pareto_verticals pv
            ON LOWER(sales.analytic_super_category) = LOWER(pv.analytic_super_category)
            AND LOWER(sales.analytic_vertical) = LOWER(pv.analytic_vertical)
            
        LEFT JOIN bmp_brands bmp 
            ON LOWER(sales.brand) = LOWER(bmp.brand) 
            AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)

        WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
            AND sales.type !='service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie =FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order =FALSE
            AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND (order_date_key between 20250701 and 20250831)
        GROUP BY
            sales.analytic_super_category,
            analytic_business_unit,
            sales.analytic_vertical,
            CASE
               WHEN sales.gmv / sales.units <= 300 THEN '0-300'
               WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN '301-500'
               WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN '501-1000'
               WHEN sales.gmv / sales.units > 1000 THEN '1000+'
            END,
            CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
            CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
            sales.product_id,
            sales.listing_id
    ) bau

    INNER JOIN

    (
        SELECT
            sales.listing_id,
            CAST(SUBSTR(CAST(order_date_key AS STRING), 1, 6) AS INT) as order_date_key,
            SUM(units) as units,
            SUM(gmv) as gmv,
            SUM(listing_price) as lp

        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

        WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
            AND sales.type !='service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie =FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order =FALSE
            AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key between 20260101 and 20260424
            
        GROUP BY
            sales.listing_id,
            CAST(SUBSTR(CAST(order_date_key AS STRING), 1, 6) AS INT)
    ) fes
    ON bau.listing_id = fes.listing_id
) sub
GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    price_bucket,
    branded_flag,
    is_alpha_seller