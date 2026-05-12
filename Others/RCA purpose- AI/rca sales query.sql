select
    order_date_key,
    cat.analytic_business_unit as business_unit,
    cat.analytic_super_category as super_category,
    CASE WHEN pareto.analytic_vertical is not null then cat.analytic_vertical else 'Non Pareto Vertical' end as vertical,
    CASE WHEN bmp.brand is not null then sales.brand else 'Unbranded' end as brand,
    CASE WHEN bmp.brand is not null then 'Branded' else 'Unbranded' end as branded_flag,
    CASE when sales.is_alpha_seller = TRUE THEN 'Diamond' else 'MP' end as diamond_mp_flag,
    CASE
    WHEN geo.city_tier IN ('Metro') THEN 'Metro' 
    WHEN geo.city_tier IN ('Tier 1A') THEN 'T1'
    WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+' 
    END AS city_tier,
    geo.zone,
    CASE WHEN hyper.pincode is not null then TRUE else FALSE end as is_minutes_serviceable,
    CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+" END AS price_bucket,
    SUM(gmv) as gmv,
    SUM(units) as units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON cat.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    and sales.marketplace_id='HYPERLOCAL'

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
    ON sales.pincode  = hyper.pincode

LEFT JOIN
        (
        select
            brand,
                analytic_super_category
        from fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
        group by       
            brand,
            analytic_super_category
        ) bmp
        on lower(sales.brand) = lower(bmp.brand) 
        and lower(sales.analytic_super_category) = lower(bmp.analytic_super_category)

LEFT JOIN
    (
    SELECT 
        analytic_super_category, 
        analytic_vertical

    FROM
    (
    SELECT
        analytic_super_category,
        analytic_vertical,
        sum(vertical_gmv) over (partition by analytic_super_category order by vertical_gmv desc ROWS UNBOUNDED PRECEDING) as vert_gmv_cumilative,
        sum(vertical_gmv) over (partition by analytic_super_category) as total_sc_gmv,
        sum(vertical_gmv) over (partition by analytic_super_category order by vertical_gmv desc)/sum(vertical_gmv) over (partition by analytic_super_category) as percentage_value

    FROM
        (
        SELECT
        sales.analytic_super_category,
        sales.analytic_vertical,
        SUM(gmv) as vertical_gmv
            
        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

        WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
            AND sales.type !='service'
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie =FALSE
            AND sales.marketplace_id IN ('FLIPKART')
            AND sales.is_shopsy_order =FALSE
            AND lower(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
            AND order_date_key BETWEEN 20250701 AND 20260331
            
        GROUP BY 
        sales.analytic_super_category,
        sales.analytic_vertical
        ) base 
    )base2

    WHERE percentage_value <=  0.8
    ) pareto 
    ON sales.analytic_super_category = pareto.analytic_super_category
    AND sales.analytic_vertical = pareto.analytic_vertical

    where lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type !='service'
        AND replacement_for_unit IS NULL
        AND exchange_for_unit IS NULL
        AND is_freebie =FALSE
        AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
        AND lower(cat.analytic_business_unit) in ('bgm','home','lifestyle','furniture')
        AND sales.is_shopsy_order =FALSE
        AND order_date_key BETWEEN 20240801 AND 20240815

group by
    order_date_key,
    cat.analytic_business_unit,
    cat.analytic_super_category,
    CASE WHEN pareto.analytic_vertical is not null then cat.analytic_vertical else 'Non Pareto Vertical' end,
    CASE 
    WHEN geo.city_tier IN ('Metro') THEN 'Metro' 
    WHEN geo.city_tier IN ('Tier 1A') THEN 'T1'
    WHEN geo.city_tier IN ('Tier 2', 'Tier 3 & Others') THEN 'T2+' 
    END,
    geo.zone,
    case when sales.is_alpha_seller = TRUE THEN 'Diamond' else 'MP' end,
    CASE 
        WHEN sales.gmv / sales.units <= 300 THEN "a) 0-300"
        WHEN sales.gmv / sales.units > 300 AND sales.gmv / sales.units <= 500 THEN "b) 300-500"
        WHEN sales.gmv / sales.units > 500 AND sales.gmv / sales.units <= 1000 THEN "c) 500-1000"
        WHEN sales.gmv / sales.units > 1000 THEN "d) 1000+" END,

    CASE WHEN bmp.brand is not null then 'Branded' else 'Unbranded' end,
    CASE WHEN bmp.brand is not null then sales.brand else 'Unbranded' end,
    CASE 
        WHEN hyper.pincode is not null then TRUE 
        else FALSE 
    end