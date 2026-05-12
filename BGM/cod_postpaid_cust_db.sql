SELECT 
    substr(fuf.order_date_key, 1, 6) as month, 
    fuf.analytic_business_unit as bu,
    fuf.analytic_super_category as SC, 
    sum(fuf.gmv) as gmv,
    sum(fuf.units) as units,

    count(distinct case when lower(p.payment_instrument) = 'cod' then fuf.order_external_id end) as cod_Orders,
    count(distinct case when lower(p.payment_instrument) = 'cod' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as cod_NN_Orders,
    COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'cod' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as cod_ONN_Orders, 
    COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'cod' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as cod_OON_Orders, 
    COUNT(DISTINCT (CASE WHEN lower(p.payment_instrument) = 'cod' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as cod_OOO_Orders,
    SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END)) AS cod_GMV,
    SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.units END)) AS cod_Units,
    SUM((CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_instrument) = 'cod' THEN fuf.order_external_id END)) as cod_AOV,

    count(distinct case when lower(p.payment_mode) = 'postpaid' then fuf.order_external_id end) as postpaid_Orders,
    count(distinct case when lower(p.payment_mode) = 'postpaid' AND sales.new_cust_flag = 1 then fuf.order_external_id end) as postpaid_NN_Orders,
    COUNT(DISTINCT (CASE WHEN lower(p.payment_mode) = 'postpaid' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu = 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as postpaid_ONN_Orders, 
    COUNT(DISTINCT (CASE WHEN lower(p.payment_mode) = 'postpaid' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc = 1)  THEN fuf.order_external_id END)) as postpaid_OON_Orders, 
    COUNT(DISTINCT (CASE WHEN lower(p.payment_mode) = 'postpaid' AND (sales.new_cust_flag <> 1 AND sales.new_to_bu <> 1 AND sales.new_to_sc <> 1)  THEN fuf.order_external_id END)) as postpaid_OOO_Orders,
    SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.gmv END)) AS postpaid_GMV,
    SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.units END)) AS postpaid_Units,
    SUM((CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.gmv END))/COUNT(DISTINCT(CASE WHEN lower(p.payment_mode) = 'postpaid' THEN fuf.order_external_id END)) as postpaid_AOV


FROM 
    bigfoot_external_neo.cp_bi_prod_sales__forward_unit_history_fact fuf

Left join
    bigfoot_external_neo.analytics_cdo__customer_insight_hive_fact sales
    ON fuf.order_item_id = sales.order_item_id

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
    AND fuf.order_date_key between 20240101 and 20240601

GROUP BY 
    substr(fuf.order_date_key,1,6), 
    fuf.analytic_business_unit,
    fuf.analytic_super_category