SELECT
    sales.unit_creation_date_key AS order_date_key,
    EXTRACT(HOUR FROM from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,
    sales.business_unit AS analytic_business_unit,
    sales.super_category AS analytic_super_category,
    sales.marketplace_id AS marketplace_id,
    CASE WHEN lower(sales.alpha_flag) = 'alpha' THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
    sales.event_flag AS event_flag,
    SUM(sales.amount) AS gmv,
    SUM(sales.units) AS units
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales
LEFT JOIN
    fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl
    ON sales.vertical = hl.analytic_vertical AND lower(hl.bu_final) IN ('bgm','home','furniture')
WHERE
    lower(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.unit_type = 'physical'
    AND sales.freebie_flag = FALSE
    AND sales.unit_creation_date_key >= 20250901
    AND unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm') < UNIX_TIMESTAMP() - 3600
    AND lower(sales.business_unit) IN ('bgm','home','furniture')
    AND UPPER(sales.is_shopsy_order) = 'FALSE'
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND hl.analytic_vertical IS NOT NULL))
GROUP BY
    sales.unit_creation_date_key,
    EXTRACT(HOUR FROM from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))),
    sales.business_unit,
    sales.super_category,
    sales.marketplace_id,
    CASE WHEN lower(sales.alpha_flag) = 'alpha' THEN 'Diamond' ELSE 'Rest of MP' END,
    sales.event_flag