SELECT
    fes.order_date_key,
    fes.hour_of_day,
    bau.analytic_business_unit,
    bau.analytic_super_category,

    SUM((bau.gmv / bau.units) * bau.units) AS input_bau_weighted_asp,
    SUM((fes.gmv / fes.units) * bau.units) AS input_fes_weighted_asp,
    SUM((bau.gmv / bau.units) * fes.units) AS output_bau_weighted_asp,
    SUM((fes.gmv / fes.units) * fes.units) AS output_fes_weighted_asp

FROM (
    SELECT
        sales.analytic_super_category,
        sales.analytic_business_unit,
        sales.listing_id,
        SUM(units) AS units,
        SUM(gmv)   AS gmv

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.is_shopsy_order = FALSE
        AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
        AND sales.order_date_key BETWEEN CAST(date_format(add_months(trunc(current_date, 'MM'), -1), 'yyyyMMdd') AS BIGINT) AND CAST(date_format(date_add(add_months(trunc(current_date, 'MM'), -1), 24), 'yyyyMMdd') AS BIGINT)

    GROUP BY
        sales.analytic_super_category,
        sales.analytic_business_unit,
        sales.listing_id
) bau

INNER JOIN (
    SELECT
        sales.listing_id,
        sales.unit_creation_date_key AS order_date_key,
        HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm'))) AS hour_of_day,
        SUM(net_units)  AS units,
        SUM(net_amount) AS gmv

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_live_hbase_snapshot_fact sales

    WHERE LOWER(sales.unit_status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND sales.unit_type != 'service'
        AND sales.freebie_flag = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND LOWER(sales.is_shopsy_order) = 'false'
        AND LOWER(sales.business_unit) IN ('bgm','home','lifestyle','furniture')
        AND sales.unit_creation_date_key BETWEEN CAST(date_format(date_sub(current_date, 30), 'yyyyMMdd') AS BIGINT) AND CAST(date_format(current_date, 'yyyyMMdd') AS BIGINT)

    GROUP BY
        sales.listing_id,
        sales.unit_creation_date_key,
        HOUR(from_unixtime(unix_timestamp(sales.unit_creation_timestamp, 'MM/dd/yy HH:mm')))
) fes
    ON bau.listing_id = fes.listing_id

GROUP BY
    fes.order_date_key,
    fes.hour_of_day,
    bau.analytic_business_unit,
    bau.analytic_super_category