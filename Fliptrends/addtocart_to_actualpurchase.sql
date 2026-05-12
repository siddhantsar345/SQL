WITH SalesData AS (
    SELECT
        sales.product_id,
        cat.analytic_super_category,
        SUM(sales.units) AS purchased_units
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN
        bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id
    WHERE
        LOWER(sales.status) IN ('completed', 'delivered', 'approved', 'shipped')
        AND sales.type != 'service'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND sales.order_date_key BETWEEN 20250801 AND 20250831
        AND sales.analytic_business_unit IN ('BGM')
        AND sales.is_shopsy_order = FALSE
    GROUP BY
        sales.product_id, cat.analytic_super_category
),

ClicksData AS (
    SELECT
        clicks.productid,
        cat.analytic_super_category,
        SUM(clicks.addtocartclicks) AS add_to_cart_clicks
    FROM
        bigfoot_external_neo.cp_cdm_consumer__incr_agg_consumer_session_id_listing_fact clicks
    LEFT JOIN
        bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON clicks.productid = cat.product_id
    WHERE
        cat.analytic_business_unit IN ('BGM')
        AND clicks.datekey BETWEEN 20250801 AND 20250831
    GROUP BY
        clicks.productid, cat.analytic_super_category
)

SELECT
    t1.analytic_super_category,
    SUM(t1.purchased_units) AS total_purchased_units,
    SUM(t2.add_to_cart_clicks) AS total_add_to_cart_clicks,
    (CAST(SUM(t1.purchased_units) AS DOUBLE) / NULLIF(CAST(SUM(t2.add_to_cart_clicks) AS DOUBLE), 0)) AS conversion_rate
FROM
    SalesData t1
INNER JOIN
    ClicksData t2
    ON t1.product_id = t2.productid AND t1.analytic_super_category = t2.analytic_super_category
GROUP BY
    t1.analytic_super_category
ORDER BY
    conversion_rate DESC
LIMIT 1;