SELECT
    sales.product_id AS fsn,
    sales.listing_id AS listing_id,
    CONCAT('https://www.flipkart.com/product/p/itm?pid=', sales.product_id) AS url,
    dd.week_begin_date AS week,
    sales.analytic_super_category AS sc,
    sales.analytic_vertical AS vertical,
    sales.service_profile AS service_profile,
    sales.is_alpha_seller AS alpha_mp,
    sales.marketplace_id AS marketplace,
    SUM(sales.units) AS units,
    SUM(sales.gmv) AS gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact dd
    ON sales.order_date_key = dd.date_dim_key

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'home'

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key BETWEEN 20260101 AND 20260514
    AND LOWER(sales.analytic_business_unit) = 'home'

GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9


-- month level --


SELECT
    sales.product_id AS fsn,
    sales.listing_id AS listing_id,
    CONCAT('https://www.flipkart.com/product/p/itm?pid=', sales.product_id) AS url,
    DIV(sales.order_date_key, 100) AS month,
    sales.analytic_super_category AS sc,
    sales.analytic_vertical AS vertical,
    sales.service_profile AS service_profile,
    sales.is_alpha_seller AS alpha_mp,
    sales.marketplace_id AS marketplace,
    SUM(sales.units) AS units,
    SUM(sales.gmv) AS gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) = 'home'

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key BETWEEN 20260101 AND 20260514
    AND LOWER(sales.analytic_business_unit) = 'home'

GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9