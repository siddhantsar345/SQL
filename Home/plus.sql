SELECT
substr(cast(sales.order_date_key as string), 1, 6) as year_mo,
sales.analytic_super_category,
count(distinct sales.account_id) as customers,
case 
    when lockin_context = "VIP_ACTIVE" then "VIP"
    when lockin_context in ("PREMIUM_ACTIVE", "CLASSIC_ACTIVE", "DEFAULT_ACTIVE") then "Plus" 
    else "Others" end as lockin_context

FROM bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact as sales

    LEFT JOIN  fdp_uploads.ds_fkint_cp_santa_hyperlocal_vertical_bu_mapping_2_0 AS hl 
    ON sales.analytic_vertical = hl.analytic_vertical 
    AND LOWER(hl.bu_final) = 'home'  
    and sales.marketplace_id='HYPERLOCAL'

left join bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim as geo
    on geo.pincode = sales.pincode

WHERE lower(sales.status) in ('in_progress', 'undelivered', 'completed', 'delivered', 'approved', 'shipped', 'ready_to_ship', 'returned', 'return_requested', 'activated')
    and sales.type != 'service'
    and sales.replacement_for_unit IS NULL
    and sales.exchange_for_unit IS NULL
    and sales.is_freebie = FALSE
    and sales.order_date_key between 20250101 and 20250930
    AND (sales.marketplace_id IN ('FLIPKART') OR (sales.marketplace_id = 'HYPERLOCAL' AND  hl.analytic_vertical IS NOT NULL))
    and sales.analytic_business_unit = 'Home'
    and lower(sales. analytic_super_category) in ('homedecor','homefurnishing','homeimprovementtool','household')
    and sales.is_shopsy_order = FALSE 

GROUP BY
    1,
    sales.analytic_super_category,
    case 
        when lockin_context = "VIP_ACTIVE" then "VIP"
        when lockin_context in ("PREMIUM_ACTIVE", "CLASSIC_ACTIVE", "DEFAULT_ACTIVE") then "Plus" 
    else "Others" end ;