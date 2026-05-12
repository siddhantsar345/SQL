SELECT
    order_date_key,
    cat.analytic_business_unit AS business_unit,
    cat.analytic_super_category AS super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN cat.analytic_vertical ELSE 'Non Pareto Vertical' END AS vertical,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END AS diamond_mp_flag,
    CASE 
        WHEN geo.city_tier IN ('Metro') THEN 'Metro' 
        WHEN geo.city_tier IN ('Tier 1A', 'Tier 1B') THEN 'T1'
        WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+' 
    END AS city_tier,
    geo.zone,
    CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END AS is_minutes_serviceable,
    CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
    END AS price_bucket,
    SUM(gmv) AS gmv,
    SUM(units) AS units
FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id
LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode
LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON cat.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'
LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON sales.pincode = hyper.pincode
LEFT JOIN (
    SELECT brand, analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
) bmp
    ON LOWER(sales.brand) = LOWER(bmp.brand)
    AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
LEFT JOIN (
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
) pareto
    ON sales.analytic_super_category = pareto.analytic_super_category
    AND sales.analytic_vertical = pareto.analytic_vertical
WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
    AND sales.type != 'service'
    AND replacement_for_unit IS NULL
    AND exchange_for_unit IS NULL
    AND is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(cat.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND sales.is_shopsy_order = FALSE
    AND order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
GROUP BY
    order_date_key,
    cat.analytic_business_unit,
    cat.analytic_super_category,
    CASE WHEN pareto.analytic_vertical IS NOT NULL THEN cat.analytic_vertical ELSE 'Non Pareto Vertical' END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    CASE
        WHEN geo.city_tier IN ('Metro') THEN 'Metro'
        WHEN geo.city_tier IN ('Tier 1A', 'Tier 1B') THEN 'T1'
        WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+'
    END,
    geo.zone,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END,
    CASE
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+"
    END,
    CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END