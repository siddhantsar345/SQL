SELECT
    domain_name,
    order_date_key,
    marketplace,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    is_alpha_seller,
    brand,
    city_tier,
    zone,
    price_point,
    kam_nkam_flag,
    branded_flag,
    service_profile, -- **New Column**

    cy_gmv,
    cy_units,
    ly_gmv,
    ly_units,
    cy_ja_gmv,
    cy_ja_units,
    ly_ja_gmv,
    ly_ja_units,

    cy_search_ppvs,
    cy_primary_ppvs,
    cy_net_units,

    ly_search_ppvs,
    ly_primary_ppvs,
    ly_net_units,

    cy_ja_search_ppvs,
    cy_ja_primary_ppvs,
    cy_ja_net_units,

    ly_ja_search_ppvs,
    ly_ja_primary_ppvs,
    ly_ja_net_units,

    cy_input_bau_weighted_asp,
    cy_input_fes_weighted_asp,
    cy_output_bau_weighted_asp,
    cy_output_fes_weighted_asp,

    ly_input_bau_weighted_asp,
    ly_input_fes_weighted_asp,
    ly_output_bau_weighted_asp,
    ly_output_fes_weighted_asp,
    event_type

FROM
(
    -- **1. current_year_festive_sales**
    SELECT
        'current_year_festive_sales' AS domain_name,
        sales.order_date_key AS order_date_key,
        sales.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,

        geo.city_tier AS city_tier,
        geo.zone AS zone,

        CASE
            WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 300 THEN '0-300'
                    WHEN sales.gmv / sales.units <= 500 THEN '301-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN sales.analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 500 THEN '0-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
                    WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
                    WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
                    WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
                    WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
                    WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        -- **New Service Profile Logic**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END AS service_profile,


        SUM(sales.gmv) AS cy_gmv,
        SUM(sales.units) AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,

        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
        ON sales.order_date_key = date_map.dates_current_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5
        ON sales.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
        ON LOWER(sales.analytic_super_category) = LOWER(fur_b.analytic_super_category)
        AND LOWER(sales.brand) = LOWER(fur_b.brand)
        AND LOWER(sales.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
        ON sales.analytic_vertical = hl.analytic_vertical
        AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture')
        AND sales.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo
        ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category)
        AND LOWER(sales.brand) = LOWER(home_b.brand)
    LEFT JOIN (
        SELECT
            LOWER(analytic_super_category) AS analytic_super_category,
            LOWER(brand) AS brand,
            MIN(branded_flag) AS branded_flag
        FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
        GROUP BY 1, 2
    ) bgm_b
        ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
        AND LOWER(sales.brand) = LOWER(bgm_b.brand)

    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND (sales.order_date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
        AND sales.is_shopsy_order = FALSE

    GROUP BY
        sales.order_date_key,
        sales.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END,
        geo.city_tier,
        geo.zone,
        5, -- price_point column alias position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END,
        -- **New Group By for Service Profile**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END,
        date_map.event_type

    UNION ALL

    -- **2. last_year_festive_sales**
    SELECT
        'last_year_festive_sales' AS domain_name,
        date_map.dates_current_year AS order_date_key,
        sales.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,

        CASE
            WHEN sales.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN sales.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN sales.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,
        geo.city_tier AS city_tier,
        geo.zone AS zone,

        CASE
            WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 300 THEN '0-300'
                    WHEN sales.gmv / sales.units <= 500 THEN '301-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN sales.analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 500 THEN '0-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
                    WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
                    WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
                    WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
                    WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
                    WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        -- **New Service Profile Logic**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END AS service_profile,


        0.0 AS cy_gmv,
        0.0 AS cy_units,
        SUM(sales.gmv) AS ly_gmv,
        SUM(sales.units) AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,

        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
        ON sales.order_date_key = date_map.dates_last_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5
        ON sales.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
        ON LOWER(sales.analytic_super_category) = LOWER(fur_b.analytic_super_category)
        AND LOWER(sales.brand) = LOWER(fur_b.brand)
        AND LOWER(sales.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
        ON sales.analytic_vertical = hl.analytic_vertical
        AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture')
        AND sales.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo
        ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category)
        AND LOWER(sales.brand) = LOWER(home_b.brand)
    LEFT JOIN (
        SELECT
            LOWER(analytic_super_category) AS analytic_super_category,
            LOWER(brand) AS brand,
            MIN(branded_flag) AS branded_flag
        FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
        GROUP BY 1, 2
    ) bgm_b
        ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
        AND LOWER(sales.brand) = LOWER(bgm_b.brand)

    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND (sales.order_date_key BETWEEN 20240901 AND 20241031)
        AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
        AND sales.is_shopsy_order = FALSE

    GROUP BY
        date_map.dates_current_year,
        sales.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
        CASE
            WHEN sales.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN sales.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN sales.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END,
        geo.city_tier,
        geo.zone,
        5, -- price_point column alias position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END,
        -- **New Group By for Service Profile**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END,
        date_map.event_type


    UNION ALL

    -- **3. BAU/JA Summary (Doesn't use sales, so service_profile is 'null')**
    SELECT
        domain_name,
        ss.order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        is_alpha_seller,
        brand,
        city_tier,
        zone,
        price_point,
        kam_nkam_flag,
        branded_flag,
        'null' AS service_profile, -- **New Column - Set to 'null' as base table is different**

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,

        cy_ja_gmv,
        cy_ja_units,
        ly_ja_gmv,
        ly_ja_units,


        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,

        cy_ja_search_ppvs,
        cy_ja_primary_ppvs,
        cy_ja_net_units,

        ly_ja_search_ppvs,
        ly_ja_primary_ppvs,
        ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type

    FROM bigfoot_external_neo.analytics_cdo__festive_rca_bau_ja_base_summary_fact AS ss
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
        ON ss.order_date_key = date_map.dates_current_year

    UNION ALL

    -- **4. current_year_festive_traffic**
    SELECT
        'current_year_festive_traffic' AS domain_name,
        date_key AS order_date_key,
        base.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END AS is_alpha_seller,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,
        '' AS city_tier,
        '' AS zone,

        CASE
            WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN base.fsp <= 300 THEN '0-300'
                    WHEN base.fsp <= 500 THEN '301-500'
                    WHEN base.fsp <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN cat.analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN base.fsp <= 500 THEN '0-500'
                    WHEN base.fsp <= 1000 THEN '501-1k'
                    WHEN base.fsp <= 2500 THEN '1k-2.5k'
                    WHEN base.fsp <= 5000 THEN '2.5k-5k'
                    WHEN base.fsp <= 7500 THEN '5k-7.5k'
                    WHEN base.fsp <= 10000 THEN '7.5k-10k'
                    WHEN base.fsp <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        'null' AS service_profile, -- **New Column - Set to 'null' as base table is different**

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,
        SUM(search_ppvs) AS cy_search_ppvs,
        SUM(primary_ppvs) AS cy_primary_ppvs,
        SUM(net_units) AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type


    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
        ON base.date_key = date_map.dates_current_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON base.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5
        ON base.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
        ON LOWER(base.analytic_super_category) = LOWER(fur_b.analytic_super_category)
        AND LOWER(base.brand) = LOWER(fur_b.brand)
        AND LOWER(base.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
        ON base.analytic_vertical = hl.analytic_vertical
        AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture')
        AND base.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        ON LOWER(base.analytic_super_category) = LOWER(home_b.analytic_super_category)
        AND LOWER(base.brand) = LOWER(home_b.brand)
    LEFT JOIN (
        SELECT
            LOWER(analytic_super_category) AS analytic_super_category,
            LOWER(brand) AS brand,
            MIN(branded_flag) AS branded_flag
        FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
        GROUP BY 1, 2
    ) bgm_b
        ON LOWER(base.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
        AND LOWER(base.brand) = LOWER(bgm_b.brand)


    WHERE base.analytic_business_unit IN ('Home', 'BGM', 'Furniture')
        AND (base.marketplace_id IN ('FLIPKART') OR (base.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND (date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))

    GROUP BY
        date_key,
        base.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END,
        4, -- price_point column alias position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END,
        'null', -- **New Group By for Service Profile**
        event_type

    UNION ALL

    -- **5. last_year_festive_traffic**
    SELECT
        'last_year_festive_traffic' AS domain_name,
        date_map.dates_current_year AS order_date_key,
        base.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END AS is_alpha_seller,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,
        '' AS city_tier,
        '' AS zone,

        CASE
            WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN base.fsp <= 300 THEN '0-300'
                    WHEN base.fsp <= 500 THEN '301-500'
                    WHEN base.fsp <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN cat.analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN base.fsp <= 500 THEN '0-500'
                    WHEN base.fsp <= 1000 THEN '501-1k'
                    WHEN base.fsp <= 2500 THEN '1k-2.5k'
                    WHEN base.fsp <= 5000 THEN '2.5k-5k'
                    WHEN base.fsp <= 7500 THEN '5k-7.5k'
                    WHEN base.fsp <= 10000 THEN '7.5k-10k'
                    WHEN base.fsp <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        'null' AS service_profile, -- **New Column - Set to 'null' as base table is different**

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,

        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,

        SUM(search_ppvs) AS ly_search_ppvs,
        SUM(primary_ppvs) AS ly_primary_ppvs,
        SUM(net_units) AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type


    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
        ON base.date_key = date_map.dates_last_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON base.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5
        ON base.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b
        ON LOWER(base.analytic_super_category) = LOWER(fur_b.analytic_super_category)
        AND LOWER(base.brand) = LOWER(fur_b.brand)
        AND LOWER(base.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
        ON base.analytic_vertical = hl.analytic_vertical
        AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture')
        AND base.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
        ON LOWER(base.analytic_super_category) = LOWER(home_b.analytic_super_category)
        AND LOWER(base.brand) = LOWER(home_b.brand)
    LEFT JOIN (
        SELECT
            LOWER(analytic_super_category) AS analytic_super_category,
            LOWER(brand) AS brand,
            MIN(branded_flag) AS branded_flag
        FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
        GROUP BY 1, 2
    ) bgm_b
        ON LOWER(base.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
        AND LOWER(base.brand) = LOWER(bgm_b.brand)


    WHERE base.analytic_business_unit IN ('Home', 'BGM', 'Furniture')
        AND (base.marketplace_id IN ('FLIPKART') OR (base.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND date_key BETWEEN 20240901 AND 20241031

    GROUP BY
        date_map.dates_current_year,
        base.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END,
        4, -- price_point column alias position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END,
        'null', -- **New Group By for Service Profile**
        date_map.event_type

    UNION ALL

    -- **6. current_year_pricing**
    SELECT
        'current_year_pricing' AS domain_flag,
        order_date_key AS order_date_key,
        marketplace AS marketplace,
        analytic_business_unit AS analytic_business_unit,
        analytic_super_category AS analytic_super_category,
        analytic_vertical AS analytic_vertical,
        is_alpha_seller AS is_alpha_seller,
        brand,
        city_tier,
        zone,

        CASE
            WHEN analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN bau_price_point <= 300 THEN '0-300'
                    WHEN bau_price_point <= 500 THEN '301-500'
                    WHEN bau_price_point <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN bau_price_point <= 500 THEN '0-500'
                    WHEN bau_price_point <= 1000 THEN '501-1k'
                    WHEN bau_price_point <= 2500 THEN '1k-2.5k'
                    WHEN bau_price_point <= 5000 THEN '2.5k-5k'
                    WHEN bau_price_point <= 7500 THEN '5k-7.5k'
                    WHEN bau_price_point <= 10000 THEN '7.5k-10k'
                    WHEN bau_price_point <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,
        kam_nkam_flag,
        branded_flag,
        service_profile, -- **New Column (inherited from subquery)**

        0.0 AS cy_gmv,
        0.0 AS cy_units,

        0.0 AS ly_gmv,
        0.0 AS ly_units,

        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,

        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,

        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,

        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,


        SUM(input_bau_weighted_asp) AS cy_input_bau_weighted_asp,
        SUM(input_fes_weighted_asp) AS cy_input_fes_weighted_asp,
        SUM(output_bau_weighted_asp) AS cy_output_bau_weighted_asp,
        SUM(output_fes_weighted_asp) AS cy_output_fes_weighted_asp,


        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        event_type AS event_type

    FROM
    (
        SELECT
            bau.marketplace AS marketplace,
            bau.analytic_business_unit AS analytic_business_unit,
            bau.analytic_super_category AS analytic_super_category,
            bau.analytic_vertical AS analytic_vertical,
            bau.is_alpha_seller AS is_alpha_seller,
            bau.brand AS brand,
            bau.city_tier AS city_tier,
            bau.zone AS zone,
            bau.kam_nkam_flag AS kam_nkam_flag,
            bau.branded_flag AS branded_flag,
            fes.event_type AS event_type,

            bau.service_profile AS service_profile, -- **New Column (inherited from BAU subquery)**

            bau.product_id AS product_id,
            bau.listing_id AS listing_id,
            fes.order_date_key AS order_date_key,
            bau.gmv / bau.units AS bau_price_point,

            (bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
            (fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
            (bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
            (fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp

        FROM
        (
            SELECT
                sales.marketplace_id AS marketplace,
                cat.analytic_business_unit,
                cat.analytic_super_category,
                cat.analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,

                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
                    ELSE 'Unbranded'
                END AS brand,

                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
                    ELSE 'Unbranded'
                END AS branded_flag,

                geo.city_tier AS city_tier,
                geo.zone AS zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

                -- **New Service Profile Logic in BAU**
                CASE
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF'
                    WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
                    ELSE 'null'
                END AS service_profile,


                sales.product_id,
                sales.listing_id,

                SUM(units) / 62 AS units,
                SUM(gmv) / 62 AS gmv,
                SUM(listing_price) AS lp

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
                ON sales.product_id = cat.product_id
            LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5
                ON sales.seller_id = t5.seller_id
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 AS fur_b
                ON LOWER(cat.analytic_super_category) = LOWER(fur_b.analytic_super_category)
                AND LOWER(cat.brand) = LOWER(fur_b.brand)
                AND LOWER(cat.analytic_vertical) = LOWER(fur_b.analytic_vertical)
            LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo
                ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
                ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category)
                AND LOWER(sales.brand) = LOWER(home_b.brand)
            LEFT JOIN (
                SELECT
                    LOWER(analytic_super_category) AS analytic_super_category,
                    LOWER(brand) AS brand,
                    MIN(branded_flag) AS branded_flag
                FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
                GROUP BY 1, 2
            ) bgm_b
                ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
                AND LOWER(sales.brand) = LOWER(bgm_b.brand)

            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20250701 AND 20250831

            GROUP BY
                sales.marketplace_id,
                cat.analytic_business_unit,
                cat.analytic_super_category,
                cat.analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
                    ELSE 'Unbranded'
                END,
                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
                    ELSE 'Unbranded'
                END,
                geo.city_tier,
                geo.zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
                -- **New Group By for Service Profile in BAU**
                CASE
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF'
                    WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
                    ELSE 'null'
                END,
                sales.product_id,
                sales.listing_id
        ) bau

        INNER JOIN
        (
            SELECT
                sales.listing_id,
                order_date_key,
                SUM(units) AS units,
                SUM(gmv) AS gmv,
                SUM(listing_price) AS lp,
                date_map.event_type AS event_type

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
                ON sales.order_date_key = date_map.dates_current_year

            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)


            GROUP BY
                sales.listing_id,
                order_date_key,
                date_map.event_type
        ) fes
            ON bau.listing_id = fes.listing_id
    ) sub

    GROUP BY
        order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        is_alpha_seller,
        brand,
        city_tier,
        zone,

        4, -- price_point column alias position
        kam_nkam_flag,
        branded_flag,
        service_profile, -- **New Group By for Service Profile**
        event_type


    UNION ALL


    -- **7. last_year_pricing**
    SELECT
        'last_year_pricing' AS domain_flag,
        order_date_key AS order_date_key,
        marketplace AS marketplace,
        analytic_business_unit AS analytic_business_unit,
        analytic_super_category AS analytic_super_category,
        analytic_vertical AS analytic_vertical,
        is_alpha_seller AS is_alpha_seller,
        brand,
        city_tier,
        zone,
        CASE
            WHEN analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN bau_price_point <= 300 THEN '0-300'
                    WHEN bau_price_point <= 500 THEN '301-500'
                    WHEN bau_price_point <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN bau_price_point <= 500 THEN '0-500'
                    WHEN bau_price_point <= 1000 THEN '501-1k'
                    WHEN bau_price_point <= 2500 THEN '1k-2.5k'
                    WHEN bau_price_point <= 5000 THEN '2.5k-5k'
                    WHEN bau_price_point <= 7500 THEN '5k-7.5k'
                    WHEN bau_price_point <= 10000 THEN '7.5k-10k'
                    WHEN bau_price_point <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,
        kam_nkam_flag,
        branded_flag,
        service_profile, -- **New Column (inherited from subquery)**

        0.0 AS cy_gmv,
        0.0 AS cy_units,

        0.0 AS ly_gmv,
        0.0 AS ly_units,

        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,

        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,

        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,

        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,


        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        SUM(input_bau_weighted_asp) AS ly_input_bau_weighted_asp,
        SUM(input_fes_weighted_asp) AS ly_input_fes_weighted_asp,
        SUM(output_bau_weighted_asp) AS ly_output_bau_weighted_asp,
        SUM(output_fes_weighted_asp) AS ly_output_fes_weighted_asp,
        event_type AS event_type

    FROM
    (
        SELECT
            bau.marketplace AS marketplace,
            bau.analytic_business_unit AS analytic_business_unit,
            bau.analytic_super_category AS analytic_super_category,
            bau.analytic_vertical AS analytic_vertical,
            bau.is_alpha_seller AS is_alpha_seller,
            bau.brand AS brand,
            bau.city_tier AS city_tier,
            bau.zone AS zone,
            bau.kam_nkam_flag,
            bau.branded_flag AS branded_flag,
            fes.event_type AS event_type,

            bau.service_profile AS service_profile, -- **New Column (inherited from BAU subquery)**

            bau.product_id AS product_id,
            bau.listing_id AS listing_id,
            fes.order_date_key AS order_date_key,
            bau.gmv / bau.units AS bau_price_point,

            (bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
            (fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
            (bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
            (fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp

        FROM
        (
            SELECT
                sales.marketplace_id AS marketplace,
                cat.analytic_business_unit AS analytic_business_unit,
                cat.analytic_super_category AS analytic_super_category,
                cat.analytic_vertical AS analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
                    ELSE 'Unbranded'
                END AS brand,

                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
                    ELSE 'Unbranded'
                END AS branded_flag,

                geo.city_tier AS city_tier,
                geo.zone AS zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

                -- **New Service Profile Logic in BAU**
                CASE
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF'
                    WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
                    ELSE 'null'
                END AS service_profile,

                sales.product_id,
                sales.listing_id,


                SUM(units) / 62 AS units,
                SUM(gmv) / 62 AS gmv,
                SUM(listing_price) AS lp

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
                ON sales.product_id = cat.product_id
            LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5
                ON sales.seller_id = t5.seller_id
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 AS fur_b
                ON LOWER(cat.analytic_super_category) = LOWER(fur_b.analytic_super_category)
                AND LOWER(cat.brand) = LOWER(fur_b.brand)
                AND LOWER(cat.analytic_vertical) = LOWER(fur_b.analytic_vertical)
            LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo
                ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b
                ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category)
                AND LOWER(sales.brand) = LOWER(home_b.brand)
            LEFT JOIN (
                SELECT
                    LOWER(analytic_super_category) AS analytic_super_category,
                    LOWER(brand) AS brand,
                    MIN(branded_flag) AS branded_flag
                FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
                GROUP BY 1, 2
            ) bgm_b
                ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category)
                AND LOWER(sales.brand) = LOWER(bgm_b.brand)


            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20240701 AND 20240831

            GROUP BY
                sales.marketplace_id,
                cat.analytic_business_unit,
                cat.analytic_super_category,
                cat.analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
                    ELSE 'Unbranded'
                END,
                CASE
                    WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
                    WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
                    ELSE 'Unbranded'
                END,
                geo.city_tier,
                geo.zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
                -- **New Group By for Service Profile in BAU**
                CASE
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF'
                    WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
                    ELSE 'null'
                END,
                sales.product_id,
                sales.listing_id
        ) bau

        INNER JOIN
        (
            SELECT
                sales.listing_id,
                date_map.dates_current_year AS order_date_key,
                SUM(units) AS units,
                SUM(gmv) AS gmv,
                SUM(listing_price) AS lp,
                date_map.event_type AS event_type

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map
                ON sales.order_date_key = date_map.dates_last_year

            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20240901 AND 20241031


            GROUP BY
                sales.listing_id,
                date_map.dates_current_year,
                date_map.event_type
        ) fes
            ON bau.listing_id = fes.listing_id
    ) sub

    GROUP BY
        order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        is_alpha_seller,
        brand,
        city_tier,
        zone,
        4, -- price_point column alias position
        kam_nkam_flag,
        branded_flag,
        service_profile, -- **New Group By for Service Profile**
        event_type

) AS festive_dates
```That is an extremely detailed and complex query, primarily built using `UNION ALL` across different data domains (sales, traffic, pricing) for current year (`cy`) and last year (`ly`) festive periods.

As a 10-year data analyst, I can see where the new `service_profile` logic needs to be integrated: specifically, in every subquery that selects data directly from the `cp_bi_prod_sales__forward_unit_history_fact` table, as this is where the `is_alpha_seller`, `service_profile`, and `source_facility_id` columns reside.

I have updated the four relevant subqueries (Sales CY, Sales LY, Pricing CY BAU, Pricing LY BAU) and the top-level `SELECT` and `GROUP BY` statements to include the new logic.

Here is the final integrated query:

```sql
SELECT
    domain_name,
    order_date_key,
    marketplace,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    is_alpha_seller,
    brand,
    city_tier,
    zone,
    price_point,
    kam_nkam_flag,
    branded_flag,
    service_profile, -- <<< ADDED TO FINAL SELECT

    cy_gmv,
    cy_units,
    ly_gmv,
    ly_units,
    cy_ja_gmv,
    cy_ja_units,
    ly_ja_gmv,
    ly_ja_units,

    cy_search_ppvs,
    cy_primary_ppvs,
    cy_net_units,

    ly_search_ppvs,
    ly_primary_ppvs,
    ly_net_units,

    cy_ja_search_ppvs,
    cy_ja_primary_ppvs,
    cy_ja_net_units,

    ly_ja_search_ppvs,
    ly_ja_primary_ppvs,
    ly_ja_net_units,

    cy_input_bau_weighted_asp,
    cy_input_fes_weighted_asp,
    cy_output_bau_weighted_asp,
    cy_output_fes_weighted_asp,

    ly_input_bau_weighted_asp,
    ly_input_fes_weighted_asp,
    ly_output_bau_weighted_asp,
    ly_output_fes_weighted_asp,
    event_type

FROM
(

    -- **1. current_year_festive_sales (SALES)**
    SELECT
        'current_year_festive_sales' AS domain_name,
        sales.order_date_key AS order_date_key,
        sales.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,

        geo.city_tier AS city_tier,
        geo.zone AS zone,

        CASE
            WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 300 THEN '0-300'
                    WHEN sales.gmv / sales.units <= 500 THEN '301-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN sales.analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 500 THEN '0-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
                    WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
                    WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
                    WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
                    WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
                    WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        -- **New Service Profile Logic**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END AS service_profile,

        SUM(sales.gmv) AS cy_gmv,
        SUM(sales.units) AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,
        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,
        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,
        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,
        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,
        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON sales.order_date_key = date_map.dates_current_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat ON sales.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5 ON sales.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b ON LOWER(sales.analytic_super_category) = LOWER(fur_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(fur_b.brand) AND LOWER(sales.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl ON sales.analytic_vertical = hl.analytic_vertical AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture') AND sales.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(home_b.brand)
    LEFT JOIN (SELECT LOWER(analytic_super_category) AS analytic_super_category, LOWER(brand) AS brand, MIN(branded_flag) AS branded_flag FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0 GROUP BY 1, 2) bgm_b ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(bgm_b.brand)

    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND (sales.order_date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
        AND sales.is_shopsy_order = FALSE

    GROUP BY
        sales.order_date_key,
        sales.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
        6, -- brand position
        geo.city_tier,
        geo.zone,
        10, -- price_point position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        12, -- branded_flag position
        -- **New Group By for Service Profile**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END,
        date_map.event_type

    UNION ALL

    -- **2. last_year_festive_sales (SALES)**
    SELECT
        'last_year_festive_sales' AS domain_name,
        date_map.dates_current_year AS order_date_key,
        sales.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,

        CASE
            WHEN sales.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN sales.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN sales.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,
        geo.city_tier AS city_tier,
        geo.zone AS zone,

        CASE
            WHEN sales.analytic_business_unit IN ('BGM', 'Home') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 300 THEN '0-300'
                    WHEN sales.gmv / sales.units <= 500 THEN '301-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1000'
                    ELSE '1000+'
                END)
            WHEN sales.analytic_business_unit IN ('Furniture') THEN
                (CASE
                    WHEN sales.gmv / sales.units <= 500 THEN '0-500'
                    WHEN sales.gmv / sales.units <= 1000 THEN '501-1k'
                    WHEN sales.gmv / sales.units <= 2500 THEN '1k-2.5k'
                    WHEN sales.gmv / sales.units <= 5000 THEN '2.5k-5k'
                    WHEN sales.gmv / sales.units <= 7500 THEN '5k-7.5k'
                    WHEN sales.gmv / sales.units <= 10000 THEN '7.5k-10k'
                    WHEN sales.gmv / sales.units <= 15000 THEN '10k-15k'
                    ELSE '15k+'
                END)
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        -- **New Service Profile Logic**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END AS service_profile,

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        SUM(sales.gmv) AS ly_gmv,
        SUM(sales.units) AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,
        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,
        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,
        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,
        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,
        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON sales.order_date_key = date_map.dates_last_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat ON sales.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5 ON sales.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b ON LOWER(sales.analytic_super_category) = LOWER(fur_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(fur_b.brand) AND LOWER(sales.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl ON sales.analytic_vertical = hl.analytic_vertical AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture') AND sales.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(home_b.brand)
    LEFT JOIN (SELECT LOWER(analytic_super_category) AS analytic_super_category, LOWER(brand) AS brand, MIN(branded_flag) AS branded_flag FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0 GROUP BY 1, 2) bgm_b ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(bgm_b.brand)

    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND (sales.order_date_key BETWEEN 20240901 AND 20241031)
        AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
        AND sales.is_shopsy_order = FALSE

    GROUP BY
        date_map.dates_current_year,
        sales.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
        6, -- brand position
        geo.city_tier,
        geo.zone,
        10, -- price_point position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        12, -- branded_flag position
        -- **New Group By for Service Profile**
        CASE
            WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
            WHEN sales.service_profile = 'FBF' THEN 'FBF'
            WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
            ELSE 'null'
        END,
        date_map.event_type


    UNION ALL

    -- **3. BAU/JA Summary (Already exists, cannot calculate service_profile)**
    SELECT
        domain_name,
        ss.order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        is_alpha_seller,
        brand,
        city_tier,
        zone,
        price_point,
        kam_nkam_flag,
        branded_flag,
        'null' AS service_profile, -- <<< ADDED - Set to 'null' as source table does not have necessary fields

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,

        cy_ja_gmv,
        cy_ja_units,
        ly_ja_gmv,
        ly_ja_units,

        cy_search_ppvs,
        cy_primary_ppvs,
        cy_net_units,
        ly_search_ppvs,
        ly_primary_ppvs,
        ly_net_units,

        cy_ja_search_ppvs,
        cy_ja_primary_ppvs,
        cy_ja_net_units,

        ly_ja_search_ppvs,
        ly_ja_primary_ppvs,
        ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type

    FROM bigfoot_external_neo.analytics_cdo__festive_rca_bau_ja_base_summary_fact AS ss
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON ss.order_date_key = date_map.dates_current_year

    UNION ALL

    -- **4. current_year_festive_traffic (TRAFFIC)**
    SELECT
        'current_year_festive_traffic' AS domain_name,
        date_key AS order_date_key,
        base.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END AS is_alpha_seller,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,
        '' AS city_tier,
        '' AS zone,

        CASE
            WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN 9 -- Price point logic
            WHEN cat.analytic_business_unit IN ('Furniture') THEN 10 -- Price point logic
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        'null' AS service_profile, -- <<< ADDED - Set to 'null' as source table does not have necessary fields

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,
        SUM(search_ppvs) AS cy_search_ppvs,
        SUM(primary_ppvs) AS cy_primary_ppvs,
        SUM(net_units) AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,
        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,
        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,
        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,
        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type


    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON base.date_key = date_map.dates_current_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat ON base.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5 ON base.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b ON LOWER(base.analytic_super_category) = LOWER(fur_b.analytic_super_category) AND LOWER(base.brand) = LOWER(fur_b.brand) AND LOWER(base.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl ON base.analytic_vertical = hl.analytic_vertical AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture') AND base.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b ON LOWER(base.analytic_super_category) = LOWER(home_b.analytic_super_category) AND LOWER(base.brand) = LOWER(home_b.brand)
    LEFT JOIN (SELECT LOWER(analytic_super_category) AS analytic_super_category, LOWER(brand) AS brand, MIN(branded_flag) AS branded_flag FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0 GROUP BY 1, 2) bgm_b ON LOWER(base.analytic_super_category) = LOWER(bgm_b.analytic_super_category) AND LOWER(base.brand) = LOWER(bgm_b.brand)


    WHERE base.analytic_business_unit IN ('Home', 'BGM', 'Furniture')
        AND (base.marketplace_id IN ('FLIPKART') OR (base.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND (date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))

    GROUP BY
        date_key,
        base.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END,
        6, -- brand position
        12, -- price_point position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        14, -- branded_flag position
        'null', -- **New Group By for Service Profile**
        event_type

    UNION ALL

    -- **5. last_year_festive_traffic (TRAFFIC)**
    SELECT
        'last_year_festive_traffic' AS domain_name,
        date_map.dates_current_year AS order_date_key,
        base.marketplace_id AS marketplace,
        cat.analytic_business_unit AS analytic_business_unit,
        cat.analytic_super_category AS analytic_super_category,
        cat.analytic_vertical AS analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END AS is_alpha_seller,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN bgm_b.brand
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN home_b.brand
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN fur_b.brand
            ELSE 'Unbranded'
        END AS brand,
        '' AS city_tier,
        '' AS zone,

        CASE
            WHEN cat.analytic_business_unit IN ('BGM', 'Home') THEN 9 -- Price point logic
            WHEN cat.analytic_business_unit IN ('Furniture') THEN 10 -- Price point logic
        END AS price_point,

        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

        CASE
            WHEN cat.analytic_business_unit = 'BGM' AND LOWER(bgm_b.branded_flag) = 'branded' THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Home' AND (LOWER(home_b.type) = 'branded' OR LOWER(home_b.type) = 'd2c') THEN 'Branded'
            WHEN cat.analytic_business_unit = 'Furniture' AND LOWER(fur_b.branded_flag) = 'branded' THEN 'Branded'
            ELSE 'Unbranded'
        END AS branded_flag,

        'null' AS service_profile, -- <<< ADDED - Set to 'null' as source table does not have necessary fields

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,

        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,

        SUM(search_ppvs) AS ly_search_ppvs,
        SUM(primary_ppvs) AS ly_primary_ppvs,
        SUM(net_units) AS ly_net_units,

        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,

        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,

        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        date_map.event_type AS event_type


    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact base
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON base.date_key = date_map.dates_last_year
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat ON base.product_id = cat.product_id
    LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5 ON base.seller_id = t5.seller_id
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 fur_b ON LOWER(base.analytic_super_category) = LOWER(fur_b.analytic_super_category) AND LOWER(base.brand) = LOWER(fur_b.brand) AND LOWER(base.analytic_vertical) = LOWER(fur_b.analytic_vertical)
    LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl ON base.analytic_vertical = hl.analytic_vertical AND LOWER(hl.bu_final) IN ('bgm', 'home', 'furniture') AND base.marketplace_id = 'HYPERLOCAL'
    LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b ON LOWER(base.analytic_super_category) = LOWER(home_b.analytic_super_category) AND LOWER(base.brand) = LOWER(home_b.brand)
    LEFT JOIN (SELECT LOWER(analytic_super_category) AS analytic_super_category, LOWER(brand) AS brand, MIN(branded_flag) AS branded_flag FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0 GROUP BY 1, 2) bgm_b ON LOWER(base.analytic_super_category) = LOWER(bgm_b.analytic_super_category) AND LOWER(base.brand) = LOWER(bgm_b.brand)


    WHERE base.analytic_business_unit IN ('Home', 'BGM', 'Furniture')
        AND (base.marketplace_id IN ('FLIPKART') OR (base.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
        AND date_key BETWEEN 20240901 AND 20241031

    GROUP BY
        date_map.dates_current_year,
        base.marketplace_id,
        cat.analytic_business_unit,
        cat.analytic_super_category,
        cat.analytic_vertical,
        CASE WHEN is_first_party_seller = TRUE THEN 'Alpha' ELSE 'Mp' END,
        6, -- brand position
        12, -- price_point position
        CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
        14, -- branded_flag position
        'null', -- **New Group By for Service Profile**
        date_map.event_type


    UNION ALL

    -- **6. current_year_pricing (PRICING)**
    SELECT
        'current_year_pricing' AS domain_flag,
        order_date_key AS order_date_key,
        marketplace AS marketplace,
        analytic_business_unit AS analytic_business_unit,
        analytic_super_category AS analytic_super_category,
        analytic_vertical AS analytic_vertical,
        is_alpha_seller AS is_alpha_seller,
        brand,
        city_tier,
        zone,

        CASE WHEN analytic_business_unit IN ('BGM', 'Home') THEN 11
             WHEN analytic_business_unit IN ('Furniture') THEN 12
        END AS price_point,
        kam_nkam_flag,
        branded_flag,
        service_profile, -- <<< ADDED - From subquery

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,
        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,
        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,
        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,


        SUM(input_bau_weighted_asp) AS cy_input_bau_weighted_asp,
        SUM(input_fes_weighted_asp) AS cy_input_fes_weighted_asp,
        SUM(output_bau_weighted_asp) AS cy_output_bau_weighted_asp,
        SUM(output_fes_weighted_asp) AS cy_output_fes_weighted_asp,


        0.0 AS ly_input_bau_weighted_asp,
        0.0 AS ly_input_fes_weighted_asp,
        0.0 AS ly_output_bau_weighted_asp,
        0.0 AS ly_output_fes_weighted_asp,
        event_type AS event_type

    FROM
    (
        SELECT
            bau.marketplace AS marketplace,
            bau.analytic_business_unit AS analytic_business_unit,
            bau.analytic_super_category AS analytic_super_category,
            bau.analytic_vertical AS analytic_vertical,
            bau.is_alpha_seller AS is_alpha_seller,
            bau.brand AS brand,
            bau.city_tier AS city_tier,
            bau.zone AS zone,
            bau.kam_nkam_flag AS kam_nkam_flag,
            bau.branded_flag AS branded_flag,
            fes.event_type AS event_type,

            bau.service_profile AS service_profile, -- <<< ADDED - From BAU subquery

            bau.product_id AS product_id,
            bau.listing_id AS listing_id,
            fes.order_date_key AS order_date_key,
            bau.gmv / bau.units AS bau_price_point,
            (bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
            (fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
            (bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
            (fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp

        FROM
        (
            -- BAU Subquery for Pricing CY
            SELECT
                sales.marketplace_id AS marketplace,
                cat.analytic_business_unit,
                cat.analytic_super_category,
                cat.analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
                6, -- brand position
                13, -- branded_flag position
                geo.city_tier AS city_tier,
                geo.zone AS zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

                -- **New Service Profile Logic in BAU**
                CASE
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF'
                    WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
                    ELSE 'null'
                END AS service_profile,

                sales.product_id,
                sales.listing_id,
                SUM(units) / 62 AS units,
                SUM(gmv) / 62 AS gmv,
                SUM(listing_price) AS lp

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            -- ... (All joins remain the same) ...
            LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat ON sales.product_id = cat.product_id
            LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5 ON sales.seller_id = t5.seller_id
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 AS fur_b ON LOWER(cat.analytic_super_category) = LOWER(fur_b.analytic_super_category) AND LOWER(cat.brand) = LOWER(fur_b.brand) AND LOWER(cat.analytic_vertical) = LOWER(fur_b.analytic_vertical)
            LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(home_b.brand)
            LEFT JOIN (SELECT LOWER(analytic_super_category) AS analytic_super_category, LOWER(brand) AS brand, MIN(branded_flag) AS branded_flag FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0 GROUP BY 1, 2) bgm_b ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(bgm_b.brand)


            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20250701 AND 20250831

            GROUP BY
                sales.marketplace_id,
                cat.analytic_business_unit,
                cat.analytic_super_category,
                cat.analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
                6, -- brand position
                13, -- branded_flag position
                geo.city_tier,
                geo.zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
                11, -- service_profile position
                sales.product_id,
                sales.listing_id
        ) bau
        INNER JOIN
        (
            -- Festive Subquery for Pricing CY
            SELECT
                sales.listing_id,
                order_date_key,
                SUM(units) AS units,
                SUM(gmv) AS gmv,
                SUM(listing_price) AS lp,
                date_map.event_type AS event_type
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON sales.order_date_key = date_map.dates_current_year
            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20250823 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64)
            GROUP BY 1, 2, 6
        ) fes ON bau.listing_id = fes.listing_id
    ) sub
    GROUP BY
        order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        is_alpha_seller,
        brand,
        city_tier,
        zone,
        10, -- price_point position
        kam_nkam_flag,
        branded_flag,
        service_profile, -- <<< ADDED to GROUP BY
        event_type


    UNION ALL

    -- **7. last_year_pricing (PRICING)**
    SELECT
        'last_year_pricing' AS domain_flag,
        order_date_key AS order_date_key,
        marketplace AS marketplace,
        analytic_business_unit AS analytic_business_unit,
        analytic_super_category AS analytic_super_category,
        analytic_vertical AS analytic_vertical,
        is_alpha_seller AS is_alpha_seller,
        brand,
        city_tier,
        zone,
        CASE WHEN analytic_business_unit IN ('BGM', 'Home') THEN 11
             WHEN analytic_business_unit IN ('Furniture') THEN 12
        END AS price_point,
        kam_nkam_flag,
        branded_flag,
        service_profile, -- <<< ADDED - From subquery

        0.0 AS cy_gmv,
        0.0 AS cy_units,
        0.0 AS ly_gmv,
        0.0 AS ly_units,
        0.0 AS cy_ja_gmv,
        0.0 AS cy_ja_units,
        0.0 AS ly_ja_gmv,
        0.0 AS ly_ja_units,
        0.0 AS cy_search_ppvs,
        0.0 AS cy_primary_ppvs,
        0.0 AS cy_net_units,
        0.0 AS ly_search_ppvs,
        0.0 AS ly_primary_ppvs,
        0.0 AS ly_net_units,
        0.0 AS cy_ja_search_ppvs,
        0.0 AS cy_ja_primary_ppvs,
        0.0 AS cy_ja_net_units,
        0.0 AS ly_ja_search_ppvs,
        0.0 AS ly_ja_primary_ppvs,
        0.0 AS ly_ja_net_units,


        0.0 AS cy_input_bau_weighted_asp,
        0.0 AS cy_input_fes_weighted_asp,
        0.0 AS cy_output_bau_weighted_asp,
        0.0 AS cy_output_fes_weighted_asp,

        SUM(input_bau_weighted_asp) AS ly_input_bau_weighted_asp,
        SUM(input_fes_weighted_asp) AS ly_input_fes_weighted_asp,
        SUM(output_bau_weighted_asp) AS ly_output_bau_weighted_asp,
        SUM(output_fes_weighted_asp) AS ly_output_fes_weighted_asp,
        event_type AS event_type

    FROM
    (
        SELECT
            bau.marketplace AS marketplace,
            bau.analytic_business_unit AS analytic_business_unit,
            bau.analytic_super_category AS analytic_super_category,
            bau.analytic_vertical AS analytic_vertical,
            bau.is_alpha_seller AS is_alpha_seller,
            bau.brand AS brand,
            bau.city_tier AS city_tier,
            bau.zone AS zone,
            bau.kam_nkam_flag,
            bau.branded_flag AS branded_flag,
            fes.event_type AS event_type,

            bau.service_profile AS service_profile, -- <<< ADDED - From BAU subquery

            bau.product_id AS product_id,
            bau.listing_id AS listing_id,
            fes.order_date_key AS order_date_key,
            bau.gmv / bau.units AS bau_price_point,
            (bau.gmv / bau.units) * bau.units AS input_bau_weighted_asp,
            (fes.gmv / fes.units) * bau.units AS input_fes_weighted_asp,
            (bau.gmv / bau.units) * fes.units AS output_bau_weighted_asp,
            (fes.gmv / fes.units) * fes.units AS output_fes_weighted_asp

        FROM
        (
            -- BAU Subquery for Pricing LY
            SELECT
                sales.marketplace_id AS marketplace,
                cat.analytic_business_unit AS analytic_business_unit,
                cat.analytic_super_category AS analytic_super_category,
                cat.analytic_vertical AS analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
                6, -- brand position
                13, -- branded_flag position
                geo.city_tier AS city_tier,
                geo.zone AS zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS kam_nkam_flag,

                -- **New Service Profile Logic in BAU**
                CASE
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%\\alite\\%' OR LOWER(sales.source_facility_id) LIKE '%\\al\\%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF'
                    WHEN sales.service_profile IN ('NON_FBF', 'FBF_LITE') THEN 'NFBF'
                    ELSE 'null'
                END AS service_profile,

                sales.product_id,
                sales.listing_id,
                SUM(units) / 62 AS units,
                SUM(gmv) / 62 AS gmv,
                SUM(listing_price) AS lp

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            -- ... (All joins remain the same) ...
            LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat ON sales.product_id = cat.product_id
            LEFT JOIN (SELECT seller_id, MIN(managed_by) AS owner FROM fdp_uploads.ds_fkint_analytics_cdo_seller_kam_ukam_mapping_1_0 GROUP BY seller_id) AS t5 ON sales.seller_id = t5.seller_id
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_furniture_brand_mapping_analytics_1_0 AS fur_b ON LOWER(cat.analytic_super_category) = LOWER(fur_b.analytic_super_category) AND LOWER(cat.brand) = LOWER(fur_b.brand) AND LOWER(cat.analytic_vertical) = LOWER(fur_b.analytic_vertical)
            LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 home_b ON LOWER(sales.analytic_super_category) = LOWER(home_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(home_b.brand)
            LEFT JOIN (SELECT LOWER(analytic_super_category) AS analytic_super_category, LOWER(brand) AS brand, MIN(branded_flag) AS branded_flag FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0 GROUP BY 1, 2) bgm_b ON LOWER(sales.analytic_super_category) = LOWER(bgm_b.analytic_super_category) AND LOWER(sales.brand) = LOWER(bgm_b.brand)


            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND (sales.marketplace_id IN ('FLIPKART'))
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20240701 AND 20240831

            GROUP BY
                sales.marketplace_id,
                cat.analytic_business_unit,
                cat.analytic_super_category,
                cat.analytic_vertical,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
                6, -- brand position
                13, -- branded_flag position
                geo.city_tier,
                geo.zone,
                CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END,
                11, -- service_profile position
                sales.product_id,
                sales.listing_id
        ) bau
        INNER JOIN
        (
            -- Festive Subquery for Pricing LY
            SELECT
                sales.listing_id,
                date_map.dates_current_year AS order_date_key,
                SUM(units) AS units,
                SUM(gmv) AS gmv,
                SUM(listing_price) AS lp,
                date_map.event_type AS event_type

            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 AS date_map ON sales.order_date_key = date_map.dates_last_year
            WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
                AND sales.type != 'service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM', 'Home', 'Furniture')
                AND order_date_key BETWEEN 20240901 AND 20241031

            GROUP BY 1, 2, 6
        ) fes ON bau.listing_id = fes.listing_id
    ) sub

    GROUP BY
        order_date_key,
        marketplace,
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        is_alpha_seller,
        brand,
        city_tier,
        zone,
        10, -- price_point position
        kam_nkam_flag,
        branded_flag,
        service_profile, -- <<< ADDED to GROUP BY
        event_type

) AS festive_dates