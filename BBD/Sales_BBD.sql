SELECT
  *
FROM (
  -- BAU Last Year (Historic)
  SELECT
    sales.order_date_key as order_date_key,
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    SUM(sales.gmv) AS ly_gmv,
    SUM(sales.units) AS ly_units
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
  WHERE
    lower(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.order_date_key = 20240814
    AND lower(sales.business_unit) IN ('bgm','home','furniture')
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
  GROUP BY
    order_date_key,
    analytic_business_unit,
    analytic_super_category,
  
  UNION ALL
  
  -- BAU This Year (Live Snapshot)
  SELECT
    sales.unit_creation_date_key AS order_date_key,
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    SUM(sales.amount) AS gmv,
    SUM(sales.units) AS units
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
    EXTRACT(HOUR FROM PARSE_TIMESTAMP('%m/%d/%y %H:%M', sales.unit_creation_timestamp)) AS hour_of_day,
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    CASE WHEN sales.is_alpha_seller = 'Alpha' THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    SUM(sales.amount) AS ly_gmv,
    SUM(sales.units) AS ly_units
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
  WHERE
    lower(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.order_date_key = 20241020
    AND lower(sales.business_unit) IN ('bgm','home','furniture')
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
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    CASE WHEN sales.alpha_flag = 'Alpha' THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    SUM(sales.amount) AS gmv,
    SUM(sales.units) AS units,
    EXTRACT(HOUR FROM PARSE_TIMESTAMP('%m/%d/%y %H:%M', sales.unit_creation_timestamp)) AS hour_of_day,
    sales.event_flag AS event_flag
  FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
  WHERE
    lower(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.unit_creation_date_key = 20251020 -- Example Festive date
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