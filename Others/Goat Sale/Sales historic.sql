SELECT
    sales.order_date_key AS order_date_key,
    HOUR(sales.order_date_time) AS hour_of_day,
    sales.analytic_business_unit AS business_unit,
    sales.analytic_super_category AS super_category,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END AS diamond_mp_flag,
    sales.marketplace_id AS marketplace_id,
    SUM(sales.units) AS units,
    SUM(sales.gmv) AS gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON  sales.analytic_vertical  = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'

WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
    AND sales.type = 'physical'
    AND sales.is_freebie = FALSE
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND (
        sales.order_date_key BETWEEN 20250601 AND 20250731
        OR sales.order_date_key BETWEEN 20260601 AND 20260630
    )

GROUP BY
    sales.order_date_key,
    HOUR(sales.order_date_time),
    sales.analytic_business_unit,
    sales.analytic_super_category,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END,
    sales.marketplace_id