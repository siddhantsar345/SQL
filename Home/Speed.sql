SELECT
    SLA_date_dim.yearmo,
    SLA_date_dim.year,
    fulfill_item_service_profile,
    sel.is_first_party_seller,
    COUNT(fulfill_item_unit_id) AS total_units,
    SUM(approve_delivery_cdays_sla) AS sla_sum,
    SUM(approve_delivery_o2d_cdays_dd) AS o2d_sum,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 0 THEN 1 ELSE 0 END) AS d0,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 1 THEN 1 ELSE 0 END) AS d1,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 2 THEN 1 ELSE 0 END) AS d2,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 3 THEN 1 ELSE 0 END) AS d3,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 4 THEN 1 ELSE 0 END) AS d4,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 5 THEN 1 ELSE 0 END) AS d5,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 6 THEN 1 ELSE 0 END) AS d6,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 7 THEN 1 ELSE 0 END) AS d7,
    SUM(CASE WHEN approve_delivery_cdays_sla <= 8 THEN 1 ELSE 0 END) AS d8,
    COUNT(CASE WHEN new_lzn IN ('L1', 'L2', 'Z1', 'Z2') THEN fulfill_item_unit_id END) AS ru_units

FROM bigfoot_external_neo.scp_fulfillment__fulfillment_speed_vas_new_hive_history_fact ff

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact SLA_date_dim
    ON ff.order_item_approve_date_key = SLA_date_dim.date_dim_key

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON ff.order_item_product_id = cat.product_id

LEFT JOIN 
    (
    SELECT DISTINCT seller_id, is_first_party_seller 
    FROM bigfoot_external_neo.sp_seller__seller_hive_dim
    ) sel
    ON ff.order_item_seller_id = sel.seller_id

WHERE
    order_item_is_replacement = 0
    AND ff.order_item_is_pre_order = 0
    AND ff.order_item_type = "physical"
    AND ff.order_item_is_exchange = 0
    AND ff.fulfill_item_unit_dropshipment = false
    AND LOWER(marketplace_id) = 'flipkart'
    -- AND is_shopsy_order = FALSE
    AND ff.large_flag = "Non_Large"
    AND ((ff.order_item_approve_date_key BETWEEN 20250101 AND 20250810) OR (ff.order_item_approve_date_key BETWEEN 20240101 AND 20240810))
    AND ff.order_item_approve_date_key not in (20240229)
    AND cat.analytic_business_unit IN ('Home')

GROUP BY
    SLA_date_dim.yearmo,
    SLA_date_dim.year,
    --cat.analytic_super_category,
    fulfill_item_service_profile,
    sel.is_first_party_seller