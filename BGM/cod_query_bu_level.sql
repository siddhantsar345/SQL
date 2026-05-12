SELECT
    substr(fuf.order_date_key, 1, 6) AS month,
    fuf.analytic_business_unit AS bu,

    -- COD Metrics
    COUNT(DISTINCT CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.order_external_id END) AS cod_orders,
    COUNT(DISTINCT CASE WHEN lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag = 1 THEN fuf.order_external_id END) AS cod_nn_orders,
    COUNT(DISTINCT CASE WHEN lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.order_external_id END) AS cod_on_orders,
    COUNT(DISTINCT CASE WHEN lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.order_external_id END) AS cod_oo_orders,
    SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END)) AS cod_GMV,
    SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.units END)) AS cod_Units,
    SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END)) / COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.order_external_id END)) AS cod_AOV
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact fuf
LEFT JOIN
    (SELECT order_item_id, new_cust_flag, new_to_bu FROM bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact) AS sales
    ON fuf.order_item_id = sales.order_item_id
LEFT JOIN
    (SELECT order_item_id, payment_instrument FROM bigfoot_external_neo.cp_bi_prod_sales__forward_payments_365_fact) AS p
    ON fuf.order_item_id = p.order_item_id
WHERE
    lower(fuf.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND fuf.type != 'service'
    AND fuf.category_id != 21726
    AND fuf.category_id != 21651
    AND fuf.replacement_for_unit IS NULL
    AND fuf.exchange_for_unit IS NULL
    AND fuf.is_freebie = FALSE
    AND fuf.marketplace_id IN ('FLIPKART')
    AND fuf.is_shopsy_order = FALSE
    AND fuf.analytic_business_unit IN ('BGM','Home')
    AND fuf.order_date_key BETWEEN 20250801 AND 20250831
GROUP BY
    substr(fuf.order_date_key, 1, 6),
    fuf.analytic_business_unit