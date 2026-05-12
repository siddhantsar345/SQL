SELECT 
    sales.order_date_key AS order_date_key,
    sales.analytic_business_unit AS analytic_business_unit, 
    sales.analytic_super_category AS analytic_super_category,
    sales.analytic_vertical AS analytic_vertical,

    CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END AS brand, 
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS brand_flag,

    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller, 
    CASE WHEN hyper.pincode IS NOT NULL THEN 'Serviceable' ELSE 'Non-Serviceable' END AS serviceability_status,

    CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "301-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "501-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "1000+"
    END AS price_bucket,
    
    case 
    when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end as service_profile,

    SUM(sales.units) AS overall_units, 
    SUM(CASE WHEN sales.sla_in_days <= 0 THEN 1 ELSE 0 END) AS d0_units,
    SUM(CASE WHEN sales.sla_in_days <= 1 THEN 1 ELSE 0 END) AS d1_units,
    SUM(CASE WHEN sales.sla_in_days <= 2 THEN 1 ELSE 0 END) AS d2_units,
    SUM(CASE WHEN sales.sla_in_days <= 4 THEN 1 ELSE 0 END) AS d4_units,
    SUM(CASE WHEN sales.sla_in_days <= 6 THEN 1 ELSE 0 END) AS d6_units,
    SUM(rudata.ru_den) AS ru_den, 
    SUM(rudata.ru_num) AS ru_num

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim prod_cat
    ON sales.product_id = prod_cat.product_id

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON CAST(sales.pincode AS STRING) = CAST(hyper.pincode AS STRING)

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo 
    ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key 

LEFT JOIN (
    SELECT
        brand,
        analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
) bmp
    ON LOWER(sales.brand) = LOWER(bmp.brand)
    AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)

LEFT JOIN (
    SELECT
        ff.fulfill_item_unit_id,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2') THEN fulfill_item_unit_id END) AS ru_num,
        COUNT(DISTINCT CASE WHEN fulfill_item_unit_granular_shipment_movement_type IN ('L1', 'L2', 'Z1', 'Z2','N1','N2') THEN fulfill_item_unit_id END) AS ru_den
    FROM bigfoot_external_neo.scp_fulfillment__fulfillment_unit_hive_365_fact ff
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON ff.fulfill_item_product_id = cat.product_id
    WHERE (ff.fulfill_item_unit_order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))
        AND LOWER(cat.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    GROUP BY ff.fulfill_item_unit_id
) AS rudata
    ON sales.fulfill_item_unit_id = rudata.fulfill_item_unit_id

WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type != 'service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.is_shopsy_order = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND (sales.order_date_key BETWEEN 20260101 AND CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64))

GROUP BY 
    sales.order_date_key,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
    
    CASE WHEN bmp.brand IS NOT NULL THEN prod_cat.brand ELSE 'Unbranded' END,
    CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
    CASE WHEN hyper.pincode IS NOT NULL THEN 'Serviceable' ELSE 'Non-Serviceable' END,
    CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "301-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "501-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "1000+"
    END,
    case 
    when is_alpha_seller = TRUE and ((lower(sales.source_facility_id)  like '%\\_alite\\_%') or (lower(sales.source_facility_id) like '%\\_al\\_%')) then 'Alite'
    when sales.service_profile = 'FBF' then 'FBF' 
    when sales.service_profile in ('NON_FBF','FBF_LITE') then 'NFBF'
    else 'null' end