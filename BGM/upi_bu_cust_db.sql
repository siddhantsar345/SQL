SELECT 
substr(fuf.order_date_key,1,6) as month, 
fuf.analytic_business_unit as bu, 

count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' then fuf.order_external_id end) as upi_orders,
count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as upi_nn_orders,
count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as upi_on_orders,
count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as upi_oo_orders,
SUM((case when lower(p.payment_instrument) = 'phonepe'  OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' THEN fuf.gmv END)) AS upi_GMV,
SUM((case when lower(p.payment_instrument) = 'phonepe'  OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' THEN fuf.units END)) AS upi_Units,
SUM((case when lower(p.payment_instrument) = 'phonepe'  OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' THEN fuf.gmv END))/COUNT(DISTINCT(case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' THEN fuf.order_external_id END)) as upi_AOV,

sum(fuf.gmv) as gmv,
sum(fuf.units) as units

FROM 
bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact  fuf

Left join (select order_item_id, approve_date_key, new_cust_flag, new_to_bu from bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact) as sales  
on fuf.order_item_id = sales.order_item_id 

LEFT JOIN  bigfoot_external_neo.cp_uie__account_demographics_insight_beta_fact as demo
on fuf.account_id = demo.account_id

left join (select distinct account_id,cohort from bigfoot_external_neo.cp_uie__affluence_v3_2_final_output_fact where cohort="H") as prem
on prem.account_id=fuf.account_id

left join (select logistics_geo_hive_dim_key, city_tier from bigfoot_external_neo.scp_ekl__logistics_geo_hive_dim) as geo
on geo.logistics_geo_hive_dim_key = fuf.shipping_address_pincode_key 

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
AND fuf.order_date_key  between 20250101 and 20251031

GROUP BY 
substr(fuf.order_date_key,1,6), 
fuf.analytic_business_unit