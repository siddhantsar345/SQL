WITH date_bounds AS (
    SELECT
        CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 2 MONTH)) AS INT64) AS start_date,
        CAST(FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)) AS INT64) AS end_date
),

week_map AS (
    SELECT
        date_dim_key,
        MAX(week_begin_date) AS week_begin_date,
        MAX(yearmo) AS yearmo,
        MAX(week_num_in_year) AS week_num_in_year
    FROM bigfoot_external_neo.scp_oms__date_dim_fact
    WHERE date_dim_key BETWEEN (SELECT start_date FROM date_bounds) AND (SELECT end_date FROM date_bounds)
    GROUP BY date_dim_key
),

sales_base AS (
    SELECT
        wm.week_begin_date,
        wm.yearmo,
        wm.week_num_in_year,
        a.product_id,
        a.listing_id,
        a.order_date_key,
        t6.analytic_business_unit,
        t6.analytic_super_category,
        t6.analytic_vertical,
        SUM(a.gmv)   AS gmv,
        SUM(a.units) AS units
    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact a
    LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim t6
        ON a.product_id = t6.product_id
    INNER JOIN week_map wm
        ON a.order_date_key = wm.date_dim_key
    WHERE LOWER(a.status) IN (
        'in_progress','undelivered','completed','delivered',
        'approved','shipped','ready_to_ship','returned','return_requested','activated'
    )
    AND a.type = 'physical'
    AND a.replacement_for_unit IS NULL
    AND a.exchange_for_unit IS NULL
    AND a.is_freebie = FALSE
    AND a.is_shopsy_order = FALSE
    AND a.marketplace_id = 'FLIPKART'
    AND LOWER(t6.analytic_business_unit) = 'home'
    AND a.order_date_key BETWEEN (SELECT start_date FROM date_bounds) AND (SELECT end_date FROM date_bounds)
    GROUP BY 1,2,3,4,5,6,7,8,9
),

perf_base AS (
    SELECT
        listing_id,
        SUM(impressions)  AS impressions,
        SUM(primary_ppvs) AS ppvs
    FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact
    WHERE date_key BETWEEN (SELECT start_date FROM date_bounds) AND (SELECT end_date FROM date_bounds)
    GROUP BY listing_id
),

combined AS (
    SELECT
        s.week_begin_date,
        s.yearmo,
        s.week_num_in_year,
        s.analytic_business_unit,
        s.analytic_super_category,
        s.analytic_vertical,
        s.product_id,
        s.order_date_key,
        SUM(s.gmv) AS gmv,
        SUM(s.units) AS units,
        SUM(COALESCE(p.impressions, 0)) AS impressions,
        SUM(COALESCE(p.ppvs, 0)) AS ppvs,
        MAX(CASE WHEN t.product_id IS NOT NULL THEN 1 ELSE 0 END) AS is_trendy
    FROM sales_base s
    LEFT JOIN perf_base p
        ON s.listing_id = p.listing_id
    LEFT JOIN bigfoot_external_neo.analytics_cdo__trendy_new_pipeling_historical_v2_fact t
        ON s.product_id = t.product_id
        AND s.order_date_key = t.date_tag
    GROUP BY 1,2,3,4,5,6,7,8
)

SELECT
    week_begin_date,
    yearmo,
    week_num_in_year,
    analytic_business_unit,
    analytic_super_category,
    analytic_vertical,

    SUM(gmv) AS total_gmv,
    SUM(units) AS total_units,
    SUM(impressions) AS total_impressions,
    SUM(ppvs) AS total_ppvs,
    COUNT(DISTINCT product_id) AS total_product_count,

    SUM(CASE WHEN is_trendy = 1 THEN gmv ELSE 0 END) AS trendy_gmv,
    SUM(CASE WHEN is_trendy = 1 THEN units ELSE 0 END) AS trendy_units,
    SUM(CASE WHEN is_trendy = 1 THEN impressions ELSE 0 END) AS trendy_impressions,
    SUM(CASE WHEN is_trendy = 1 THEN ppvs ELSE 0 END) AS trendy_ppvs,
    COUNT(DISTINCT CASE WHEN is_trendy = 1 THEN product_id END) AS trendy_product_count,

    ROUND(100.0 * SAFE_DIVIDE(SUM(CASE WHEN is_trendy = 1 THEN gmv ELSE 0 END), SUM(gmv)),2) AS trendy_gmv_pct,
    ROUND(100.0 * SAFE_DIVIDE(SUM(CASE WHEN is_trendy = 1 THEN units ELSE 0 END), SUM(units)),2) AS trendy_units_pct,
    ROUND(100.0 * SAFE_DIVIDE(SUM(CASE WHEN is_trendy = 1 THEN impressions ELSE 0 END), SUM(impressions)),2) AS trendy_impressions_pct,
    ROUND(100.0 * SAFE_DIVIDE(SUM(CASE WHEN is_trendy = 1 THEN ppvs ELSE 0 END), SUM(ppvs)),2) AS trendy_ppvs_pct,
    ROUND(100.0 * SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN is_trendy = 1 THEN product_id END),
    COUNT(DISTINCT product_id)),2) AS trendy_product_pct,
    ROUND(100.0 * SAFE_DIVIDE(SUM(units),SUM(ppvs)), 2)AS overall_conversion_pct,
    ROUND(100.0 * SAFE_DIVIDE(SUM(CASE WHEN is_trendy = 1 THEN units ELSE 0 END),SUM(CASE WHEN is_trendy = 1 THEN ppvs  ELSE 0 END)), 2) AS trendy_conversion_pct,
    ROUND(100.0 * SAFE_DIVIDE( SUM(CASE WHEN is_trendy = 0 THEN units ELSE 0 END),SUM(CASE WHEN is_trendy = 0 THEN ppvs  ELSE 0 END)), 2) AS non_trendy_conversion_pct

FROM combined
GROUP BY 1,2,3,4,5,6