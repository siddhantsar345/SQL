SELECT 
    DISTINCT imp.account_id 
FROM 
    bigfoot_external_neo.cp_cdm_consumer__incr_consumer_impression_ppv_agg_mini_fact imp
inner join 
    bigfoot_external_neo.sp_product__listing_hive_dim sales
    on imp.listing_id = sales.listing_id
WHERE 
    imp.datekey between 20260108 and 20260408
    and imp.product_page_views > 0
    and LOWER(sales.analytic_business_unit) = 'bgm'
    and LOWER(sales.analytic_super_category) = 'pets'




create table adhoc_ttl_90days.bgm_pets_last_3_months as (
SELECT 
    DISTINCT imp.account_id 
FROM 
    bigfoot_external_neo.cp_cdm_consumer__incr_consumer_impression_ppv_agg_mini_fact imp
inner join 
    bigfoot_external_neo.sp_product__listing_hive_dim sales
    on imp.listing_id = sales.listing_id
WHERE 
    imp.datekey between 20260108 and 20260408
    and imp.product_page_views > 0
    and LOWER(sales.analytic_business_unit) = 'bgm'
    and LOWER(sales.analytic_super_category) = 'pets'
)