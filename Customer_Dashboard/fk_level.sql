SELECT 
substr(fuf.order_date_key,1,6) as month, 

COUNT(DISTINCT fuf.account_id) as tc,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag = 1 THEN fuf.account_id END)) AS nn,
SUM((CASE WHEN sales.new_cust_flag = 1 THEN fuf.gmv END)) AS nn_GMV,
SUM((CASE WHEN sales.new_cust_flag = 1 THEN fuf.units END)) AS nn_units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag = 1 THEN fuf.order_external_id END)) AS nn_orders,
SUM((CASE WHEN sales.new_cust_flag = 1 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag = 1 THEN fuf.order_external_id END)) as nn_aov,

COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.account_id END)) AS onbu ,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.gmv END)) AS on_gmv,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.units END)) AS on_units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.order_external_id END)) AS on_orders,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.order_external_id END)) as on_aov,

COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.account_id END)) AS oobu ,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.gmv END)) AS oo_gmv,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.units END)) AS oo_units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu <>  1 THEN fuf.order_external_id END)) AS oo_orders,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.order_external_id END)) as oo_aov,

COUNT(DISTINCT fuf.order_external_id)/COUNT(DISTINCT fuf.account_id) as tpc,
SUM(fuf.units)/COUNT(DISTINCT fuf.account_id) as u2o,
COUNT (DISTINCT CASE WHEN prem.cohort="H" then fuf.account_id end ) as premium_customers,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND sales.new_cust_flag = 1 THEN fuf.account_id END)) AS nn_premium,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 THEN fuf.account_id END)) AS on_premium,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 THEN fuf.account_id END)) AS oo_premium,
SUM((CASE WHEN prem.cohort="H" THEN fuf.gmv END)) AS premium_gmv,
SUM((CASE WHEN prem.cohort="H" THEN fuf.units END)) AS premium_units,

COUNT(DISTINCT(CASE WHEN prem.cohort="H" THEN fuf.order_external_id END)) AS premium_orders,
SUM((CASE WHEN prem.cohort="H" THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN prem.cohort="H" THEN fuf.order_external_id END)) as premium_aov,

COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.account_id END)) as tc_women, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as nn_women, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1  THEN fuf.account_id END)) as on_women, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_women,  
SUM((CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.gmv END)) AS women_gmv,
SUM((CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.units END)) AS women_units,
COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.order_external_id END)) AS women_orders,
SUM((CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.order_external_id END)) as women_aov,

COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.account_id END)) as tc_male, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as nn_male, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1  THEN fuf.account_id END)) as on_male, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_male,  
SUM((CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.gmv END)) AS male_gmv,
SUM((CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.units END)) AS male_units,
COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.order_external_id END)) AS male_orders,
SUM((CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.order_external_id END)) as male_aov,

COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' THEN fuf.account_id END)) as tc_metro,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 1A' THEN fuf.account_id END)) as tc_tier1a,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 1B' THEN fuf.account_id END)) as tc_tier1b,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 2' THEN fuf.account_id END)) as tc_Tier2,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 3 & Others' THEN fuf.account_id END)) as tc_tier3,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.account_id END)) as tc_mt1, 
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as nn_mt1, 
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1  THEN fuf.account_id END)) as on_mt1,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_mt1,
SUM((CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.gmv END)) AS metrot1_gmv,
SUM((CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.units END)) AS metrot1_units,
COUNT(DISTINCT(CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.order_external_id END)) AS metrot1_orders,
SUM((CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.order_external_id END)) as metrot1_aov,

COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES'  THEN fuf.account_id END)) as tc_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES'  AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as nn_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES'  AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1  THEN fuf.account_id END)) as on_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES'  AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_parent,  
SUM((CASE WHEN demo.is_parent = 'YES'  THEN fuf.gmv END)) AS parent_gmv,
SUM((CASE WHEN demo.is_parent = 'YES'  THEN fuf.units END)) AS parent_units,
COUNT(DISTINCT(CASE WHEN demo.is_parent = 'YES'  THEN fuf.order_external_id END)) AS parent_orders,
SUM((CASE WHEN demo.is_parent = 'YES'  THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN demo.is_parent = 'YES' THEN fuf.order_external_id END)) as parent_aov, 
 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES'  THEN fuf.account_id END)) as tc_student, 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as nn_student, 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1  THEN fuf.account_id END)) as on_student, 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES'  AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_student,  
SUM((CASE WHEN demo.is_student = 'YES'  THEN fuf.gmv END)) AS student_gmv,
SUM((CASE WHEN demo.is_student = 'YES'  THEN fuf.units END)) AS student_units,
COUNT(DISTINCT(CASE WHEN demo.is_student = 'YES'  THEN fuf.order_external_id END)) AS student_orders,
SUM((CASE WHEN demo.is_student = 'YES' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN demo.is_student = 'YES'  THEN fuf.order_external_id END)) as student_aov,

COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.account_id END)) as tc_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as nn_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1  THEN fuf.account_id END)) as on_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_alpha,  
SUM((CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.gmv END)) AS alpha_gmv,
SUM((CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.units END)) AS alpha_units,
COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.order_external_id END)) AS alpha_orders,
SUM((CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.order_external_id END)) as alpha_aov,

COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.account_id END)) as tc_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND sales.new_cust_flag = 0 THEN fuf.account_id END)) as nn_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 0  THEN fuf.account_id END)) as on_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1  THEN fuf.account_id END)) as oo_mp,  
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.gmv END)) AS mp_gmv,
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.units END)) AS mp_units,
COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.order_external_id END)) AS mp_orders,
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.order_external_id END)) as mp_aov,

count(distinct case when lower(p.payment_instrument) = 'cod' then fuf.order_external_id end) as cod_orders,
count(distinct case when lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as cod_nn_orders,
count(distinct case when lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as cod_on_orders,
count(distinct case when lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as cod_oo_orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END)) AS cod_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.units END)) AS cod_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.order_external_id END)) as cod_AOV,

count(distinct case when lower(p.payment_instrument) = 'credit' then fuf.order_external_id end) as credit_orders,
count(distinct case when lower(p.payment_instrument) = 'credit' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as credit_nn_orders,
count(distinct case when lower(p.payment_instrument) = 'credit' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as credit_on_orders,
count(distinct case when lower(p.payment_instrument) = 'credit' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as credit_oo_orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.gmv END)) AS credit_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.units END)) AS credit_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.order_external_id END)) as credit_AOV,

count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' then fuf.order_external_id end) as upi_orders,
count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as upi_nn_orders,
count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as upi_on_orders,
count(distinct case when lower(p.payment_instrument) = 'phonepe' OR lower(p.payment_instrument) = 'upi_intent' OR lower(p.payment_instrument) = 'upi_collect' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as upi_oo_orders,
SUM((CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.gmv END)) AS upi_GMV,
SUM((CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.units END)) AS upi_Units,
SUM((CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN LOWER(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.order_external_id END)) AS upi_AOV,

count(distinct case when lower(p.payment_instrument) = 'net' then fuf.order_external_id end) as net_banking_orders,
count(distinct case when lower(p.payment_instrument) = 'net' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as net_banking_nn_orders,
count(distinct case when lower(p.payment_instrument) = 'net' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as net_banking_on_orders,
count(distinct case when lower(p.payment_instrument) = 'net' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as net_banking_oo_orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.gmv END)) AS net_banking_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.units END)) AS net_banking_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.order_external_id END)) as net_banking_AOV,

count(distinct case when lower(p.payment_mode) = 'postpaid' then fuf.order_external_id end) as postpaid_orders,
count(distinct case when lower(p.payment_mode) = 'postpaid' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as postpaid_nn_orders,
count(distinct case when lower(p.payment_mode) = 'postpaid' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as postpaid_on_orders,
count(distinct case when lower(p.payment_mode) = 'postpaid' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as postpaid_oo_orders,
SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.gmv END)) AS postpaid_GMV,
SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.units END)) AS postpaid_Units,
SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.order_external_id END)) as postpaid_AOV,

count(distinct case when lower(p.payment_instrument) = 'emi' then fuf.order_external_id end) as emi_orders,
count(distinct case when lower(p.payment_instrument) = 'emi' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as emi_nn_orders,
count(distinct case when lower(p.payment_instrument) = 'emi' AND sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 then fuf.order_external_id end) as emi_on_orders,
count(distinct case when lower(p.payment_instrument) = 'emi' AND sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 then fuf.order_external_id end) as emi_oo_orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.gmv END)) AS emi_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.units END)) AS emi_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.order_external_id END)) as emi_AOV,

COUNT(DISTINCT fuf.order_external_id) as orders, 

COUNT(DISTINCT(CASE WHEN fuf.user_lockin_state='active' THEN fuf.account_id END)) as Plus_customers,
SUM((CASE WHEN fuf.user_lockin_state='active' THEN fuf.gmv END)) as Plus_GMV,
SUM((CASE WHEN fuf.user_lockin_state='active' THEN fuf.units END)) as Plus_Units,
COUNT(DISTINCT(CASE WHEN fuf.user_lockin_state='active' THEN fuf.order_external_id END)) as Plus_Orders,
SUM((CASE WHEN fuf.user_lockin_state='active' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN fuf.user_lockin_state='active' THEN fuf.order_external_id END)) as Plus_AOV,

sum(fuf.gmv) as gmv,
sum(fuf.units) as units,
sum(fuf.gmv)/count(distinct fuf.order_external_id) as aov

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
AND fuf.order_date_key between 20251101 and 20251130

GROUP BY 
substr(fuf.order_date_key,1,6)