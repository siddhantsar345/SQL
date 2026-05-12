SELECT
  *
FROM (
  -- BAU Last Year (Historic)
  SELECT
    sales.order_date_key AS order_date_key,
    sales.analytic_business_unit AS analytic_business_unit,
    sales.analytic_super_category AS analytic_super_category,
    SUM(sales.gmv) AS ly_gmv,
    SUM(sales.units) AS ly_units,
    NULL AS gmv,
    NULL AS units,
    NULL AS is_alpha_seller,
    NULL AS hour_of_day,
    NULL AS event_flag
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
  WHERE
    lower(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type = 'physical'
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.order_date_key = 20240814
    AND lower(sales.analytic_business_unit) IN ('bgm','home','furniture')
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
  GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category
  
  UNION ALL
  
  -- BAU This Year (Live Snapshot)
  SELECT
    sales.unit_creation_date_key AS order_date_key,
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    NULL AS ly_gmv,
    NULL AS ly_units,
    SUM(sales.amount) AS gmv,
    SUM(sales.units) AS units,
    NULL AS is_alpha_seller,
    NULL AS hour_of_day,
    NULL AS event_flag
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
  WHERE
    lower(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.unit_creation_date_key = 20250814
    AND lower(sales.business_unit) IN ('bgm','home','furniture')
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
  GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category
  
  UNION ALL
  
  -- Festive Last Year (Historic)
  SELECT
    sales.order_date_key AS order_date_key,
    EXTRACT(HOUR FROM from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,
    sales.analytic_business_unit AS analytic_business_unit,
    sales.analytic_super_category AS analytic_super_category,
    SUM(sales.amount) AS ly_gmv,
    SUM(sales.units) AS ly_units,
    NULL AS gmv,
    NULL AS units,
    CASE WHEN sales.is_alpha_seller = 'Alpha' THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    NULL AS event_flag
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
  WHERE
    lower(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type = 'physical'
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.order_date_key = 20241020
    AND lower(sales.analytic_business_unit) IN ('bgm','home','furniture')
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
  GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    is_alpha_seller,
    hour_of_day
    
  UNION ALL
  
  -- Festive This Year (Live Snapshot)
  SELECT
    sales.unit_creation_date_key AS order_date_key,
    EXTRACT(HOUR FROM from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    NULL AS ly_gmv,
    NULL AS ly_units,
    SUM(sales.amount) AS gmv,
    SUM(sales.units) AS units,
    CASE WHEN sales.alpha_flag = 'Alpha' THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    sales.event_flag AS event_flag
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
  WHERE
    lower(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.unit_creation_date_key = 20251020
    AND lower(sales.business_unit) IN ('bgm','home','furniture')
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
  GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
    is_alpha_seller,
    hour_of_day,
    event_flag
) AS combined_sales;