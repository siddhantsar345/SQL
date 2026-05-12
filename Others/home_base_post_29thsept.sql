create table adhoc_ttl_90days.homedecor_post_base_29th_sep2025 as 
SELECT
    sales.datekey AS day_key,
    count(distinct CONCAT(sales.accountid, '_', pc.analytic_vertical)) as accountverticalcombo,
    SUM(sales.primarylistingppvs) AS total_primary_ppvs,
    SUM(sales.addtocartclicks) AS total_addtocart_clicks,
    SUM(sales.buynowclicks) AS total_buynow_clicks
FROM
    bigfoot_external_neo.cp_cdm_consumer__incr_agg_consumer_session_id_listing_fact sales
INNER JOIN
    (
        SELECT DISTINCT account_id
        FROM adhoc_ttl_90days.homedecor_on_test_till_16th_sep2025
    ) AS ad
    ON sales.accountid = ad.account_id
INNER JOIN
    (
        SELECT
            product_id,
            analytic_vertical
        FROM
            bigfoot_external_neo.sp_product__product_categorization_hive_dim
        WHERE
            lower(analytic_business_unit)= 'home'
            AND lower(analytic_super_category) IN ('homedecor')
            AND lower(analytic_vertical) IN (
                'fashionmangalsutratanmaniya', 'womenfashionbangle', 'fashionjewelleryset',
                'womenlehengacholi', 'fashionjewellerycombo', 'makeupkit', 'womencargo',
                'girllehengacholi', 'womenfashionearring', 'womenfabric', 'womendupatta',
                'womenblouse'
            )
    ) pc
    ON sales.productid = pc.product_id
WHERE
    sales.datekey BETWEEN 20250923 AND 20250927
GROUP BY
    sales.datekey