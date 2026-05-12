-- transacting selection


SELECT
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    COUNT(DISTINCT sales.listing_id) AS trans_lid_count,
    COUNT(DISTINCT sales.product_id) AS trans_pid_count,
    SUM(sales.gmv) AS gmv,
    SUM(sales.units) AS sales_units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS sales

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

LEFT JOIN (
    SELECT
        listing_id,
        is_first_party_seller AS is_alpha_seller,
        flipkart_selling_price
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
) list_dim_fact
    ON list_dim_fact.listing_id = sales.listing_id

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim AS prod_dim
    ON sales.product_id = prod_dim.product_id

INNER JOIN fdp_uploads.ds_fkint_analytics_cdo_underindexed_verticals_1_0 AS virt_filter
    ON LOWER(prod_dim.analytic_super_category) = LOWER(virt_filter.sc)
    AND LOWER(prod_dim.analytic_vertical) = LOWER(virt_filter.vertical)

WHERE
    LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type != 'service'
    AND sales.category_id NOT IN (21726, 21651)
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id = 'FLIPKART'
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key BETWEEN 20260101 AND 20260329
    AND LOWER(prod_dim.analytic_business_unit) IN ('home', 'furniture')
    AND LOWER(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')

GROUP BY 1, 2, 3, 4, 5


-- new transaction selection --


SELECT
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    NULL AS snapshot_used,
    NULL AS lid_created_month_cohort,
    prod_dim.analytic_business_unit,
    prod_dim.analytic_super_category,
    COUNT(DISTINCT sales.listing_id) AS trans_lid_count,
    COUNT(DISTINCT sales.product_id) AS trans_pid_count,
    SUM(sales.gmv) AS gmv,
    SUM(sales.units) AS sales_units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact AS sales

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
    ON sales.product_id = prod_dim.product_id

INNER JOIN fdp_uploads.ds_fkint_analytics_cdo_underindexed_verticals_1_0 AS virt_filter
    ON LOWER(prod_dim.analytic_super_category) = LOWER(virt_filter.sc)
    AND LOWER(prod_dim.analytic_vertical) = LOWER(virt_filter.vertical)

LEFT JOIN (
    SELECT 
        listing_id, 
        CAST(MIN(listing_created_on) AS DATE) AS listing_birth_date
    FROM bigfoot_external_neo.sp_product__listing_hive_dim
    WHERE marketplace_id = 'FLIPKART'
    AND listing_created_on >= '2024-08-01'
    GROUP BY 1
) list_dim_fact
    ON list_dim_fact.listing_id = sales.listing_id

WHERE
    LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
    AND sales.type != 'service'
    AND sales.category_id NOT IN (21726, 21651)
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id = 'FLIPKART'
    AND sales.is_shopsy_order = FALSE
    AND sales.order_date_key BETWEEN 20260101 AND 20260329
    AND DATE_DIFF(
            PARSE_DATE('%Y%m%d', CAST(sales.order_date_key AS STRING)), 
            list_dim_fact.listing_birth_date, 
            DAY
        ) <= 90
    AND LOWER(prod_dim.analytic_business_unit) IN ('home', 'furniture')
    AND LOWER(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')

GROUP BY 1, 2, 3, 4, 5, 6, 7

--- GMV share and unit share ---

SELECT 
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    sales.analytic_business_unit,
    sales.analytic_super_category,
    SUM(CASE WHEN vertical_filter.vertical IS NOT NULL THEN sales.gmv ELSE 0 END) AS underindexed_vertical_gmv,
    SUM(sales.gmv) AS total_mp_home_gmv,
    SUM(CASE WHEN vertical_filter.vertical IS NOT NULL THEN sales.gmv ELSE 0 END) / 
        NULLIF(SUM(sales.gmv), 0) AS gmv_share,

    SUM(CASE WHEN vertical_filter.vertical IS NOT NULL THEN sales.units ELSE 0 END) AS underindexed_vertical_units,
    SUM(sales.units) AS total_mp_home_units,
    SUM(CASE WHEN vertical_filter.vertical IS NOT NULL THEN sales.units ELSE 0 END) / 
        NULLIF(SUM(sales.units), 0) AS units_share

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
    ON sales.order_date_key = wd.date_dim_key

LEFT JOIN fdp_uploads.ds_fkint_analytics_cdo_underindexed_verticals_1_0 AS vertical_filter
    ON LOWER(sales.analytic_super_category) = LOWER(vertical_filter.sc)
    AND LOWER(sales.analytic_vertical) = LOWER(vertical_filter.vertical)

WHERE 

    (CASE WHEN sales.is_alpha_seller = TRUE THEN 'Diamond' ELSE 'MP' END) = 'MP'
    AND LOWER(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    AND sales.type = 'physical'
    AND sales.replacement_for_unit IS NULL
    AND sales.exchange_for_unit IS NULL
    AND sales.is_freebie = FALSE
    AND sales.marketplace_id = 'FLIPKART'
    AND sales.analytic_business_unit = 'Home'
    AND sales.order_date_key BETWEEN 20260101 AND 20260329
    AND sales.is_shopsy_order = FALSE

group by 
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year,
    sales.analytic_business_unit,
    sales.analytic_super_category