-- Approach number 2 ---


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
LoyalBrandCustomers AS (
    SELECT
        account_id,
        brand
    FROM
        CustomerBrandCategory
    GROUP BY
        account_id, brand
    HAVING
        COUNT(DISTINCT analytic_sub_category) > 1
),

BrandMetrics AS (
    SELECT
        t1.brand,
        COUNT(DISTINCT t1.account_id) AS total_brand_customers_count,
        COUNT(DISTINCT t2.account_id) AS loyal_brand_customers_count
    FROM
        CustomerBrandCategory t1
    LEFT JOIN
        LoyalBrandCustomers t2
        ON t1.account_id = t2.account_id AND t1.brand = t2.brand
    GROUP BY
        t1.brand
),
BrandCategoryList AS (
    SELECT DISTINCT
        t1.brand,
        t1.analytic_sub_category
    FROM
        CustomerBrandCategory t1
    INNER JOIN
        LoyalBrandCustomers t2
        ON t1.account_id = t2.account_id AND t1.brand = t2.brand
),

LoyalBrandDetails AS (
    SELECT
        brand,
        STRING_AGG(DISTINCT analytic_sub_category, ', ') AS purchased_sub_categories
    FROM
        BrandCategoryList
    GROUP BY
        brand
)

SELECT
    t1.brand,
    t2.purchased_sub_categories,
    t1.total_brand_customers_count,
    t1.loyal_brand_customers_count,
    (t1.loyal_brand_customers_count * 100.0) / t1.total_brand_customers_count AS brand_cross_category_loyalty_percentage
FROM
    BrandMetrics t1
INNER JOIN
    LoyalBrandDetails t2
    ON t1.brand = t2.brand
WHERE
    t1.loyal_brand_customers_count > 0
ORDER BY
    brand_cross_category_loyalty_percentage DESC;