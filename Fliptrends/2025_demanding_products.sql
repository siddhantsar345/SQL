WITH
cte_2024_top_demand AS (
    SELECT
        sales.product_id
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
        AND sales.order_date_key BETWEEN 20240101 AND 20241231
        AND sales.is_shopsy_order = FALSE
        AND sales.analytic_business_unit IN ('BGM')
        AND lower(sales.analytic_super_category) IN ('makeupfragrances')
    GROUP BY
        sales.product_id
    ORDER BY
        SUM(sales.units) DESC
    LIMIT 100
),

cte_2025_demand_data AS (
    SELECT
        sales.product_id,
        sales.product_title,
        sales.analytic_super_category,
        SUM(sales.units) AS total_units_sold
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
        AND sales.order_date_key BETWEEN 20250101 AND 20251031
        AND sales.is_shopsy_order = FALSE
        AND sales.analytic_business_unit IN ('BGM')
        AND lower(sales.analytic_super_category) IN ('makeupfragrances')
    GROUP BY
        sales.product_id,
        sales.product_title,
        sales.analytic_super_category
)
SELECT
    d25.product_id,
    d25.product_title,
    d25.analytic_super_category,
    d25.total_units_sold,
    ROW_NUMBER() OVER (ORDER BY d25.total_units_sold DESC) AS sales_rank_2025,
    CASE
        WHEN d25.product_id IN (SELECT product_id FROM cte_2024_top_demand) THEN 'Existing Top Product (2024 Demand)'
        ELSE 'New/Rising Product (2025 Demand)'
    END AS demand_status
FROM
    cte_2025_demand_data d25
ORDER BY
    d25.total_units_sold DESC
LIMIT 10;