--- Approach number 1 ---

WITH CustomerBrandCategory AS (
    SELECT DISTINCT
        sales.account_id,
        cat.brand,
        sales.analytic_super_category,
        sales.analytic_sub_category
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
),

MultiCategoryBuyers AS (
    SELECT
        account_id
    FROM
        CustomerBrandCategory
    GROUP BY
        account_id, brand
    HAVING
        COUNT(DISTINCT analytic_sub_category) > 1
),

TotalBuyers AS (
    SELECT
        COUNT(DISTINCT account_id) AS total_customers
    FROM
        CustomerBrandCategory
)

SELECT
    MAX(t1.total_customers) AS total_customers_count,
    COUNT(DISTINCT t2.account_id) AS loyal_customers_count,
    (COUNT(DISTINCT t2.account_id) * 100.0) / MAX(t1.total_customers) AS cross_category_brand_loyalty_percentage
FROM
    TotalBuyers t1
CROSS JOIN
    MultiCategoryBuyers t2;