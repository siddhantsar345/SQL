SELECT
    date_format(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm')), 'yyyy-MM-dd') AS day,
    HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))) AS hour_of_day,
    sales.analytic_business_unit AS business_unit,
    sales.analytic_super_category AS super_category,
    SUM(sales.gmv) AS gmv,
    SUM(sales.units) AS units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.analytic_vertical = hl.analytic_vertical
   AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
   AND sales.marketplace_id = 'HYPERLOCAL'

WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
    AND sales.type = 'physical'
    AND sales.is_freebie = FALSE
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
    AND sales.order_date_key BETWEEN CAST(date_format(date_sub(add_months(current_date, -12), 34), 'yyyyMMdd') AS BIGINT)
                                 AND CAST(date_format(add_months(current_date, -12), 'yyyyMMdd') AS BIGINT)

GROUP BY
    date_format(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm')), 'yyyy-MM-dd'),
    HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))),
    sales.analytic_business_unit,
    sales.analytic_super_category