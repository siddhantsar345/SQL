create table adhoc_ttl_90days.homedecor_base_till_29th_sep2025_base_1 as
SELECT
    sales.datekey AS day_key,
    count(distinct CONCAT(sales.accountid, '_', pc.analytic_vertical)) as accountverticalcombo,
    COUNT(DISTINCT sales.accountid) AS total_distinct_account_ids_in_group,
    SUM(sales.primarylistingppvs) AS total_primary_ppvs,
    SUM(sales.addtocartclicks) AS total_addtocart_clicks,
    SUM(sales.buynowclicks) AS total_buynow_clicks
FROM
   bigfoot_external_neo.cp_cdm_consumer__incr_agg_consumer_session_id_listing_fact sales
INNER JOIN bigfoot_external_neo.sp_product__product_categorization_hive_dim pc
        ON sales.productid = pc.product_id
INNER JOIN
    adhoc_ttl_90days.homedecor_on_test_till_16th_sep2025 AS ad
    ON sales.accountid = ad.account_id
WHERE
    sales.datekey BETWEEN 20250923 AND 20250927
    AND lower(pc.analytic_business_unit)= 'home'
    AND lower(pc.analytic_super_category) IN ('homedecor')
    AND lower(pc.analytic_vertical) IN (
        'fashionmangalsutratanmaniya', 'womenfashionbangle', 'fashionjewelleryset', 
        'womenlehengacholi', 'fashionjewellerycombo', 'makeupkit', 'womencargo', 
        'girllehengacholi', 'womenfashionearring', 'womenfabric', 'womendupatta', 
        'womenblouse'
    )
GROUP BY
sales.datekey