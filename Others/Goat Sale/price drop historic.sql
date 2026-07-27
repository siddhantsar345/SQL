SELECT
   fes.order_date_key,
   fes.hour_of_day,
   bau.analytic_business_unit,
   bau.analytic_super_category,
   bau.is_alpha_seller,
   bau.marketplace_id,
   SUM((bau.gmv / bau.units) * bau.units) AS input_bau_weighted_asp,
   SUM((fes.gmv / fes.units) * bau.units) AS input_fes_weighted_asp,
   SUM((bau.gmv / bau.units) * fes.units) AS output_bau_weighted_asp,
   SUM((fes.gmv / fes.units) * fes.units) AS output_fes_weighted_asp


FROM (
   SELECT
       sales.analytic_super_category,
       sales.analytic_business_unit,
       sales.marketplace_id,
       CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
       sales.product_id,
       sales.listing_id,
       SUM(units) AS units,
       SUM(gmv) AS gmv,
       SUM(listing_price) AS lp


   FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

   LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')


   WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
       AND sales.type != 'service'
       AND sales.replacement_for_unit IS NULL
       AND sales.exchange_for_unit IS NULL
       AND sales.is_freebie = FALSE
       AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
       AND sales.is_shopsy_order = FALSE
       AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
       AND order_date_key BETWEEN 20250601 AND 20250625


   GROUP BY
       sales.analytic_super_category,
       sales.analytic_business_unit,
       sales.marketplace_id,
       CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
       sales.product_id,
       sales.listing_id
) bau


INNER JOIN (


   SELECT
       sales.listing_id,
       sales.marketplace_id,
       sales.order_date_key AS order_date_key,
       HOUR(from_unixtime(unix_timestamp(sales.order_date_time, 'MM/dd/yy HH:mm'))) AS hour_of_day,
       SUM(units) AS units,
       SUM(gmv) AS gmv,
       SUM(listing_price) AS lp


   FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

   LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')


   WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
       AND sales.type != 'service'
       AND sales.is_freebie = FALSE
       AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
       AND LOWER(sales.is_shopsy_order) = 'false'
       AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
       AND sales.order_date_key BETWEEN 20250701 AND 20250731


   GROUP BY
       sales.listing_id,
       sales.marketplace_id,
       sales.order_date_key,
       HOUR(from_unixtime(unix_timestamp(sales.order_date_time, 'MM/dd/yy HH:mm')))


) fes
   ON bau.listing_id = fes.listing_id
   AND bau.marketplace_id = fes.marketplace_id


GROUP BY
   fes.order_date_key,
   fes.hour_of_day,
   bau.analytic_business_unit,
   bau.analytic_super_category,
   bau.is_alpha_seller,
   bau.marketplace_id