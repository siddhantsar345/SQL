SELECT
  SUBSTR(CAST(fuf.order_date_key AS STRING), 1, 6) AS month,
  fuf.analytic_business_unit AS bu,
  fuf.analytic_super_category AS SC,


  COUNT(DISTINCT CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.order_external_id END) AS UPI_Orders,
  COUNT(DISTINCT CASE WHEN (LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND sales.new_cust_flag = 1 THEN fuf.order_external_id END) AS UPI_NN_Orders,
  COUNT(DISTINCT CASE WHEN (LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.order_external_id END) AS phonepe_ONN_Orders,
  COUNT(DISTINCT CASE WHEN (LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.order_external_id END) AS phonepe_OON_Orders,
  COUNT(DISTINCT CASE WHEN (LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.order_external_id END) AS phonepe_OOO_Orders,
  SUM(CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.gmv END) AS upi_GMV,
  SUM(CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.units END) AS upi_Units,
  SAFE_DIVIDE(
    SUM(CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.gmv END),
    COUNT(DISTINCT CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.order_external_id END)
  ) AS upi_AOV,
  SUM(fuf.gmv) AS gmv

FROM
  bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS fuf
LEFT JOIN
  bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact AS sales
  ON fuf.order_item_id = sales.order_item_id
LEFT JOIN
  bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact AS demo
  ON fuf.account_id = demo.account_id
LEFT JOIN
  (
    SELECT DISTINCT
      account_id,
      cohort
    FROM
      bigfoot_external_neo.cp_uie__affluence_v3_2_final_output_fact
    WHERE
      cohort = 'H'
  ) AS prem
  ON prem.account_id = fuf.account_id
LEFT JOIN
  bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
  ON geo.logistics_geo_hive_dim_key = fuf.shipping_address_pincode_key
LEFT JOIN
  (
    SELECT
      order_external_id,
      MAX(payment_instrument) AS payment_instrument,
      MAX(payment_mode) AS payment_mode
    FROM
      bigfoot_external_neo.cp_bi_prod_sales__forward_payments_365_fact
    GROUP BY
      1
  ) AS p
  ON p.order_external_id = fuf.order_external_id

WHERE
  LOWER(fuf.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
  AND fuf.type != 'service'
  AND fuf.category_id NOT IN (21726, 21651)
  AND fuf.replacement_for_unit IS NULL
  AND fuf.exchange_for_unit IS NULL
  AND NOT fuf.is_freebie
  AND fuf.marketplace_id = 'FLIPKART'
  AND NOT fuf.is_shopsy_order
  AND fuf.analytic_business_unit IN ('BGM', 'Home')
  AND fuf.order_date_key BETWEEN 20250801 AND 20250802

GROUP BY
  1,
  2,
  3