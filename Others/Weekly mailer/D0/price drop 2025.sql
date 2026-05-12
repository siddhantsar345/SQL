WITH bmp_brands AS (
    SELECT brand, analytic_super_category
    FROM fdp_uploads.ds_fkint_analytics_cdo_final_central_consolidated_sc_brand_list_fact_1_0
    GROUP BY brand, analytic_super_category
),

pareto_verticals AS (
    SELECT analytic_super_category, analytic_vertical
    FROM (
        SELECT
            analytic_super_category,
            analytic_vertical,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category ORDER BY vertical_gmv DESC ROWS UNBOUNDED PRECEDING) AS vert_gmv_cumilative,
            SUM(vertical_gmv) OVER (PARTITION BY analytic_super_category) AS total_sc_gmv,
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
)

SELECT
    fes.order_date_key,
    fes.hour_of_day,
    fes.day_hour,
    bau.analytic_business_unit,
    bau.analytic_super_category,
    bau.analytic_vertical,
    bau.brand,
    bau.branded_flag,
    bau.is_alpha_seller,
    CASE
        WHEN bau.gmv / bau.units <= 300 THEN '0-300'
        WHEN bau.gmv / bau.units > 300  AND bau.gmv / bau.units <= 500  THEN '300-500'
        WHEN bau.gmv / bau.units > 500  AND bau.gmv / bau.units <= 1000 THEN '500-1000'
        WHEN bau.gmv / bau.units > 1000 THEN '1000+'
        ELSE 'Unknown'
    END AS price_bucket,

    SUM((bau.gmv / bau.units) * bau.units) AS input_bau_weighted_asp,
    SUM((fes.gmv / fes.units) * bau.units) AS input_fes_weighted_asp,
    SUM((bau.gmv / bau.units) * fes.units) AS output_bau_weighted_asp,
    SUM((fes.gmv / fes.units) * fes.units) AS output_fes_weighted_asp

FROM (
    SELECT
        sales.analytic_super_category,
        sales.analytic_business_unit,
        sales.analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END AS brand,
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END AS branded_flag,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END AS is_alpha_seller,
        sales.product_id,
        sales.listing_id,
        SUM(units) AS units,
        SUM(gmv) AS gmv,
        SUM(listing_price) AS lp

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN bmp_brands bmp
        ON LOWER(sales.brand) = LOWER(bmp.brand)
       AND LOWER(sales.analytic_super_category) = LOWER(bmp.analytic_super_category)

    WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.is_shopsy_order = FALSE
        AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
        AND order_date_key BETWEEN 20250401 AND 20250425

    GROUP BY
        sales.analytic_super_category,
        sales.analytic_business_unit,
        sales.analytic_vertical,
        CASE WHEN bmp.brand IS NOT NULL THEN sales.brand ELSE 'Unbranded' END,
        CASE WHEN bmp.brand IS NOT NULL THEN 'Branded' ELSE 'Unbranded' END,
        CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'Rest of MP' END,
        sales.product_id,
        sales.listing_id
) bau

INNER JOIN (

    SELECT
        sales.listing_id,
        sales.order_date_key AS order_date_key,
        HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))) AS hour_of_day,
        CONCAT(
            date_format(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm')), 'yyyyMMdd'),
            LPAD(CAST(HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))) AS STRING), 2, '0')
        ) AS day_hour,
        SUM(units) AS units,
        SUM(gmv) AS gmv,
        SUM(listing_price) AS lp

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned','return_requested','activated')
        AND sales.type != 'service'
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND LOWER(sales.is_shopsy_order) = 'false'
        AND LOWER(sales.analytic_business_unit) IN ('bgm','home','lifestyle','furniture')
        AND sales.order_date_key BETWEEN 20250501 AND 20250531
        AND CAST(
                CONCAT(
                    date_format(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm')), 'yyyyMMdd'),
                    LPAD(CAST(HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))) AS STRING), 2, '0')
                ) AS BIGINT
            )
            <= CAST(
                CONCAT(
                    date_format(current_date, 'yyyyMMdd'),
                    LPAD(CAST(HOUR(current_timestamp) AS STRING), 2, '0')
                ) AS BIGINT
            )

    GROUP BY
        sales.listing_id,
        sales.order_date_key,
        sales.unit_creation_date_time,
        HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))),
        CONCAT(
            date_format(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm')), 'yyyyMMdd'),
            LPAD(CAST(HOUR(from_unixtime(unix_timestamp(sales.unit_creation_date_time, 'M/d/yy H:mm'))) AS STRING), 2, '0')
        )

) fes
    ON bau.listing_id = fes.listing_id

LEFT JOIN pareto_verticals pv
    ON LOWER(bau.analytic_super_category) = LOWER(pv.analytic_super_category)
   AND LOWER(bau.analytic_vertical) = LOWER(pv.analytic_vertical)

GROUP BY
    fes.order_date_key,
    fes.hour_of_day,
    fes.day_hour,
    bau.analytic_business_unit,
    bau.analytic_super_category,
    bau.analytic_vertical,
    bau.brand,
    bau.branded_flag,
    bau.is_alpha_seller,
    CASE
        WHEN bau.gmv / bau.units <= 300 THEN '0-300'
        WHEN bau.gmv / bau.units > 300  AND bau.gmv / bau.units <= 500  THEN '300-500'
        WHEN bau.gmv / bau.units > 500  AND bau.gmv / bau.units <= 1000 THEN '500-1000'
        WHEN bau.gmv / bau.units > 1000 THEN '1000+'
        ELSE 'Unknown'
    END