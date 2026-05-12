SELECT 
    substr(cast(sales.order_date_key as string),1,6) as year_mo,
    CASE when c.new_cust_flag = 1 then 'NN'
        when c.new_cust_flag <> 1 and c.new_to_bu = 1 then 'ON' else 'OO' end as nn_on_oo_flag,
    geo.city_tier,
    case 
        when lockin_context = "VIP_ACTIVE" then "VIP"
        when lockin_context in ("PREMIUM_ACTIVE", "CLASSIC_ACTIVE", "DEFAULT_ACTIVE") then "Plus" 
    else "Others" end as lockin_context,
    count(distinct sales.account_id) as customers,
    sum(sales.gmv) as gmv,
    sum(sales.units) as units

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales 

LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'home'  
    and sales.marketplace_id='HYPERLOCAL'

left join bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim as geo
    on geo.pincode = sales.pincode


LEFT JOIN 
(
    SELECT 
        order_item_id,
        MAX(new_cust_flag) as new_cust_flag,
        MAX(new_to_bu) as new_to_bu

    FROM bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact

    WHERE approve_date_key >= 20220101
    and (new_cust_flag = 1 or new_to_bu = 1)
    GROUP BY 
        order_item_id
) c
ON c.order_item_id = sales.order_item_id

WHERE lower(sales.status) in ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    and sales.type != 'service'
    and sales.replacement_for_unit IS NULL
    and sales.exchange_for_unit IS NULL
    and sales.is_freebie = FALSE
    and sales.order_date_key between 20240101 and 20240831
    and sales.order_date_key <> 20240229
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    and sales.analytic_business_unit = 'Home'
    and sales.is_shopsy_order = FALSE 

GROUP BY
    substr(cast(sales.order_date_key as string),1,6),
    CASE when c.new_cust_flag = 1 then 'NN'
        when c.new_cust_flag <> 1 and c.new_to_bu = 1 then 'ON' else 'OO' end ,
    geo.city_tier,
    case 
        when lockin_context = "VIP_ACTIVE" then "VIP"
        when lockin_context in ("PREMIUM_ACTIVE", "CLASSIC_ACTIVE", "DEFAULT_ACTIVE") then "Plus" 
    else "Others" end ;