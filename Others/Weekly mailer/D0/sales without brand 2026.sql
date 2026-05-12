WITH pareto AS (
   SELECT analytic_super_category, analytic_vertical
   FROM (
       SELECT
           analytic_super_category,
           analytic_vertical,
           SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC)
               / SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS percentage_value
       FROM (
           SELECT
               sales.analytic_super_category,
               sales.analytic_vertical,
               SUM(gmv) AS vertical_gmv
           FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
           WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
               AND sales.type != 'service'
               AND sales.replacement_for_unit IS NULL
               AND sales.exchange_for_unit IS NULL
               AND sales.is_freebie = FALSE
               AND sales.marketplace_id IN ('FLIPKART')
               AND sales.is_shopsy_order = FALSE
               AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
               AND order_date_key BETWEEN 20250701 AND 20260331
           GROUP BY sales.analytic_super_category, sales.analytic_vertical
       ) base
   ) base2
   WHERE percentage_value <= 0.8
),
bmp AS (
   SELECT brand, analytic_super_category
   FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
   GROUP BY brand, analytic_super_category
),

april_history AS (
   SELECT
       sales.order_date_key                                                        AS order_date_key,
       HOUR(sales.order_date_time)                                                 AS hour_of_day,
       CONCAT(
           CAST(sales.order_date_key AS STRING),
           LPAD(CAST(HOUR(sales.order_date_time) AS STRING), 2, '0')
       )                                                                           AS day_hour,
       sales.analytic_business_unit                                                AS business_unit,
       sales.analytic_super_category                                               AS super_category,
       CASE WHEN pareto.analytic_vertical IS NOT NULL
            THEN sales.analytic_vertical
            ELSE 'Non Pareto Vertical'
       END                                                                         AS vertical,
       CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END        AS branded_flag,
       CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END        AS diamond_mp_flag,
       CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END                AS is_minutes_serviceable,
       CASE
           WHEN sales.gmv / NULLIF(sales.units, 0) <= 300                                                THEN 'a) 0-300'
           WHEN sales.gmv / NULLIF(sales.units, 0) > 300  AND sales.gmv / NULLIF(sales.units, 0) <= 500  THEN 'b) 300-500'
           WHEN sales.gmv / NULLIF(sales.units, 0) > 500  AND sales.gmv / NULLIF(sales.units, 0) <= 1000 THEN 'c) 500-1000'
           WHEN sales.gmv / NULLIF(sales.units, 0) > 1000                                                THEN 'd) 1000+'
       END                                                                         AS price_bucket,
       SUM(sales.gmv)                                                              AS gmv,
       SUM(sales.units)                                                            AS units
   FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
   LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
       ON  sales.analytic_vertical  = hl.analytic_vertical
       AND LOWER(hl.bu_final)       IN ('bgm','home','lifestyle','furniture')
       AND sales.marketplace_id     = 'HYPERLOCAL'
   LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
       ON sales.pincode = hyper.pincode
   LEFT JOIN bmp
       ON  LOWER(sales.brand)                  = LOWER(bmp.brand)
       AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)
   LEFT JOIN pareto
       ON  sales.analytic_super_category = pareto.analytic_super_category
       AND sales.analytic_vertical       = pareto.analytic_vertical
   WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
       AND sales.type != 'service'
       AND sales.replacement_for_unit IS NULL
       AND sales.exchange_for_unit IS NULL
       AND sales.is_freebie = FALSE
       AND sales.is_shopsy_order = FALSE
       AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
       AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
       AND sales.order_date_key BETWEEN 20260401 AND 20260430
   GROUP BY
       sales.order_date_key,
       HOUR(sales.order_date_time),
       CONCAT(
           CAST(sales.order_date_key AS STRING),
           LPAD(CAST(HOUR(sales.order_date_time) AS STRING), 2, '0')
       ),
       sales.analytic_business_unit,
       sales.analytic_super_category,
       CASE WHEN pareto.analytic_vertical IS NOT NULL THEN sales.analytic_vertical ELSE 'Non Pareto Vertical' END,
       CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
       CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END,
       CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END,
       CASE
           WHEN sales.gmv / NULLIF(sales.units, 0) <= 300                                                THEN 'a) 0-300'
           WHEN sales.gmv / NULLIF(sales.units, 0) > 300  AND sales.gmv / NULLIF(sales.units, 0) <= 500  THEN 'b) 300-500'
           WHEN sales.gmv / NULLIF(sales.units, 0) > 500  AND sales.gmv / NULLIF(sales.units, 0) <= 1000 THEN 'c) 500-1000'
           WHEN sales.gmv / NULLIF(sales.units, 0) > 1000                                                THEN 'd) 1000+'
       END
),


may_hbase AS (
   SELECT
       sales.unit_creation_date_key                                                AS order_date_key,
       HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,
       CONCAT(
           CAST(sales.unit_creation_date_key AS STRING),
           LPAD(CAST(HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS STRING), 2, '0')
       )                                                                           AS day_hour,
       sales.business_unit                                                         AS business_unit,
       sales.super_category                                                        AS super_category,
       CASE WHEN pareto.analytic_vertical IS NOT NULL
            THEN sales.vertical
            ELSE 'Non Pareto Vertical'
       END                                                                         AS vertical,
       CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END        AS branded_flag,
       CASE WHEN LOWER(sales.alpha_flag) = 'alpha' THEN 'Diamond' ELSE 'MP' END   AS diamond_mp_flag,
       CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END                AS is_minutes_serviceable,
       CASE
           WHEN sales.amount / NULLIF(sales.units, 0) <= 300                                                   THEN 'a) 0-300'
           WHEN sales.amount / NULLIF(sales.units, 0) > 300  AND sales.amount / NULLIF(sales.units, 0) <= 500  THEN 'b) 300-500'
           WHEN sales.amount / NULLIF(sales.units, 0) > 500  AND sales.amount / NULLIF(sales.units, 0) <= 1000 THEN 'c) 500-1000'
           WHEN sales.amount / NULLIF(sales.units, 0) > 1000                                                   THEN 'd) 1000+'
       END                                                                         AS price_bucket,
       SUM(sales.net_amount)                                                       AS gmv,
       SUM(sales.net_units)                                                        AS units
   FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
   LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
       ON  sales.vertical       = hl.analytic_vertical
       AND LOWER(hl.bu_final)   IN ('bgm','home','lifestyle','furniture')
       AND sales.marketplace_id = 'HYPERLOCAL'
   LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_pincodes_bgm_minutes_2_0 AS hyper
       ON sales.pincode = hyper.pincode
   LEFT JOIN bmp
       ON  LOWER(sales.brand)          = LOWER(bmp.brand)
       AND LOWER(sales.super_category) = LOWER(bmp.analytic_super_category)
   LEFT JOIN pareto
       ON  sales.super_category = pareto.analytic_super_category
       AND sales.vertical       = pareto.analytic_vertical
   WHERE LOWER(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
       AND sales.unit_type    = 'physical'
       AND sales.freebie_flag = FALSE
       AND UPPER(sales.is_shopsy_order) = 'FALSE'
       AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
       AND LOWER(sales.business_unit) IN ('bgm','home','lifestyle','furniture')
       AND sales.unit_creation_date_key BETWEEN 20260501
           AND CAST(date_format(current_date, 'yyyyMMdd') AS BIGINT)
   GROUP BY
       sales.unit_creation_date_key,
       HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))),
       CONCAT(
           CAST(sales.unit_creation_date_key AS STRING),
           LPAD(CAST(HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS STRING), 2, '0')
       ),
       sales.business_unit,
       sales.super_category,
       CASE WHEN pareto.analytic_vertical IS NOT NULL THEN sales.vertical ELSE 'Non Pareto Vertical' END,
       CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
       CASE WHEN LOWER(sales.alpha_flag) = 'alpha' THEN 'Diamond' ELSE 'MP' END,
       CASE WHEN hyper.pincode IS NOT NULL THEN TRUE ELSE FALSE END,
       CASE
           WHEN sales.amount / NULLIF(sales.units, 0) <= 300                                                   THEN 'a) 0-300'
           WHEN sales.amount / NULLIF(sales.units, 0) > 300  AND sales.amount / NULLIF(sales.units, 0) <= 500  THEN 'b) 300-500'
           WHEN sales.amount / NULLIF(sales.units, 0) > 500  AND sales.amount / NULLIF(sales.units, 0) <= 1000 THEN 'c) 500-1000'
           WHEN sales.amount / NULLIF(sales.units, 0) > 1000                                                   THEN 'd) 1000+'
       END
)


SELECT * FROM april_history
UNION ALL
SELECT * FROM may_hbase