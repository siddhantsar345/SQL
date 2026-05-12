SELECT
    cat.analytic_business_unit AS analytic_business_unit,
    cat.analytic_super_category AS analytic_super_category,
    sales.marketplace_id AS marketplace_id,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    SUM(sales.gmv/62) AS gmv,
    SUM(sales.units/62) AS units
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','furniture')

WHERE
    lower(sales.status) in ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated') 
    AND sales.type != 'service' 
    AND sales.replacement_for_unit IS NULL 
    AND sales.exchange_for_unit IS NULL 
    AND sales.is_freebie = FALSE 
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id IN ('HYPERLOCAL') AND hl.bu_final IS NOT NULL))
    AND sales.order_date_key BETWEEN 20250701 AND 20250831
    AND lower(sales.analytic_business_unit) IN ('bgm','home','furniture')
    AND sales.is_shopsy_order = FALSE
GROUP BY
    cat.analytic_business_unit,
    cat.analytic_super_category,
    sales.marketplace_id,
    CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END 