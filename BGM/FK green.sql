SELECT
    CASE 
        WHEN sales1.order_date_key BETWEEN 20251112 AND 20251117 THEN 'Pre'
        WHEN sales1.order_date_key BETWEEN 20251129 AND 20251204 THEN 'Post'
        WHEN sales1.order_date_key BETWEEN 20260107 AND 20260113 THEN 'Post1'
    END AS period_bucket,
    sales1.analytic_business_unit,
    sales1.analytic_super_category,
    CASE
        WHEN fsn.product_id IS NOT NULL THEN 1
        ELSE 0
    END AS is_launched_fsn,
    SUM(sales1.gmv) AS total_gmv, 
    SUM(sales1.units) AS total_units,
    SUM(sales1.primary_ppvs) AS ppvs,
    SUM(sales1.impressions) as impressions


FROM bigfoot_external_neo.cp_santa__listing_performance_at_day_level_with_sales_90d_fact sales

LEFT JOIN bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales1
    ON sales.analytic_super_category = sales1.analytic_super_category

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_bgmh_launched_fsns_1_0 fsn
    ON CAST(sales.product_id AS STRING) = CAST(fsn.product_id AS STRING)

WHERE 
        (sales1.order_date_key BETWEEN 20251112 AND 20251117 OR
        sales1.order_date_key BETWEEN 20251129 AND 20251204 OR
        sales1.order_date_key BETWEEN 20260107 AND 20260113)
        AND LOWER(sales1.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales1.type = 'physical'
        AND lower(sales1.marketplace_id) = 'flipkart'
        AND lower(sales1.analytic_super_category) IN ('grooming','makeupfragrances')
        AND sales1.is_shopsy_order = FALSE
        AND sales1.replacement_for_unit IS NULL
        AND sales1.exchange_for_unit IS NULL
        AND sales1.is_freebie = FALSE
        
GROUP BY
    CASE 
        WHEN sales1.order_date_key BETWEEN 20251112 AND 20251117 THEN 'Pre'
        WHEN sales1.order_date_key BETWEEN 20251129 AND 20251204 THEN 'Post'
        WHEN sales1.order_date_key BETWEEN 20260107 AND 20260113 THEN 'Post1'
    END,
    sales1.analytic_business_unit,
    sales1.analytic_super_category,
    CASE 
        WHEN fsn.product_id IS NOT NULL THEN 1 
        ELSE 0 
    END