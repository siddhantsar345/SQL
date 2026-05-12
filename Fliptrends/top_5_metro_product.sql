WITH TopMetroRegions AS (
    SELECT
        geo.city AS metro_region,
        SUM(sales.gmv) AS region_total_gmv

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
        ON geo.pincode = sales.pincode
    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND (sales.order_date_key BETWEEN 20250101 AND 20251031)
        AND sales.analytic_business_unit IN ('BGM')
        AND LOWER(sales.analytic_super_category) IN ('makeupfragrances','grooming')
        AND sales.is_shopsy_order = FALSE
        AND sales.city_tier IN ('Metro')
    GROUP BY 1
    ORDER BY region_total_gmv DESC
    LIMIT 5
),
ProductRanking AS (
    SELECT
        geo.city AS metro_region,
        sales.product_id,
        sales.product_title,
        sales.analytic_super_category,
        SUM(sales.gmv) AS product_gmv_in_region,
        ROW_NUMBER() OVER(PARTITION BY geo.city ORDER BY SUM(sales.gmv) DESC) AS rank_in_region

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    LEFT JOIN
    bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id

    LEFT JOIN bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim AS geo
        ON geo.pincode = sales.pincode
    WHERE
        LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
        AND sales.type = 'physical'
        AND sales.replacement_for_unit IS NULL
        AND sales.exchange_for_unit IS NULL
        AND sales.is_freebie = FALSE
        AND sales.marketplace_id IN ('FLIPKART')
        AND (sales.order_date_key BETWEEN 20250101 AND 20251031)
        AND sales.analytic_business_unit IN ('BGM')
        AND LOWER(sales.analytic_super_category) IN ('makeupfragrances','grooming')
        AND sales.city_tier IN ('Metro')
        AND sales.is_shopsy_order = FALSE
    GROUP BY 1,2,3,4
)
SELECT
    pr.metro_region,
    pr.analytic_super_category,
    t1.region_total_gmv,
    pr.product_id,
    pr.product_title,
    pr.product_gmv_in_region

FROM ProductRanking pr

INNER JOIN TopMetroRegions t1
    ON pr.metro_region = t1.metro_region
    
WHERE pr.rank_in_region = 1
ORDER BY t1.region_total_gmv DESC;