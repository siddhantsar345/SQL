SELECT
    sales.order_date_key,
    sales.analytic_business_unit,
    
    SUM(sales.gmv) AS total_gmv,
    SUM(sales.units) AS total_units,

    SUM(CASE WHEN sales.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN sales.gmv ELSE 0 END) AS Tier_2_plus_gmv,
    SUM(CASE WHEN sales.city_tier IN ('Metro', 'Tier 1A') THEN sales.gmv ELSE 0 END) AS MT1_gmv,

    SUM(CASE WHEN sales.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN sales.units ELSE 0 END) AS Tier_2_units,
    SUM(CASE WHEN sales.city_tier IN ('Metro', 'Tier 1A') THEN sales.units ELSE 0 END) AS MT1_units,

    SUM(CASE WHEN sales.is_alpha_seller = TRUE THEN sales.gmv ELSE 0 END) AS alpha_gmv,
    SUM(CASE WHEN sales.is_alpha_seller = FALSE THEN sales.gmv ELSE 0 END) AS mp_gmv,

    SUM(CASE WHEN sales.is_alpha_seller = TRUE THEN sales.units ELSE 0 END) AS alpha_units,
    SUM(CASE WHEN sales.is_alpha_seller = FALSE THEN sales.units ELSE 0 END) AS mp_units,

    SUM(CASE WHEN b.branded_flag = 'Branded' THEN sales.gmv ELSE 0 END) AS branded_gmv,
    SUM(CASE WHEN b.branded_flag = 'Unbranded' THEN sales.gmv ELSE 0 END) AS Unbranded_gmv,

    SUM(CASE WHEN b.branded_flag = 'Branded' THEN sales.units ELSE 0 END) AS branded_units,
    SUM(CASE WHEN b.branded_flag = 'Unbranded' THEN sales.units ELSE 0 END) AS Unbranded_units,

    SUM(CASE WHEN geo.zone = 'NORTH' THEN sales.gmv ELSE 0 END) AS north_gmv,
    SUM(CASE WHEN geo.zone = 'SOUTH' THEN sales.gmv ELSE 0 END) AS south_gmv,
    SUM(CASE WHEN geo.zone = 'EAST' THEN sales.gmv ELSE 0 END) AS east_gmv,
    SUM(CASE WHEN geo.zone = 'WEST' THEN sales.gmv ELSE 0 END) AS west_gmv,

    SUM(CASE WHEN geo.zone = 'NORTH' THEN sales.units ELSE 0 END) AS north_units,
    SUM(CASE WHEN geo.zone = 'SOUTH' THEN sales.units ELSE 0 END) AS south_units,
    SUM(CASE WHEN geo.zone = 'EAST' THEN sales.units ELSE 0 END) AS east_units,
    SUM(CASE WHEN geo.zone = 'WEST' THEN sales.units ELSE 0 END) AS west_units,


    CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "301-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "501-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "1000+"
    END AS price_bucket


FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode

LEFT JOIN 
    (
    SELECT 
        LOWER(analytic_super_category) AS analytic_super_category,
        LOWER(brand) AS brand,
        MIN(branded_flag) AS branded_flag,
        MIN(brand_type) AS brand_type,
        MIN(brand_tier) AS brand_tier,
        MIN(is_priority_brand) AS is_priority_brand
    FROM  
        fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
    GROUP BY 
        LOWER(analytic_super_category),
        LOWER(brand)
    ) b
    ON LOWER(cat.analytic_super_category) = LOWER(b.analytic_super_category)
    AND LOWER(cat.brand) = LOWER(b.brand)

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND (sales.order_date_key BETWEEN 20250101 AND 20251031)
    AND sales.analytic_business_unit IN ('BGM')
    AND sales.is_shopsy_order = FALSE

GROUP BY
    sales.order_date_key,
    sales.analytic_business_unit,
    (CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "301-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "501-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "1000+"
    END);