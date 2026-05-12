SELECT 
    analytic_business_unit,
    ppv_bucket,
    age_bucket,
    COUNT(DISTINCT listing_id) AS lid_count
FROM (
    SELECT 
        base.listing_id,
        base.analytic_business_unit,
        CASE 
            WHEN lower(base.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") AND base.total_ppvs >= 1000 THEN 'Selection with >= 1000 PPVs'
            WHEN lower(base.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") AND base.total_ppvs >= 50   THEN 'Selection with >= 50 PPVs'
            WHEN lower(base.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") AND base.total_ppvs >= 10   THEN 'Selection with >= 10 PPVs'
            WHEN lower(base.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") AND base.total_ppvs >= 2    THEN 'Selection with 2-9 PPVs'
            WHEN lower(base.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") AND base.total_ppvs = 1    THEN 'Selection with 1 PPV'
            WHEN lower(base.service_profile) in ("fbf","fbf_and_fbf_lite","fbf_and_non_fbf","fbf_lite") AND base.total_ppvs = 0    THEN 'No PPVs'
            ELSE 'Non-FBF or Other' 
        END AS ppv_bucket,
        CASE 
            WHEN base.age_in_days <= 90 THEN '90 days'
            WHEN base.age_in_days > 90 AND base.age_in_days <= 180 THEN '90 to 180 days'
            WHEN base.age_in_days > 180 AND base.age_in_days <= 360 THEN '180 to 360 days'
            ELSE '360 days+'
        END AS age_bucket
    FROM (
        SELECT 
            lhd.listing_id,
            lhd.analytic_business_unit,
            sales_agg.service_profile,
            COALESCE(sales_agg.total_ppvs, 0) AS total_ppvs,
            DATE_DIFF(DATE '2025-12-30', CAST(lhd.listing_created_on AS DATE), DAY) AS age_in_days
        FROM bigfoot_external_neo.sp_product__listing_hive_dim lhd
        LEFT JOIN (
            SELECT 
                listing_id, 
                service_profile,
                SUM(COALESCE(primary_ppvs, 0)) AS total_ppvs
            FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact
            WHERE date_key BETWEEN 20251201 AND 20251230
              AND marketplace_id = 'FLIPKART'
            GROUP BY 1,2
        ) sales_agg ON lhd.listing_id = sales_agg.listing_id
        WHERE lhd.marketplace_id = 'FLIPKART'
          AND LOWER(lhd.analytic_business_unit) IN ('home', 'furniture')
    ) AS base
) AS final_report
GROUP BY 1, 2, 3