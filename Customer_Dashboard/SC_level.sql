SELECT 
substr(fuf.order_date_key,1,6) as month, 
fuf.analytic_business_unit as bu,
fuf.analytic_super_category as SC, 


COUNT(DISTINCT fuf.account_id) as TC,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag = 1 THEN fuf.account_id END)) AS NN,
SUM((CASE WHEN sales.new_cust_flag = 1 THEN fuf.gmv END)) AS NN_GMV,
SUM((CASE WHEN sales.new_cust_flag = 1 THEN fuf.units END)) AS NN_Units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag = 1 THEN fuf.order_external_id END)) AS NN_Orders,
SUM((CASE WHEN sales.new_cust_flag = 1 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag = 1 THEN fuf.order_external_id END)) as NN_AOV,

COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) AS ONNBU ,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.gmv END)) AS ONN_GMV,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.units END)) AS ONN_Units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.order_external_id END)) AS ONN_Orders,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.order_external_id END)) as ONN_AOV,

COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) AS OONBU ,
SUM((CASE WHEN sales.new_cust_flag <> 1  AND (sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.gmv END)) AS OON_GMV,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND  (sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.units END)) AS OON_Units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1  AND (sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.order_external_id END)) AS OON_Orders,
SUM((CASE WHEN sales.new_cust_flag <> 1  AND (sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1  AND (sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.order_external_id END)) as OON_AOV,

COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <> 1 AND sales.new_to_sc <> 1 )THEN fuf.account_id END)) AS OOBU ,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.gmv END)) AS OO_GMV,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.units END)) AS OO_Units,
COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <>  1 AND sales.new_to_sc <> 1) THEN fuf.order_external_id END)) AS OO_Orders,
SUM((CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN sales.new_cust_flag <> 1 AND (sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.order_external_id END)) as OO_AOV,

COUNT(DISTINCT fuf.order_external_id)/COUNT(DISTINCT fuf.account_id) as TPC,
SUM(fuf.units)/COUNT(DISTINCT fuf.account_id) as U2O,

COUNT(DISTINCT(CASE WHEN prem.cohort="H" then fuf.account_id end))as Premium_customers,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND sales.new_cust_flag = 1 THEN fuf.account_id END)) AS NN_Premium,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) AS ONN_Premium,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) AS OON_Premium,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.account_id END)) AS OOO_Premium,
SUM((CASE WHEN prem.cohort="H" THEN fuf.gmv END)) AS Premium_GMV,
SUM((CASE WHEN prem.cohort="H" THEN fuf.units END)) AS Premium_Units,
COUNT(DISTINCT(CASE WHEN prem.cohort="H" THEN fuf.order_external_id END)) AS Premium_Orders,
SUM((CASE WHEN prem.cohort="H" THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN prem.cohort="H" THEN fuf.order_external_id END)) as Premium_AOV,

COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.account_id END)) as TC_women, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as NN_women, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) as ONN_women,
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) as OON_women, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('FEMALE') AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.account_id END)) as OOO_women,  
SUM((CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.gmv END)) AS Women_GMV,
SUM((CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.units END)) AS Women_Units,
COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.order_external_id END)) AS Women_Orders,
SUM((CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('FEMALE') THEN fuf.order_external_id END)) as Women_AOV,

COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.account_id END)) as TC_male, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as NN_male, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) as ONN_male,
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) as OON_male, 
COUNT(DISTINCT (CASE WHEN UPPER(demo.gender) in ('MALE') AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1) THEN fuf.account_id END)) as OOO_male,   
SUM((CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.gmv END)) AS male_GMV,
SUM((CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.units END)) AS male_Units,
COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.order_external_id END)) AS male_Orders,
SUM((CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN UPPER(demo.gender) in ('MALE') THEN fuf.order_external_id END)) as male_AOV,

COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' THEN fuf.account_id END)) as TC_Metro,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 1A' THEN fuf.account_id END)) as TC_Tier1A,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 1B' THEN fuf.account_id END)) as TC_Tier1B,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 2' THEN fuf.account_id END)) as TC_Tier2,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Tier 3 & Others' THEN fuf.account_id END)) as TC_Tier3,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.account_id END)) as TC_MT1, 
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as NN_MT1, 
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1) THEN fuf.account_id END)) as ONN_MT1,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as OON_MT1,
COUNT(DISTINCT (CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.account_id END)) as OOO_MT1,
SUM((CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.gmv END)) AS MetroT1_GMV,
SUM((CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.units END)) AS MetroT1_Units,
COUNT(DISTINCT(CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.order_external_id END)) AS MetroT1_Orders,
SUM((CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN geo.city_tier = 'Metro' OR geo.city_tier = 'Tier 1A' OR geo.city_tier = 'Tier 1B' THEN fuf.order_external_id END)) as MetroT1_AOV,

COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES' THEN fuf.account_id END)) as TC_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES' AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as NN_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as ONN_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as OON_parent, 
COUNT(DISTINCT (CASE WHEN demo.is_parent = 'YES' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.account_id END)) as OOO_parent,  
SUM((CASE WHEN demo.is_parent = 'YES' THEN fuf.gmv END)) AS parent_GMV,
SUM((CASE WHEN demo.is_parent = 'YES' THEN fuf.units END)) AS parent_Units,
COUNT(DISTINCT(CASE WHEN demo.is_parent = 'YES' THEN fuf.order_external_id END)) AS parent_Orders,
SUM((CASE WHEN demo.is_parent = 'YES' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN demo.is_parent = 'YES' THEN fuf.order_external_id END)) as parent_AOV, 
 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' THEN fuf.account_id END)) as TC_student, 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as NN_student, 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as ONN_student,  
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as OON_student, 
COUNT(DISTINCT (CASE WHEN demo.is_student = 'YES' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.account_id END)) as OOO_student,  
SUM((CASE WHEN demo.is_student = 'YES' THEN fuf.gmv END)) AS student_GMV,
SUM((CASE WHEN demo.is_student = 'YES' THEN fuf.units END)) AS student_Units,
COUNT(DISTINCT(CASE WHEN demo.is_student = 'YES' THEN fuf.order_external_id END)) AS student_Orders,
SUM((CASE WHEN demo.is_student = 'YES' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN demo.is_student = 'YES' THEN fuf.order_external_id END)) as student_AOV,

COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.account_id END)) as TC_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND sales.new_cust_flag = 1 THEN fuf.account_id END)) as NN_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as ONN_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as OON_alpha, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 1 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.account_id END)) as OOO_alpha,  
SUM((CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.gmv END)) AS alpha_GMV,
SUM((CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.units END)) AS alpha_Units,
COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.order_external_id END)) AS alpha_Orders,
SUM((CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 1 THEN fuf.order_external_id END)) as alpha_AOV,

COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.account_id END)) as TC_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND sales.new_cust_flag = 0 THEN fuf.account_id END)) as NN_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as ONN_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.account_id END)) as OON_mp, 
COUNT(DISTINCT (CASE WHEN fuf.is_alpha_seller = 0 AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.account_id END)) as OOO_mp,   
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.gmv END)) AS mp_GMV,
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.units END)) AS mp_Units,
COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.order_external_id END)) AS mp_Orders,
SUM((CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN fuf.is_alpha_seller = 0 THEN fuf.order_external_id END)) as mp_AOV,

count(distinct case when lower(p.payment_instrument) = 'cod' then fuf.order_external_id end) as cod_Orders,
count(distinct case when lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as cod_NN_Orders,
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'cod' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as cod_ONN_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'cod' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as cod_OON_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'cod' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as cod_OOO_Orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END)) AS cod_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.units END)) AS cod_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.order_external_id END)) as cod_AOV,

count(distinct case when lower(p.payment_instrument) = 'credit' then fuf.order_external_id end) as credit_Orders,
count(distinct case when lower(p.payment_instrument) = 'credit' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as credit_NN_Orders,
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'credit' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as credit_ONN_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'credit' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as credit_OON_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'credit' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as credit_OOO_Orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.gmv END)) AS credit_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.units END)) AS credit_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'credit' THEN fuf.order_external_id END)) as credit_AOV,

count(distinct case when lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') then fuf.order_external_id end) as UPI_Orders,
count(distinct case when (lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND sales.new_cust_flag = 1 then fuf.order_external_id end) as UPI_NN_Orders,
count(DISTINCT (CASE WHEN (lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as phonepe_ONN_Orders, 
count(DISTINCT (CASE WHEN (lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as phonepe_OON_Orders,
count(DISTINCT (CASE WHEN (lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect')) AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as phonepe_OOO_Orders,
sum((CASE WHEN lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.gmv END)) AS upi_GMV,
sum((CASE WHEN lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.units END)) AS upi_Units,
sum((CASE WHEN lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) IN ('phonepe', 'upi_intent', 'upi_collect') THEN fuf.order_external_id END)) as upi_AOV,

count(distinct case when lower(p.payment_instrument) = 'net' then fuf.order_external_id end) as net_Banking_Orders,
count(distinct case when lower(p.payment_instrument) = 'net' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as net_Banking_NN_Orders,
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'net' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as net_Banking_ONN_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'net' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as net_Banking_OON_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'net' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as net_Banking_OOO_Orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.gmv END)) AS net_banking_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.units END)) AS net_banking_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'net' THEN fuf.order_external_id END)) as net_banking_AOV,

count(distinct case when lower(p.payment_mode) = 'postpaid' then fuf.order_external_id end) as postpaid_Orders,
count(distinct case when lower(p.payment_mode) = 'postpaid' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as postpaid_NN_Orders,
COUNT(DISTINCT (CASE WHEN lower(p.payment_mode) = 'postpaid' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as postpaid_ONN_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_mode) = 'postpaid' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as postpaid_OON_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_mode) = 'postpaid' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as postpaid_OOO_Orders,
SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.gmv END)) AS postpaid_GMV,
SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.units END)) AS postpaid_Units,
SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.order_external_id END)) as postpaid_AOV,

count(distinct case when lower(p.payment_instrument) = 'emi' then fuf.order_external_id end) as emi_Orders,
count(distinct case when lower(p.payment_instrument) = 'emi' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as emi_NN_Orders,
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'emi' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as emi_ONN_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'emi' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as emi_OON_Orders, 
COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'emi' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as emi_OOO_Orders,
SUM((CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.gmv END)) AS emi_GMV,
SUM((CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.units END)) AS emi_Units,
SUM((CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'emi' THEN fuf.order_external_id END)) as emi_AOV,

COUNT(DISTINCT fuf.order_external_id) as Orders,

COUNT(DISTINCT(CASE WHEN lower(fuf.user_lockin_state)='active' THEN fuf.account_id END)) AS Plus_customers,
SUM((CASE WHEN lower(fuf.user_lockin_state)='active' THEN fuf.gmv END)) AS Plus_GMV,
SUM((CASE WHEN lower(fuf.user_lockin_state)='active' THEN fuf.units END)) AS Plus_Units,
COUNT(DISTINCT(CASE WHEN lower(fuf.user_lockin_state)='active' THEN fuf.order_external_id END)) AS Plus_Orders,
SUM((CASE WHEN lower(fuf.user_lockin_state)='active' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(fuf.user_lockin_state)='active' THEN fuf.order_external_id END)) as Plus_AOV,

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
AND fuf.order_date_key between 20251101 and 20251130

GROUP BY 
substr(fuf.order_date_key,1,6), 
fuf.analytic_business_unit,
fuf.analytic_super_category