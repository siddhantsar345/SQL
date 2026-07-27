SELECT
    sales.unit_creation_date_key  AS order_date_key,
    HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,
    sales.business_unit AS business_unit,
    sales.super_category AS super_category,
    CASE WHEN LOWER(sales.alpha_flag) = 'alpha' THEN 'Diamond' ELSE 'MP' END AS diamond_mp_flag,
    sales.marketplace_id AS marketplace_id,
    SUM(sales.net_units) AS units,
    SUM(sales.net_amount) AS gmv

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales

LEFT JOIN fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON  sales.vertical = hl.analytic_vertical
    AND LOWER(hl.bu_final) IN ('bgm','home','lifestyle','furniture')
    AND sales.marketplace_id = 'HYPERLOCAL'

WHERE LOWER(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
    AND LOWER(sales.business_unit) IN ('bgm','home','lifestyle','furniture')
    AND sales.unit_creation_date_key BETWEEN
        CAST(date_format(date_sub(current_date, 10), 'yyyyMMdd') AS BIGINT)
        AND CAST(date_format(current_date, 'yyyyMMdd') AS BIGINT)

GROUP BY
    sales.unit_creation_date_key,
    HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))),
    sales.business_unit,
    sales.super_category,
    CASE WHEN LOWER(sales.alpha_flag) = 'alpha' THEN 'Diamond' ELSE 'MP' END,
    sales.marketplace_id