SELECT
  CAST(substr(fuf.order_date_key, 1, 6) AS INT)  AS month,
  COALESCE(geo.city_tier, 'Unknown')             AS city_tier,
  COUNT(DISTINCT fuf.account_id)                 AS tc

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact fuf

LEFT JOIN (
    SELECT logistics_geo_hive_dim_key, city_tier
    FROM bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim
) geo
  ON geo.logistics_geo_hive_dim_key = fuf.shipping_address_pincode_key

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
  ON fuf.analytic_vertical = hl.analytic_vertical
 AND LOWER(hl.bu_final) = 'home'

WHERE
  LOWER(fuf.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
  AND fuf.type != 'service'
  AND fuf.category_id NOT IN (21726, 21651)
  AND fuf.replacement_for_unit IS NULL
  AND fuf.exchange_for_unit    IS NULL
  AND fuf.is_freebie      = FALSE
  AND fuf.is_shopsy_order = FALSE
  AND (
        fuf.marketplace_id = 'FLIPKART'
        OR (fuf.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL)
      )
  AND fuf.analytic_business_unit = 'Home'
  AND fuf.order_date_key BETWEEN 20240515 AND 20260515

GROUP BY
  CAST(substr(fuf.order_date_key, 1, 6) AS INT),
  COALESCE(geo.city_tier, 'Unknown')