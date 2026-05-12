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
        AND sales.date_key BETWEEN 20250101 AND 20260202
        AND lower(sales.analytic_business_unit) IN ('home', 'furniture')
        AND lower(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')
        AND (prod_dim.analytic_vertical NOT IN ('MobileProtectionDesignerCaseCover','Book','BikeBodyCover','MobileProtectionPlainCaseCover','WatchCombo','CarBodyCover','MobileSkin','MobileProtectionMobileScreenGuard','CameraLensProtector','SmartWatchStraps','SmartWatchScreenGuard','MobileProtectionDesignerCaseCover(OLD)','MobileProtectionPlainCaseCover(OLD)','MobileProtectionMobilePouches(OLD)') OR prod_dim.vertical_name IN ('book','regionalbooks')) 

    GROUP BY 1,2,3,4,5,6,7
) AS sales
GROUP BY 1,2,3,4