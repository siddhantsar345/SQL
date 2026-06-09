-- selection overall-- 

SELECT
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    list_dim.process_date_key AS snapshot_used,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,

    COUNT(DISTINCT list_dim.listing_id) AS a_listings,
    COUNT(DISTINCT list_dim.product_id) AS a_products,

    COUNT(DISTINCT CASE WHEN list_dim.final_atp > 0 THEN list_dim.listing_id END) AS ai_listings,
    COUNT(DISTINCT CASE WHEN list_dim.final_atp > 0 THEN list_dim.product_id END) AS ai_products,
    
    COUNT(DISTINCT CASE WHEN list_dim.service_profile = 'FBF' THEN list_dim.listing_id END) AS a_fbf_lids,
    COUNT(DISTINCT CASE WHEN list_dim.service_profile = 'FBF' THEN list_dim.product_id END) AS a_fbf_pids,

    COUNT(DISTINCT CASE WHEN (LOWER(list_dim.service_profile) IN ('non_fbf','fbf_and_non_fbf') AND list_dim.final_atp > 0) THEN list_dim.listing_id END) AS ai_nfbf_lids,
    COUNT(DISTINCT CASE WHEN (LOWER(list_dim.service_profile) IN ('non_fbf','fbf_and_non_fbf') AND list_dim.final_atp > 0) THEN list_dim.product_id END) AS ai_nfbf_pids,

    COUNT(DISTINCT CASE WHEN (LOWER(list_dim.service_profile) IN ('fbf','fbf_and_fbf_lite','fbf_and_non_fbf','fbf_lite') AND list_dim.final_atp > 0) THEN list_dim.listing_id END) AS ai_fbf_lids,
    COUNT(DISTINCT CASE WHEN (LOWER(list_dim.service_profile) IN ('fbf','fbf_and_fbf_lite','fbf_and_non_fbf','fbf_lite') AND list_dim.final_atp > 0) THEN list_dim.product_id END) AS ai_fbf_pids

FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact AS list_dim

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON list_dim.process_date_key = wd.date_dim_key

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    ON list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    AND LOWER(prod_dim.analytic_business_unit) IN ('furniture', 'home')
    AND LOWER(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')
    AND (
        prod_dim.analytic_vertical NOT IN (
            'MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover',
            'WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard',
            'CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard',
            'MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)',
            'MobileProtectionMobilePouches(OLD)'
        ) 
        OR prod_dim.vertical_name IN ('book','regionalbooks')
    )
    AND process_date_key between 20260401 AND 20260322

GROUP BY 1, 2, 3, 4, 5, 6


--2ND attempt selection overall --

WITH weekly_snapshot AS (
    SELECT 
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        MAX(list_dim.process_date_key) as report_date

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact list_dim

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
        ON list_dim.process_date_key = wd.date_dim_key
        
    WHERE list_dim.process_date_key >= 20260517
    AND list_dim.marketplace_id = 'FLIPKART'
    GROUP BY 1,2,3

)
SELECT 
    snap.week_begin_date,
    snap.yearmo,
    snap.week_num_in_year,
    
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,

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

INNER JOIN weekly_snapshot snap
    ON list_dim.process_date_key = snap.report_date

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in  ('furniture', 'home')
    and lower(analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4,5



-- New selection -- 


    SELECT
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    COUNT(DISTINCT list.listing_id) AS new_selection_listings,
    COUNT(DISTINCT CASE WHEN list.listing_created_on = list.first_seen THEN list.product_id END) AS new_selection_products
FROM
(
    SELECT 
        listing_id,
        product_id,
        listing_created_on,
        CAST(FORMAT_DATETIME('%Y%m%d', CAST(listing_created_on AS TIMESTAMP)) AS INT64) AS process_date_key,
        MIN(listing_created_on) OVER(PARTITION BY product_id) AS first_seen
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
) AS list

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON list.process_date_key = wd.date_dim_key

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    ON list.product_id = prod_dim.product_id

WHERE DATE(CAST(list.listing_created_on AS TIMESTAMP)) >= '2026-05-17'
  AND LOWER(prod_dim.analytic_business_unit) IN ('home', 'furniture')    
  AND LOWER(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')
  AND (
      prod_dim.analytic_vertical NOT IN (
          'MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover',
          'WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard',
          'CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard',
          'MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)',
          'MobileProtectionMobilePouches(OLD)'
      ) 
      OR prod_dim.vertical_name IN ('book','regionalbooks')
  ) 
GROUP BY 1, 2, 3, 4, 5


-- transacting selection-- 

SELECT
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.gmv) as gmv,
        sum(sales.units) as sales_units

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

    left join (
    select
        listing_id
        ,is_first_party_seller as is_alpha_seller
        ,flipkart_selling_price
    from bigfoot_external_neo.sp_product__listing_hive_dim
    where marketplace_id = 'FLIPKART'
) list_dim_fact
on list_dim_fact.listing_id = sales.listing_id

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
        AND sales.order_date_key >= 20260517
        AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    group by 1,2,3,4,5



    -- new transaction selection --

        SELECT
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        null as snapshot_used,
        null as lid_created_month_cohort,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.gmv) as gmv,
        sum(sales.units) as sales_units

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

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
        AND sales.order_date_key >= 20260517
        AND DATE_DIFF(
                PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING)), 
                list_dim_fact.listing_birth_date, 
                DAY
            ) <= 90
        AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
        AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        AND (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    GROUP BY 1,2,3,4,5,6,7


    --  ppvs --

    select
    sales.week_begin_date,
    sales.yearmo,
    sales.week_num_in_year,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    count(distinct case when primary_ppvs >= 1 then listing_id end) as ppv_1_lid_count,
    count(distinct case when primary_ppvs >= 1000 then listing_id end) as ppv_1000_lid_count,
    sum(units) as total_units,

    count(distinct case when primary_ppvs >= 1 then product_id end) as ppv_1_pid_count,
    count(distinct case when primary_ppvs >= 1000 then product_id end) as ppv_1000_pid_count,

    count(distinct case when primary_ppvs >= 1  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_1_fbf_lid_count,
    count(distinct case when primary_ppvs >= 1000  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_1000_fbf_lid_count,

    count(distinct case when primary_ppvs >= 1  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_1_fbf_pid_count,
    count(distinct case when primary_ppvs >= 1000  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_1000_fbf_pid_count,

    count(distinct case when primary_ppvs >= 50 then listing_id end) as ppv_50_lid_count,
    count(distinct case when primary_ppvs >= 50 then product_id end) as ppv_50_pid_count,
    count(distinct case when primary_ppvs >= 50  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_50_fbf_lid_count,
    count(distinct case when primary_ppvs >= 50  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_50_fbf_pid_count,

    count(distinct case when primary_ppvs >= 10 then listing_id end) as ppv_10_lid_count,
    count(distinct case when primary_ppvs >= 10  and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_10_fbf_lid_count,

from 
(
    SELECT
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        sales.listing_id,
        sales.product_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.service_profile,
        sum(COALESCE(sales.primary_ppvs, 0)) AS primary_ppvs,
        sum(COALESCE(sales.gross_units, 0)) AS units

    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.date_key = wd.date_dim_key

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        ON sales.product_id = prod_dim.product_id

    WHERE sales.marketplace_id='FLIPKART' 
        and sales.date_key >= 20260517
        and lower(sales.analytic_business_unit) in ('home', 'furniture')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 


    GROUP BY 1,2,3,4,5,6,7,8
) as sales
group by 1,2,3,4,5


-- new selection ppvs --


SELECT
    a.week_begin_date,
    a.yr_month,
    a.week_num_in_year,
    analytic_business_unit,
    analytic_super_category,
    COUNT(DISTINCT CASE WHEN total_ppvs >= 50 THEN listing_id END) AS ppv_count,
    COUNT(DISTINCT CASE WHEN total_ppvs >= 1 THEN listing_id END) AS ppv_counts,
    COUNT(listing_id) AS ppv_count1

FROM (
    SELECT
        wd.week_begin_date,
        substring(cast(sales.date_key as string),1,6) as yr_month,
        wd.week_num_in_year,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        sales.listing_id,
        

        SUM(COALESCE(sales.primary_ppvs, 0)) AS total_ppvs

    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.date_key = wd.date_dim_key
    
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
        AND sales.date_key >= 20260517
        AND DATE_DIFF(
                PARSE_DATE('%Y%m%d', CAST(sales.date_key AS STRING)), 
                lhd.listing_birth_date, 
                DAY
            ) <= 90
        
        AND lower(sales.analytic_business_unit) in ('home', 'furniture')

    GROUP BY 1, 2, 3, 4, 5, 6
) as a
GROUP BY 1, 2, 3,4, 5



--- price point selection overall -fsp -----


WITH weekly_snapshot AS (
    SELECT 
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        MAX(list_dim.process_date_key) as report_date

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact list_dim

    INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
        ON list_dim.process_date_key = wd.date_dim_key
        
    WHERE list_dim.process_date_key >= 20260517
    AND list_dim.marketplace_id = 'FLIPKART'
    GROUP BY 1,2,3

)
SELECT 
    snap.week_begin_date,
    snap.yearmo,
    snap.week_num_in_year,
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

INNER JOIN weekly_snapshot snap
    ON list_dim.process_date_key = snap.report_date

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in  ('furniture', 'home')
    and lower(analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4,5,6