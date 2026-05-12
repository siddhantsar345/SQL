SELECT
    SUM(sales.gmv) AS total_gmv,
    SUM(CASE WHEN pi_data.fsn IS NOT NULL THEN sales.gmv ELSE 0 END) AS az_pi_covered_gmv,
    (SUM(CASE WHEN pi_data.fsn IS NOT NULL THEN sales.gmv ELSE 0 END) * 100.0) / NULLIF(SUM(sales.gmv), 0) AS az_pi_coverage_percentage_gmv,
    SUM(CASE WHEN ci_data.fsn IS NOT NULL THEN sales.gmv ELSE 0 END) AS az_ci_covered_gmv,
    (SUM(CASE WHEN ci_data.fsn IS NOT NULL THEN sales.gmv ELSE 0 END) * 100.0) / NULLIF(SUM(sales.gmv), 0) AS az_ci_coverage_percentage_gmv

FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS sales
LEFT JOIN
    bigfoot_external_neo.sp_product__product_categorization_hive_dim AS cat
    ON sales.product_id = cat.product_id

LEFT JOIN
    (
        SELECT DISTINCT
            fsn
        FROM
            bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact
        WHERE
            comp_price IS NOT NULL
            AND fk_price IS NOT NULL
            AND search_ppvs > 0
    ) AS pi_data
    ON sales.product_id = pi_data.fsn

LEFT JOIN
    (
        SELECT DISTINCT
            fsn
        FROM
            bigfoot_external_neo.analytics_cdo__unweighted_comp_base_hist_fact
        WHERE
            fsn_landscape IN ('FK_Comp', 'AI_Comp')
            AND search_ppvs IS NOT NULL
    ) AS ci_data
    ON sales.product_id = ci_data.fsn

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND (sales.order_date_key BETWEEN 20250801 AND 20250831)
    AND sales.analytic_business_unit IN ('BGM')
    AND sales.is_shopsy_order = FALSE;