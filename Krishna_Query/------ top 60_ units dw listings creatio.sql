------ top 60% units dw listings creation
create table adhoc_ttl_90days.bgm_sc_mp_lids_aug_2025_ranking_units_60 as

SELECT
    analytic_super_category,
    listing_id,
    units / 31 as aug_drr_units,
    sum(units) over (order by units desc rows unbounded preceding) / sum(units) over() as perc_dw

FROM
(
    SELECT
        sales.analytic_super_category,
        sales.analytic_vertical,
        sales.listing_id,
        sum(sales.units) as units

    FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales

    WHERE lower(sales.status) in ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated') 
    and sales.type != 'service' 
    and sales.replacement_for_unit IS NULL 
    and sales.exchange_for_unit IS NULL 
    and sales.is_freebie = FALSE 
    and sales.marketplace_id IN ('FLIPKART') 
    and order_date_key between 20250801 and 20250831
    and sales.is_shopsy_order = FALSE 
    and lower(sales.analytic_business_unit) IN ('bgm')
    and sales.is_alpha_seller = FALSE

    GROUP BY
        sales.analytic_super_category,
        sales.analytic_vertical,
        sales.listing_id
) fuf




-- create table adhoc_ttl_90days.bgm_sc_vertical_ratio_for_festive_lids_2025 as
select 
    post.analytic_super_category as sc,
    post.analytic_vertical as vertical,
    post.order_date_key, 
    post.units as post_units,
    pre.units_drr as pre_units,
    post.units / pre.units_drr AS ratio

from
(
    select 
        sales.analytic_super_category,
        sales.analytic_vertical,
        sales.order_date_key,
        sum(sales.gmv) as gmv,
        sum(sales.units) as units

    from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales 

    WHERE 
        lower(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated') 
        AND sales.type != 'service' 
        AND sales.replacement_for_unit IS NULL 
        AND sales.exchange_for_unit IS NULL 
        AND sales.is_freebie = FALSE 
        AND sales.marketplace_id IN ('FLIPKART') 
        AND sales.order_date_key between 20240901 and 20241031
        AND sales.is_shopsy_order = FALSE 
        AND sales.analytic_business_unit IN ('BGM')
        and sales.is_alpha_seller = FALSE
    GROUP by
        sales.analytic_super_category,
        sales.analytic_vertical,
        sales.order_date_key
) as post

left join
(  
    select 
        sales.analytic_super_category,
        sales.analytic_vertical,
        sum(sales.gmv / 31)  as gmv_drr,
        sum(sales.units / 31)  as units_drr

    from bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact sales 

    WHERE 
        lower(sales.status) IN ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated') 
        AND sales.type != 'service' 
        AND sales.replacement_for_unit IS NULL 
        AND sales.exchange_for_unit IS NULL 
        AND sales.is_freebie = FALSE 
        AND sales.marketplace_id IN ('FLIPKART') 
        AND sales.order_date_key BETWEEN 20240801 AND 20240831 
        AND sales.is_shopsy_order = FALSE 
        AND sales.analytic_business_unit IN ('BGM')
        and sales.is_alpha_seller = FALSE
    GROUP by         
        sales.analytic_super_category,
        sales.analytic_vertical
)as pre 

on pre.analytic_super_category = post.analytic_super_category  
    and pre.analytic_vertical = post.analytic_vertical




----
with top_60 as(
    SELECT
        listing_id,
        analytic_super_category,
        aug_drr_units
    from adhoc_ttl_90days.bgm_sc_mp_lids_aug_2025_ranking_units_60
    WHERE perc_dw <= 0.6
),

ratio AS (
    SELECT 
        date_map.dates_current_year,
        ratio.sc as analytic_super_category,
        ratio.vertical,
        ratio.ratio
    FROM adhoc_ttl_90days.bgm_sc_vertical_ratio_for_festive_lids_2025 AS ratio

    inner join fdp_uploads.ds_fkint_analytics_cdo_festive_date_mapping_1_1 as date_map
        on ratio.order_date_key = date_map.dates_last_year

),

inventory as(
    SELECT
        listing_id,
        sum(final_atp) as atp
    FROM bigfoot_external_neo.mp_sp__listing_atp_inventory_fact
    GROUP BY listing_id
),

listing_mapping as(
    select
        listing_id,
        analytic_vertical
    from bigfoot_external_neo.sp_product__listing_hive_dim
),

dates AS (
    select distinct dates_current_year FROM ratio
    -- where dates_current_year = CAST(DATE_FORMAT(CURRENT_DATE, '%Y%m%d') AS INT)
)

SELECT 
    b.listing_id,
    -- b.analytic_super_category,
    r.vertical,
    r.dates_current_year as date,
    i.atp AS atp,
    b.aug_drr_units as units,
    r.ratio as ratio

FROM top_60 b

left join listing_mapping as lm 
    on lm.listing_id = b.listing_id

cross join dates as d

left join ratio r 
    ON r.analytic_super_category = b.analytic_super_category
        and lm.analytic_vertical = r.vertical 
        and d.dates_current_year = r.dates_current_year

left join inventory as i
    ON b.listing_id = i.listing_id

-- WHERE d.dates_current_year = CAST(DATE_FORMAT(CURRENT_DATE, '%Y%m%d') AS INT)