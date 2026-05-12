WITH weekly_snapshot AS (
    SELECT 
        wd.week_begin_date,
        wd.yearmo,
        wd.week_num_in_year,
        MAX(wd.date_dim_key) as report_date
    FROM bigfoot_external_neo.scp_oms__date_dim_fact wd
    WHERE wd.date_dim_key BETWEEN 20260101 AND 20260329
    GROUP BY  
    wd.week_begin_date,
    wd.yearmo,
    wd.week_num_in_year
),

inventory_agg AS (
    SELECT 
        snap.week_begin_date,
        snap.yearmo,
        snap.week_num_in_year,
        prod_dim.analytic_business_unit,
        prod_dim.analytic_super_category,

        COUNT(distinct CASE WHEN list_dim.final_atp > 0 THEN list_dim.listing_id END) as ai_listings,
        COUNT(distinct CASE WHEN list_dim.final_atp > 0 THEN list_dim.seller_id END) as ai_sellerid

    FROM bigfoot_external_neo.sp_analytics__listing_history_90d_fact as list_dim

    INNER JOIN weekly_snapshot snap 
        ON list_dim.process_date_key = snap.report_date

    INNER JOIN fdp_uploads.ds_fkint_analytics_cdo_cluster_track_1_0 AS filter_listt
        ON list_dim.seller_id = filter_listt.seller_id

    LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim prod_dim
        ON list_dim.product_id = prod_dim.product_id

    WHERE list_dim.marketplace_id = 'FLIPKART'
      AND LOWER(prod_dim.analytic_business_unit) in ('home','furniture')
      AND LOWER(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')

    GROUP BY 1,2,3,4,5
),

sales_agg AS (
    SELECT
        week_begin_date,
        yearmo,
        week_num_in_year,
        analytic_business_unit,
        analytic_super_category,
        COUNT(distinct listing_id) as trans_lid_count,
        SUM(gmv) as gmv,
        SUM(units) as sales_units,
        COUNT(distinct CASE WHEN daily_seller_units > 10 THEN seller_id END) as sellers_10_units_daily
        
    FROM (
        SELECT
            wd.week_begin_date,
            wd.yearmo,
            wd.week_num_in_year,
            prod_dim.analytic_business_unit,
            prod_dim.analytic_super_category,
            sales.listing_id,
            sales.seller_id,
            sales.gmv,
            sales.units,
            SUM(sales.units) OVER (PARTITION BY sales.seller_id, sales.order_date_key) as daily_seller_units

        FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

        INNER JOIN fdp_uploads.ds_fkint_analytics_cdo_cluster_track_1_0 AS filter_list
            ON sales.seller_id = filter_list.seller_id

        INNER JOIN bigfoot_external_neo.scp_oms__date_dim_fact wd
            ON sales.order_date_key = wd.date_dim_key

        LEFT JOIN bigfoot_external_neo.sp_product__product_attribute_hive_dim as prod_dim
            ON sales.product_id = prod_dim.product_id

        WHERE sales.order_date_key BETWEEN 20260101 AND 20260329
            AND LOWER(sales.status) IN ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
            AND sales.type !='service'
            AND sales.category_id NOT IN (21726, 21651)
            AND sales.replacement_for_unit IS NULL
            AND sales.exchange_for_unit IS NULL
            AND sales.is_freebie = FALSE
            AND sales.marketplace_id = 'FLIPKART'
            AND sales.is_shopsy_order = False
            AND (LOWER(prod_dim.analytic_business_unit) = 'home' OR LOWER(prod_dim.analytic_business_unit) = 'furniture')
            AND LOWER(prod_dim.analytic_vertical) NOT IN ('plantsapling', 'plantseed')

    ) sub
    GROUP BY 1,2,3,4,5
)

SELECT 
    coalesce(i.week_begin_date, s.week_begin_date) AS week_begin_date,
    coalesce(i.yearmo, s.yearmo) AS yearmo,
    coalesce(i.week_num_in_year, s.week_num_in_year) AS week_num_in_year,
    coalesce(i.analytic_business_unit, s.analytic_business_unit) AS analytic_business_unit,
    coalesce(i.analytic_super_category, s.analytic_super_category) AS analytic_super_category,
    
    coalesce(i.ai_listings, 0) AS ai_listings,
    coalesce(i.ai_sellerid, 0) AS ai_sellerid,
    
    coalesce(s.trans_lid_count, 0) AS trans_lid_count,
    coalesce(s.gmv, 0) AS gmv,
    coalesce(s.sales_units, 0) AS sales_units,
    coalesce(s.sellers_10_units_daily, 0) AS sellers_10_units_daily

FROM inventory_agg i
FULL OUTER JOIN sales_agg s
    ON i.week_begin_date = s.week_begin_date
    AND i.analytic_business_unit = s.analytic_business_unit
    AND i.analytic_super_category = s.analytic_super_category;