SELECT
    geo.pincode AS Pincode,
    SUM(CASE WHEN sales.unit_is_rtod = TRUE THEN sales.units END) AS rto_Units,
    SUM(ret.return_item_quantity) AS rvp_Units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim geo
ON sales.shipping_address_pincode_key = geo.logistics_geo_hive_dim_key

LEFT JOIN
    (
    SELECT
        forward_unit_id,
        SUM(return_item_quantity) AS return_item_quantity
    FROM bigfoot_external_neo.scp_rrr__return_l2_id_level_hive_ss_fact
    WHERE UPPER(return_type) = 'CUSTOMER_RETURN'
          AND (order_item_approve_date_key BETWEEN 20250801 AND 20250805)
          AND UPPER(return_item_status) IN ('INIT', 'COMPLETED', 'APPROVED')
    GROUP BY
        forward_unit_id
    ) ret
    ON ret.forward_unit_id = sales.id


   WHERE LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND (sales.marketplace_id IN ('FLIPKART') )
        AND lower(analytic_business_unit) IN ('furniture')
        AND (sales.order_date_key BETWEEN 20250801 and 20250805)
        AND sales.is_shopsy_order = FALSE

GROUP BY
    geo.pincode