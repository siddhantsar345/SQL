
select 
    year_month,
    analytic_business_unit,
    analytic_super_category,
    -- case 
    --     when lower(analytic_vertical) in ('gardensprayer', 'socketset', 'doorlock', 'bathroommirror', 'impactwrench', 'lock', 'gardentoolset', 'solarchargecontroller', 'doorstopper', 'heatsealer', 'invertertrolley', 'knobandhandle', 'crackfiller', 'doorcloser', 'storagevaccumbag', 'solarbattery', 'flushtanks', 'wallpaint', 'walldecoration', 'decorwallshelf', 'outdoorlamp', 'walllamp', 'wallphotoframe', 'floorlamp', 'vase', 'windchime', 'magnet', 'decorativemirror', 'photoalbum', 'waterfountain', 'diffusersets', 'tapestry', 'appliancecover', 'floormat', 'carpetrug', 'bathtowel', 'pillowcover', 'tablecover', 'curtainaccessories', 'laundrybasket', 'diwanset', 'apron', 'tableplacemat', 'bathrobe', 'napkin', 'tablerunner', 'tablelinenset', 'coaster', 'kitchenlinenset', 'blinds', 'pillowprotectors', 'roticover', 'bathlinenset', 'chefhat', 'sofafabric', 'quiltbatting', 'curtainfabric', 'napkinring', 'showerrodhooks', 'rugpad', 'tableskirt', 'mug', 'storagebasket', 'dustbin', 'bucket', 'storagebox', 'mould', 'cleaningglove', 'vegetableandfruitbasket', 'gascylinderregulator', 'duster', 'scrubpad', 'masher', 'otherkitchentool', 'colanderandsieve', 'cutleryspoon', 'servingset', 'coffeemaker', 'grocerybag', 'homecleaningset', 'bathroomset', 'barset', 'bakingdish', 'cakepieserver', 'bakingdecorationaccessories',
    --     'bakingspatula', 'cookingspoon', 'spatula', 'storagedrum', 'bakingcutter', 'tong', 'pressurecookergasket', 'flambetorches', 'kitchenscissor', 'whisk', 'kitchenweighingscale', 'dustpan') 
    --     then analytic_vertical else 'Others' 
    -- end as analytic_vertical,
    analytic_vertical,
    -- fs_bucket,
    sum(a_lid_count) as a_lid_count,
    sum(ai_lid_count) as ai_lid_count,
    sum(a_pid_count) as a_pid_count,
    sum(ai_pid_count) as ai_pid_count,
    sum(ai_fbf_lids) as ai_fbf_lids,
    sum(ai_nfbf_lids) as ai_nfbf_lids


from bigfoot_external_neo.analytics_cdo__selection_historical_aggregated_snapshot_fact
-- from bigfoot_external_neo.sp_analytics__listing_history_90d_fact
where lower(analytic_business_unit) in  ('furniture', 'home')
-- and lower(analytic_vertical) in 
    AND lower(analytic_vertical) not in ('plantsapling', 'plantseed')
    AND (analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

group by 1,2,3,4




with month_end AS (
    SELECT 
        substr(cast(process_date_key as string),1,6) as year_mo,
        MAX(process_date_key) as report_date
    
    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact
    WHERE marketplace_id = 'FLIPKART'
        AND process_date_key BETWEEN 20251201 AND 20251231
    GROUP BY 1
)

SELECT 
    med.year_mo, 
    list_dim.process_date_key as snapshot_used, 
    
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    prod_dim.analytic_vertical,

    count(distinct list_dim.listing_id) as a_listings,
    count(distinct list_dim.product_id) as a_products,

    count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
    count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products,
    

    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.listing_id end) as a_fbf_lids,
    count(distinct case when list_dim.service_profile = 'FBF' then list_dim.product_id end) as a_fbf_pids,

    count(distinct case when (lower(list_dim.service_profile) not in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_fbf_lids,


    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_fbf_lids,
    count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_fbf_pids


FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

INNER JOIN month_end med
    ON list_dim.process_date_key = med.report_date

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on list_dim.product_id = prod_dim.product_id

WHERE
    list_dim.marketplace_id = 'FLIPKART'
    and lower(prod_dim.analytic_business_unit) in  ('furniture', 'home')
    and lower(analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

GROUP BY 1,2,3,4,5




----------------------

select 
    year_mo,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    sales.analytic_vertical,
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

from 
(
    SELECT
        sales.listing_id,
        sales.product_id,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical,
        sales.service_profile,

        substr(cast(sales.date_key as string),1,6) as year_mo,

        sum(COALESCE(sales.primary_ppvs, 0)) AS primary_ppvs,
        sum(COALESCE(sales.gross_units, 0)) AS units

    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales
    
    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        ON sales.product_id = prod_dim.product_id

    WHERE sales.marketplace_id	 = 'FLIPKART' 
        and sales.date_key between 20250101 and 20251130
        and lower(sales.analytic_business_unit) in ('home', 'furniture')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 


    GROUP BY 1,2,3,4,5,6,7
) as sales
group by 1,2,3,4











------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------- Final Summary Queries  --------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------- Part: Transacting LIDs / PIDs
SELECT
    
    prod_dim.analytic_business_unit
    ,prod_dim.analytic_super_category
    ,prod_dim.analytic_vertical
    ,substring(cast(sales.order_date_key as string),1,6) as year_month

    ,count(distinct sales.listing_id) as trans_lid_count
    ,count(distinct sales.product_id) as trans_pid_count
    ,sum(sales.units) as units
    ,sum(sales.gmv) as gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

left join bigfoot_external_neo.sp_product__product_attribute_hive_dim as prod_dim
    on sales.product_id = prod_dim.product_id

left join (
    select
        listing_id
        ,is_first_party_seller as is_alpha_seller
        ,flipkart_selling_price
    from bigfoot_external_neo.sp_product__listing_hive_dim
    where marketplace_id = 'FLIPKART'
) list_dim_fact
on list_dim_fact.listing_id = sales.listing_id

WHERE
    lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.category_id !=21726
    AND sales.category_id !=21651
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie =FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.is_shopsy_order = False
    AND sales.order_date_key >= 20240801
    AND prod_dim.analytic_business_unit IN ("Home","Furniture")
    and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
    and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

group by 1,2,3,4




-------- Part: New Trxn Selection

SELECT
    substring(cast(sales.order_date_key as string),1,6) as yr_month
    ,prod_dim.analytic_business_unit
    ,prod_dim.analytic_super_category
    ,prod_dim.analytic_vertical
    ,CASE 
        WHEN list_dim_fact.lid_created_month < '202406' THEN 'older_202406' 
        ELSE list_dim_fact.lid_created_month 
    END AS lid_created_month

    ,count(distinct sales.listing_id) as trans_lid_count
    ,count(distinct sales.product_id) as trans_pid_count
    ,sum(sales.units) as units
    ,sum(sales.gmv) as gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

left join bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    on sales.product_id = prod_dim.product_id


left join (
    select
        listing_id
        ,FORMAT_DATETIME('%Y%m', listing_created_on) as lid_created_month
        ,is_first_party_seller as is_alpha_seller
        ,flipkart_selling_price
    from bigfoot_external_neo.sp_product__listing_hive_dim
    where marketplace_id = 'FLIPKART'
) list_dim_fact
on list_dim_fact.listing_id = sales.listing_id

WHERE
    lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type !='service'
    AND sales.category_id !=21726
    AND sales.category_id !=21651
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie =FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.is_shopsy_order = False
    AND sales.order_date_key >= 20240801
    AND prod_dim.analytic_business_unit IN ("Home","Furniture")

group by 1,2,3,4,5
having lid_created_month <> 'older_202406'




------ New Selection acquired LIDs and PIDs
select 
    analytic_business_unit,
    FORMAT_DATETIME('%Y%m', listing_created_on) as created_month,
    count(distinct listing_id) as listings

from bigfoot_external_neo.sp_product__listing_hive_dim as list

where  
    lower(list.analytic_business_unit) in ('home', 'furniture')
    -- and lower(list.listing_status) = 'active'
    and listing_created_on between '2025-01-01' and '2025-11-30'

group by 1,2

UNION ALL

select 
    analytic_business_unit,
    FORMAT_DATETIME('%Y%m', first_seen) as created_month,
    count(distinct product_id) as products
from
(
    select 
        analytic_business_unit,
        product_id,
        min(listing_created_on) as first_seen,

    from bigfoot_external_neo.sp_product__listing_hive_dim as list

    where  
        lower(list.analytic_business_unit) in ('home', 'furniture')


    group by 1,2
) as a
group by 1,2




SELECT 
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    FORMAT_DATETIME('%Y%m', listing_created_on) as created_month,
    count(distinct listing_id) as listings,
    count(distinct case when listing_created_on = first_seen then product_id end) as new_products

FROM (
    select 
        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        listing_id,
        product_id,
        listing_created_on,
        min(listing_created_on) over(PARTITION by product_id) as first_seen,

    from bigfoot_external_neo.sp_product__listing_hive_dim as list

    where lower(list.analytic_business_unit) in ('home', 'furniture')
        -- and lower(list.listing_status) = 'active'
    
           
) as a
where listing_created_on between '2025-01-01' and '2025-11-30'
GROUP BY 1, 2,3,4







----------- New Selection with PPV

SELECT
    time,
    pp,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,
    COUNT(DISTINCT CASE WHEN total_ppvs >= 50 THEN listing_id END) AS ppv_count,
    COUNT(listing_id) AS ppv_count1

FROM (
    SELECT
        sales.listing_id,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,
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
          AND listing_created_on >= '2024-07-01'
        GROUP BY 1, 2
    ) lhd
    ON sales.listing_id = lhd.listing_id

    WHERE sales.marketplace_id = 'FLIPKART' 
        AND sales.date_key BETWEEN 20250101 AND 20251207
        AND DATE_DIFF(
                PARSE_DATE('%Y%m%d', CAST(sales.date_key AS STRING)), 
                lhd.listing_birth_date, 
                DAY
            ) <= 90
        
        AND lower(sales.analytic_business_unit) in ('home', 'furniture')

    GROUP BY 1, 2, 3, 4, 5
) as a

WHERE time <> 'na'
GROUP BY 1, 2, 3,4 ,5



----- New Trxn Selection 


new_transacting_selection as (
    SELECT
        'New_Trxn_Sel_90_Days' as source_table,
        
        substring(cast(sales.order_date_key as string),1,6) as year_mo,
        
        null as snapshot_used,
        null as lid_created_month_cohort,

        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,

        null, null, null, null, null, null, null, null,   
        null, null, null, null, null,

        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.gmv) as gmv,
        sum(sales.units) as sales_units,

        null, null

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        on sales.product_id = prod_dim.product_id

    LEFT JOIN (
        SELECT 
            listing_id, 
            CAST(MIN(listing_created_on) AS DATE) as listing_birth_date
        FROM bigfoot_external_neo.sp_product__listing_hive_dim
        WHERE marketplace_id = 'FLIPKART'
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
        
        AND sales.order_date_key BETWEEN 20240101 AND CAST(FORMAT_DATE('%Y%m%d', CURRENT_DATE()) AS INT64)
        
        AND DATE_DIFF(
                PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING)), 
                list_dim_fact.listing_birth_date, 
                DAY
            ) <= 90

        AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
        AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        AND (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    GROUP BY 1,2,3,4,5,6,7
)



----------------------- Final query ----------------------- 

WITH month_end AS (
    SELECT 
        substr(cast(process_date_key as string),1,6) as year_mo,
        MAX(process_date_key) as report_date
    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact
    WHERE marketplace_id = 'FLIPKART'
        AND process_date_key BETWEEN CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)) AS INT64) 
            AND CAST(FORMAT_DATE('%Y%m%d', CURRENT_DATE()) AS INT64)
    GROUP BY 1
),

main as (
    SELECT 
        'MainPart' as source_table,
        med.year_mo, 
        list_dim.process_date_key as snapshot_used, 
        null as lid_created_month_cohort, 
        
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,

        count(distinct list_dim.listing_id) as a_listings,
        count(distinct list_dim.product_id) as a_products,
        count(distinct case when list_dim.final_atp > 0 then list_dim.listing_id end) as ai_listings,
        count(distinct case when list_dim.final_atp > 0 then list_dim.product_id end) as ai_products,
        count(distinct case when list_dim.service_profile = 'FBF' then list_dim.listing_id end) as a_fbf_lids,
        count(distinct case when list_dim.service_profile = 'FBF' then list_dim.product_id end) as a_fbf_pids,
        count(distinct case when list_dim.service_profile = 'FBF' and list_dim.final_atp > 0 then list_dim.listing_id end) as ai_fbf_lids,
        count(distinct case when list_dim.service_profile = 'FBF' and list_dim.final_atp > 0 then list_dim.product_id end) as ai_fbf_pids,
        
        null as ppv_1_lid_count, null as ppv_1000_lid_count, null as total_ppv_units,
        null as ppv_1_pid_count, null as ppv_1000_pid_count,
        null as trans_lid_count, null as trans_pid_count, null as gmv, null as sales_units,
        null as new_selection_listings, null as new_selection_products

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

    INNER JOIN month_end med
        ON list_dim.process_date_key = med.report_date

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        on list_dim.product_id = prod_dim.product_id

    WHERE
        list_dim.marketplace_id = 'FLIPKART'
        and lower(prod_dim.analytic_business_unit) in  ('furniture', 'home')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    GROUP BY 1,2,3,4,5,6,7
),

----  change the query
ppv_story as (
    select 
        'PPV_Story' as source_table,
        year_mo,
        null as snapshot_used,
        null as lid_created_month_cohort,

        analytic_business_unit,
        analytic_super_category,
        analytic_vertical,
        null, null, null, null, null, null, null, null,    
        
        count(distinct case when primary_ppvs >= 1 then listing_id end) as ppv_1_lid_count,
        count(distinct case when primary_ppvs >= 1000 then listing_id end) as ppv_1000_lid_count,
        sum(units) as total_ppv_units,
        count(distinct case when primary_ppvs >= 1 then product_id end) as ppv_1_pid_count,
        count(distinct case when primary_ppvs >= 1000 then product_id end) as ppv_1000_pid_count,

        null, null, null, null, null, null 

    from 
    (
        SELECT
            sales.listing_id,
            sales.product_id,
            prod_dim.analytic_business_unit,
            prod_dim.analytic_super_category,
            prod_dim.analytic_vertical,
            substr(cast(sales.date_key as string),1,6) as year_mo,
            sum(COALESCE(sales.primary_ppvs, 0)) AS primary_ppvs,
            sum(COALESCE(sales.gross_units, 0)) AS units

        FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales
        
        LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
            ON sales.product_id = prod_dim.product_id

        WHERE sales.marketplace_id = 'FLIPKART' 
            AND sales.date_key BETWEEN 20250101 AND CAST(FORMAT_DATE('%Y%m%d', CURRENT_DATE()) AS INT64)
            and lower(prod_dim.analytic_business_unit) in ('home', 'furniture')
            and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
            and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

        GROUP BY 1,2,3,4,5,6
    ) as sales_agg
    group by 1,2,3,4,5,6,7
),

transacting_selection as (
    SELECT
        'Transacting_Sel' as source_table,
        substring(cast(sales.order_date_key as string),1,6) as year_mo,
        null as snapshot_used,
        null as lid_created_month_cohort,

        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,

        null, null, null, null, null, null, null, null,   
        null, null, null, null, null,

        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.gmv) as gmv,
        sum(sales.units) as sales_units,

        null, null

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
        AND sales.order_date_key BETWEEN 20250101 AND CAST(FORMAT_DATE('%Y%m%d', CURRENT_DATE()) AS INT64)
        AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
        and lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        and (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    group by 1,2,3,4,5,6,7
),



new_transacting_selection as (
    SELECT
        'New_Trxn_Sel_90_Days' as source_table,
        substring(cast(sales.order_date_key as string),1,6) as year_mo,
        
        null as snapshot_used,
        null as lid_created_month_cohort,

        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,

        null, null, null, null, null, null, null, null,   
        null, null, null, null, null,

        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.gmv) as gmv,
        sum(sales.units) as sales_units,

        null, null

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
        
        AND sales.order_date_key BETWEEN 20250101 AND CAST(FORMAT_DATE('%Y%m%d', CURRENT_DATE()) AS INT64)
        
        AND DATE_DIFF(
                PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING)), 
                list_dim_fact.listing_birth_date, 
                DAY
            ) <= 90

        AND lower(prod_dim.analytic_business_unit) IN ('home', 'furniture')
        AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        AND (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 

    GROUP BY 1,2,3,4,5,6,7
),

new_selection as (
    SELECT 
        'New_Selection_Created' as source_table,
        FORMAT_DATETIME('%Y%m', listing_created_on) as year_mo,
        null as snapshot_used,
        null as lid_created_month_cohort,

        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,

        null, null, null, null, null, null, null, null,   
        null, null, null, null, null,
        null, null, null, null,

        count(distinct listing_id) as new_selection_listings,
        count(distinct case when listing_created_on = first_seen then list.product_id end) as new_selection_products

    FROM
    (
        select 
            listing_id,
            product_id,
            listing_created_on,
            min(listing_created_on) over(PARTITION by product_id) as first_seen
        from bigfoot_external_neo.sp_product__listing_hive_dim
        where marketplace_id = 'FLIPKART'
    ) as list
    
    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        ON list.product_id = prod_dim.product_id

    WHERE CAST(listing_created_on AS DATE) BETWEEN '2025-01-01' AND CURRENT_DATE()
      AND lower(prod_dim.analytic_business_unit) in ('home', 'furniture')    
      AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
      AND (prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') or prod_dim.vertical_name in ('book','regionalbooks')) 
            
    GROUP BY 1,2,3,4,5,6,7
)


select * from main 
UNION ALL
select * from ppv_story
UNION ALL
select * from transacting_selection
UNION ALL
select * from new_transacting_selection
UNION ALL
select * from new_selection













---------- HouseHold BIS
SELECT  
    sales.analytic_vertical,
    sales.brand,
    -- case when lower(b.type)='branded' or lower(b.type)='d2c' then b.brand else 'Others' end as brand,
    -- substr(cast(sales.order_date_key as string),1,6) as year_mo,
    sales.order_date_key,
    SUM(sales.gmv) AS gmv,
    SUM(sales.units) AS units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales


-- LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_brand_d2c_home_mapping_1_0 b
--     on lower(sales.analytic_super_category) = lower(b.analytic_super_category) 
--         and lower(sales.brand) = lower(b.brand)


WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type != 'service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.order_date_key BETWEEN 20250101 and 20251031
    AND SUBSTR(CAST(sales.order_date_key AS STRING), 5, 2) NOT IN ('09', '10')
    and lower(sales.analytic_business_unit) = 'home'
    AND sales.is_shopsy_order = FALSE
    and lower(sales.analytic_super_category) = 'household'
    and lower(sales.analytic_vertical) in ('lunchbox', 'bottle', 'flask', 'thermalcasseroleandset')

GROUP BY 1,2,3



------ Saketh Deck

SELECT 
    SUBSTR(CAST(order_date_key AS STRING), 1, 6) AS year_mo,
    sales.analytic_business_unit as bu,
    sum(gmv) as gmv,
    sum(case when sales.sla_in_days <= 0 then sales.units else 0 end) as d0_units,
    sum(case when sales.sla_in_days <= 2 then sales.units else 0 end) as d2_units,
    sum(units) as units,
    COUNT(DISTINCT sales.product_id) AS trxn_selections


FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales 

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND lower(hl.bu_final) IN ('home')

left join bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim as geo
    on geo.pincode = sales.pincode


WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type  = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') or (sales.marketplace_id IN ('HYPERLOCAL') AND hl.bu_final is not null))
    AND lower(sales.analytic_business_unit) IN ('home')
    AND sales.order_date_key BETWEEN 20250101 AND 20251130
    AND sales.is_shopsy_order = FALSE
    and lower(geo.city) in ('kolkata', 'chennai', 'ahmedabad', 'ncr', 'bangalore', 'pune', 'hyderabad', 'mumbai', 'varanasi', 'ernakulam', 'thrissur', 'coimbatore', 'vishakhapatnam', 'patna', 'ranchi', 'trivandrum', 'lucknow', 'guwahati', 'bhubaneswar', 'cuttack')

group by 1,2













---------  %LIDs -> top50
with sales as(
    select 
        sales.analytic_business_unit as bu,
        sales.listing_id as lid,
        case 
            when sales.order_date_key between 20250101 AND 20250131 then 'Jan'
            when sales.order_date_key between 20250801 AND 20250831 then 'Aug'
            when sales.order_date_key between 20251101 AND 20251130 then 'Nov'
            else 'Others'
        end as time_period,
        sum(sales.gmv) AS lid_gmv,
        sum(sales.units) as lid_units

    from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    left join bigfoot_external_neo.sp_product__product_categorization_hive_dim cat 
        ON cat.product_id = sales.product_id
        
    WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id = 'FLIPKART'
        AND sales.is_shopsy_order = FALSE
        AND sales.analytic_business_unit = 'Home'
        AND sales.order_date_key BETWEEN 20250101 AND 20251130

    GROUP BY 1,2,3

    having time_period != 'Others'
),

cumulative_calc as(
    select *,
        sum(lid_units) over (partition by time_period
                    order by lid_units desc rows between unbounded preceding and current row) as cumulative_units,

        sum(lid_units) over (partition by time_period) as total_units

    from sales
),

top_lids as(
    select *,
        case when cumulative_units <= total_units * 0.5 then 1 else 0 end as top_50_percent
    from cumulative_calc
)

select 
    bu, time_period,
    count(distinct lid) as total_lids,
    count(distinct case when top_50_percent = 1 then lid end) as top_50_lids_count

from top_lids

group by 1,2





--------------
SELECT
    analytic_business_unit,
    analytic_super_category,

    case 
        when sales.net_gmv / nullif(sales.net_units,0) < 300 then '0-300'
        when sales.net_gmv / nullif(sales.net_units,0) between 300 and 500 then '301 - 500'
        when sales.net_gmv / nullif(sales.net_units,0) between 500 and 1000 then '501 - 1000'
        when sales.net_gmv / nullif(sales.net_units,0) > 1000 then '1000+'
    end as asp
    
    ,sum(case when list_dim_fact.is_fassured_listing = TRUE then sales.primary_ppvs else 0 end) as ppvs_fass
    ,sum(case when list_dim_fact.is_fassured_listing = TRUE then sales.net_units else 0 end) as units_fass
    ,sum(case when list_dim_fact.is_fassured_listing = TRUE then sales.net_gmv else 0 end) as gmv_fass
    ,sum(sales.primary_ppvs) as ppvs
    ,sum(sales.net_units) as units
    ,sum(sales.net_gmv) as gmv


-- FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales


left join(
    select
        listing_id
        ,is_fassured_listing as is_fassured_listing
    from bigfoot_external_neo.sp_product__listing_hive_dim
    where marketplace_id = 'FLIPKART'
    group by 1,2
) list_dim_fact
on list_dim_fact.listing_id = sales.listing_id



WHERE sales.marketplace_id	 = 'FLIPKART' 
    AND sales.date_key between 20251101 and 20251130
    and sales.analytic_business_unit = 'Home'
group by 1,2,3









SELECT
    sales.business_unit AS BU,
    sales.super_category as sc,
    sales.unit_creation_date_key AS order_date_key,
    EXTRACT(HOUR FROM from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,

    case when sales.alpha_flag = "Alpha" then 'Diamond' else 'Rest of MP' end as alpha_flag,
    service_profile,
    SUM(sales.amount) AS gmv,
    SUM(sales.units) AS units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales

WHERE
    lower(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type != 'service'
    AND sales.freebie_flag = FALSE
    AND sales.unit_creation_date_key >= 20251209
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
    AND sales.marketplace_id IN ('FLIPKART')
    AND lower(sales.business_unit) IN ('bgm')

GROUP BY 
    sales.business_unit,
    sales.super_category,
    sales.unit_creation_date_key,
    EXTRACT(HOUR FROM from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))),
    case when sales.alpha_flag = "Alpha" then 'Diamond' else 'Rest of MP' end,
    service_profile