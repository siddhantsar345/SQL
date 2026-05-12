SELECT 
substr(fuf.order_date_key,1,6) as month, 
fuf.analytic_business_unit as bu,
fuf.analytic_super_category as SC,

COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.account_id END)) as TC_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND sales.new_cust_flag = 0 and sales.new_to_bu = 1 THEN fuf.account_id END)) as NN_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as ONN_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as OON_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.account_id END)) as OOO_mp,   
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.gmv END)) AS mp_GMV,
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.units END)) AS mp_Units,
COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.order_external_id END)) AS mp_Orders,
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.order_external_id END)) as mp_AOV,
sum(fuf.gmv) as gmv,
sum(fuf.units) as units,
sum(fuf.gmv)/count(distinct fuf.order_external_id) as aov

FROM 
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact  fuf
Left join
bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact sales
ON fuf.order_item_id = sales.order_item_id

LEFT JOIN  bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact demo
on fuf.account_id = demo.account_id

left join (select distinct account_id,cohort from bigfoot_external_neo.cp_uie__affluence_v3_2_final_output_fact where cohort="H") as prem
on prem.account_id=fuf.account_id

left join bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim as geo
ON geo.logistics_geo_hive_dim_key = fuf.shipping_address_pincode_key 

   left join 

    (select order_external_id, 
    max(payment_instrument) as payment_instrument, 
    max(payment_mode) as payment_mode 
    from bigfoot_external_neo.cp_bi_prod_sales__forward_payments_365_fact
    group by order_external_id) as p

    ON fuf.order_external_id = p.order_external_id

where
lower(fuf.status) in ('in_progress','undelivered','completed','delivered','approved','shipped','ready_to_ship','returned', 'return_requested','activated')
AND fuf.type !='service'
AND fuf.category_id !=21726
AND fuf.category_id !=21651
AND fuf.replacement_for_unit IS NULL
AND fuf.exchange_for_unit IS NULL
AND fuf.is_freebie =FALSE
AND fuf.marketplace_id IN ('FLIPKART')
AND fuf.is_shopsy_order =FALSE
AND fuf.analytic_business_unit in ('BGM','Home') 
AND fuf.order_date_key between 20250801 and 20250831

GROUP BY 
substr(fuf.order_date_key,1,6), 
fuf.analytic_business_unit,
fuf.analytic_super_category