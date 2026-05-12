--- Which Tier 3 and Tier 4 city has the highest AOV (Average Order Value) in beauty and skincare? ---
--- gmv/orders= AOV ---

SELECT
    sales.city_tier,
    SUM(sales.gmv) / count(distinct sales.order_external_id) AS average_order_value 

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

LEFT JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
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
    AND (sales.order_date_key BETWEEN 20250801 AND 20251031)
    AND sales.analytic_business_unit IN ('BGM')
    AND lower(sales.analytic_super_category) IN ('makeupfragrance','grooming')
    AND sales.is_shopsy_order = FALSE
    AND sales.city_tier IN ('Tier 3 & Others') 

GROUP BY
    sales.city_tier

HAVING
    SUM(sales.order_id) > 0

ORDER BY
    average_order_value DESC
LIMIT 1;