SELECT
    sales.product_id,
    sales.analytic_super_category,
    COUNT(DISTINCT sales.account_id) AS distinct_customer_count,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT sales.account_id) DESC) AS customer_rank
FROM
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales
LEFT JOIN
    bigfoot_external_neo.sp_product__product_categorization_hive_dim cat
    ON sales.product_id = cat.product_id
WHERE
    lower(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type != 'service'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id IN ('FLIPKART')
    AND sales.order_date_key BETWEEN 20250801 AND 20250831
    AND sales.is_shopsy_order = FALSE
    AND sales.analytic_business_unit IN ('BGM')
    AND lower(sales.analytic_super_category) IN ('makeupfragrances')
GROUP BY
    sales.product_id,
    sales.analytic_super_category
ORDER BY
    distinct_customer_count DESC
LIMIT 10;