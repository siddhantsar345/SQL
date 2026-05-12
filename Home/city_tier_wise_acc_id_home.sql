SELECT
    analytic_super_category,
    sales.city_tier,
    COUNT(DISTINCT sales.account_id) AS distinct_account_count
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
    ON geo.pincode = sales.pincode

WHERE
    LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND LOWER(sales.marketplace_id) IN ('flipkart')
    AND (sales.order_date_key BETWEEN 20240101 AND 20240331)
    AND sales.order_date_key!= 20240229
    AND sales.analytic_business_unit IN ('Home')
    AND lower(sales.analytic_super_category) IN ('homedecor','homefurnishing','homeimprovementtool','household')
    AND sales.is_shopsy_order = FALSE
GROUP BY
    1,
    analytic_super_category,
    sales.city_tier;