WITH month_end_ref AS (
    SELECT 
        substr(cast(process_date_key as string), 1, 6) as year_mo,
        MAX(process_date_key) as report_date

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact

    WHERE marketplace_id = 'FLIPKART'
    AND process_date_key BETWEEN 20250801 AND 20251203
    GROUP BY 1
),

selection_overall AS (
    SELECT 
        'SELECTION_OVERALL' as metric_source,
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
        count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.listing_id end) as ai_fbf_lids,
        count(distinct case when (lower(list_dim.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") and list_dim.final_atp > 0) then list_dim.product_id end) as ai_fbf_pids

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

    INNER JOIN month_end_ref med 
        ON list_dim.process_date_key = med.report_date

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim 
        on list_dim.product_id = prod_dim.product_id

    WHERE list_dim.marketplace_id = 'FLIPKART'
        AND lower(prod_dim.analytic_business_unit) in ('furniture', 'home')
        AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        AND (
            prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') 
            OR prod_dim.vertical_name in ('book','regionalbooks')
        )
    GROUP BY 1, 2, 3, 4, 5
),

selection_new AS (
    SELECT 
        'SELECTION_NEW' as metric_source,
        FORMAT_DATETIME('%Y%m', listing_created_on) as year_mo,
        analytic_business_unit,
        analytic_super_category,
        'N/A' as analytic_vertical,
        count(distinct listing_id) as listings,
        count(distinct case when listing_created_on = first_seen then product_id end) as new_products

    FROM (
        select 
            analytic_business_unit, 
            analytic_super_category, 
            listing_id, 
            product_id, 
            listing_created_on,
            min(listing_created_on) over(PARTITION by product_id) as first_seen

        from bigfoot_external_neo.sp_product__listing_hive_dim
        
        where lower(analytic_business_unit) in ('home', 'furniture')
    ) as a

    where listing_created_on between '2025-01-01' and '2025-11-30'
    GROUP BY 1, 2, 3, 4, 5
),

transacting_selection AS (
    SELECT
        'TRANSACTING' as metric_source,
        substring(cast(sales.order_date_key as string), 1, 6) as year_mo,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,
        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.units) as units,
        sum(sales.gmv) as gmv

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim as prod_dim 
        on sales.product_id = prod_dim.product_id

    LEFT JOIN (
        select
            listing_id,
            is_first_party_seller as is_alpha_seller,
            flipkart_selling_price

        from bigfoot_external_neo.sp_product__listing_hive_dim

        where marketplace_id = 'FLIPKART'
    ) list_dim_fact

        on list_dim_fact.listing_id = sales.listing_id

    WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type !='service'
        AND sales.category_id !=21726
        AND sales.category_id !=21651
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.is_shopsy_order = False
        AND sales.order_date_key >= 20240801
        AND prod_dim.analytic_business_unit IN ("Home","Furniture")
        AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
        AND (
            prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') 
            OR prod_dim.vertical_name in ('book','regionalbooks')
        ) 
    GROUP BY 1, 2, 3, 4, 5
),

new_trxn_selection AS (
    SELECT
        'NEW_TRXN' as metric_source,
        substring(cast(sales.order_date_key as string), 1, 6) as year_mo,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,
        prod_dim.analytic_vertical,
        CASE 
            WHEN list_dim_fact.lid_created_month < '202406' THEN 'older_202406' 
            ELSE list_dim_fact.lid_created_month 
        END AS lid_created_month,
        count(distinct sales.listing_id) as trans_lid_count,
        count(distinct sales.product_id) as trans_pid_count,
        sum(sales.units) as units,
        sum(sales.gmv) as gmv

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim 
        on sales.product_id = prod_dim.product_id

    LEFT JOIN (
        select
            listing_id,
            FORMAT_DATETIME('%Y%m', listing_created_on) as lid_created_month,
            is_first_party_seller as is_alpha_seller,
            flipkart_selling_price
        from bigfoot_external_neo.sp_product__listing_hive_dim
        where marketplace_id = 'FLIPKART'
    ) list_dim_fact

        on list_dim_fact.listing_id = sales.listing_id

    WHERE lower(sales.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
        AND sales.type !='service'
        AND sales.category_id !=21726
        AND sales.category_id !=21651
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.is_shopsy_order = False
        AND sales.order_date_key >= 20240801
        AND prod_dim.analytic_business_unit IN ("Home","Furniture")
    GROUP BY 1, 2, 3, 4, 5, 6
),

new_selection_ppv AS (
    SELECT
        'NEW_PPV_90D' as metric_source,
        yr_month as year_mo,
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
            substring(cast(sales.date_key as string), 1, 6) as yr_month,
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
            GROUP BY 1,2
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
    GROUP BY 1, 2, 3, 4, 5
),

discovery_metrics AS (
    SELECT 
        'DISCOVERY_PPV' as metric_source,
        year_mo,
        sales.analytic_business_unit,
        sales.analytic_super_category,
        sales.analytic_vertical,
        count(distinct case when primary_ppvs >= 1 then listing_id end) as ppv_1_lid_count,
        count(distinct case when primary_ppvs >= 1000 then listing_id end) as ppv_1000_lid_count,
        sum(units) as total_units,
        count(distinct case when primary_ppvs >= 1 then product_id end) as ppv_1_pid_count,
        count(distinct case when primary_ppvs >= 1000 then product_id end) as ppv_1000_pid_count,
        count(distinct case when primary_ppvs >= 1 and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_1_fbf_lid_count,
        count(distinct case when primary_ppvs >= 1000 and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_1000_fbf_lid_count,
        count(distinct case when primary_ppvs >= 1 and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_1_fbf_pid_count,
        count(distinct case when primary_ppvs >= 1000 and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_1000_fbf_pid_count,
        count(distinct case when primary_ppvs >= 50 then listing_id end) as ppv_50_lid_count,
        count(distinct case when primary_ppvs >= 50 then product_id end) as ppv_50_pid_count,
        count(distinct case when primary_ppvs >= 50 and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then listing_id end) as ppv_50_fbf_lid_count,
        count(distinct case when primary_ppvs >= 50 and lower(service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") then product_id end) as ppv_50_fbf_pid_count


    FROM (
        SELECT
            sales.listing_id,
            sales.product_id,
            sales.analytic_business_unit,
            sales.analytic_super_category,
            sales.analytic_vertical,
            sales.service_profile,
            substr(cast(sales.date_key as string), 1, 6) as year_mo,
            sum(COALESCE(sales.primary_ppvs, 0)) AS primary_ppvs,
            sum(COALESCE(sales.gross_units, 0)) AS units


        FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales

        LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
            ON sales.product_id = prod_dim.product_id
            
        WHERE sales.marketplace_id = 'FLIPKART' 
            AND sales.date_key between 20250101 and 20251130
            AND lower(sales.analytic_business_unit) in ('home', 'furniture')
            AND lower(prod_dim.analytic_vertical) not in ('plantsapling', 'plantseed')
            AND (
                prod_dim.analytic_vertical not in ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') 
                OR prod_dim.vertical_name in ('book','regionalbooks')
            ) 
        GROUP BY 1, 2, 3, 4, 5, 6, 7
    ) as sales
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM selection_overall
UNION ALL
SELECT * FROM selection_new
UNION ALL
SELECT * FROM transacting_selection
UNION ALL
SELECT * FROM new_trxn_selection
UNION ALL
SELECT * FROM new_selection_ppv
UNION ALL
SELECT * FROM discovery_metrics;