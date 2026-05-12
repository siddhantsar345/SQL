--- selection overall --


WITH month_end AS (
    SELECT 
        substr(cast(process_date_key as string),1,6) as year_mo,
        MAX(process_date_key) as report_date
    
    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact
    WHERE marketplace_id = 'FLIPKART'
        AND process_date_key >= 20260501
    GROUP BY substr(cast(process_date_key as string),1,6)
)

SELECT 
    med.year_mo, 
    list_dim.process_date_key as snapshot_used, 
    
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    "" as analytic_vertical,

    count(distinct list_dim.listing_id) as a_listings,
    count(distinct list_dim.product_id) as a_products,

    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products,
    

    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.listing_id end) as a_fbf_lids,
    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.product_id end) as a_fbf_pids,


    count(distinct case when (lower(list_dim.service_profile) in ("non_fbf","fbf_and_non_fbf") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_nfbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("non_fbf","fbf_and_non_fbf") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_nfbf_pids,


    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_fbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_fbf_pids


FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

INNER JOIN month_end med
    ON list_dim.process_date_key = med.report_date

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in ('furniture', 'home')
    and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4,5



-- New selection --


SELECT 
    FORMAT_DATETIME('%Y%m', listing_created_on) as year_mo,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    "" as analytic_vertical,
    count(distinct listing_id) as new_selection_listings,
    count(distinct case when listing_created_on = first_seen then list.product_id end) as new_selection_products

FROM
(
    SELECT 
        listing_id,
        product_id,
        listing_created_on,
        min(listing_created_on) over(PARTITION by product_id) as first_seen
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
) as list

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    ON list.product_id = prod_dim.product_id

WHERE CAST(listing_created_on AS DATE) >= '2026-05-01'
  AND lower(prod_dim.analytic_business_unit) in ('home', 'furniture')    
  AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        
GROUP BY 1,2,3,4


-- transacting selection --

SELECT
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    "" as analytic_vertical,
    substring(cast(sales.order_date_key as string),1,6) as year_mo,
    count(distinct sales.listing_id) as trans_lid_count,
    count(distinct sales.product_id) as trans_pid_count,
    sum(sales.units) as sales_units,
    sum(sales.gmv) as gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim as prod_dim
    on sales.product_id = prod_dim.product_id

WHERE
    lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.category_id NOT IN (21726, 21651)
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id = 'FLIPKART'
    AND sales.is_shopsy_order = False
    AND sales.order_date_key >= 20260501
    AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
    AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
    AND (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4

-- new transaction selection --

SELECT
    substring(cast(sales.order_date_key as string),1,6) as year_mo,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    "" as analytic_vertical,
    count(distinct sales.listing_id) as trans_lid_count,
    count(distinct sales.product_id) as trans_pid_count,
    sum(sales.gmv) as gmv,
    sum(sales.units) as sales_units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on sales.product_id = prod_dim.product_id

LEFT JOIN (
    SELECT 
        listing_id, 
        CAST(MIN(listing_created_on) AS DATE) as listing_birth_date
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
    AND listing_created_on >= '2024-08-01'
    GROUP BY 1
) list_dim_fact
on list_dim_fact.listing_id = sales.listing_id

WHERE
    lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.category_id NOT IN (21726, 21651)
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id = 'FLIPKART'
    AND sales.is_shopsy_order = False
    
    AND sales.order_date_key >= 20260501
    
    AND DATE_DIFF(
            PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING)), 
            list_dim_fact.listing_birth_date, 
            DAY
        ) <= 90

    AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
    AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
    AND (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4


-- new selection ppvs --


    SELECT
        a.yr_month,
        analytic_business_unit,
        analytic_super_category,
        "" as analytic_vertical,
        COUNT(DISTINCT CASE WHEN total_ppvs >= 50 THEN listing_id END) AS ppv_count,
        COUNT(listing_id) AS ppv_count1,
        COUNT(DISTINCT CASE WHEN total_ppvs >= 1 THEN listing_id END) AS ppv_counts
        
    FROM (
        SELECT
            sales.listing_id,
            sales.analytic_business_unit,
            sales.analytic_super_category,
            "" as analytic_vertical,
            substring(cast(sales.date_key as string),1,6) as yr_month,

            SUM(COALESCE(sales.primary_ppvs, 0)) AS total_ppvs

        FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales
        
        LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
            ON sales.product_id = prod_dim.product_id

        LEFT JOIN (
            SELECT 
                listing_id, 
                flipkart_selling_price,
                CAST(MIN(listing_created_on) AS DATE) as listing_birth_date
            FROM bigfoot_external_neo.sp_product__listing_hive_dim
            WHERE marketplace_id = 'FLIPKART'
            AND listing_created_on >= '2024-08-01'
            GROUP BY 1, 2
        ) lhd
        ON sales.listing_id = lhd.listing_id

        WHERE sales.marketplace_id = 'FLIPKART' 
            AND sales.date_key >= 20260501
            AND DATE_DIFF(
                    PARSE_DATE('%Y%m%d', CAST(sales.date_key AS STRING)), 
                    lhd.listing_birth_date, 
                    DAY
                ) <= 90
            
            AND lower(sales.analytic_business_unit) in ('home', 'furniture')
            AND lower(sales.analytic_vertical) not in ('plantsapling', 'plantseed')
            AND (sales.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

        GROUP BY 1, 2, 3, 4, 5
    ) as a
    GROUP BY 1, 2, 3, 4

-- ppvs --

SELECT 
    year_mo,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    "" AS analytic_vertical,
    count(DISTINCT CASE WHEN primary_ppvs >= 1 THEN listing_id END) AS ppv_1_lid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 1000 THEN listing_id END) AS ppv_1000_lid_count,
    sum(units) AS total_units,

    count(DISTINCT CASE WHEN primary_ppvs >= 1 THEN product_id END) AS ppv_1_pid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 1000 THEN product_id END) AS ppv_1000_pid_count,

    count(DISTINCT CASE WHEN primary_ppvs >= 1 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN listing_id END) AS ppv_1_fbf_lid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 1000 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN listing_id END) AS ppv_1000_fbf_lid_count,

    count(DISTINCT CASE WHEN primary_ppvs >= 1 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN product_id END) AS ppv_1_fbf_pid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 1000 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN product_id END) AS ppv_1000_fbf_pid_count,

    count(DISTINCT CASE WHEN primary_ppvs >= 50 THEN listing_id END) AS ppv_50_lid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 50 THEN product_id END) AS ppv_50_pid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 50 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN listing_id END) AS ppv_50_fbf_lid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 50 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN product_id END) AS ppv_50_fbf_pid_count,

    count(DISTINCT CASE WHEN primary_ppvs >= 10 THEN listing_id END) AS ppv_10_lid_count,
    count(DISTINCT CASE WHEN primary_ppvs >= 10 AND lower(service_profile) IN ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") THEN listing_id END) AS ppv_10_fbf_lid_count

FROM 
(
    SELECT
        sales.listing_id,
        sales.product_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        "" AS analytic_vertical,
        sales.service_profile,
        substr(cast(sales.date_key as string),1,6) as year_mo,
        sum(COALESCE(sales.primary_ppvs, 0)) AS primary_ppvs,
        sum(COALESCE(sales.gross_units, 0)) AS units

    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales
    
    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        ON sales.product_id = prod_dim.product_id

    WHERE sales.marketplace_id='FLIPKART' 
        AND sales.date_key >= 20260501
        AND lower(sales.analytic_business_unit) IN ('home', 'furniture')
        AND lower(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')
        AND (prod_dim.analytic_vertical NOT IN ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') OR prod_dim.vertical_name IN ('book','regionalbooks')) 

    GROUP BY 1,2,3,4,5,6,7
) AS sales
GROUP BY 1,2,3,4



--- price point selection overall -fsp -----

WITH month_end AS (
    SELECT 
        substr(cast(process_date_key as string),1,6) as year_mo,
        MAX(process_date_key) as report_date
    
    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact
    WHERE marketplace_id = 'FLIPKART'
        AND process_date_key >= 20260501
    GROUP BY substr(cast(process_date_key as string),1,6)
)

SELECT 
    med.year_mo, 
    list_dim.process_date_key as snapshot_used,
    CASE
    WHEN list_dim.flipkart_selling_price <= 200 THEN "0-200"
    WHEN list_dim.flipkart_selling_price > 200 AND list_dim.flipkart_selling_price <= 300 THEN "201-300"
    WHEN list_dim.flipkart_selling_price > 300 AND list_dim.flipkart_selling_price <= 500 THEN "301-500"
    WHEN list_dim.flipkart_selling_price > 500 AND list_dim.flipkart_selling_price <= 1000 THEN "501-1000"
    WHEN list_dim.flipkart_selling_price > 1000 THEN "1000+"
    ELSE "NA"
    END AS price_bucket,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,

    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products,

    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.listing_id end) as a_fbf_lids,
    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.product_id end) as a_fbf_pids,


    count(distinct case when (lower(list_dim.service_profile) in ("non_fbf","fbf_and_non_fbf") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_nfbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("non_fbf","fbf_and_non_fbf") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_nfbf_pids,


    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_fbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_fbf_pids

    
FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

INNER JOIN month_end med
    ON list_dim.process_date_key = med.report_date

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in ('furniture', 'home')
    and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4,5




--- price point selection overall -fsp from aggregated fact -----

SELECT 
    list_dim.year_month, 
    CASE
    WHEN list_dim.fsp_bucket <= 200 THEN "0-200"
    WHEN list_dim.fsp_bucket > 200 AND list_dim.fsp_bucket <= 300 THEN "201-300"
    WHEN list_dim.fsp_bucket > 300 AND list_dim.fsp_bucket <= 500 THEN "301-500"
    WHEN list_dim.fsp_bucket > 500 AND list_dim.fsp_bucket <= 1000 THEN "501-1000"
    WHEN list_dim.fsp_bucket > 1000 THEN "1000+"
    ELSE "NA"
    END AS fsp_bucket,
    list_dim.analytic_business_unit,
    list_dim.analytic_super_category,

    sum(a_lid_count) as a_lid_count,
    sum(ai_lid_count) as ai_lid_count,
    sum(a_pid_count) as a_pid_count,
    sum(ai_pid_count) as ai_pid_count,
    sum(ai_fbf_lids) as ai_fbf_lids,
    sum(ai_nfbf_lids) as ai_nfbf_lids
    
FROM bigfoot_external_neo.analytics_cdo__selection_historical_aggregated_snapshot_fact as list_dim

WHERE
    lower(list_dim.analytic_business_unit) in ('furniture', 'home')
    and lower(list_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
    and (list_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or list_dim.vertical_name in ('book','regionalbooks'))
    and year_month between 20250101 and 20250731

GROUP BY list_dim.year_month,
fsp_bucket,
list_dim.analytic_business_unit,
list_dim.analytic_super_category