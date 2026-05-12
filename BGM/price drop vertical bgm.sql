WITH vertical_gmv_table AS (
    SELECT
        sales.analytic_super_category,
        sales.analytic_vertical,
        SUM(gmv) AS vertical_gmv
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type !='service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.is_shopsy_order = FALSE
        AND sales.analytic_business_unit IN ('BGM')
        AND order_date_key BETWEEN 20250701 AND 20250831
    GROUP BY 1, 2
),

cum_sum_vertical AS (
    SELECT
        analytic_super_category,
        analytic_vertical,
        SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC ROWS UNBOUNDED PRECEDING) AS vert_gmv_cumilative,
        SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS total_sc_gmv,
        SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC) / SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS percentage_value
    FROM vertical_gmv_table
),

top_80_percent_vertical_bgm AS (
   SELECT analytic_super_category, analytic_vertical
   FROM cum_sum_vertical
   WHERE percentage_value <= 0.8
)

SELECT
    t1.order_date_key,
    t1.analytic_business_unit,
    t1.analytic_super_category,
    case when top_verticals.analytic_vertical is not null then t1.analytic_vertical end as analytic_vertical,
    CASE WHEN b.branded_flag = 'Branded' THEN b.brand ELSE 'others' END AS brand,
    CASE WHEN b.branded_flag = 'Branded' THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
    asp_bucket AS price_bucket,
    CASE WHEN t1.is_alpha_seller = 'alpha' THEN 'Diamond' ELSE 'Rest of MP' END AS alpha_mp_flag,
    service_profile_flag,
    CASE WHEN t5.owner = 'KAM' THEN 'KAM' ELSE 'N-KAM' END AS managed_seller_flag,
    
    
    SUM(t1.input_fes_weighted_asp) AS input_festive_weighted_asp_sum,
    SUM(t1.input_bau_weighted_asp) AS input_bau_weighted_asp_sum,
    SUM(t1.output_fes_weighted_asp) AS output_festive_weighted_asp_sum,
    SUM(t1.output_bau_weighted_asp) AS output_bau_weighted_asp_sum,

    SUM(t1.input_fes_weighted_fsp) AS input_festive_weighted_fsp_sum,
    SUM(t1.input_bau_weighted_fsp) AS input_bau_weighted_fsp_sum,
    SUM(t1.output_fes_weighted_fsp) AS output_fes_weighted_fsp_sum,
    SUM(t1.outut_bau_weighted_fsp) AS outut_bau_weighted_fsp_sum

FROM (
    SELECT
        a.*,
        CASE 
            WHEN bau_asp BETWEEN 0 AND 300 THEN '0-300'
            WHEN bau_asp BETWEEN 300 AND 500 THEN '300-500'
            WHEN bau_asp BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE '1000_plus' 
        END AS asp_bucket
    FROM (
        SELECT
            bau.analytic_business_unit,
            bau.analytic_super_category,
            bau.analytic_vertical,
            bau.listing_id,
            bau.seller_id,
            bau.brand,
            bau.is_alpha_seller,
            bau.service_profile_flag,
            fes.order_date_key,
            bau.units AS bau_units_sum,
            fes.units AS fes_units_sum,
            (bau.gmv/bau.units)*bau.units AS input_bau_weighted_asp,
            (bau.gmv/bau.units)*fes.units AS output_bau_weighted_asp,
            (fes.gmv/fes.units)*bau.units AS input_fes_weighted_asp,
            (fes.gmv/fes.units)*fes.units AS output_fes_weighted_asp,
            (fes.lp/fes.units)*bau.units AS input_fes_weighted_fsp,
            (bau.lp/bau.units)*bau.units AS input_bau_weighted_fsp,
            (fes.lp/fes.units)*fes.units AS output_fes_weighted_fsp,
            (bau.lp/bau.units)*fes.units AS outut_bau_weighted_fsp,
            fes.gmv AS fest_gmv,
            bau.gmv AS tot_bau_gmv,
            bau.gmv/bau.units AS bau_asp
        FROM (
            SELECT
                sales.analytic_business_unit,
                sales.analytic_super_category,
                sales.analytic_vertical,
                sales.listing_id,
                sales.seller_id,
                sales.brand,
                CASE WHEN sales.is_alpha_seller = TRUE THEN 'alpha' ELSE 'MP' END AS is_alpha_seller,
                CASE 
                    WHEN sales.is_alpha_seller = TRUE AND (LOWER(sales.source_facility_id) LIKE '%alite%' OR LOWER(sales.source_facility_id) LIKE '%al%') THEN 'Alite'
                    WHEN sales.service_profile = 'FBF' THEN 'FBF' 
                    WHEN sales.service_profile IN ('NON_FBF','FBF_LITE') THEN 'NFBF'
                    ELSE 'null' END AS service_profile_flag,
                sales.order_date_key,
                SUM(units) AS units,
                SUM(gmv) AS gmv,
                SUM(listing_price) + SUM(COALESCE((CAST(REGEXP_EXTRACT(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) AS NUMERIC)), 0)) AS lp
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
            WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                AND sales.type !='service'
                AND sales.replacement_for_unit IS NULL
                AND sales.exchange_for_unit IS NULL
                AND sales.is_freebie = FALSE
                AND sales.marketplace_id IN ('FLIPKART')
                AND sales.is_shopsy_order = FALSE
                AND sales.analytic_business_unit IN ('BGM')
                AND order_date_key BETWEEN 20250701 AND 20250831
            GROUP BY 1,2,3,4,5,6,7,8,9
        ) bau
        INNER JOIN (
            SELECT
                sales.listing_id,
                order_date_key,
                SUM(units) AS units,
                SUM(net_amount) AS gmv,
                SUM(listing_price) + SUM(COALESCE((CAST(REGEXP_EXTRACT(construct_fee_adjustments, '"amount":([0-9.]+)[^}]*?"referenceId":"iks:001"', 1) AS NUMERIC)), 0)) AS lp
            FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
            WHERE LOWER(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
                AND sales.unit_type !='service'
                AND sales.marketplace_id IN ('FLIPKART')
                AND LOWER(sales.is_shopsy_order) = 'false'
                AND sales.business_unit IN ('BGM')
                AND order_date_key BETWEEN 20260101 AND CAST(DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd') AS BIGINT)
            GROUP BY 1,2
        ) fes ON bau.listing_id = fes.listing_id
    ) AS a
) AS t1

LEFT JOIN (
       SELECT LOWER(analytic_super_category) AS analytic_super_category, 
       LOWER(brand) AS brand, 
       MIN(branded_flag) AS branded_flag
       FROM fdp_uploads.ds_fkint_analytics_cdo_bgm_sc_brand_mapping_analytics_1_0
       GROUP BY 1, 2
    ) b ON LOWER(sales.analytic_super_category) = b.analytic_super_category 
    AND LOWER(sales.brand) = b.brand


LEFT JOIN top_80_percent_vertical_bgm AS top_verticals
    ON top_verticals.analytic_vertical = t1.analytic_vertical 
    AND top_verticals.brand = t1.brand

LEFT JOIN (
    SELECT
        seller_id,
        MIN(owner) AS owner
    FROM fdp_uploads.ds_fkint_mp_sp_sellers_owners_mapping_fact_1_2
    GROUP BY seller_id
) AS t5 ON t1.seller_id = t5.seller_id

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12;