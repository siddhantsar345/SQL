WITH High_ASP_FSNs AS (
    SELECT
        sales.product_id AS FSN,
        SUM(sales.gmv) / SUM(sales.units) AS Product_ASP
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN
        bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id
    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship')
        AND sales.type  = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND lower(sales.analytic_business_unit) IN ('furniture')
        AND lower(sales.analytic_vertical) IN ('recliner','sofabedandfuton','sofaandsectional','inflatablesofa','bed','tvandentertainmentunit')
        AND (sales.order_date_key BETWEEN 20250801 AND  20250805)
        AND sales.is_shopsy_order = FALSE
    GROUP BY
        sales.product_id
    HAVING
        SUM(sales.gmv) / SUM(sales.units) > 10000
),

Purchased_FSNs AS (
    SELECT DISTINCT
        cat.product_id AS FSN,
        sales.account_id
    FROM
        bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
    LEFT JOIN
        bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
        ON sales.product_id = cat.product_id
    WHERE
        LOWER(sales.status) IN ('completed', 'delivered')
        AND (sales.order_date_key BETWEEN 20250801 AND 20250805)
),

Cart_Events AS (
    SELECT DISTINCT
        t1.accountid,
        t1.productid AS FSN
    FROM
        bigfoot_external_neo.cp_cdm_consumer__incr_agg_consumer_session_id_listing_fact t1
    WHERE
        t1.addtocartclicks > 0
        AND t1.datekey BETWEEN 20250801 AND 20250805
)

SELECT DISTINCT
    ce.accountid
FROM
    Cart_Events ce
INNER JOIN
    High_ASP_FSNs asp
    ON ce.FSN = asp.FSN
LEFT JOIN
    Purchased_FSNs p
    ON ce.accountid = p.account_id
    AND ce.FSN = p.FSN
WHERE
    p.FSN IS NULL;